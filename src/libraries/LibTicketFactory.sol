// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {TicketData, FeeType} from "@host-it/libraries/constants/Types.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//*//////////////////////////////////////////////////////////////////////////
//                           TICKET FACTORY ERRORS
//////////////////////////////////////////////////////////////////////////*//

error InvalidTicketAmount();
error FeeAlreadySet();
error NameCannotBeEmpty();
error SymbolCannotBeEmpty();
error URICannotBeEmpty();
error StartTimeMustBeInTheFuture();
error EndTimeMustBeAfterStartTime();
error PurchaseStartTimeMustBeInTheFutureBeforeStartTime();
error MaxTicketsMustBeGreaterThanZero();
error InvalidFeeConfig();
error FeeMustBeGreaterThanZero();
error TicketUseHasCommenced();
error InvalidTicketId();
error TicketPurchaseNotStarted();
error TicketPurchasePeriodHasEnded();
error AllTicketsSoldOut();
error FeeNotEnabledForThisPaymentMethod();
error InsufficientETHSent();
error InsufficientAllowance(FeeType feeType);
error PaymentFailed(FeeType feeType);
error UnsupportedFee(FeeType feeType);

//*//////////////////////////////////////////////////////////////////////////
//                            TICKET FACET EVENTS
//////////////////////////////////////////////////////////////////////////*//

event TicketCreated(uint256 indexed ticketId);

event TicketUpdated(uint256 indexed ticketId);

event TicketPurchased(uint256 indexed ticketId, FeeType indexed feeType);

//*//////////////////////////////////////////////////////////////////////////
//                           TICKET STORAGE STRUCT
//////////////////////////////////////////////////////////////////////////*//

/// @custom:storage-location erc7201:host.it.ticket.factory.storage
struct TicketStorage {
    uint256 ticketCount; // Total number of tickets created
    mapping(uint256 => TicketData) tickets; // Mapping from ticketId to ticket data
    mapping(address => uint256[]) allAdminTickets; // Mapping from organizer address to all ticket IDs they administer
    mapping(uint256 => mapping(address => bool)) ticketAttendance; // Mapping from ticketId to attendance by attendee address
    mapping(uint256 => mapping(uint8 => mapping(address => bool))) ticketAttendanceByDay; // Mapping from ticketId and day to attendance by attendee address
    mapping(uint256 => mapping(FeeType => bool)) ticketFeeEnabled; // Mapping from ticketId to ticket fee data
    mapping(uint256 => mapping(FeeType => uint256)) ticketFee; // Mapping from ticketId to ticket fee amount
    mapping(FeeType => address) feeTokenAddress; // Mapping from FeeType to token address
}

library LibTicketFactory {
    using SafeERC20 for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                               TICKET STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode(uint256(keccak256("host.it.ticket.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TICKET_STORAGE_POSITION =
        0x610b7ed6689c503e651500bb8179583591f93afc835ec7dbed5872619168c100;

    /// @dev Get the ticket storage.
    function _ticketStorage() internal pure returns (TicketStorage storage $) {
        bytes32 position = TICKET_STORAGE_POSITION;
        assembly {
            $.slot := position
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 CONSTANTS
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256("host.it.ticket")
    bytes32 private constant HOST_IT_TICKET = 0x2d39ca42f70b8fb1aad3b6b712ac8513c31a927ee8719e6858dd209fe8ec8293;
    // keccak256("host.it.main.ticket.admin")
    bytes32 private constant MAIN_TICKET_ADMIN = 0x6a359c448f32c347d7788ed2db1d4048bae93c3383047a3950c8c540e8b8806f;
    // keccak256("host.it.ticket.admin")
    bytes32 private constant TICKET_ADMIN = 0x66d6cfcd439cf68144fc7493914c7b690fcf4a642ab874f3276cb229bd8bcef2;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getTicketCount() internal view returns (uint256) {
        return _ticketStorage().ticketCount;
    }

    function _getTicketData(uint256 _ticketId) internal view returns (TicketData memory) {
        return _ticketStorage().tickets[_ticketId];
    }

    function _getAllTicketData() internal view returns (TicketData[] memory tickets) {
        uint256 count = _getTicketCount();
        tickets = new TicketData[](count);
        for (uint256 i; i < count;) {
            tickets[i] = _getTicketData(i + 1); // Ticket IDs start from 1
            unchecked {
                ++i;
            }
        }
    }

    // review
    function _getLastAmountOfTicketData(uint256 _amount) internal view returns (TicketData[] memory tickets) {
        uint256 count = _getTicketCount();
        require(_amount > 0 && _amount <= count, InvalidTicketAmount());
        tickets = new TicketData[](_amount);
        uint256 range = count - _amount;
        for (uint256 i = range; i < count;) {
            tickets[i - range] = _getTicketData(i + 1); // Ticket IDs start from 1
            unchecked {
                ++i;
            }
        }
    }

    function _getAllAdminTickets(address _organizer) internal view returns (TicketData[] memory tickets) {
        uint256[] memory adminTicketIds = _ticketStorage().allAdminTickets[_organizer];
        uint256 adminTicketCount = adminTicketIds.length;
        tickets = new TicketData[](adminTicketCount);
        for (uint256 i; i < adminTicketCount;) {
            tickets[i] = _getTicketData(adminTicketIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _getTicketAttendance(uint256 _ticketId, address _attendee) internal view returns (bool) {
        return _ticketStorage().ticketAttendance[_ticketId][_attendee];
    }

    function _getTicketAttendanceByDay(uint256 _ticketId, uint8 _day, address _attendee) internal view returns (bool) {
        return _ticketStorage().ticketAttendanceByDay[_ticketId][_day][_attendee];
    }

    function _getTicketFeeEnabled(uint256 _ticketId, FeeType _feeType) internal view returns (bool) {
        return _ticketStorage().ticketFeeEnabled[_ticketId][_feeType];
    }

    function _getTicketFee(uint256 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return _ticketStorage().ticketFee[_ticketId][_feeType];
    }

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return _ticketStorage().feeTokenAddress[_feeType];
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getHostItTicketHash() internal pure returns (bytes32) {
        return HOST_IT_TICKET;
    }

    function _generateTicketHash(uint256 _ticketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(_getHostItTicketHash(), _ticketId));
    }

    function _generateMainTicketAdminRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_getHostItTicketHash(), MAIN_TICKET_ADMIN, _ticketId)));
    }

    function _generateTicketAdminRole(uint256 _ticketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_getHostItTicketHash(), TICKET_ADMIN, _ticketId)));
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
        require(_startTime > block.timestamp + 1 hours, StartTimeMustBeInTheFuture());
        require(_endTime > _startTime + 1 days, EndTimeMustBeAfterStartTime());
        require(
            _purchaseStartTime >= block.timestamp && _purchaseStartTime < _startTime,
            PurchaseStartTimeMustBeInTheFutureBeforeStartTime()
        );
        require(_maxTickets > 0, MaxTicketsMustBeGreaterThanZero());
        if (!_isFree) require(_feeTypes.length == _fees.length && _feeTypes.length > 0, InvalidFeeConfig());

        TicketStorage storage $ = _ticketStorage();
        uint256 ticketId = ++$.ticketCount;
        address ticketAdmin = msg.sender;
        LibOwnableRoles._grantRoles(ticketAdmin, _generateMainTicketAdminRole(ticketId));
        LibOwnableRoles._grantRoles(ticketAdmin, _generateTicketAdminRole(ticketId));

        TicketNFT ticketNFT = new TicketNFT{salt: _generateTicketHash(ticketId)}(address(this), _name, _symbol, _uri);

        $.tickets[ticketId] = TicketData({
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

        $.allAdminTickets[ticketAdmin].push(ticketId);

        if (!_isFree) {
            uint256 feeTypesLength = _feeTypes.length;
            for (uint256 i; i < feeTypesLength;) {
                FeeType feeType = _feeTypes[i];
                if ($.ticketFeeEnabled[ticketId][feeType]) revert FeeAlreadySet();
                uint256 fee = _fees[i];
                require(fee > 0, FeeMustBeGreaterThanZero());
                $.ticketFeeEnabled[ticketId][feeType] = true;
                $.ticketFee[ticketId][feeType] = fee;
                unchecked {
                    ++i;
                }
            }
        }

        emit TicketCreated(ticketId);

        return (address(ticketNFT), ticketId);
    }

    function _updateTicket(
        uint256 _ticketId,
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
    ) internal {
        LibOwnableRoles._checkRoles(_generateMainTicketAdminRole(_ticketId));

        TicketStorage storage $ = _ticketStorage();
        TicketData storage ticketData = $.tickets[_ticketId];

        require(bytes(_name).length > 0, NameCannotBeEmpty());
        require(bytes(_symbol).length > 0, SymbolCannotBeEmpty());
        require(bytes(_uri).length > 0, URICannotBeEmpty());
        require(ticketData.startTime > block.timestamp, TicketUseHasCommenced());
        require(_startTime > block.timestamp + 1 hours, StartTimeMustBeInTheFuture());
        require(_endTime > _startTime + 1 days, EndTimeMustBeAfterStartTime());
        require(_purchaseStartTime > block.timestamp, PurchaseStartTimeMustBeInTheFutureBeforeStartTime());
        require(_maxTickets > 0, MaxTicketsMustBeGreaterThanZero());

        ticketData.updatedAt = block.timestamp;
        ticketData.startTime = _startTime;
        ticketData.endTime = _endTime;
        ticketData.purchaseStartTime = _purchaseStartTime;
        ticketData.maxTickets = _maxTickets;
        ticketData.isFree = _isFree;

        if (!_isFree) {
            uint256 feeTypesLength = _feeTypes.length;
            require(feeTypesLength == _fees.length && feeTypesLength > 0, InvalidFeeConfig());
            for (uint256 i; i < feeTypesLength;) {
                FeeType feeType = _feeTypes[i];
                if ($.ticketFeeEnabled[_ticketId][feeType]) revert FeeAlreadySet();
                uint256 fee = _fees[i];
                require(fee > 0, FeeMustBeGreaterThanZero());
                $.ticketFeeEnabled[_ticketId][feeType] = true;
                $.ticketFee[_ticketId][feeType] = fee;
                unchecked {
                    ++i;
                }
            }
        }

        TicketNFT ticketNFT = TicketNFT(ticketData.ticketNFTAddress);
        ticketNFT.updateMetadata(_name, _symbol);
        ticketNFT.setBaseURI(_uri);

        emit TicketUpdated(_ticketId);
    }

    function _purchaseTicket(uint256 _ticketId, FeeType _feeType) internal {
        TicketStorage storage $ = _ticketStorage();

        require(_ticketId > 0 && _ticketId <= $.ticketCount, InvalidTicketId());
        TicketData storage ticketData = $.tickets[_ticketId];

        require(ticketData.purchaseStartTime <= block.timestamp, TicketPurchaseNotStarted());
        require(ticketData.endTime > block.timestamp, TicketPurchasePeriodHasEnded());
        require(ticketData.soldTickets < ticketData.maxTickets, AllTicketsSoldOut());

        if (ticketData.isFree) {
            ticketData.soldTickets = _mintTicket(ticketData.ticketNFTAddress, msg.sender);
        } else {
            require($.ticketFeeEnabled[_ticketId][_feeType], FeeNotEnabledForThisPaymentMethod());
            uint256 fee = $.ticketFee[_ticketId][_feeType];
            require(fee > 0, FeeMustBeGreaterThanZero());

            if (_feeType == FeeType.ETH) {
                require(msg.value >= fee, InsufficientETHSent());
                (bool success,) = address(payable(ticketData.ticketAdmin)).call{value: fee}("");
                require(success, PaymentFailed(_feeType));
            } else if (_feeType == FeeType.USDT) {
                // Handle USDT payment
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).allowance(msg.sender, address(this)) >= fee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).trySafeTransferFrom(msg.sender, address(this), fee),
                    PaymentFailed(_feeType)
                );
            } else if (_feeType == FeeType.USDC) {
                // Handle USDC payment
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).allowance(msg.sender, address(this)) >= fee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).trySafeTransferFrom(msg.sender, address(this), fee),
                    PaymentFailed(_feeType)
                );
            } else if (_feeType == FeeType.EURC) {
                // Handle EURC payment
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).allowance(msg.sender, address(this)) >= fee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).trySafeTransferFrom(msg.sender, address(this), fee),
                    PaymentFailed(_feeType)
                );
            } else if (_feeType == FeeType.USDT0) {
                // Handle USDT0 payment
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).allowance(msg.sender, address(this)) >= fee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).trySafeTransferFrom(msg.sender, address(this), fee),
                    PaymentFailed(_feeType)
                );
            } else if (_feeType == FeeType.LSK) {
                // Handle LSK payment
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).allowance(msg.sender, address(this)) >= fee,
                    InsufficientAllowance(_feeType)
                );
                require(
                    IERC20(_getFeeTokenAddress(_feeType)).trySafeTransferFrom(msg.sender, address(this), fee),
                    PaymentFailed(_feeType)
                );
            } else {
                revert UnsupportedFee(_feeType);
            }

            ticketData.soldTickets = _mintTicket(ticketData.ticketNFTAddress, msg.sender);
        }
        emit TicketPurchased(_ticketId, _feeType);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _mintTicket(address _ticketNFT, address _to) private returns (uint256 tokenId_) {
        TicketNFT ticketNFT = TicketNFT(_ticketNFT);
        tokenId_ = ticketNFT.safeMint(_to);
    }
}
