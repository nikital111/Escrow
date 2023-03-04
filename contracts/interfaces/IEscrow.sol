// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IEscrow {
    // Events

    /**
     * @dev Emitted when the deal was created.
     */
    event CreateDeal(
        uint256 indexed id,
        address indexed creator,
        address indexed performer,
        uint256 amount,
        address token,
        uint256 date
    );

    /**
     * @dev Emitted when the deal was confirmed.
     */
    event ConfirmDeal(uint256 indexed id, uint256 date);

    /**
     * @dev Emitted when the deal was completed.
     */
    event CompleteDeal(uint256 indexed id, uint256 date);

    /**
     * @dev Emitted when the deal was canceled.
     */
    event CancelDeal(uint256 indexed id, uint256 date);

    /**
     * @dev Emitted when the deal was closed.
     */
    event CloseDeal(uint256 indexed id, uint256 date, bool typeClose);

<<<<<<< HEAD
    /**
     * @dev Emitted when withdrawing funds.
     */
    event Withdraw(address indexed receiver, uint amount, address token, uint date);

=======
>>>>>>> 3cbc25888f0bf224ecd0ab7e5116b50e59efae0b
    // Functions

    /**
     * @dev Creates a new deal using custom token.
     *
     * Emits a {CreateDeal} event.
     *
     */
    function createDeal(
        address performer,
        uint256 amount,
        address token
    ) external;

    /**
     * @dev Creates a new deal using ETH.
     *
     * Emits a {CreateDeal} event.
     *
     */
    function createDealNative(address performer) external payable;

    /**
     * @dev Confirms the deal.
     *
     * Emits a {ConfirmDeal} event.
     *
     */
    function confirmDeal(uint256 id) external;

    /**
     * @dev Completes the deal.
     *
     * Emits a {CompleteDeal} event.
     *
     */
    function completeDeal(uint256 id) external;

    /**
     * @dev Cancels the deal.
     *
     * Emits a {CancelDeal} event.
     *
     */
    function cancelDeal(uint256 id) external;

    /**
     * @dev Closes the deal.
     *
     * Emits a {CloseDeal} event.
     *
     */
    function closeDeal(uint256 id, bool _type) external;

    /**
     * @dev Returns the deal data.
     */
    function getDeal(uint256 id)
        external
        returns (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        );

    /**
     * @dev Returns all deals id in which the user participates.
     */
    function getUserDealsId(address user)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Changes the commission.
     */
    function changeCommission(uint256 newCommission) external;

    /**
     * @dev Withdraws funds from the contract.
     */
    function withdraw(
        address receiver,
        address token,
        uint256 amount
    ) external;

    /**
     * @dev Withdraws funds from the contract.
     */
    function withdrawNative(address payable receiver, uint256 amount) external;
}
