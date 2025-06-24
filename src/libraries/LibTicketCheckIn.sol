// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {LibTicketStorage, TicketStorage} from "@host-it/libraries/LibTicketStorage.sol";
import {TicketData} from "@host-it/libraries/types/TicketTypes.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";
import {TicketCheckIn} from "@host-it/libraries/logs/TicketLogs.sol";
import {LibTicketFactory} from "@host-it/libraries/LibTicketFactory.sol";
import {
    TicketUsePeriodNotStarted,
    TicketUsePeriodHasEnded,
    NotTicketOwner,
    InvalidTicketId
} from "@host-it/libraries/errors/TicketErrors.sol";

library LibTicketCheckIn {
    using LibTicketCheckIn for uint256;
    using LibTicketFactory for uint256;
    using {LibOwnableRoles._checkRoles} for uint256;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getTicketCheckIns(uint256 _ticketId, address _attendee) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketCheckIns[_ticketId][_attendee];
    }

    function _getTicketCheckInsByDay(uint256 _ticketId, uint16 _day, address _attendee) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketCheckInsByDay[_ticketId][_day][_attendee];
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _checkInTicket(uint256 _ticketId, address _ticketOwner, uint256 _tokenId) internal {
        require(_ticketId._ticketExists(), InvalidTicketId());
        _ticketId._generateTicketAdminRole()._checkRoles();

        TicketStorage storage $ = LibTicketStorage._ticketStorage();

        TicketData memory ticketData = _ticketId._getTicketData();
        uint256 blockTimestamp = block.timestamp;
        require(blockTimestamp >= ticketData.startTime, TicketUsePeriodNotStarted());
        require(blockTimestamp <= ticketData.endTime, TicketUsePeriodHasEnded());
        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        require(ticketNFT.ownerOf(_tokenId) == _ticketOwner, NotTicketOwner(_tokenId));

        // Pause the NFT contract if it is not already paused
        // This is a security measure to ensure that the ticket cannot be transferred while the check-in
        // is being processed, which could lead to inconsistencies in attendance tracking
        if (!ticketNFT.paused()) ticketNFT.pause();

        // Mark attendance
        if (!_ticketId._getTicketCheckIns(_ticketOwner)) $.ticketCheckIns[_ticketId][_ticketOwner] = true;

        // Mark attendance by day
        uint16 day = uint16((blockTimestamp - ticketData.startTime) / 1 days);
        if (!_ticketId._getTicketCheckInsByDay(day, _ticketOwner)) {
            $.ticketCheckInsByDay[_ticketId][day][_ticketOwner] = true;
        }

        emit TicketCheckIn(_ticketId, _ticketOwner, blockTimestamp);
    }
}
