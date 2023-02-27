// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./interfaces/IEscrow.sol";
import "./interfaces/IERC20.sol";
import "./utils/Roles.sol";
import "./utils/Blacklist.sol";


contract Escrow is IEscrow, Roles, Blacklist {
    uint256 public currentCommission = 10;
    // packedInfo256 = amount208, date32, commission8, status8
    enum Status {
        PENDING,
        OPEN,
        CLOSED
    }
    struct Deal {
        uint256 packedInfo;
        address creator;
        address performer;
        address token;
    }

    uint256 count = 1;

    mapping(uint256 => Deal) deals;

    function createDeal(
        address performer,
        uint256 amount,
        address token
    ) external isBlacklisted{
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

    function createDealNative(address performer) external isBlacklisted payable {
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

    function confirmDeal(uint256 id) external {
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

        uint256 _amount = amount - ((amount * (commission * 100)) / 10000);

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

        uint256 _amount = amount - ((amount * (commission * 100)) / 10000);

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

    function getHash(address creator, uint256 nonce)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(creator, nonce));
    }

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

    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        IERC20(token).transferFrom(from, to, amount);
    }

    function changeCommission(uint newCommission) external onlyOwner {
        require(newCommission > 0 && newCommission < 100, "Commission must be > 0 && < 100");
        currentCommission = newCommission;
    }

    function withdraw(address receiver, address token, uint amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(receiver != address(0), "Receiver cannot be zero address");
        require(token != address(0), "Token cannot be zero address");
        transferToken(token,address(this),receiver,amount);
    }

    function withdrawNative(address payable receiver, uint amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(receiver != address(0), "Receiver cannot be zero address");
        receiver.transfer(amount);
    }
}
