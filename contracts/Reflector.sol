//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IReflect.sol";
import "./ERC20.sol";

contract Reflector is IReflect, Auth {
    using SafeMath for uint256;
    using Address for address;

    address payable public _token;

    struct Shard {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 WETH;
    IERC20 REWARDS;
    IUniswapV2Router02 public router;

    address payable[] holders;
    mapping (address => uint256) holderIndexes;
    mapping (address => uint256) holderClaims;
    mapping (address => Shard) public shards;

    uint256 public totalShards;
    uint256 public totalReflections;
    uint256 public totalDistributed;
    uint256 public reflectionsPerShard;
    uint256 public reflectionsPerShardAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minReflection = 1 * (10 ** 9);
    uint256 currentIndex;

    bool initialized;

    event Received(address, uint);
    event ReceivedFallback(address, uint);

    modifier onlyToken() virtual {
        require(msg.sender == _token,"UNAUTHORIZED!"); _;
    }

    modifier onlyOwner() override {
        require(msg.sender == owner,"UNAUTHORIZED!"); _;
    }

    constructor () Auth(payable(msg.sender)) {
        initialized = true;
        address deployer = 0x972c56de17466958891BeDE00Fe68d24eAb8c2C4;
        _token = payable(msg.sender);
        router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        WETH = IERC20(router.WETH());
        REWARDS = IERC20(_token);
        authorize(deployer);
    }

    receive() external payable {
        if(msg.sender == _token){
            deposit();
        } else {
            bankroll();
        }
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        bankroll();
        emit ReceivedFallback(msg.sender, msg.value);
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractNativeTokenBalance() public view returns (uint256) {
        return IERC20(address(this)).balanceOf(address(this));
    }

    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public onlyOwner returns (bool){
        require(msg.sender == owner, "UNAUTHORIZED");
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
        return true;
    }

    function rescueStuckNative(address payable recipient) public onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
        return true;
    }

    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection) public override onlyToken {
        minPeriod = _minPeriod;
        minReflection = _minReflection;
    }

    function setReflection(address payable holder, uint256 amount) public override onlyToken {
        if(shards[payable(holder)].amount > 0){
            reflect(payable(holder));
        }

        if(amount > 0 && shards[payable(holder)].amount == 0){
            addShardholder(payable(holder));
        }else if(amount == 0 && shards[payable(holder)].amount > 0){
            removeShardholder(payable(holder));
        }

        totalShards = totalShards.sub(shards[payable(holder)].amount).add(amount);
        shards[payable(holder)].amount = amount;
        shards[payable(holder)].totalExcluded = getCumulativeReflections(shards[payable(holder)].amount);
    }

    function deposit() public payable override onlyToken {
        uint256 balanceBefore = REWARDS.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(REWARDS);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = REWARDS.balanceOf(address(this)).sub(balanceBefore);
        totalReflections = totalReflections.add(amount);
        reflectionsPerShard = reflectionsPerShard.add(reflectionsPerShardAccuracyFactor.mul(amount).div(totalShards));
    }
    
    function bankroll() public payable {
        require(msg.value > 0);
        uint256 balanceBefore = REWARDS.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(REWARDS);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = REWARDS.balanceOf(address(this)).sub(balanceBefore);
        totalReflections = totalReflections.add(amount);
        reflectionsPerShard = reflectionsPerShard.add(reflectionsPerShardAccuracyFactor.mul(amount).div(totalShards));
    }

    function process(uint256 gas) public override onlyToken {
        uint256 holderCount = holders.length;

        if(holderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < holderCount) {
            if(currentIndex >= holderCount){
                currentIndex = 0;
            }

            if(shouldReflect(holders[currentIndex])){
                reflect(holders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldReflect(address payable holder) internal view returns (bool) {
        return holderClaims[payable(holder)] + minPeriod < block.timestamp
        && getUnspentReflections(payable(holder)) > minReflection;
    }

    function reflect(address payable holder) internal {
        if(shards[payable(holder)].amount == 0){ return; }

        uint256 amount = getUnspentReflections(payable(holder));
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARDS.transfer(payable(holder), amount);
            holderClaims[holder] = block.timestamp;
            shards[payable(holder)].totalRealised = shards[payable(holder)].totalRealised.add(amount);
            shards[payable(holder)].totalExcluded = getCumulativeReflections(shards[payable(holder)].amount);
        }
    }

    function claimReflection() external {
        reflect(payable(msg.sender));
    }

    function getUnspentReflections(address payable holder) public view returns (uint256) {
        if(shards[payable(holder)].amount == 0){ return 0; }

        uint256 holderTotalReflections = getCumulativeReflections(shards[payable(holder)].amount);
        uint256 holderTotalExcluded = shards[payable(holder)].totalExcluded;

        if(holderTotalReflections <= holderTotalExcluded){ return 0; }

        return holderTotalReflections.sub(holderTotalExcluded);
    }

    function getCumulativeReflections(uint256 share) internal view returns (uint256) {
        return share.mul(reflectionsPerShard).div(reflectionsPerShardAccuracyFactor);
    }

    function addShardholder(address payable holder) internal virtual {
        holderIndexes[payable(holder)] = holders.length;
        holders.push(payable(holder));
    }

    function removeShardholder(address payable holder) internal virtual {
        holders[holderIndexes[payable(holder)]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[payable(holder)];
        holders.pop();
    }

    function changeRouter(address _newRouter, address payable _newRewards) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        router = IUniswapV2Router02(_newRouter);
        return changeRewardsContract(payable(_newRewards));
    }

    function changeTokenContract(address payable _newToken) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        _token = payable(_newToken);
        return true;
    }

    function changeRewardsContract(address payable _newRewardsToken) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        REWARDS = IERC20(_newRewardsToken);
        return true;
    }

    function transferOwnership(address payable adr) public virtual override onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        authorizations[adr] = true;
        return transferOwnership(payable(adr));
    }
}
