// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TicketData, PayFeeIn} from "@host-it/libraries/constants/Types.sol";

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
}
