// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @notice Thrown when the withdraw call fails
error WithdrawFailed();

/// @title TicketNFT
/// @notice NFT contract for event ticketing with royalty support, pausability, and metadata management
/// @dev Inherits from OpenZeppelin and Solady base contracts to combine ERC721, royalties, pausability, and URI storage
contract TicketNFT is ERC721, ERC721Enumerable, ERC721Royalty, ERC721URIStorage, Ownable, Pausable {
    /// @notice Constructor to initialize the NFT collection with name, symbol, and royalty receiver
    /// @param _owner The initial owner of the contract
    /// @param __name The name of the TicketNFT
    /// @param __symbol The symbol of the TicketNFT
    constructor(address _owner, string memory __name, string memory __symbol) payable ERC721(__name, __symbol) {
        _initializeOwner(_owner);
        _setDefaultRoyalty(_owner, 500); // Set default royalty to 5%
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    /// @notice Check if a given interface is supported by this contract
    /// @param _interfaceId The interface identifier to check
    /// @return True if the interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721URIStorage, ERC721Royalty, ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId) || ERC721Enumerable.supportsInterface(_interfaceId)
            || ERC721Royalty.supportsInterface(_interfaceId) || ERC721URIStorage.supportsInterface(_interfaceId);
    }

    /// @notice Returns the metadata URI for a given token ID
    /// @param _tokenId The ID of the token
    /// @return The URI pointing to the token's metadata
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    /// @notice Allows the owner to set the metadata URI for a specific token
    /// @param _tokenId The ID of the token
    /// @param _tokenURI The URI to assign
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external payable onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /// @notice Pauses token transfers
    function pause() external payable onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfers
    function unpause() external payable onlyOwner {
        _unpause();
    }

    /// @notice Mints a new token to a given address
    /// @param _to The address to receive the newly minted token
    /// @return tokenId_ The ID of the newly minted token
    function safeMint(address _to) external payable onlyOwner returns (uint256 tokenId_) {
        tokenId_ = totalSupply() + 1; // Increment tokenId based on total supply
        _safeMint(_to, tokenId_);
    }

    /// @notice Withdraws the contract's ETH balance to the owner's address
    function withdraw() external payable onlyOwner {
        (bool success,) = address(payable(owner())).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//
    /// @dev Internal override for token transfer logic, applies pausability
    function _update(address _to, uint256 _tokenId, address _auth)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
        returns (address)
    {
        return super._update(_to, _tokenId, _auth);
    }

    /// @dev Internal override to increase balance, applies pausability
    function _increaseBalance(address _account, uint128 _amount)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._increaseBalance(_account, _amount);
    }
}
