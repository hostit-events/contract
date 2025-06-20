// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {TicketData, PayFeeIn} from "@host-it/libraries/constants/Types.sol";
import {FeeAlreadySet} from "@host-it/libraries/constants/Errors.sol";
import {TicketCreated} from "@host-it/libraries/constants/Logs.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";

/// @custom:storage-location erc7201:host.it.ticket.factory.storage
struct TicketStorage {
    uint256 ticketCount;
    // Mapping from ticketId to ticket data.
    mapping(uint256 => TicketData) tickets;
    // Mapping from ticketId to ticket fee data.
    mapping(uint256 => mapping(PayFeeIn => bool)) ticketFeeEnabled;
    // Mapping from ticketId to ticket fee amount.
    mapping(uint256 => mapping(PayFeeIn => uint256)) ticketFee;
    // Mapping from ticketId to attendance by attendee address.
    mapping(uint256 => mapping(address => bool)) ticketAttendance;
    // Mapping from ticketId and day to attendance by attendee address.
    mapping(uint256 => mapping(uint8 => mapping(address => bool))) ticketAttendanceByDay;
}

library LibTicketFactory {
    //*//////////////////////////////////////////////////////////////////////////
    //                               TICKET STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TICKET_STORAGE_POSITION =
        0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

    // keccak256("host.it.event")
    bytes32 private constant HOST_IT_EVENT = 0x2370ff48664935bbd91bfcc2e27d83f8e80f6e0f844565fdc9c2f102483eb37f;
    // keccak256("host.it.main.organizer")
    bytes32 private constant MAIN_ORGANIZER = 0x2487a75af03597315acf7d6da832c95b21649da209abb10a542527fad8eea5a4;
    // keccak256("host.it.organizer")
    bytes32 private constant ORGANIZER = 0xf073cf9cd7609887f5af80611e0acfc2c67ccf2eb78ddd5eec71007794177229;

    /// @dev Get the ticket storage.
    function _ticketStorage() internal pure returns (TicketStorage storage $) {
        bytes32 position = TICKET_STORAGE_POSITION;
        assembly {
            $.slot := position
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    function _getTicketCount() internal view returns (uint256) {
        return _ticketStorage().ticketCount;
    }

    function _getTicketData(uint256 _ticketId) internal view returns (TicketData memory) {
        return _ticketStorage().tickets[_ticketId];
    }

    function _getTicketFeeEnabled(uint256 _ticketId, PayFeeIn _payFeeIn) internal view returns (bool) {
        return _ticketStorage().ticketFeeEnabled[_ticketId][_payFeeIn];
    }

    function _getTicketFee(uint256 _ticketId, PayFeeIn _payFeeIn) internal view returns (uint256) {
        return _ticketStorage().ticketFee[_ticketId][_payFeeIn];
    }

    function _getTicketAttendance(uint256 _ticketId, address _attendee) internal view returns (bool) {
        return _ticketStorage().ticketAttendance[_ticketId][_attendee];
    }

    function _getTicketAttendanceByDay(uint256 _ticketId, uint8 _day, address _attendee) internal view returns (bool) {
        return _ticketStorage().ticketAttendanceByDay[_ticketId][_day][_attendee];
    }

    function _getAllTicketData() internal view returns (TicketData[] memory tickets) {
        uint256 count = _getTicketCount();
        tickets = new TicketData[](count);
        for (uint256 i; i < count;) {
            tickets[i] = _getTicketData(i + 1); // Ticket IDs start from 1
            unchecked {
                ++i;
            }
        }
    }

    // review
    function _getLastAmountOfTicketData(uint256 _amount) internal view returns (TicketData[] memory tickets) {
        uint256 count = _getTicketCount();
        require(_amount > 0 && _amount <= count, "Invalid amount");
        tickets = new TicketData[](_amount);
        uint256 range = count - _amount;
        for (uint256 i = range; i < count;) {
            tickets[i - range] = _getTicketData(i + 1); // Ticket IDs start from 1
            unchecked {
                ++i;
            }
        }
    }

    function _getHostItEvent() private pure returns (bytes32) {
        return HOST_IT_EVENT;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    function _generateEventHash(uint256 _ticketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(_getHostItEvent(), _ticketId));
    }

    function _generateMainOrganizerRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_getHostItEvent(), MAIN_ORGANIZER, _ticketId)));
    }

    function _generateOrganizerRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_getHostItEvent(), ORGANIZER, _ticketId)));
    }

    function _createTicket(
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTickets,
        bool _isFree,
        PayFeeIn[] calldata _payFeeIns,
        uint256[] calldata _fees
    ) internal returns (address) {
        TicketStorage storage $ = _ticketStorage();
        uint256 ticketId = $.ticketCount + 1;
        uint256 mainOrganizerRole = _generateMainOrganizerRole(ticketId);
        uint256 organizerRole = _generateOrganizerRole(ticketId);
        address organizer = msg.sender;
        LibOwnableRoles._grantRoles(organizer, mainOrganizerRole);
        LibOwnableRoles._grantRoles(organizer, organizerRole);

        TicketNFT ticketNFT = new TicketNFT{salt: _generateEventHash(ticketId)}(address(this), _name, _symbol, _uri);

        $.tickets[ticketId] = TicketData({
            id: ticketId,
            organizer: organizer,
            ticketNFTAddress: address(ticketNFT),
            isFree: _isFree,
            createdAt: block.timestamp,
            updatedAt: 0,
            startTime: _startTime,
            endTime: _endTime,
            maxTickets: _maxTickets,
            soldTickets: 0
        });

        if (!_isFree) {
            uint256 payFeeInsLength = _payFeeIns.length;
            require(payFeeInsLength == _fees.length && payFeeInsLength > 0, "Invalid fee configuration");
            for (uint256 i; i < payFeeInsLength;) {
                PayFeeIn payFeeIn = _payFeeIns[i];
                if ($.ticketFeeEnabled[ticketId][payFeeIn]) revert FeeAlreadySet();
                uint256 fee = _fees[i];
                require(fee > 0, "Fee must be greater than zero");
                $.ticketFeeEnabled[ticketId][payFeeIn] = true;
                $.ticketFee[ticketId][payFeeIn] = fee;
                unchecked {
                    ++i;
                }
            }
        }

        emit TicketCreated(ticketId);

        return address(ticketNFT);
    }
}
