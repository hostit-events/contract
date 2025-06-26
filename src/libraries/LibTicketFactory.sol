// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";
import {LibTicketStorage, TicketStorage} from "@host-it/libraries/LibTicketStorage.sol";
import {LibTicketMarketplace} from "@host-it/libraries/LibTicketMarketplace.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";
import {HOST_IT_MAIN_TICKET_ADMIN, HOST_IT_TICKET_ADMIN} from "@host-it/libraries/roles/TicketRoles.sol";
import {
    HOST_IT_TICKET,
    HOST_IT_FEE_NUMERATOR,
    HOST_IT_FEE_DENOMINATOR
} from "@host-it/libraries/constants/TicketConstants.sol";
import {
    TicketCreated,
    TicketUpdated,
    TicketPurchased,
    TicketMinted,
    TicketCheckIn,
    TicketBalanceWithdrawn
} from "@host-it/libraries/logs/TicketLogs.sol";
import {
    InvalidTicketAmount,
    FeeAlreadySet,
    NameCannotBeEmpty,
    SymbolCannotBeEmpty,
    URICannotBeEmpty,
    StartTimeMustBeInTheFuture,
    EndTimeMustBeAfterStartTime,
    PurchaseStartTimeMustBeBeforeStartTime,
    MaxTicketsMustBeGreaterThanZero,
    MaxTicketsMustBeLessThanTicketsSold,
    InvalidFeeConfig,
    FeeMustBeGreaterThanZero,
    TicketUseHasCommenced,
    InvalidTicketId,
    NotTicketOwner,
    TicketUsePeriodNotStarted,
    TicketUsePeriodHasEnded
} from "@host-it/libraries/errors/TicketErrors.sol";

library LibTicketFactory {
    using LibTicketFactory for *;
    using {LibOwnableRoles._grantRoles} for address;
    using {LibOwnableRoles._checkRoles} for uint256;
    using {LibTicketMarketplace._getFeeTokenAddress} for FeeType;
    using {LibTicketMarketplace._getTicketFeeEnabled} for uint256;
    using LibTicketStorage for uint256;
    using SafeERC20 for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getTicketCount() internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().ticketCount;
    }

    function _ticketExists(uint256 _ticketId) internal view returns (bool) {
        return _ticketId > 0 && _ticketId <= _getTicketCount();
    }

    function _getTicketData(uint256 _ticketId) internal view returns (TicketData memory ticketData_) {
        require(_ticketExists(_ticketId), InvalidTicketId());
        ticketData_ = LibTicketStorage._ticketStorage().tickets[_ticketId];
    }

    function _getTicketMetadata(uint256 _ticketId) internal view returns (TicketMetadata memory ticketMetadata_) {
        require(_ticketExists(_ticketId), InvalidTicketId());

        TicketData memory ticketData = _ticketId._getTicketData();
        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        ticketMetadata_ = TicketMetadata({
            id: ticketData.id,
            ticketAdmin: ticketData.ticketAdmin,
            ticketNFTAddress: ticketData.ticketNFTAddress,
            name: ticketNFT.name(),
            symbol: ticketNFT.symbol(),
            uri: ticketNFT.baseURI(),
            isFree: ticketData.isFree,
            isUpdated: ticketData.isUpdated,
            createdAt: ticketData.createdAt,
            updatedAt: ticketData.updatedAt,
            startTime: ticketData.startTime,
            endTime: ticketData.endTime,
            purchaseStartTime: ticketData.purchaseStartTime,
            maxTickets: ticketData.maxTickets,
            soldTickets: ticketData.soldTickets
        });
    }

    function _getAllTicketMetadata() internal view returns (TicketMetadata[] memory ticketMetadatas_) {
        uint256 count = _getTicketCount();
        ticketMetadatas_ = new TicketMetadata[](count);
        for (uint256 i = 1; i <= count;) {
            // Ticket IDs start from 1
            ticketMetadatas_[i - 1] = i._getTicketMetadata();
            unchecked {
                ++i;
            }
        }
    }

    function _getAllAdminTicketIds(address _organizer) internal view returns (uint256[] memory adminTicketIds_) {
        adminTicketIds_ = LibTicketStorage._ticketStorage().allAdminTickets[_organizer];
    }

    function _getAllAdminTicketMetadata(address _organizer)
        internal
        view
        returns (TicketMetadata[] memory ticketMetadatas_)
    {
        uint256[] memory adminTicketIds = _organizer._getAllAdminTicketIds();
        uint256 adminTicketCount = adminTicketIds.length;
        ticketMetadatas_ = new TicketMetadata[](adminTicketCount);
        for (uint256 i; i < adminTicketCount;) {
            ticketMetadatas_[i] = adminTicketIds[i]._getTicketMetadata();
            unchecked {
                ++i;
            }
        }
    }

    // review
    function _getLastAmountOfTicketMetadata(uint256 _amount)
        internal
        view
        returns (TicketMetadata[] memory ticketMetadatas_)
    {
        uint256 count = _getTicketCount();
        require(_amount > 0 && _amount <= count, InvalidTicketAmount());
        ticketMetadatas_ = new TicketMetadata[](_amount);
        uint256 range = count - _amount;
        for (uint256 i = range; i < count;) {
            ticketMetadatas_[i - range] = _getTicketMetadata(i + 1); // Ticket IDs start from 1
            unchecked {
                ++i;
            }
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getHostItTicketHash() internal pure returns (bytes32) {
        return HOST_IT_TICKET;
    }

    function _generateTicketHash(uint256 _ticketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(_getHostItTicketHash(), _ticketId));
    }

    function _generateMainTicketAdminRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(HOST_IT_MAIN_TICKET_ADMIN, _ticketId)));
    }

    function _generateTicketAdminRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(HOST_IT_TICKET_ADMIN, _ticketId)));
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _createTicket(
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseStartTime,
        uint256 _maxTickets,
        bool _isFree,
        FeeType[] calldata _feeTypes,
        uint256[] calldata _fees
    ) internal returns (address, uint256) {
        require(bytes(_name).length > 0, NameCannotBeEmpty());
        require(bytes(_symbol).length > 0, SymbolCannotBeEmpty());
        require(bytes(_uri).length > 0, URICannotBeEmpty());
        require(_startTime > block.timestamp, StartTimeMustBeInTheFuture());
        require(_endTime > _startTime + 1 days, EndTimeMustBeAfterStartTime());
        require(_purchaseStartTime < _startTime, PurchaseStartTimeMustBeBeforeStartTime());
        require(_maxTickets > 0, MaxTicketsMustBeGreaterThanZero());
        uint256 feeTypesLength = _feeTypes.length;
        if (!_isFree) require(feeTypesLength == _fees.length && feeTypesLength > 0, InvalidFeeConfig());

        TicketStorage storage $ = LibTicketStorage._ticketStorage();
        uint256 ticketId = ++$.ticketCount;
        address ticketAdmin = msg.sender;
        ticketAdmin._grantRoles(ticketId._generateMainTicketAdminRole());
        ticketAdmin._grantRoles(ticketId._generateTicketAdminRole());

        TicketNFT ticketNFT = new TicketNFT{salt: ticketId._generateTicketHash()}(address(this), _name, _symbol, _uri);

        TicketData memory ticketData = TicketData({
            id: ticketId,
            ticketAdmin: ticketAdmin,
            ticketNFTAddress: address(ticketNFT),
            isFree: _isFree,
            isUpdated: false,
            createdAt: block.timestamp,
            updatedAt: 0,
            startTime: _startTime,
            endTime: _endTime,
            purchaseStartTime: _purchaseStartTime,
            maxTickets: _maxTickets,
            soldTickets: 0
        });

        $.tickets[ticketId] = ticketData;

        $.allAdminTickets[ticketAdmin].push(ticketId);

        if (!_isFree) {
            for (uint256 i; i < feeTypesLength;) {
                FeeType feeType = _feeTypes[i];
                require(!$.ticketFeeEnabled[ticketId][feeType], FeeAlreadySet());
                uint256 fee = _fees[i];
                require(fee > 0, FeeMustBeGreaterThanZero());
                $.ticketFeeEnabled[ticketId][feeType] = true;
                $.ticketFee[ticketId][feeType] = fee;
                unchecked {
                    ++i;
                }
            }
        }

        emit TicketCreated(ticketId, ticketData, ticketAdmin);

        return (address(ticketNFT), ticketId);
    }

    function _updateTicketMetadata(
        uint256 _ticketId,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseStartTime,
        uint256 _maxTickets
    ) internal {
        require(_ticketId._ticketExists(), InvalidTicketId());
        _ticketId._generateMainTicketAdminRole()._checkRoles();
        TicketData memory ticketData = _ticketId._getTicketData();

        require(ticketData.startTime > block.timestamp, TicketUseHasCommenced());
        if (_startTime > 0) {
            require(_startTime > block.timestamp, StartTimeMustBeInTheFuture());
            ticketData.startTime = _startTime;
            ticketData.isUpdated = true; // Mark the ticket as updated if the start time is updated
        }
        if (_endTime > 0) {
            require(_endTime > _startTime + 1 days, EndTimeMustBeAfterStartTime());
            ticketData.endTime = _endTime;
        }
        if (_purchaseStartTime > 0) {
            require(_purchaseStartTime < _startTime, PurchaseStartTimeMustBeBeforeStartTime());
            ticketData.purchaseStartTime = _purchaseStartTime;
        }
        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        if (_maxTickets > 0) {
            require(_maxTickets >= ticketNFT.totalSupply(), MaxTicketsMustBeLessThanTicketsSold());
            ticketData.maxTickets = _maxTickets;
        }

        ticketData.updatedAt = block.timestamp;

        LibTicketStorage._ticketStorage().tickets[_ticketId] = ticketData;

        if (bytes(_name).length > 0) ticketNFT.updateName(_name);
        if (bytes(_symbol).length > 0) ticketNFT.updateSymbol(_symbol);
        if (bytes(_uri).length > 0) ticketNFT.setBaseURI(_uri);

        emit TicketUpdated(_ticketId, ticketData);
    }
}
