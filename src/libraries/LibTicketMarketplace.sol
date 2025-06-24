// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnableRoles} from "@diamond/libraries/LibOwnableRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TicketNFT} from "@host-it/external/TicketNFT.sol";
import {TicketData, TicketMetadata, FeeType} from "@host-it/libraries/types/TicketTypes.sol";
import {LibTicketStorage, TicketStorage} from "@host-it/libraries/LibTicketStorage.sol";
import {LibTicketFactory} from "@host-it/libraries/LibTicketFactory.sol";
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
    FeeAlreadySet,
    InvalidFeeConfig,
    FeeMustBeGreaterThanZero,
    TicketUseHasCommenced,
    InvalidTicketId,
    TicketPurchaseNotStarted,
    TicketPurchasePeriodHasEnded,
    TicketUseAndRefundPeriodHasNotEnded,
    TicketAlreadyPurchased,
    AllTicketsSoldOut,
    FeeNotEnabledForThisPaymentMethod,
    InsufficientETHSent,
    InsufficientBalance,
    InsufficientAllowance,
    PaymentFailed,
    WithdrawFailed
} from "@host-it/libraries/errors/TicketErrors.sol";

library LibTicketMarketplace {
    using LibTicketMarketplace for *;
    using {LibOwnableRoles._checkRoles} for uint256;
    using LibTicketFactory for *;
    using LibTicketStorage for uint256;
    using SafeERC20 for IERC20;

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function _getFeeTokenAddress(FeeType _feeType) internal view returns (address) {
        return LibTicketStorage._ticketStorage().feeTokenAddress[_feeType][block.chainid];
    }

    function _getTicketFeeEnabled(uint256 _ticketId, FeeType _feeType) internal view returns (bool) {
        return LibTicketStorage._ticketStorage().ticketFeeEnabled[_ticketId][_feeType];
    }

    function _getTicketFee(uint256 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().ticketFee[_ticketId][_feeType];
    }

    function _getTicketBalance(uint256 _ticketId, FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().ticketBalanceByChainId[_ticketId][_feeType][block.chainid];
    }

    function _getHostItBalance(FeeType _feeType) internal view returns (uint256) {
        return LibTicketStorage._ticketStorage().hostItBalanceByChainId[_feeType][block.chainid];
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
            require(IERC20(_feeType._getFeeTokenAddress()).trySafeTransfer(_to, balance), WithdrawFailed(_feeType));
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
            require(IERC20(_feeType._getFeeTokenAddress()).trySafeTransfer(_to, balance), WithdrawFailed(_feeType));
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
