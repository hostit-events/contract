// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibTicketCheckIn} from "@host-it/libraries/LibTicketCheckIn.sol";

contract TicketCheckInFacet {
    using LibTicketCheckIn for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getTicketCheckIns(uint256 _ticketId, address _attendee) external view returns (bool) {
        return _ticketId._getTicketCheckIns(_attendee);
    }

    function getTicketCheckInsByDay(uint256 _ticketId, uint16 _day, address _attendee) external view returns (bool) {
        return _ticketId._getTicketCheckInsByDay(_day, _attendee);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function checkInTicket(uint256 _ticketId, address _ticketOwner, uint256 _tokenId) external payable {
        _ticketId._checkInTicket(_ticketOwner, _tokenId);
    }
}
