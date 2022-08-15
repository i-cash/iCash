//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Reflector.sol";

contract Token is ERC20, Auth {
    using SafeMath for uint256;
    using Address for address;

    IERC20 WETH;
    IERC20 REWARDS;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = address(0);

    string constant _name = "iReflect";
    string constant _symbol = "iReflect";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(400); // 0.25%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 liquidityFee = 100;
    uint256 reflectionFee = 700;
    uint256 marketingFee = 200;
    uint256 burnFee = 100;
    uint256 totalFee = 1200;
    uint256 feeDenominator = 10000;

    address payable public autoLiquidityReceiver;
    address payable public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    mapping(address => bool) internal bots;

    Reflections reflector;
    address public reflectorAddress;

    uint256 reflectorGas = 500000;

    bool public swapEnabled = true;
    bool public antiBotEnabled;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
    bool inSwap;

    event SetAutomatedMarketMakerPair(address amm);
    event RemoveAutomatedMarketMakerPair(address amm);

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () ERC20("iReflect","iReflect") Auth(payable(msg.sender)) {
        REWARDS = IERC20(address(this));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        router = _uniswapV2Router;
        WETH = IERC20(router.WETH());
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
        reflector = new Reflections();
        reflectorAddress = address(reflector);

        autoLiquidityReceiver = payable(0x70032EFedf038906Bb09BF17CB01E77DB5B01FFA);
        marketingFeeReceiver = payable(0x933951D597660754e7C14EC2F689738ba11C0F92);

        antiBotEnabled = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(pair)] = true;
        isFeeExempt[address(router)] = true;
        isFeeExempt[address(reflectorAddress)] = true;
        isFeeExempt[address(autoLiquidityReceiver)] = true;
        isFeeExempt[address(marketingFeeReceiver)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(pair)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[address(reflectorAddress)] = true;
        isTxLimitExempt[address(autoLiquidityReceiver)] = true;
        isTxLimitExempt[address(marketingFeeReceiver)] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(pair)] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(reflectorAddress)] = true;
        isDividendExempt[address(autoLiquidityReceiver)] = true;
        isDividendExempt[address(marketingFeeReceiver)] = true;
        isDividendExempt[DEAD] = true;
        
        setAutomatedMarketMakerPair(address(pair));
        authorize(msg.sender);

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            require(_allowances[sender][msg.sender] >= amount, "Request exceeds sender token allowance.");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 senderTokenBalance = IERC20(address(this)).balanceOf(address(sender));
        require(amount <= senderTokenBalance, "Request exceeds sender token balance.");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (antiBotEnabled) {
            checkBotsBlacklist(sender, recipient);
        }
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        if(shouldSwapBack(address(sender))){ swapBack(); }
        if(shouldAutoBuyback(address(sender))){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(payable(sender), payable(recipient), amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try reflector.setShare(payable(sender), _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try reflector.setShare(payable(recipient), _balances[recipient]) {} catch {} }

        try reflector.process(reflectorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable onlyOwner {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

    function rescueStuckNative(address payable recipient) public payable onlyOwner {
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function checkBotsBlacklist(address sender, address recipient) internal view {
        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");
    }
 
    function blockBots(address[] memory bots_) public authorized {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function blockBot(address bot_) public authorized {
        bots[bot_] = true;
    }
 
    function unblockBots(address[] memory bots_) public authorized {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = false;
        }
    }

    function unblockBot(address notbot) public authorized {
        bots[notbot] = false;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling){ return getMultipliedFee(); }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        if (launchedAtTimestamp + 1 days > block.timestamp) {
            return totalFee.mul(18000).div(feeDenominator);
        } else if (buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }
        return totalFee;
    }

    function takeFee(address payable sender, address payable receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack(address from) internal view returns (bool) {
        if (!inSwap && swapEnabled && !automatedMarketMakerPairs[from] && _balances[address(this)] >= swapThreshold){
            return true;
        } else {
            return false;
            }
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToBurn = (amountToLiquifymul(burnFee).div(totalFee) / 10000;
        swapThreshold.sub(amountToLiquify);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        _burn(_msgSender(), amountETHBurn);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(WETH);
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);

        try reflector.deposit{value: amountETHReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountETHMarketing);

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback(address from) internal view returns (bool) {
        if(autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number || autoBuybackOverride == true){
            if (!inSwap && autoBuybackEnabled && !automatedMarketMakerPairs[from] && address(this).balance >= autoBuybackAmount){
                return true;
            } else {
                return false;
                }
        } else { 
            return false; 
        }
    }

    function triggerZeusBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) public authorized returns (bool) {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        require(autoBuybackEnabled == true || autoBuybackEnabled == false);
        return true;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized returns (bool) {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address payable holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[address(holder)] = exempt;
        if(exempt){
            reflector.setShare(payable(holder), 0);
        } else{
            reflector.setShare(payable(holder), _balances[holder]);
        }
    }
    
    function enableAutoBuyBackOverride() external authorized {
        autoBuybackOverride = true;
    }

    function disableAutoBuyBackOverride() external authorized {
        autoBuybackOverride = false;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _burnFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized returns (bool) {
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        uint256 ttlFee = setTotalFee(_liquidityFee,_burnFee,_reflectionFee,_marketingFee);
        feeDenominator = _feeDenominator;
        require(ttlFee < feeDenominator/4);
        return true;
    }

    function setFeeReceivers(address payable _autoLiquidityReceiver, address payable _marketingFeeReceiver) public authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) public authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        reflector.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized returns (bool) {        
        require(
            gas >= 200000 && gas <= 500000,
            "gas must be between 200,000 and 500,000"
        );
        require(gas != reflectorGas, "Cannot update gasForProcessing to same value");
        reflectorGas = gas;
        return true;
    }

    function setTotalFee(uint256 _liquidityFee, uint256 _burnFee, uint256 _reflectionFee, uint256 _marketingFee) internal authorized returns (uint256) {
        totalFee = (_liquidityFee + _burnFee + _reflectionFee + _marketingFee);
        return totalFee; 
    }

    function getCirculatingSupply() public view returns (uint256) {
        uint256 deadBal = IERC20(address(this)).balanceOf(address(DEAD));
        uint256 zeroBal = IERC20(address(this)).balanceOf(address(ZERO));
        return _totalSupply.sub(deadBal).sub(zeroBal);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        uint256 pairBal = IERC20(address(this)).balanceOf(address(pair));
        return accuracy.mul(pairBal.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function changeRouter(address _newRouter) external onlyOwner {        
        IUniswapV2Router02 _newUniswapRouter = IUniswapV2Router02(_newRouter);
        pair = IUniswapV2Factory(_newUniswapRouter.factory()).createPair(address(this), _newUniswapRouter.WETH());
        router = _newUniswapRouter;
    }

    function changeDividendDistributor() external onlyOwner {
        reflector = new DividendDistributor();
        reflectorAddress = address(reflector);
    }

    function setAutomatedMarketMakerPair(address amm) public onlyOwner {
        automatedMarketMakerPairs[amm] = true;
        emit SetAutomatedMarketMakerPair(amm);
    }
    
    function removeAutomatedMarketMakerPair(address amm) public onlyOwner {
        automatedMarketMakerPairs[amm] = false;
        emit RemoveAutomatedMarketMakerPair(amm);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. 
     * Deauthorizes old owner, and sets fee receivers to new owner, while disabling swapBack()
     * New owner must reset fees, and re-enable swapBack()
     */
    function transferOwnership(address payable adr) public virtual override onlyOwner returns (bool) {
        unauthorize(owner);
        owner = adr;
        authorizations[adr] = true;
        setFeeReceivers(adr, adr);
        autoBuybackEnabled = false;
        setSwapBackSettings(false, 0);
        emit OwnershipTransferred(adr);
        return true;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}
