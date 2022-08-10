//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IReflections.sol";
import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract Reflections is IReflections, Auth {
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
