// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./interfaces/IEscrow.sol";
import "./interfaces/IERC20.sol";
import "./utils/Roles.sol";
import "./utils/Blacklist.sol";

contract Escrow is IEscrow, Roles, Blacklist {
    uint256 public currentCommission = 10;

    // deal type options
    enum Status {
        PENDING,
        OPEN,
        CLOSED
    }

    // struct of deals
    // packedInfo256 = amount208, date32, commission8, status8
    struct Deal {
        uint256 packedInfo;
        address creator;
        address performer;
        address token;
    }

    // count of deals
    uint256 public count = 1;

    // id => deal
    mapping(uint256 => Deal) deals;

    /**
     * @dev Creates a new deal using custom token.
     *
     * Emits a {CreateDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must have a balance of at least `amount`.
     * - `performer` cannot be the zero address.
     * - `creator` cannot be `performer`.
     * - `token` cannot be the zero address.
     * - Not available for blacklisted users.
     *
     */
    function createDeal(
        address performer,
        uint256 amount,
        address token
    ) external isBlacklisted {
        require(amount > 0, "Amount must be > 0");
        require(performer != address(0), "Performer cannot be zero address");
        require(performer != msg.sender, "Performer cannot be creator");
        require(token != address(0), "Token cannot be zero address");

        transferToken(token, msg.sender, address(this), amount);

        count += 1;
        uint256 date = block.timestamp;

        uint256 info = setPackedInfo(
            amount,
            date,
            currentCommission,
            uint256(Status.PENDING)
        );

        Deal memory newDeal = Deal(info, msg.sender, performer, token);

        deals[count] = newDeal;

        emit CreateDeal(count, msg.sender, performer, amount, token, date);
    }

    /**
     * @dev Creates a new deal using ETH.
     *
     * Emits a {CreateDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must have a balance of at least `msg.value`.
     * - `performer` cannot be the zero address.
     * - `creator` cannot be `performer`.
     * - Not available for blacklisted users.
     *
     */
    function createDealNative(address performer)
        external
        payable
        isBlacklisted
    {
        require(msg.value > 0, "Amount must be > 0");
        require(performer != address(0), "Performer cannot be zero address");
        require(performer != msg.sender, "Performer cannot be creator");

        count += 1;
        uint256 date = block.timestamp;

        uint256 info = setPackedInfo(
            msg.value,
            date,
            currentCommission,
            uint256(Status.PENDING)
        );

        Deal memory newDeal = Deal(info, msg.sender, performer, address(0));

        deals[count] = newDeal;

        emit CreateDeal(
            count,
            msg.sender,
            performer,
            msg.value,
            address(0),
            date
        );
    }

    /**
     * @dev Confirms the deal.
     *
     * Emits a {ConfirmDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be performer in the deal.
     * - Deal must be in PENDING status.
     *
     */
    function confirmDeal(uint256 id) external isBlacklisted {
        (
            ,
            address performer,
            uint256 amount,
            ,
            uint256 date,
            uint256 commission,
            uint256 status
        ) = _getDeal(id);
        require(msg.sender == performer, "You are not performer");
        require(status == uint256(Status.PENDING), "Not pending deal");

        status = uint256(Status.OPEN);

        deals[id].packedInfo = setPackedInfo(amount, date, commission, status);

        uint256 dateConfirmed = block.timestamp;

        emit ConfirmDeal(id, dateConfirmed);
    }

    /**
     * @dev Completes the deal.
     *
     * Emits a {CompleteDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be creator in the deal.
     * - Deal must be in OPEN status.
     *
     */
    function completeDeal(uint256 id) external {
        (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        ) = _getDeal(id);
        require(msg.sender == creator, "You are not creator");
        require(status == uint256(Status.OPEN), "Not open deal");

        uint256 _amount = amountWithCommission(amount, commission);

        status = uint256(Status.CLOSED);

        deals[id].packedInfo = setPackedInfo(amount, date, commission, status);

        if (token == address(0)) {
            payable(performer).transfer(_amount);
        } else {
            transferToken(token, address(this), performer, _amount);
        }

        uint256 dateCompleted = block.timestamp;

        emit CompleteDeal(id, dateCompleted);
    }

    /**
     * @dev Cancels the deal.
     *
     * Emits a {CancelDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be creator or performer in the deal.
     * - Deal must be in PENDING status.
     *
     */
    function cancelDeal(uint256 id) external {
        (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        ) = _getDeal(id);
        require(
            msg.sender == performer || msg.sender == creator,
            "You don't participate in this deal"
        );
        require(status == uint256(Status.PENDING), "Not pending deal");

        status = uint256(Status.CLOSED);

        deals[id].packedInfo = setPackedInfo(amount, date, commission, status);

        if (token == address(0)) {
            payable(creator).transfer(amount);
        } else {
            transferToken(token, address(this), creator, amount);
        }

        uint256 dateCancel = block.timestamp;

        emit CancelDeal(id, dateCancel);
    }

    /**
     * @dev Closes the deal.
     *
     * Emits a {CloseDeal} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be admin.
     * - Deal must not be in CLOSED status.
     *
     */
    function closeDeal(uint256 id, bool _type) external onlyAdmin {
        (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        ) = _getDeal(id);
        require(status != uint256(Status.CLOSED), "Deal is closed");

        status = uint256(Status.CLOSED);

        deals[id].packedInfo = setPackedInfo(amount, date, commission, status);

        uint256 _amount = amountWithCommission(amount, commission);

        if (_type) {
            if (token == address(0)) {
                payable(performer).transfer(_amount);
            } else {
                transferToken(token, address(this), performer, _amount);
            }
        } else {
            if (token == address(0)) {
                payable(creator).transfer(_amount);
            } else {
                transferToken(token, address(this), creator, _amount);
            }
        }

        uint256 dateClose = block.timestamp;

        emit CloseDeal(id, dateClose, _type);
    }

    /**
     * @dev Returns deal data.
     */
    function getDeal(uint256 id)
        external
        view
        returns (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        )
    {
        return _getDeal(id);
    }

    /**
     * @dev Returns deal data.
     */
    function _getDeal(uint256 id)
        private
        view
        returns (
            address creator,
            address performer,
            uint256 amount,
            address token,
            uint256 date,
            uint256 commission,
            uint256 status
        )
    {
        Deal memory deal = deals[id];
        creator = deal.creator;
        performer = deal.performer;
        token = deal.token;
        (amount, date, commission, status) = getPackedInfo(deal.packedInfo);
    }

    /**
     * @dev Returns packedinfo about the deal.
     */
    function setPackedInfo(
        uint256 _amount,
        uint256 _date,
        uint256 _commission,
        uint256 _status
    ) private pure returns (uint256) {
        uint256 packed = uint256(_amount);
        packed |= _date << 208;
        packed |= _commission << 240;
        packed |= _status << 248;
        return packed;
    }

    /**
     * @dev Returns unpackedinfo about the deal.
     */
    function getPackedInfo(uint256 _info)
        private
        pure
        returns (
            uint256 _amount,
            uint256 _date,
            uint256 _commission,
            uint256 _status
        )
    {
        _amount = uint208(_info);
        _date = uint256(uint32(_info >> 208));
        _commission = uint256(uint8(_info >> 240));
        _status = uint256(uint8(_info >> 248));
    }

    /**
     * @dev Returns all deals id in which the user participates.
     */
    function getUserDealsId(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _count = count;
        uint256 numL;
        uint256 num;
        for (uint256 i = 2; i <= _count; i++) {
            if (deals[i].creator == user || deals[i].performer == user) {
                numL++;
            }
        }
        uint256[] memory ids = new uint256[](numL);
        for (uint256 i = 2; i <= _count; i++) {
            if (deals[i].creator == user || deals[i].performer == user) {
                ids[num] = i;
                num++;
            }
        }
        return ids;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @dev Changes the commission.
     *
     * Requirements:
     *
     * - `commission` cannot be less than 0 and greater than 100.
     *
     */
    function changeCommission(uint256 newCommission) external onlyOwner {
        require(
            newCommission > 0 && newCommission < 100,
            "Commission must be > 0 && < 100"
        );
        currentCommission = newCommission;
    }

    /**
     * @dev Returns amount including commissioning.
     */
    function amountWithCommission(uint256 _amount, uint256 _commission)
        private
        pure
        returns (uint256)
    {
        return _amount - ((_amount * (_commission * 100)) / 10000);
    }

    /**
     * @dev Returns amount that can be withdraw.
     */
    function amountCanWithdraw(address _token) public view returns (uint256) {
        uint256 _count = count;
        uint256 _amount;
        uint256 balance = _token == address(0)
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));
        for (uint256 i = 2; i <= _count; i++) {
            (
                ,
                ,
                uint256 amount,
                address token,
                ,
                uint256 commission,

            ) = _getDeal(i);
            if (_token == token) {
                _amount += amountWithCommission(amount, commission);
            }
        }

        return balance - _amount;
    }

    /**
     * @dev Withdraws funds from the contract.
     *
     * Requirements:
     *
     * - `amount` must be greater than 0.
     * - `amount` must be not greater than {amountCanWithdraw}.
     * - `receiver` cannot be the zero address.
     * - `token` cannot be the zero address.
     *
     */
    function withdraw(
        address receiver,
        address token,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(
            amount <= amountCanWithdraw(token),
            "Amount greater than can be"
        );
        require(receiver != address(0), "Receiver cannot be zero address");
        require(token != address(0), "Token cannot be zero address");

        transferToken(token, address(this), receiver, amount);

        emit Withdraw(receiver, amount, token, block.timestamp);
    }

    /**
     * @dev Withdraws funds from the contract.
     *
     * Requirements:
     *
     * - `amount` must be greater than 0.
     * - `amount` must be not greater than {amountCanWithdraw}.
     * - `receiver` cannot be the zero address.
     *
     */
    function withdrawNative(address payable receiver, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "Amount must be > 0");
        require(
            amount <= amountCanWithdraw(address(0)),
            "Amount greater than can be"
        );
        require(receiver != address(0), "Receiver cannot be zero address");
        receiver.transfer(amount);

        emit Withdraw(receiver, amount, address(0), block.timestamp);
    }
}
