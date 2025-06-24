// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                                 CONSTANTS
//////////////////////////////////////////////////////////////////////////*//

// keccak256("host.it.ticket")
bytes32 constant HOST_IT_TICKET = 0x2d39ca42f70b8fb1aad3b6b712ac8513c31a927ee8719e6858dd209fe8ec8293;
uint256 constant HOST_IT_FEE_NUMERATOR = 300; // 3% fee for HostIt
uint256 constant HOST_IT_FEE_DENOMINATOR = 10e3; // 10000 (3% = 300 / 10000)
uint256 constant REFUND_PERIOD = 3 days;
