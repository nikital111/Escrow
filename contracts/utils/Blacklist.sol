// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "../interfaces/IBlacklist.sol";
import "./Roles.sol";

contract Blacklist is Roles, IBlacklist {
    mapping(address => bool) internal blacklist;

    /**
     * @dev Throws if called by user that was blacklisted.
     */
    modifier isBlacklisted() {
        require(!blacklist[msg.sender], "Blacklisted");
        _;
    }

    /**
     * @dev Adds or removes a user from the blacklist.
     *
     * Emits a {setBlacklist} event.
     *
     */
    function setBlacklisted(address user, bool _isBlacklisted)
        external
        onlyAdmin
    {
        blacklist[user] = _isBlacklisted;
        emit setBlacklist(user, _isBlacklisted, block.timestamp);
    }

    /**
     * @dev Returns whether the user was blacklisted.
     */
    function getBlacklisted(address user) external view returns (bool) {
        return blacklist[user];
    }
}
