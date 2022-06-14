//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Incubator.sol";

contract iReflect is IERC20, Auth {
    using SafeMath for uint256;
    using Address for address;

    IERC20 WETH;
    IERC20 REWARDS;

    Incubator incubator;
    address public incubatorEOA;

    address payable public operator;
    address payable public marketing;

    string constant _name = "iReflect";
    string constant _symbol = "iReflect";

    uint256 _totalSupply = 1_024 * (10 ** _decimals);
    uint256 incubatorGas = 500000;
    uint8 constant _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    event StartStacking(address indexed staker, uint256 indexed pool, uint256 amount);
    event Unstacked(address indexed staker, uint256 indexed pool, uint256 amount);
    event CreatedReflectionsPool(IERC20 _stakingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _genesisBlock);
    event ClaimedReflections(address indexed stacker, uint256 indexed pool);

    constructor () Auth(payable(msg.sender)) {

        incubator = new Incubator();
        incubatorEOA = address(incubator);

        operator = payable(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        marketing = payable(0x972c56de17466958891BeDE00Fe68d24eAb8c2C4);

        authorize(msg.sender);
        authorize(address(operator));
        authorize(address(marketing));

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

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function close() public {
        selfdestruct(payable(owner)); 
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
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

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Withdraw tokens from ReflectionsPool.
    function leaveStacking(uint256 _amount, uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.leaveStacking(_amount, _pool, payable(foundling));

        emit Unstacked(msg.sender, _amount, _pool);
    }
    

    // Reflection Tracker
    // add user amount staked
    // update stakingBalance / amount 
    // update pastReward to initial stake block
    // Stake tokens to ReflectionsPool
    function enterStacking(uint256 _amount,uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.enterStacking(_amount, _pool, payable(foundling));
        
        emit StartStacking(msg.sender, _amount, _pool);
    }

    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint _precision) public authorized {
        require(address(operator) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.createReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _minPeriod, _minDist, _genesisBlock, _precision);
        
        emit CreatedReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _genesisBlock);
    }
    
    // Stake tokens to ReflectionsPool
    function claimReflections(uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        uint256 pending = incubator.pendingIReflect(_pool, payable(foundling), false);
        if(pending > 0){
            incubator.claimReflections(_pool, payable(foundling));
        }
        
        emit ClaimedReflections(address(foundling), _pool);
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

    function changeIncubator() external onlyOwner {
        incubator = new Incubator();
        incubatorEOA = address(incubator);
    }

    function _transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        return transferOwnership(payable(adr));
    }
}
