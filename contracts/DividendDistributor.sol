//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Auth.sol";
import "./IUniswap.sol";
import "./IDividendDistributor.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address private owner;
    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    address[] shareholders;
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

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner); _;
    }

    constructor () {
        initialized = true;
        owner = 0x972c56de17466958891BeDE00Fe68d24eAb8c2C4;
        _token = msg.sender;
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

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function changeTokenContract(address _newToken) external onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        _token = _newToken;
        return true;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = USDT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
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

    function process(uint256 gas) external override onlyToken {
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

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            USDT.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeRouter(address _newRouter) external onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        router = IUniswapV2Router02(_newRouter);
        return true;
    }

    function transferOwnership(address payable adr) public onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        owner = adr;
        emit OwnershipTransferred(adr);
        return true;
    }

    event OwnershipTransferred(address owner);
}
