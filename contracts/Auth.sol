//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
abstract contract Auth {
    using Address for address;
    address public owner;
    address public _owner;
    mapping (address => bool) internal authorizations;

    constructor(address payable _maintainer) {
        _owner = payable(_maintainer);
        owner = payable(_owner);
        authorizations[_owner] = true;
        authorize(msg.sender);
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() virtual {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyZero() virtual {
        require(isOwner(address(0)), "!ZERO"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() virtual {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        if(account == owner || account == _owner){
            return true;
        } else {
            return false;
        }
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
        require(isOwner(msg.sender), "Unauthorized!");
        emit OwnershipTransferred(address(0));
        authorizations[owner] = false;
        authorizations[_owner] = false;
        _owner = address(0);
        owner = _owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        authorizations[owner] = false;
        authorizations[_owner] = false;
        _owner = payable(adr);
        owner = _owner;
        authorize(adr);
        emit OwnershipTransferred(adr);
        return true;
    }

    event OwnershipTransferred(address owner);
}