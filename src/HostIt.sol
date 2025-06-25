// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "@diamond/Diamond.sol";
import {FacetCut, DiamondArgs} from "@diamond/libraries/types/DiamondTypes.sol";

contract HostIt is Diamond {
    constructor(FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable Diamond(_diamondCut, _args) {}
}
