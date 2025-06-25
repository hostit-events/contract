// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TicketData, FeeType} from "@host-it/libraries/types/TicketTypes.sol";

//*//////////////////////////////////////////////////////////////////////////
//                           TICKET STORAGE STRUCT
//////////////////////////////////////////////////////////////////////////*//

/// @custom:storage-location erc7201:host.it.ticket.factory.storage
struct TicketStorage {
    uint256 ticketCount; // Total number of tickets created
    mapping(uint256 => TicketData) tickets; // Mapping from ticketId to ticket data
    mapping(address => uint256[]) allAdminTickets; // Mapping from organizer address to all ticket IDs they administer
    mapping(uint256 => mapping(address => bool)) ticketCheckIns; // Mapping from ticketId to attendance by attendee address
    mapping(uint256 => mapping(uint16 => mapping(address => bool))) ticketCheckInsByDay; // Mapping from ticketId and day to attendance by attendee address
    mapping(uint256 => mapping(FeeType => bool)) ticketFeeEnabled; // Mapping from ticketId to ticket fee data
    mapping(uint256 => mapping(FeeType => uint256)) ticketFee; // Mapping from ticketId to ticket fee amount
    mapping(FeeType => mapping(uint256 => address)) feeTokenAddress; // Mapping from FeeType to ChainId to token address
    mapping(uint256 => mapping(FeeType => mapping(uint256 => uint256))) ticketBalanceByChainId; // Mapping from ticketId to chainId to ticket fee balance
    mapping(FeeType => mapping(uint256 => uint256)) hostItBalanceByChainId; // Mapping from FeeType to chainId to HostIt fee balance
}

library LibTicketStorage {
    //*//////////////////////////////////////////////////////////////////////////
    //                               TICKET STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TICKET_STORAGE_POSITION =
        0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

    /// @dev Get the ticket storage.
    function _ticketStorage() internal pure returns (TicketStorage storage $) {
        bytes32 position = TICKET_STORAGE_POSITION;
        assembly {
            $.slot := position
        }
    }
}
