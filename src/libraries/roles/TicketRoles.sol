// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                                   ROLES
//////////////////////////////////////////////////////////////////////////*//

// keccak256(abi.encode("host.it.ticket", "host.it.main.ticket.admin"))
bytes32 constant HOST_IT_MAIN_TICKET_ADMIN = 0x4f62ba22fe32d34f7d04ed4df946da35e566bd8d2c18d248ee027926debe6800;
// keccak256(abi.encode("host.it.ticket", "host.it.ticket.admin"))
bytes32 constant HOST_IT_TICKET_ADMIN = 0xa1905dd34f004fe1d2938a45a40621b381f6ace7cbdf0cdb3514edf0f9c07dcc;
