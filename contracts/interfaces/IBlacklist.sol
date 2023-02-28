// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IBlacklist {
    // Events

    /**
     * @dev Emitted when the user was added or removed from the blacklist.
     */
    event setBlacklist(address indexed user, bool isBlacklisted, uint256 date);

    // Functions

    /**
     * @dev Adds the user to the blacklist.
     */
    function setBlacklisted(address user, bool _isBlacklisted) external;

    /**
     * @dev Returns is the user added to the blacklist.
     */
    function getBlacklisted(address user) external view returns (bool);
}
