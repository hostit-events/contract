// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {HostIt} from "@host-it/HostIt.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {MultiInit} from "@diamond/initializers/MultiInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {SetFeeTokenAddresses} from "@diamond/initializers/SetFeeTokenAddresses.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {LibDiamond} from "@diamond/libraries/LibDiamond.sol";
import {FacetCutAction, FacetCut, DiamondArgs} from "@diamond/libraries/types/DiamondTypes.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";
import {TicketFactoryFacet} from "@host-it/facets/TicketFactoryFacet.sol";
import {TicketCheckInFacet} from "@host-it/facets/TicketCheckInFacet.sol";
import {TicketMarketplaceFacet} from "@host-it/facets/TicketMarketplaceFacet.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";
import "@host-it/libraries/constants/TokenAddresses.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
///
/// @dev Uses Foundry's `Script` and a helper contract to deploy and wire up DiamondCutFacet, DiamondLoupeFacet, and OwnableRolesFacet
contract DeployHostIt is Script, HelperContract {
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnableRolesFacet ownableRolesFacet;
    TicketFactoryFacet ticketFactoryFacet;
    TicketCheckInFacet ticketCheckInFacet;
    TicketMarketplaceFacet ticketMarketplaceFacet;
    MultiInit multiInit;
    ERC165Init erc165Init;
    SetFeeTokenAddresses setFeeTokenAddresses;

    /// @notice Executes the deployment of the Diamond contract with the initial facets and ERC165 interface setup
    /// @dev Broadcasts transactions using Foundry's scripting environment (`vm.startBroadcast()` and `vm.stopBroadcast()`).
    ///      Deploys three core facets, sets up DiamondArgs, encodes an initializer call, and constructs the Diamond.
    /// @return diamond_ The address of the deployed Diamond proxy contract
    function run() external returns (HostIt diamond_) {
        vm.createSelectFork("base-sepolia");
        vm.startBroadcast();

        // Deploy facet contracts
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownableRolesFacet = new OwnableRolesFacet();
        ticketFactoryFacet = new TicketFactoryFacet();
        ticketCheckInFacet = new TicketCheckInFacet();
        ticketMarketplaceFacet = new TicketMarketplaceFacet();

        // Deploy ERC165 initializer contract
        erc165Init = new ERC165Init();

        // Deploy SetFeeTokenAddresses initializer contract
        setFeeTokenAddresses = new SetFeeTokenAddresses();

        // Deploy MultiInit contract to handle multiple initializers
        multiInit = new MultiInit();

        address[] memory initAddr = new address[](2);
        bytes[] memory initData = new bytes[](2);

        initAddr[0] = address(erc165Init);
        initData[0] = abi.encodeWithSignature("initERC165()");

        uint8[] memory feeTypes = new uint8[](3);
        feeTypes[0] = uint8(FeeType.USDC);
        feeTypes[1] = uint8(FeeType.EURC);
        feeTypes[2] = uint8(FeeType.USDT);

        address[] memory feeTokenAddresses = new address[](3);
        feeTokenAddresses[0] = BASE_SEPOLIA_USDC_ADDRESS;
        feeTokenAddresses[1] = BASE_SEPOLIA_EURC_ADDRESS;
        feeTokenAddresses[2] = BASE_SEPOLIA_USDT_ADDRESS;

        initAddr[1] = address(setFeeTokenAddresses);
        initData[1] = abi.encodeWithSignature("setFeeTokenAddresses(uint8[],address[])", feeTypes, feeTokenAddresses);

        // Prepare DiamondArgs: owner and init data
        DiamondArgs memory args = DiamondArgs({
            owner: msg.sender,
            init: address(multiInit),
            initData: abi.encodeWithSignature("multiInit(address[],bytes[])", initAddr, initData)
        });

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](6);

        // Add DiamondCutFacet to the cut list
        cut[0] = FacetCut({
            facetAddress: address(diamondCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondCutFacet")
        });

        // Add DiamondLoupeFacet to the cut list
        cut[1] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondLoupeFacet")
        });

        // Add OwnableRolesFacet to the cut list
        cut[2] = FacetCut({
            facetAddress: address(ownableRolesFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("OwnableRolesFacet")
        });

        // Add TicketFactoryFacet to the cut list
        cut[3] = FacetCut({
            facetAddress: address(ticketFactoryFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("TicketFactoryFacet")
        });

        // Add TicketCheckInFacet to the cut list
        cut[4] = FacetCut({
            facetAddress: address(ticketCheckInFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("TicketCheckInFacet")
        });

        // Add TicketMarketplaceFacet to the cut list
        cut[5] = FacetCut({
            facetAddress: address(ticketMarketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("TicketMarketplaceFacet")
        });

        // Deploy the Diamond contract with the facets and initialization args
        diamond_ = new HostIt(cut, args);
        console.log("HostIt deployed at:", address(diamond_));

        vm.stopBroadcast();
    }
}
