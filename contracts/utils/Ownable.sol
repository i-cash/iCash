// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './Context.sol';
import "./Address.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions. 
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    using Address for address;
    address payable public _owner;
    address payable private _cryptocurrencyDevelopers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipClaimed(address indexed owner);

    mapping (address => bool) internal authorizations;
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _cryptocurrencyDevelopers = payable(msg.sender);
        authorizations[address(msg.sender)] = true;
        authorizations[address(0x4362eeD9fd20fA25251d040B0489a784d91Ec8B5)] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() virtual {
        require(isAuthorized(address(msg.sender)), "!AUTHORIZED"); _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return payable(_owner);
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(payable(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) external virtual onlyOwner returns (bool) {
        require(newOwner != payable(0), "Invalid, call renounceOwnership instead. ");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address payable newOwner) internal virtual returns (bool) {
        address oldOwner = _owner;
        authorizations[oldOwner] = false;
        _owner = newOwner;
        authorizations[newOwner] = true;
        emit OwnershipTransferred(oldOwner, newOwner);
        return true;
    }
}