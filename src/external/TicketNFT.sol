// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @notice Thrown when the withdraw call fails
error WithdrawFailed();

/// @notice Emitted when the base URI is updated
/// @dev This event is emitted when the base URI for the NFT collection is changed
/// @param newBaseURI The new base URI set for the NFT collection
event BaseURIUpdated(string newBaseURI);

/// @notice Emitted when the metadata of the NFT collection is updated
/// @dev This event is emitted when the name or symbol of the NFT collection is changed
/// @param newName The new name of the NFT collection
/// @param newSymbol The new symbol of the NFT collection
event MetadataUpdated(string newName, string newSymbol);

/// @title TicketNFT
/// @notice NFT contract for event ticketing with royalty support, pausability, and metadata management
/// @dev Inherits from OpenZeppelin and Solady base contracts to combine ERC721, royalties, and pausability
contract TicketNFT is ERC721Enumerable, ERC721Royalty, Ownable, Pausable {
    string private _name;
    string private _symbol;
    string private _uri;

    /// @notice Constructor to initialize the NFT collection with name, symbol, and royalty receiver
    /// @param _owner The initial owner of the contract
    /// @param __name The name of the TicketNFT
    /// @param __symbol The symbol of the TicketNFT
    constructor(address _owner, string memory __name, string memory __symbol, string memory __uri)
        payable
        ERC721(__name, __symbol)
    {
        _initializeOwner(_owner);
        _setDefaultRoyalty(_owner, 500); // Set default royalty to 5%
        _name = __name;
        _symbol = __symbol;
        _uri = __uri;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Returns the name of the NFT collection
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the NFT collection
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the metadata URI for the TicketNFT
    /// @dev This function returns the base URI set for the NFT collection, which is used
    /// @param _tokenId The ID of the token
    /// @return The URI pointing to the token's metadata
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Ensure the token exists and is owned by the caller
        return _baseURI(); // Return the base URI set for the NFT collection
    }

    /// @notice Returns the metadata URI for the TicketNFT
    /// @dev This function returns the base URI set for the NFT collection, which is used
    /// @return The URI pointing to the collection's metadata
    function baseURI() public view returns (string memory) {
        return _baseURI(); // Return the base URI set for the NFT collection
    }

    /// @notice Check if a given interface is supported by this contract
    /// @param _interfaceId The interface identifier to check
    /// @return True if the interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Royalty, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId) || ERC721Royalty.supportsInterface(_interfaceId);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function updateMetadata(string calldata __name, string calldata __symbol) external payable onlyOwner {
        _name = __name; // Update the name of the NFT collection
        _symbol = __symbol; // Update the symbol of the NFT collection
        emit MetadataUpdated(__name, __symbol);
    }

    /// @notice Allows the owner to set the base URI
    /// @param __baseURI The URI to assign
    function setBaseURI(string calldata __baseURI) external payable onlyOwner {
        _uri = __baseURI;
        emit BaseURIUpdated(__baseURI);
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

    /// @dev Internal override for base URI, returns the set base URI
    /// @notice This function is used to retrieve the base URI for the NFT collection
    /// @return The base URI for the NFT collection
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

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

// t>6cXt+Y=JccMMiM~'i:tJcNXi'.'~''~:::::::::::::~:~~~~~~~~~~~~~~~~~~~~'~''
// +>+>+>i+: '+MM5+      'YDc:.~~~~~::::;;:;;::::~:::::~~~~'.          .'~~
// iiiiiiii+~.>KMMH+':!+=JD6=''~~~~:::::::::::::::~:~:~~'.                '
// ccci===i=; .iMMMMMMMMMMQc: ~;!:::::::::::::::;:::::~'   '>=+;!>++>!:
// ijcii==++>~ ~jMMMMMMMNSi~ .;!;:::;;;;:;;;;:;;;;;::~'  '>j5YYY565YYYJj+~
// cjjci===++!~ .;+icccc+~   ~;;:;;;;!!!!!;!;!!;;;:::'. ~=Y66665Y5665YY55j;
// cJttii=+>>>>;~.         '::;;!!!;;!!!!!!;;;;;;;;:~. '+Y665Yt>  :=J55666c
// cJJttcc=>>!!!;;:~''~::;;;;;:;;;;!;!!!!!!!!;;!;;;:~. :i5S556t!   '=Y566St
// =jYYJJti=+!!;;::;!!>!!;;::;;;;;:;;;;;;;;;;;;;;;;:~  :=5S55Yj>  .+t55SSt;
// =jY6S6Ytci>;;;::::~~~~:::;:::::::;;!:;;;;:;;;;;;::'  !tXS666Jtt5SDDSJ+
// +itSNQSYji+>;;;;;;::::::::~::;;;;;;;!!;!;!;;;;!;;;:'  :=JSDKQKKQQ5j!.
// !+=jDMQtji>;;;;:::;:::::~:~~::::::;;;;;;;;!!!;;!;:::'    .:!++>;~     .~
// !;;;=MMMNti+>!;;;:;;::~:~~~~~~~::::::::;;;;;!!!!;;!;;::'            ':::
// >;;~':iMMMM5j=>;:::::::::~~~~~~~:~~:::::::;;;;;;;;;;;:;:::~;!!>>>;;:::::
// +!;:~.  ~MMMM6Jc=>;;:;;:::::::::::~~~::::::::;;;:;::;:::::::::~:::::::::
// c+!;:~~  ;MMMMMSi+;;:;;;;;;;:::::::::::::;;;:::::;;;::;;::::::::::::::::
// Yc+!;::~   iMMMMMMMc!:;;!!;;!;;;;;:;:::::::::;;;;::;::;:;:::::::::::::::
// QJc+!::~''   >MMMMMMMKYc++==+>!!;;;;;;;;::::::::;;;:;;:;;:::::::::::::::
// MM6j=!::~''.     '=tXNHSYJJYt==+!!;!;:::::::::::::;:;;;;:;::::::::::::::
// MMMXc=!:~~''''          ':!+===>+>!!;::::::~::::~::::::::::::::::;::::~:
// MMMMMt>::~~~~''.    .~:'    ':;;!!;;!!;;;::::~~~~~~~~~~:~::::::::~~:::::
// MMMMMMJ!:::~~~''.   .~;!>>:.    :;:::~:;;;;;;;:::::~~''''''~~~~~~:~~::::
// MMMMMMMc::~~''''..     .':!!;'''                            '''''~~~~~::
// MMMMMMMM>~~::~~''...         .::;!!!;:.                    .'''~~:~::;;;
// MMMMMMMMM:~~~~~~''''....                              ...''''~~::::;::;:
// MMMMMMMMMN~~~~'''''''''....  .               . .    ..'''''~~::::;:::;::
// MMMMMMMMMMX'~::~~~~'~~~~'''''''..........'''''.....'~~~:::;;;;;;;;;:;;;;
// MMMMMMMMMMMN!;::~~~'''~~~~''~~~~~'''''''''''..'''~~::;;;;;:;;;;;:;;;:;;;
/////////////////////////////THANKS FOR COMING/////////////////////////////
