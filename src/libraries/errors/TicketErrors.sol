// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FeeType} from "@host-it/libraries/types/TicketTypes.sol";

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
error PurchaseStartTimeMustBeBeforeStartTime();
error MaxTicketsMustBeGreaterThanZero();
error MaxTicketsMustBeAtLeastTicketsSold();
error InvalidFeeConfig();
error FeeMustBeGreaterThanZero();
error TicketUseHasCommenced();
error InvalidTicketId();
error TicketPurchaseNotStarted();
error TicketPurchasePeriodHasEnded();
error TicketUsePeriodNotStarted();
error TicketUsePeriodHasEnded();
error TicketUseAndRefundPeriodHasNotEnded();
error TicketAlreadyPurchased();
error AllTicketsSoldOut();
error FeeNotEnabledForThisPaymentMethod();
error InsufficientETHSent();
error InsufficientBalance(FeeType feeType);
error InsufficientAllowance(FeeType feeType);
error PaymentFailed(FeeType feeType);
error WithdrawFailed(FeeType feeType);
error NotTicketOwner(uint256 tokenId);
// Custom error for invalid token address
error InvalidTokenAddress();
error NoAdmins();
error InvalidAdminAddress();
