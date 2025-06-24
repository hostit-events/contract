// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TicketStorage, LibTicketFactory} from "@host-it/libraries/LibTicketFactory.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";

contract TicketFactoryFacet {
    using LibTicketFactory for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getTicketCount() external view returns (uint256) {
        return LibTicketFactory._getTicketCount();
    }

    function getTicketData(uint256 _ticketId) external view returns (TicketData memory) {
        return _ticketId._getTicketData();
    }

    function getTicketMetadata(uint256 _ticketId) external view returns (TicketMetadata memory) {
        return _ticketId._getTicketMetadata();
    }

    function getAllTicketMetadata() external view returns (TicketMetadata[] memory) {
        return LibTicketFactory._getAllTicketMetadata();
    }

    function getAllAdminTicketIds(address _organizer) external view returns (uint256[] memory) {
        return _organizer._getAllAdminTicketIds();
    }

    function getAllAdminTicketMetadata(address _organizer) external view returns (TicketMetadata[] memory) {
        return _organizer._getAllAdminTicketMetadata();
    }

    function getLastAmountOfTicketMetadata(uint256 _amount) external view returns (TicketMetadata[] memory) {
        return _amount._getLastAmountOfTicketMetadata();
    }

    function getTicketCheckIns(uint256 _ticketId, address _attendee) external view returns (bool) {
        return _ticketId._getTicketCheckIns(_attendee);
    }

    function getTicketCheckInsByDay(uint256 _ticketId, uint16 _day, address _attendee) external view returns (bool) {
        return _ticketId._getTicketCheckInsByDay(_day, _attendee);
    }

    function getTicketFeeEnabled(uint256 _ticketId, FeeType _feeType) external view returns (bool) {
        return _ticketId._getTicketFeeEnabled(_feeType);
    }

    function getTicketFee(uint256 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketFee(_feeType);
    }

    function getFeeTokenAddress(FeeType _feeType) external view returns (address) {
        return _feeType._getFeeTokenAddress();
    }

    function getTicketBalance(uint256 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketBalance(_feeType);
    }

    function getHostItBalance(FeeType _feeType) external view returns (uint256) {
        return _feeType._getHostItBalance();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getHostItTicketHash() external pure returns (bytes32) {
        return LibTicketFactory._getHostItTicketHash();
    }

    function generateTicketHash(uint256 _ticketId) external pure returns (bytes32) {
        return _ticketId._generateTicketHash();
    }

    function generateMainTicketAdminRole(uint256 _ticketId) external pure returns (uint256) {
        return _ticketId._generateMainTicketAdminRole();
    }

    function generateTicketAdminRole(uint256 _ticketId) external pure returns (uint256) {
        return _ticketId._generateTicketAdminRole();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function createTicket(
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseStartTime,
        uint256 _maxTickets,
        bool _isFree,
        FeeType[] calldata _feeTypes,
        uint256[] calldata _fees
    ) external payable returns (address, uint256) {
        return _name._createTicket(
            _symbol, _uri, _startTime, _endTime, _purchaseStartTime, _maxTickets, _isFree, _feeTypes, _fees
        );
    }

    function updateTicketMetadata(
        uint256 _ticketId,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseStartTime,
        uint256 _maxTickets
    ) external payable {
        _ticketId._updateTicketMetadata(_name, _symbol, _uri, _startTime, _endTime, _purchaseStartTime, _maxTickets);
    }

    function updateTicketFee(uint256 _ticketId, bool _isFree, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
        payable
    {
        _ticketId._updateTicketFee(_isFree, _feeTypes, _fees);
    }
}
