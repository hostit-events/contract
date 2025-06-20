// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FacetCut, TicketData, PayFeeIn} from "./Types.sol";

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT EVENT
//////////////////////////////////////////////////////////////////////////*//

/// @notice Emitted when a diamond cut (facet add/replace/remove) is executed.
/// @dev Logged after executing `diamondCut` with its associated initializer.
/// @param diamondCut The array of facet cuts specifying facet addresses, actions, and function selectors.
/// @param init The address of the contract or facet to delegatecall for initialization.
/// @param data The calldata passed to the `init` address for initialization.
event DiamondCut(FacetCut[] diamondCut, address init, bytes data);

//*//////////////////////////////////////////////////////////////////////////
//                             TICKET FACET EVENT
//////////////////////////////////////////////////////////////////////////*//

event TicketCreated(uint256 indexed ticketId);

event TicketUpdated(uint256 indexed ticketId);

event TicketFeeSet(uint256 indexed ticketId, PayFeeIn payFeeIn, uint256 fee);

event AttendeeRegistered(uint256 indexed ticketId, address attendee);

event AttendeeCheckedIn(uint256 indexed ticketId, address attendee);
