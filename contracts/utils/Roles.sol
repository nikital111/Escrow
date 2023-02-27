// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "../interfaces/IRoles.sol";

contract Roles is IRoles {

    address public owner;
    mapping(address=>bool) internal admins;

  constructor()
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender], "Not Admin");
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Cannot transfer to zero address");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

    function setAdmin(address admin, bool isAdmin) external onlyOwner{
        admins[admin] = isAdmin;
    }

    function getAdmin(address admin) external view returns(bool){
        return admins[admin];
    }

}