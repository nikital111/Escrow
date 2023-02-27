// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IEscrow {

    // Events
    event CreateDeal(uint indexed id, address indexed creator, address indexed performer, uint amount, address token, uint date);

    event ConfirmDeal(uint indexed id, uint date);

    event CompleteDeal(uint indexed id, uint date);

    event CancelDeal(uint indexed id, uint date);

    event CloseDeal(uint indexed id, uint date, bool typeClose);



    // Functions
    function createDeal(address performer, uint amount, address token) external;
    
    function createDealNative(address performer) external payable;

    function confirmDeal(uint id) external;

    function completeDeal(uint id) external;

    function cancelDeal(uint id) external;

    function closeDeal(uint id, bool _type) external;

    function getDeal(uint id) external returns(address creator,address performer, uint256 amount, address token, uint256 date, uint256 commission, uint256 status);

    function getUserDealsId(address user) external view returns(uint[] memory);

    function changeCommission(uint newCommission) external;

    function withdraw(address receiver, address token, uint amount) external;

    function withdrawNative(address payable receiver, uint amount) external;
}
