// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";

library LibTicketMarketplace {
    using SafeERC20 for IERC20;
}
