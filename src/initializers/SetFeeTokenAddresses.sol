// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";
import {LibTicketMarketplace} from "@host-it/libraries/LibTicketMarketplace.sol";

contract SetFeeTokenAddresses {
    using LibTicketMarketplace for *;
    /// @notice Sets the fee token addresses for the ticket system.
    /// @param _feeTypes The array of fee types corresponding to the fee token addresses.
    /// @param _tokenAddresses The array of fee token addresses to set.
    /// @dev This function allows the owner to set the fee token addresses for different fee types.

    function setFeeTokenAddresses(FeeType[] calldata _feeTypes, address[] calldata _tokenAddresses) external {
        _feeTypes._setFeeTokenAddresses(_tokenAddresses);
    }
}
