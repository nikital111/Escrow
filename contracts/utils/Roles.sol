// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "../interfaces/IRoles.sol";

contract Roles is IRoles {
    address public owner;
    mapping(address => bool) internal admins;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "Not Admin");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Cannot transfer to zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Grants or revokes the admin role to `user`.
     *
     * Emits a {SetAdmin} event.
     *
     */
    function setAdmin(address user, bool isAdmin) external onlyOwner {
        admins[user] = isAdmin;
        emit SetAdmin(user, isAdmin, block.timestamp);
    }

    /**
     * @dev Returns whether the user is admin.
     */
    function getAdmin(address user) external view returns (bool) {
        return admins[user];
    }
}
