// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IRoles {
    // Events

    /**
     * @dev Emitted when transfers ownership of the contract to a new account (`newOwner`).
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when grants or revokes the admin role to `user`.
     */
    event SetAdmin(address indexed user, bool isAdmin, uint256 date);

    // Functions

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) external;

    /**
     * @dev Grants or revokes the admin role to `user`.
     */
    function setAdmin(address admin, bool isAdmin) external;

    /**
     * @dev Returns is the user have the admin role.
     */
    function getAdmin(address admin) external view returns (bool);
}
