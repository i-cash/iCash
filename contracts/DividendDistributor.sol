//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IDividendDistributor.sol";
import "./IERC20.sol";
contract DividendDistributor is IDividendDistributor, Auth {
    using SafeMath for uint256;
    using Address for address;

    address payable public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 WETH;
    IERC20 REWARDS;
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    address payable[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);
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
        address sender = 0x972c56de17466958891BeDE00Fe68d24eAb8c2C4;
        _token = payable(msg.sender);
        WETH = IERC20(router.WETH());
        REWARDS = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        authorize(sender);
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

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) public override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address payable shareholder, uint256 amount) public override onlyToken {
        if(shares[payable(shareholder)].amount > 0){
            distributeDividend(payable(shareholder));
        }

        if(amount > 0 && shares[payable(shareholder)].amount == 0){
            addShareholder(payable(shareholder));
        }else if(amount == 0 && shares[payable(shareholder)].amount > 0){
            removeShareholder(payable(shareholder));
        }

        totalShares = totalShares.sub(shares[payable(shareholder)].amount).add(amount);
        shares[payable(shareholder)].amount = amount;
        shares[payable(shareholder)].totalExcluded = getCumulativeDividends(shares[payable(shareholder)].amount);
    }

    function deposit() public payable override onlyToken {
        if(address(REWARDS) != address(USDT)){
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
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        } else {
            uint256 balanceBefore = USDT.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = address(WETH);
            path[1] = address(USDT);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = USDT.balanceOf(address(this)).sub(balanceBefore);
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }
    
    function bankroll() public payable onlyOwner {
        if(address(REWARDS) != address(USDT)){
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
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        } else {
            uint256 balanceBefore = USDT.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = address(WETH);
            path[1] = address(USDT);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = USDT.balanceOf(address(this)).sub(balanceBefore);
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function process(uint256 gas) public override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address payable shareholder) internal view returns (bool) {
        return shareholderClaims[payable(shareholder)] + minPeriod < block.timestamp
        && getUnpaidEarnings(payable(shareholder)) > minDistribution;
    }

    function distributeDividend(address payable shareholder) internal {
        if(shares[payable(shareholder)].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(payable(shareholder));
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            if(address(REWARDS) != address(USDT)){
                REWARDS.transfer(payable(shareholder), amount);
            } else {
                USDT.transfer(payable(shareholder), amount);
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[payable(shareholder)].totalRealised = shares[payable(shareholder)].totalRealised.add(amount);
            shares[payable(shareholder)].totalExcluded = getCumulativeDividends(shares[payable(shareholder)].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(payable(msg.sender));
    }

    function getUnpaidEarnings(address payable shareholder) public view returns (uint256) {
        if(shares[payable(shareholder)].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[payable(shareholder)].amount);
        uint256 shareholderTotalExcluded = shares[payable(shareholder)].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address payable shareholder) internal virtual {
        shareholderIndexes[payable(shareholder)] = shareholders.length;
        shareholders.push(payable(shareholder));
    }

    function removeShareholder(address payable shareholder) internal virtual {
        shareholders[shareholderIndexes[payable(shareholder)]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[payable(shareholder)];
        shareholders.pop();
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
        owner = payable(adr);
        emit OwnershipTransferred(adr);
        return true;
    }

    /**
    * Transfer ownership to new address. 
    * Caller must be authorized, or owner must be zero address (renounced). 
    */
    function takeOwnership() public virtual override {
        require(isOwner(address(0)) || isAuthorized(msg.sender), "Unauthorized! Non-Zero address detected as this contract current owner. Contact this contract current owner to takeOwnership(). ");
        unauthorize(owner);
        unauthorize(_owner);
        _owner = payable(msg.sender);
        owner = _owner;
        authorize(msg.sender);
        emit OwnershipTransferred(msg.sender);
    }
}
