// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                            HOST IT TICKET TYPES
//////////////////////////////////////////////////////////////////////////*//

struct TicketData {
    uint256 id;
    address ticketAdmin;
    address ticketNFTAddress;
    bool isFree;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 startTime;
    uint256 endTime;
    uint256 purchaseStartTime;
    uint256 maxTickets;
    uint256 soldTickets;
}

struct TicketMetadata {
    uint256 id;
    address ticketAdmin;
    address ticketNFTAddress;
    string name;
    string symbol;
    string uri;
    bool isFree;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 startTime;
    uint256 endTime;
    uint256 purchaseStartTime;
    uint256 maxTickets;
    uint256 soldTickets;
}

enum FeeType {
    ETH,
    USDT,
    USDC,
    LSK,
    EURC,
    USDT0
}
