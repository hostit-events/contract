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
}
