// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibTicketMarketplace} from "@host-it/libraries/LibTicketMarketplace.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";

contract TicketMarketplaceFacet {
    using LibTicketMarketplace for *;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function getFeeTokenAddress(FeeType _feeType) external view returns (address) {
        return _feeType._getFeeTokenAddress();
    }

    function getTicketFeeEnabled(uint256 _ticketId, FeeType _feeType) external view returns (bool) {
        return _ticketId._getTicketFeeEnabled(_feeType);
    }

    function getTicketFee(uint256 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketFee(_feeType);
    }

    function getTicketBalance(uint256 _ticketId, FeeType _feeType) external view returns (uint256) {
        return _ticketId._getTicketBalance(_feeType);
    }

    function getHostItBalance(FeeType _feeType) external view returns (uint256) {
        return _feeType._getHostItBalance();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function updateTicketFee(uint256 _ticketId, bool _isFree, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        external
        payable
    {
        _ticketId._updateTicketFee(_isFree, _feeTypes, _fees);
    }

    function purchaseTicket(uint256 _ticketId, FeeType _feeType) external payable returns (uint256 tokenId_) {
        return _ticketId._purchaseTicket(_feeType);
    }

    function withdrawTicketBalance(uint256 _ticketId, FeeType _feeType, address _to) external payable {
        _ticketId._withdrawTicketBalance(_feeType, _to);
    }

    function withdrawHostItBalance(FeeType _feeType, address _to) external payable {
        _feeType._withdrawHostItBalance(_to);
    }
}
