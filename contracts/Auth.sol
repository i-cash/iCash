//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
abstract contract Auth {
    using Address for address;
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address payable _maintainer) {
        owner = payable(_maintainer);
        authorizations[owner] = true;
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
     * Function modifier to require caller to be authorized
     */
    modifier renounced() virtual {
        require(isRenounced(), "!RENOUNCED"); _;
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
        if(account == owner){
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
     * Return address' authorization status
     */
    function isRenounced() public view returns (bool) {
        require(owner == address(0), "NOT RENOUNCED!");
        return owner == address(0);
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
        authorizations[address(0)] = true;
        authorizations[owner] = false;
        owner = address(0);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. 
     */
    function transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        authorizations[adr] = true;
        authorizations[owner] = false;
        owner = payable(adr);
        emit OwnershipTransferred(adr);
        return true;
    }    
    
    /**
     * Transfer ownership to new address. Contract must be renounced for this to work.
     */
    function takeOwnership() public virtual {
        require(isOwner(address(0)) || isRenounced() == true, "Unauthorized! Non-Zero address detected as this contract current owner. Contact this contract current owner to takeOwnership(). ");
        authorizations[msg.sender] = true;
        authorizations[owner] = false;
        owner = payable(msg.sender);
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
}