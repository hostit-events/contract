// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

<<<<<<<< HEAD:src/libraries/logs/DiamondLogs.sol
import {FacetCut} from "@diamond/libraries/types/DiamondTypes.sol";
========
import {FacetCut, TicketData, FeeType} from "./Types.sol";
>>>>>>>> dev:src/libraries/constants/Logs.sol

//*//////////////////////////////////////////////////////////////////////////
//                            DIAMOND CUT EVENTS
//////////////////////////////////////////////////////////////////////////*//

/// @notice Emitted when a diamond cut (facet add/replace/remove) is executed.
/// @dev Logged after executing `diamondCut` with its associated initializer.
/// @param diamondCut The array of facet cuts specifying facet addresses, actions, and function selectors.
/// @param init The address of the contract or facet to delegatecall for initialization.
/// @param data The calldata passed to the `init` address for initialization.
event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
