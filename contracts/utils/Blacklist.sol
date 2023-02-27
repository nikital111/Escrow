// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "../interfaces/IBlacklist.sol";
import "./Roles.sol";

contract Blacklist is Roles, IBlacklist {

    mapping(address=>bool) internal blacklist;

  modifier isBlacklisted() {
    require(!blacklist[msg.sender], "Blacklisted");
    _;
  }

    function setBlacklisted(address user, bool _isBlacklisted) external onlyAdmin{
        blacklist[user] = _isBlacklisted;
    }

    function getBlacklisted(address user) external view returns(bool){
        return blacklist[user];
    }

}