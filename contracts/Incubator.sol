//SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IDistro.sol";
contract Incubator is IDistro, Auth {
    using SafeMath for uint256;
    using Address for address;

    // Reflection Tracker
    // add user amount 
    // update stackingBalance / amount 
    // update pastReward to initial stack block
    // calculate reward based on 
    // example: 
    // 100,100 - 100,000           *       1               /    100         /       10      
    // (block.number - pastReward) * pool.blockReflections / (stackingSupply / stackingBalance)
    // after each claim update pastReward == block.number
    struct ReflectionInfo {
        uint256 pool;
        uint256 pastReward;
        uint256 stackingBalance;
        uint256 reflectionsBalance;
        uint256 reflectionsExcluded;
    }

    // Pool Intel.
    struct PoolIntel {
        IERC20 stackingToken;
        IERC20 reflectionsToken;
        uint256 blockReflections;
        uint256 stackingSupply;
        uint256 reflectionSupply;
        uint256 totalDistributed;
        uint minPeriod;
        uint256 minDistribution;
        uint genesisBlock;
        uint decimals;
    }

    address public ireflect;
    address public operator;
    address payable public _token;

    uint256 public ireflectPerBlock;
    uint256 public REFLECTIONS_BASIS = 1;
    uint public _blocksPerDay;
    uint public genesisBlock;

    bool initialized;

    PoolIntel[] public poolIntel;
    mapping (uint256 => mapping (address => ReflectionInfo)) public reflectionInfo;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => mapping (address => uint256)) _balances;

    event ReceivedETH(address, uint);
    event ReceivedETHFallback(address, uint);
    event CreateReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _genesisBlock);
    event StartStacking(address indexed stacker, uint256 indexed pool, uint256 amount);
    event Unstacked(address indexed stacker, uint256 indexed pool, uint256 amount);
    event ClaimedReflections(address indexed stacker, uint256 indexed pool, uint256 amount);
    
    modifier onlyToken() virtual {
        require(msg.sender == _token,"UNAUTHORIZED!"); _;
    }

    modifier onlyOwner() override {
        require(msg.sender == owner,"UNAUTHORIZED!"); _;
    }

    constructor () Auth(payable(msg.sender)) {
        initialized = true;
        genesisBlock = block.number;
        _blocksPerDay = block.chainid == 1 ? 5400 : block.chainid == 56 ? 28800 : block.chainid == 137 ? 86400 : block.chainid == 103090 ? 28800 : 5400;
        address deployer = address(0x972c56de17466958891BeDE00Fe68d24eAb8c2C4);
        _token = payable(msg.sender);
        ireflect = address(0xd88AD19E67238d8bC7a217913e8D8CcB983d8c30);
        operator = address(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        authorize(deployer);
        authorize(ireflect);
        authorize(_token);
        authorize(operator);
        // initialize iReflect pool
        poolIntel.push(PoolIntel({
            stackingToken: IERC20(ireflect),
            reflectionsToken: IERC20(ireflect),
            blockReflections: 1 * (10 ** 9),
            stackingSupply: 0,
            reflectionSupply: 0,
            totalDistributed: 0,
            minPeriod: _blocksPerDay / 24,
            minDistribution: 1 * (10 ** 9),
            genesisBlock: genesisBlock,
            decimals: 1e9
        }));
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceivedETHFallback(msg.sender, msg.value);
    }

    function getPoolIntel() public view returns (PoolIntel[] memory){
        return poolIntel;
    }
    
    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getPrecision(uint256 decimals, uint256 amount) public pure returns (uint256) {
        if(decimals==2||decimals==1e2){
            return amount * 1e2;
        } else if(decimals==3||decimals==1e3){
            return amount * 1e3;
        } else if(decimals==4||decimals==1e4){
            return amount * 1e4;
        } else if(decimals==5||decimals==1e5){
            return amount * 1e5;
        } else if(decimals==6||decimals==1e6){
            return amount * 1e6;
        } else if(decimals==7||decimals==1e7){
            return amount * 1e7;
        } else if(decimals==8||decimals==1e8){
            return amount * 1e8;
        } else if(decimals==9||decimals==1e9){
            return amount * 1e9;
        } else if(decimals==10||decimals==1e10){
            return amount * 1e10;
        } else if(decimals==11||decimals==1e11){
            return amount * 1e11;
        } else if(decimals==12||decimals==1e12){
            return amount * 1e12;
        } else if(decimals==13||decimals==1e13){
            return amount * 1e13;
        } else if(decimals==14||decimals==1e14){
            return amount * 1e14;
        } else if(decimals==15||decimals==1e15){
            return amount * 1e15;
        } else if(decimals==16||decimals==1e16){
            return amount * 1e16;
        } else if(decimals==17||decimals==1e17){
            return amount * 1e17;
        } else if(decimals==18||decimals==1e18){
            return amount * 1e18;
        } else {
            return amount * 1e18; 
        }
    }

    function close() public {
        selfdestruct(payable(owner)); 
    }
    
    function getPreciseRewards(uint256 _pool, uint256 amount) public view returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        if(pool.decimals==1e2||pool.decimals==2){
            return amount * 1e2;
        } else if(pool.decimals==1e3||pool.decimals==3){
            return amount * 1e3;
        } else if(pool.decimals==1e4||pool.decimals==4){
            return amount * 1e4;
        } else if(pool.decimals==1e5||pool.decimals==5){
            return amount * 1e5;
        } else if(pool.decimals==1e6||pool.decimals==6){
            return amount * 1e6;
        } else if(pool.decimals==1e7||pool.decimals==7){
            return amount * 1e7;
        } else if(pool.decimals==1e8||pool.decimals==8){
            return amount * 1e8;
        } else if(pool.decimals==1e9||pool.decimals==9){
            return amount * 1e9;
        } else if(pool.decimals==1e10||pool.decimals==10){
            return amount * 1e10;
        } else if(pool.decimals==1e11||pool.decimals==11){
            return amount * 1e11;
        } else if(pool.decimals==1e12||pool.decimals==12){
            return amount * 1e12;
        } else if(pool.decimals==1e13||pool.decimals==13){
            return amount * 1e13;
        } else if(pool.decimals==1e14||pool.decimals==14){
            return amount * 1e14;
        } else if(pool.decimals==1e15||pool.decimals==15){
            return amount * 1e15;
        } else if(pool.decimals==1e16||pool.decimals==16){
            return amount * 1e16;
        } else if(pool.decimals==1e17||pool.decimals==17){
            return amount * 1e17;
        } else if(pool.decimals==1e18||pool.decimals==18){
            return amount * 1e18;
        } else {
            return amount * 1e18; 
        }
    }

    function getContractTokenBalance(address _tok) public view returns (uint256) {
        return IERC20(address(_tok)).balanceOf(address(this));
    }

    function rescueStuckTokens(uint256 _pool, address payable recipient, uint256 amount, uint256 decimalUnits) public returns (bool){
        PoolIntel storage pool = poolIntel[_pool];
        IERC20 _tok = pool.stackingToken;
        require(_balances[payable(recipient)][address(_tok)] >= amount, "UNAUTHORIZED");
        require(address(msg.sender) == address(recipient), "UNAUTHORIZED");
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(recipient)];
        uint256 preciseAmount = getPrecision(decimalUnits, amount);
        uint256 ogContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(preciseAmount <= ogContractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        _balances[payable(recipient)][address(_tok)] = _balances[payable(recipient)][address(_tok)].sub(preciseAmount,"Amount exceeds balance! Contact operators.");
        IERC20(_tok).transfer(payable(recipient), preciseAmount);
        uint256 finalContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[payable(recipient)][address(_tok)];
        stacker.pastReward = block.number;
        return true;
    }
    
    function emergencyRescueStuckTokens(uint256 _pool, address payable recipient, uint256 amount, uint256 decimalUnits) public authorized returns (bool){
        require(msg.sender == operator, "UNAUTHORIZED");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(recipient)];
        IERC20 _tok = pool.stackingToken;
        uint256 ogContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 preciseAmount = getPrecision(decimalUnits, amount);
        require(preciseAmount <= ogContractTokenBalance, "Request exceeds contract token balance.");
        require(_balances[payable(recipient)][address(_tok)] >= amount, "UNAUTHORIZED");
        // rescue stuck tokens 
        _balances[payable(recipient)][address(_tok)] = _balances[payable(recipient)][address(_tok)].sub(preciseAmount,"Amount exceeds balance!");
        IERC20(_tok).transfer(recipient, preciseAmount);
        uint256 finalContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[payable(recipient)][address(_tok)];
        stacker.pastReward = block.number;
        return true;
    }

    function rescueStuckNative(address payable recipient) public authorized returns (bool) {
        require(msg.sender == operator, "UNAUTHORIZED");
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
        return true;
    }

    function updateMultiplier(uint256 multiplierNumber) public override authorized {
        REFLECTIONS_BASIS = multiplierNumber;
    }

    function updateBlockReflections(uint256 _pool, uint256 reflectionsAmount) public override authorized {
        PoolIntel storage pool = poolIntel[_pool];
        uint256 pastReflectionsPoints = pool.blockReflections;
        uint256 preciseRewards = getPreciseRewards(_pool, reflectionsAmount);
        if (pastReflectionsPoints != preciseRewards) {
            pool.blockReflections = preciseRewards;
        }
    }
    
    function updateReflectionSupply(uint256 _pool, uint256 reflectionSupply) public authorized {
        PoolIntel storage pool = poolIntel[_pool];
        // to Ether
        uint256 ogContractTokenBalance = IERC20(address(pool.reflectionsToken)).balanceOf(address(this));
        uint256 preciseRewards = getPreciseRewards(_pool, reflectionSupply);
        IERC20(pool.reflectionsToken).transferFrom(msg.sender, address(this), preciseRewards);
        
        uint256 finalContractTokenBalance = IERC20(address(pool.reflectionsToken)).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.reflectionSupply += diff;
    }

    function poolLength() external view returns (uint256) {
        return poolIntel.length;
    }

    // Add new reflections pools. Can only be called by the owner.
    // DO NOT add the same reflections token more than once. 
    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint decimals) public override authorized {
        uint256 _decimals = decimals == 2 ? 1e2 : decimals == 3 ? 1e3 : decimals == 4 ? 1e4 : decimals == 5 ? 1e5 : decimals == 6 ? 1e6 : decimals == 7 ? 1e7 : decimals == 8 ? 1e8 : decimals == 9 ? 1e9 : decimals == 10 ? 1e10 : decimals == 11 ? 1e11 : decimals == 12 ? 1e12 : decimals == 13 ? 1e13 : decimals == 14 ? 1e14 : decimals == 15 ? 1e15 : decimals == 16 ? 1e16 : decimals == 17 ? 1e17 : decimals == 18 ? 1e18 : 1e18;
        uint256 preciseReward = getPrecision(decimals, _blockReflections);
        uint256 genesis = _genesisBlock < block.number ? block.number : _genesisBlock;
        poolIntel.push(PoolIntel({
            stackingToken: IERC20(_stackingToken),
            reflectionsToken: IERC20(_reflectionsToken),
            blockReflections: preciseReward,
            stackingSupply: 0,
            reflectionSupply: 0,
            totalDistributed: 0,
            minPeriod: _minPeriod,
            minDistribution: _minDist * _decimals,
            genesisBlock: genesis,
            decimals: _decimals
        }));
        emit CreateReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _genesisBlock);
    }
    
    function removeStackingPool(uint256 _pool) internal {  
        PoolIntel storage pool = poolIntel[_pool];
        pool.blockReflections = 0;
    }
    
    // Update operator address 
    function updateOperationsWallet(address _operatorWallet) public authorized {
        require(msg.sender == operator, "DENIED: Must be current operator");
        operator = _operatorWallet;
        authorize(operator);
    }

    // set reflections period, and minimum claim amount
    function setReflectionCriteria(uint256 _pool, uint256 _minPeriod, uint256 _minDistribution) public override authorized {
        PoolIntel storage pool = poolIntel[_pool];
        pool.minPeriod = _minPeriod;
        pool.minDistribution = _minDistribution;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _pool, uint256 _from, uint256 _to, address payable sender) public view returns (uint256) {
        // PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(sender)];
        uint256 aob = (block.number - stacker.pastReward);
        uint256 ftb = _to.sub(_from);
        if(aob!=ftb){
            return _to.sub(_from).mul(REFLECTIONS_BASIS);
        } else {
            return aob.mul(REFLECTIONS_BASIS);
        }
    }

    // View function to see pending iReflect on frontend.
    function pendingIReflect(uint256 _pool, address payable _stacker, bool test) public view override returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(_stacker)];
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (block.number > stacker.pastReward && rb != 0) {
            uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 
            uint256 multiplier = getMultiplier(_pool, stacker.pastReward, block.number, payable(_stacker));
            uint256 ireflectReward = (multiplier * pool.blockReflections) / (pool.stackingSupply / stackerAmount);
            return ireflectReward;
        } else if (test==true) {
            uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 
            uint256 multiplier = getMultiplier(_pool, stacker.pastReward, block.number, payable(_stacker));
            uint256 ireflectReward = (multiplier * pool.blockReflections) / (pool.stackingSupply / stackerAmount);
            return getPreciseRewards(_pool, ireflectReward);
        } else {
            return 0;
        }
    }
    
    // View function to see stacked tokens on frontend.
    function stackingBalance(uint256 _pool, address payable _stacker) external view override returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 

        return stackerAmount;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pool, address payable sender) public override {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(sender)];
        IERC20 _tok = pool.stackingToken;
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (rb == 0 || _balances[address(sender)][address(pool.stackingToken)] == 0) {
            stacker.pastReward = block.number;
            return;
        }        
        uint256 pending = pendingIReflect(_pool, payable(sender), false);
        if(pool.totalDistributed + pending >= pool.reflectionSupply){
            if(pool.totalDistributed < pool.reflectionSupply){             
                pending = pool.reflectionSupply - pool.totalDistributed;
                if(pending <= 0){
                    stacker.reflectionsBalance = 0;
                    // stacker.pastReward = block.number;
                    return;
                    // revert("Pool exhausted reflections supply; try another pool, or contact operators");
                }
            }
        }
        if(shouldDistributeReflections(_pool, address(sender))) {
            if(pending > 0) {    
                uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
                stacker.reflectionsBalance = stacker.reflectionsBalance.sub(pending, 'amount exceeds balance');
                if(pending >= contractTokenBalance){
                    IERC20(pool.reflectionsToken).transfer(payable(sender), contractTokenBalance);
                } else {
                    IERC20(pool.reflectionsToken).transfer(payable(sender), pending);
                }
                pool.totalDistributed = pool.totalDistributed.add(pending);
                stacker.pastReward = block.number;
            }
        }
    }

    // add user amount 
    // update stackingBalance / amount 
    // update pastReward to initial stack block
    // stack iReflect tokens
    function enterStacking(uint256 _amount, uint256 _pool, address payable _stacker) public override onlyToken {
        require(_amount > 0, "ERROR: stacking amount must be greater than 0");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][payable(_stacker)];
        uint256 preciseRewards = getPreciseRewards(_pool, _amount);
        updatePool(_pool, payable(_stacker));
        if (block.number <= (stacker.pastReward + pool.minPeriod)) {
            revert("Not enough blocks to claim reflections, keep stacking");
        }
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (rb == 0) {
            revert("Reflections pool contains no balance. Contact operators");
        }
        if (_balances[payable(_stacker)][address(pool.stackingToken)] == 0) {
            stacker.pastReward = block.number;
        }
        uint256 ogContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        pool.stackingToken.transferFrom(payable(_stacker), address(this), preciseRewards);
        uint256 finalContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply += diff;
        _balances[payable(_stacker)][address(pool.stackingToken)] += preciseRewards;
        stacker.stackingBalance = _balances[payable(_stacker)][address(pool.stackingToken)];
        // pool.stackingSupply += preciseRewards;

        emit StartStacking(payable(_stacker), _pool, preciseRewards);
    }

    // Withdraw ireflect tokens from stacking.
    function leaveStacking(uint256 _amount, uint256 _pool, address payable _stacker) public override onlyToken {
        require(_amount > 0, "ERROR: requested amount must be greater than 0");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][payable(_stacker)];
        uint256 stackingBal = _balances[payable(_stacker)][address(pool.stackingToken)];
        uint256 preciseRewards = getPreciseRewards(_pool, _amount);
        require(stackingBal > 0, "ERROR: stacking amount must be greater than 0 to claim reflections");
        require(stacker.stackingBalance >= preciseRewards, "DENIED: Expected larger balance, try a smaller amount.");
        updatePool(_pool, payable(_stacker));
        _balances[address(_stacker)][address(pool.stackingToken)] = _balances[address(_stacker)][address(pool.stackingToken)].sub(preciseRewards, 'amount exceeds balance');
        stacker.stackingBalance = _balances[payable(_stacker)][address(pool.stackingToken)];
        uint256 ogContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        pool.stackingToken.transfer(payable(_stacker), preciseRewards);
        uint256 finalContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[address(_stacker)][address(pool.stackingToken)];
        stacker.pastReward = block.number;
        emit Unstacked(payable(_stacker), _pool, preciseRewards);
    }

    function shouldDistributeReflections(uint256 _pool, address foundling) internal view returns (bool) {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(foundling)];
        if(_balances[address(foundling)][address(pool.stackingToken)] < pool.minDistribution) {
            return false;
        } else if(pool.totalDistributed >= pool.reflectionSupply){
            return false;
        } else if (block.number <= (stacker.pastReward + pool.minPeriod)) {
            return false;
        } else {
            return true;
        }
    }

    // calculate reward based on 
    // ((block.number - pastReward) * pool.blockReflections) / (stackingSupply / stackingBalance)
    // after each claim update pastReward == block.number
    function distributeReflections(uint256 _pool, address payable foundling) internal {
        PoolIntel storage pool = poolIntel[_pool];
        // ReflectionInfo storage stacker = reflectionInfo[_pool][address(foundling)];
        uint256 stackingBal = _balances[address(foundling)][address(pool.stackingToken)];
        uint256 pending = pendingIReflect(_pool, payable(foundling), false);
        require(pending > 0, "ERROR: pending amount must be greater than 0");
        require(stackingBal > 0, "ERROR: stacking amount must be greater than 0 to exit");
        updatePool(_pool, payable(foundling));
        
        emit ClaimedReflections(payable(foundling), _pool, pending);
    }

    function claimReflections(uint256 _pool, address payable foundling) external override {
        distributeReflections(_pool,payable(foundling));
    }

    function changeTokenContract(address payable _newToken) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        _token = payable(_newToken);
        return true;
    }

    function _transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        return transferOwnership(payable(adr));
    }
}
