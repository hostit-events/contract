// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT TYPES
//////////////////////////////////////////////////////////////////////////*//

/// @notice Actions that can be performed on a facet during a diamond cut
/// @dev `Add` will add new function selectors, `Replace` will swap existing
///       selectors to a new facet, `Remove` will delete selectors
enum FacetCutAction {
    Add,
    Replace,
    Remove
}

/// @notice Defines an operation (add/replace/remove) to perform on a facet
/// @param facetAddress The address of the facet contract to operate on
/// @param action The action to perform (Add, Replace, Remove)
/// @param functionSelectors List of function selectors to apply the action to
struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

/// @notice Initialization parameters passed to the Diamond constructor
/// @param owner The address that will be granted the initial ownership/roles
/// @param init Optional address of a contract to call after the cut (use zero address for none)
/// @param initData Calldata to pass to the init contract (if any)
struct DiamondArgs {
    address owner;
    address init;
    bytes initData;
}

/// @notice Struct representing a facet in a diamond contract.
/// @dev Used for introspection of facet data through loupe functions.
/// @param facetAddress The address of the facet contract.
/// @param functionSelectors The list of function selectors provided by this facet.
struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

//*//////////////////////////////////////////////////////////////////////////
//                               HOST IT TYPES
/////////////////////////////////////////////////////////////////////////*//

struct TicketData {
    uint256 id;
    address ticketAdmin;
    address ticketNFTAddress;
    bool isFree;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 startTime;
    uint256 endTime;
    uint256 purchaseStartTime;
    uint256 maxTickets;
    uint256 soldTickets;
}

enum FeeType {
    ETH,
    USDT,
    USDC,
    EURC,
    USDT0,
    LSK
}
