// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract TicketNFT is ERC721, ERC721Enumerable, ERC721Royalty, ERC721URIStorage, Ownable, Pausable {
    constructor(address _owner, string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _initializeOwner(_owner);
        _setDefaultRoyalty(_owner, 500); // Set default royalty to 5%
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721URIStorage, ERC721Enumerable, ERC721Royalty, ERC721)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId) || ERC721Enumerable.supportsInterface(_interfaceId)
            || ERC721Royalty.supportsInterface(_interfaceId) || ERC721URIStorage.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _update(address _to, uint256 _tokenId, address _auth)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
        returns (address)
    {
        return super._update(_to, _tokenId, _auth);
    }

    function _increaseBalance(address _account, uint128 _amount)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._increaseBalance(_account, _amount);
    }
}
