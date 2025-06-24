// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";
import {LibTicketStorage, TicketStorage} from "@host-it/libraries/LibTicketStorage.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";
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
    InvalidFeeConfig,
    FeeMustBeGreaterThanZero,
    TicketUseHasCommenced,
    InvalidTicketId,
    TicketPurchaseNotStarted,
    TicketPurchasePeriodHasEnded,
    TicketUsePeriodNotStarted,
    TicketUsePeriodHasEnded,
    TicketUseAndRefundPeriodHasNotEnded,
    TicketAlreadyPurchased,
    AllTicketsSoldOut,
    FeeNotEnabledForThisPaymentMethod,
    InsufficientETHSent,
    InsufficientBalance,
    InsufficientAllowance,
    PaymentFailed,
    NotTicketOwner
} from "@host-it/libraries/errors/TicketErrors.sol";

library LibTicketFactory {
    using LibTicketFactory for *;
    using {LibOwnableRoles._grantRoles} for address;
    using {LibOwnableRoles._checkRoles} for uint256;
    using SafeERC20 for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                                   ROLES
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode("host.it.ticket", "host.it.main.ticket.admin"))
    bytes32 private constant HOST_IT_MAIN_TICKET_ADMIN =
        0x4f62ba22fe32d34f7d04ed4df946da35e566bd8d2c18d248ee027926debe6800;
    // keccak256(abi.encode("host.it.ticket", "host.it.ticket.admin"))
    bytes32 private constant HOST_IT_TICKET_ADMIN = 0xa1905dd34f004fe1d2938a45a40621b381f6ace7cbdf0cdb3514edf0f9c07dcc;

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

    function _getTicketCheckIns(uint256 _ticketId, address _attendee) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketCheckIns[_ticketId][_attendee];
    }

    function _getTicketCheckInsByDay(uint256 _ticketId, uint16 _day, address _attendee) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketCheckInsByDay[_ticketId][_day][_attendee];
    }

    function _getTicketFeeEnabled(uint256 _ticketId, FeeType _feeType) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketFeeEnabled[_ticketId][_feeType];
    }

    function _getTicketFee(uint256 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().ticketFee[_ticketId][_feeType];
    }

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return LibTicketStorage._ticketStorage().feeTokenAddress[_feeType][block.chainid];
    }

    function _getTicketBalance(uint256 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().ticketBalanceByChainId[_ticketId][_feeType][block.chainid];
    }

    function _getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().hostItBalanceByChainId[_feeType][block.chainid];
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

    function _setFeeTokenAddresses(FeeType[] calldata _feeTypes, address[] calldata _tokenAddresses) internal {
        LibOwnableRoles._checkOwner();
        require(_feeTypes.length == _tokenAddresses.length && _feeTypes.length > 0, InvalidFeeConfig());
        for (uint256 i; i < _feeTypes.length;) {
            _setFeeTokenAddress(_feeTypes[i], _tokenAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

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
        require(_startTime > block.timestamp, StartTimeMustBeInTheFuture());
        require(_endTime > _startTime + 1 days, EndTimeMustBeAfterStartTime());
        require(_purchaseStartTime < _startTime, PurchaseStartTimeMustBeBeforeStartTime());
        require(_maxTickets > 0, MaxTicketsMustBeGreaterThanZero());

        ticketData.updatedAt = block.timestamp;
        ticketData.startTime = _startTime;
        ticketData.endTime = _endTime;
        ticketData.purchaseStartTime = _purchaseStartTime;
        ticketData.maxTickets = _maxTickets;

        // Persist the updated ticketData back to storage
        LibTicketStorage._ticketStorage().tickets[_ticketId] = ticketData;

        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        if (bytes(_name).length > 0 || bytes(_symbol).length > 0) ticketNFT.updateMetadata(_name, _symbol);
        if (bytes(_uri).length > 0) ticketNFT.setBaseURI(_uri);

        emit TicketUpdated(_ticketId, ticketData);
    }

    function _updateTicketFee(uint256 _ticketId, bool _isFree, FeeType[] calldata _feeTypes, uint256[] calldata _fees)
        internal
    {
        require(_ticketId._ticketExists(), InvalidTicketId());
        _ticketId._generateMainTicketAdminRole()._checkRoles();

        TicketStorage storage $ = LibTicketStorage._ticketStorage();
        TicketData memory ticketData = _ticketId._getTicketData();

        ticketData.isFree = _isFree;

        if (!_isFree) {
            uint256 feeTypesLength = _feeTypes.length;
            require(feeTypesLength == _fees.length && feeTypesLength > 0, InvalidFeeConfig());
            for (uint256 i; i < feeTypesLength;) {
                FeeType feeType = _feeTypes[i];
                require(!_ticketId._getTicketFeeEnabled(feeType), FeeAlreadySet());
                uint256 fee = _fees[i];
                require(fee > 0, FeeMustBeGreaterThanZero());
                $.ticketFeeEnabled[_ticketId][feeType] = true;
                $.ticketFee[_ticketId][feeType] = fee;
                unchecked {
                    ++i;
                }
            }
        }

        // Persist the updated ticketData back to storage
        $.tickets[_ticketId] = ticketData;

        emit TicketUpdated(_ticketId, ticketData);
    }

    function _purchaseTicket(uint256 _ticketId, FeeType _feeType) internal returns (uint256 tokenId_) {
        require(_ticketId._ticketExists(), InvalidTicketId());
        TicketStorage storage $ = LibTicketStorage._ticketStorage();

        TicketData memory ticketData = _ticketId._getTicketData();

        require(block.timestamp > ticketData.purchaseStartTime, TicketPurchaseNotStarted());
        require(ticketData.endTime > block.timestamp, TicketPurchasePeriodHasEnded());
        require(ticketData.soldTickets < ticketData.maxTickets, AllTicketsSoldOut());

        address ticketBuyer = msg.sender;
        address ticketAddress = ticketData.ticketNFTAddress;
        require(TicketNFT(ticketAddress).balanceOf(ticketBuyer) == 0, TicketAlreadyPurchased());

        if (!ticketData.isFree) {
            require(_ticketId._getTicketFeeEnabled(_feeType), FeeNotEnabledForThisPaymentMethod());
            uint256 fee = _ticketId._getTicketFee(_feeType);
            // Calculate HostIt's fee
            uint256 hostItFee = _calculateHostItFee(fee);
            uint256 totalFee = fee + hostItFee;

            if (_feeType == FeeType.ETH) {
                require(msg.value >= totalFee, InsufficientETHSent());
                (bool success,) = address(payable(address(this))).call{value: totalFee}("");
                require(success, PaymentFailed(_feeType));
            } else {
                // Handle ERC20 payment
                address feeTokenAddress = _feeType._getFeeTokenAddress();
                require(IERC20(feeTokenAddress).balanceOf(ticketBuyer) >= totalFee, InsufficientBalance(_feeType));
                require(
                    IERC20(feeTokenAddress).allowance(ticketBuyer, address(this)) >= totalFee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(feeTokenAddress).trySafeTransferFrom(ticketBuyer, address(this), totalFee),
                    PaymentFailed(_feeType)
                );
            }
            // Update the ticket balance for the chain
            $.ticketBalanceByChainId[_ticketId][_feeType][block.chainid] += fee;
            // Update the HostIt fee balance for the chain
            $.hostItBalanceByChainId[_feeType][block.chainid] += hostItFee;
            emit TicketPurchased(_ticketId, ticketBuyer, _feeType, fee);
        }
        tokenId_ = _mintTicket(ticketAddress, ticketBuyer);
        $.tickets[_ticketId].soldTickets = tokenId_;
        emit TicketMinted(ticketAddress, ticketBuyer, tokenId_);
    }

    function _checkInTicket(uint256 _ticketId, address _ticketOwner, uint256 _tokenId) internal {
        require(_ticketId._ticketExists(), InvalidTicketId());
        _ticketId._generateTicketAdminRole()._checkRoles();

        TicketStorage storage $ = LibTicketStorage._ticketStorage();

        TicketData memory ticketData = _ticketId._getTicketData();
        uint256 blockTimestamp = block.timestamp;
        require(blockTimestamp >= ticketData.startTime, TicketUsePeriodNotStarted());
        require(blockTimestamp <= ticketData.endTime, TicketUsePeriodHasEnded());
        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        require(ticketNFT.ownerOf(_tokenId) == _ticketOwner, NotTicketOwner(_tokenId));

        // Pause the NFT contract if it is not already paused
        // This is a security measure to ensure that the ticket cannot be transferred while the check-in
        // is being processed, which could lead to inconsistencies in attendance tracking
        if (!ticketNFT.paused()) ticketNFT.pause();

        // Mark attendance
        if (!_ticketId._getTicketCheckIns(_ticketOwner)) $.ticketCheckIns[_ticketId][_ticketOwner] = true;

        // Mark attendance by day
        uint16 day = uint16((blockTimestamp - ticketData.startTime) / 1 days);
        if (!_ticketId._getTicketCheckInsByDay(day, _ticketOwner)) {
            $.ticketCheckInsByDay[_ticketId][day][_ticketOwner] = true;
        }

        emit TicketCheckIn(_ticketId, _ticketOwner, blockTimestamp);
    }

    function _withdrawTicketBalance(uint256 _ticketId, FeeType _feeType, address _to) internal {
        _ticketId._generateMainTicketAdminRole()._checkRoles();

        TicketData memory ticketData = _ticketId._getTicketData();
        // 3 days refund period after the ticket end time
        require(ticketData.endTime + 3 days < block.timestamp, TicketUseAndRefundPeriodHasNotEnded());
        uint256 balance = _ticketId._getTicketBalance(_feeType);
        require(balance > 0, InsufficientBalance(_feeType));
        LibTicketStorage._ticketStorage().ticketBalanceByChainId[_ticketId][_feeType][block.chainid] = 0;

        if (_feeType == FeeType.ETH) {
            (bool success,) = address(payable(_to)).call{value: balance}("");
            require(success, PaymentFailed(_feeType));
        } else {
            IERC20(_feeType._getFeeTokenAddress()).safeTransfer(_to, balance);
        }

        // Unpause the NFT contract after withdrawal
        TicketNFT(ticketData.ticketNFTAddress).unpause();
        emit TicketBalanceWithdrawn(_ticketId, _feeType, balance, _to);
    }

    function _withdrawHostItBalance(FeeType _feeType, address _to) internal {
        LibOwnableRoles._checkOwner();

        TicketStorage storage $ = LibTicketStorage._ticketStorage();
        uint256 balance = _feeType._getHostItBalance();
        require(balance > 0, InsufficientBalance(_feeType));
        $.hostItBalanceByChainId[_feeType][block.chainid] = 0;

        if (_feeType == FeeType.ETH) {
            (bool success,) = address(payable(_to)).call{value: balance}("");
            require(success, PaymentFailed(_feeType));
        } else {
            IERC20(_feeType._getFeeTokenAddress()).safeTransfer(_to, balance);
        }

        emit TicketBalanceWithdrawn(0, _feeType, balance, _to); // Ticket ID is 0 for HostIt balance withdrawals
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _mintTicket(address _ticketNFT, address _to) private returns (uint256 tokenId_) {
        tokenId_ = TicketNFT(_ticketNFT).safeMint(_to);
    }

    function _calculateHostItFee(uint256 _fee) private pure returns (uint256 hostItFee_) {
        hostItFee_ = (_fee * HOST_IT_FEE_NUMERATOR) / HOST_IT_FEE_DENOMINATOR;
    }

    function _setFeeTokenAddress(FeeType _feeType, address _tokenAddress) private {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        LibTicketStorage._ticketStorage().feeTokenAddress[_feeType][block.chainid] = _tokenAddress;
    }
}
