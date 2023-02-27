// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IBlacklist {

    // Events

    event setBlacklist(address indexed user, uint date, bool isBlacklisted);


    // Functions
    function setBlacklisted(address user, bool _isBlacklisted) external;
    
    function getBlacklisted(address user) external view returns(bool);

}