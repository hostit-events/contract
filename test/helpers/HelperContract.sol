// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {Facet} from "@diamond/libraries/constants/Types.sol";

/// @notice A utility contract providing helper functions for working with diamond facets and selectors.
/// @author David Dada
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/test/HelperContract.sol)
///
/// @dev Includes support for generating selectors using Foundry FFI, array manipulation, and facet inspection.
abstract contract HelperContract is Test {
    using LibString for string;

    /// @notice Generates function selectors for a given facet using Foundry's `forge inspect`.
    /// @dev Uses `vm.ffi` to execute a shell command that retrieves method identifiers.
    /// @param _facet The name of the facet contract to inspect.
    /// @return selectors_ An array of function selectors extracted from the facet.
    function generateSelectors(string memory _facet) internal returns (bytes4[] memory selectors_) {
        string[] memory cmd = new string[](5);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facet;
        cmd[3] = "methodIdentifiers";
        cmd[4] = "--json";

        bytes memory res = vm.ffi(cmd);
        string memory output = string(res);

        // Constants for parsing
        string memory newLine = "\n";
        string memory colon = ":";
        string memory doubleQuote = '"';

        // Split the output into lines
        string[] memory lines = output.split(newLine);

        // Count the number of selectors
        uint256 selectorCount = 0;
        for (uint256 i; i < lines.length; i++) {
            // Check if the line contains a colon, indicating a selector
            if (lines[i].contains(colon)) {
                selectorCount++;
            }
        }
        // Initialize the selectors array with the selectorCount
        selectors_ = new bytes4[](selectorCount);

        // Parse the selectors from the lines
        uint256 selectorIndex = 0;
        for (uint256 i; i < lines.length; i++) {
            if (lines[i].contains(colon)) {
                string memory line = lines[i];
                uint256 firstDoubleQuote = line.indexOf(doubleQuote);
                // The second quote should start after the first one
                uint256 secondDoubleQuote = line.indexOf(doubleQuote, firstDoubleQuote + 1);

                // Extract the function signature between quotes
                string memory signature = line.slice(
                    firstDoubleQuote + 1, // +1 to exclude the quote itself
                    secondDoubleQuote
                );

                // Hash the signature to get the selector
                selectors_[selectorIndex] = bytes4(keccak256(bytes(signature)));
                selectorIndex++;
            }
        }
    }

    /// @notice Removes an element from a bytes4 array at the given index.
    /// @param _index The index of the element to remove.
    /// @param _array The original array.
    /// @return array_ A new array with the element at `_index` removed.
    function removeElement(uint256 _index, bytes4[] memory _array) public pure returns (bytes4[] memory array_) {
        array_ = new bytes4[](_array.length - 1);
        uint256 j = 0;
        for (uint256 i; i < _array.length; i++) {
            if (i != _index) {
                array_[j] = _array[i];
                j += 1;
            }
        }
    }

    /// @notice Removes a specific selector from a bytes4 array.
    /// @param el The selector to remove.
    /// @param _array The original array.
    /// @return array_ A new array without the specified selector.
    function removeElement(bytes4 el, bytes4[] memory _array) public pure returns (bytes4[] memory array_) {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == el) {
                array_ = removeElement(i, _array);
            }
        }
    }

    /// @notice Checks if a bytes4 array contains a specific selector.
    /// @param _array The array to check.
    /// @param _el The selector to look for.
    /// @return `true` if the selector is found, `false` otherwise.
    function containsElement(bytes4[] memory _array, bytes4 _el) public pure returns (bool) {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _el) {
                return true;
            }
        }

        return false;
    }

    /// @notice Checks if an address array contains a specific address.
    /// @param _array The array to check.
    /// @param _el The address to look for.
    /// @return `true` if the address is found, `false` otherwise.
    function containsElement(address[] memory _array, address _el) public pure returns (bool) {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _el) {
                return true;
            }
        }

        return false;
    }

    /// @notice Determines if two arrays of function selectors have the same members.
    /// @param _array1 The first array.
    /// @param _array2 The second array.
    /// @return `true` if the arrays contain the same elements (regardless of order), `false` otherwise.
    function sameMembers(bytes4[] memory _array1, bytes4[] memory _array2) public pure returns (bool) {
        if (_array1.length != _array2.length) {
            return false;
        }
        for (uint256 i; i < _array1.length; i++) {
            if (containsElement(_array1, _array2[i])) {
                return true;
            }
        }

        return false;
    }

    /// @notice Retrieves all function selectors from all facets of a diamond contract.
    /// @param _diamondAddress The address of the diamond contract.
    /// @return selectors_ An array of all function selectors used in the diamond.
    function getAllSelectors(address _diamondAddress) public view returns (bytes4[] memory selectors_) {
        Facet[] memory facetList = IDiamondLoupe(_diamondAddress).facets();

        uint256 len = 0;
        for (uint256 i; i < facetList.length; i++) {
            len += facetList[i].functionSelectors.length;
        }

        uint256 pos = 0;
        selectors_ = new bytes4[](len);
        for (uint256 i; i < facetList.length; i++) {
            for (uint256 j; j < facetList[i].functionSelectors.length; j++) {
                selectors_[pos] = facetList[i].functionSelectors[j];
                pos += 1;
            }
        }
    }
}
