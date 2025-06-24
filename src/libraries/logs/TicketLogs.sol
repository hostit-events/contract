// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TicketData, FeeType} from "@host-it/libraries/types/TicketTypes.sol";

//*//////////////////////////////////////////////////////////////////////////
//                           TICKET FACTORY EVENTS
//////////////////////////////////////////////////////////////////////////*//

event TicketCreated(uint256 indexed ticketId, TicketData ticketData, address indexed ticketAdmin);

event TicketUpdated(uint256 indexed ticketId, TicketData ticketData);

event TicketPurchased(uint256 indexed ticketId, address indexed buyer, FeeType feeType, uint256 fee);

event TicketMinted(address indexed ticketNFT, address indexed to, uint256 tokenId);

event TicketCheckIn(uint256 indexed ticketId, address indexed ticketOwner, uint256 timestamp);

event TicketBalanceWithdrawn(uint256 indexed ticketId, FeeType feeType, uint256 amount, address indexed target);
