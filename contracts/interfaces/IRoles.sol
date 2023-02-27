// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IRoles {

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event SetAdmin(address indexed admin, uint date, bool isAdmin);


    // Functions
    function transferOwnership(address _newOwner) external;

    function setAdmin(address admin, bool isAdmin) external;

    function getAdmin(address admin) external view returns(bool);
}