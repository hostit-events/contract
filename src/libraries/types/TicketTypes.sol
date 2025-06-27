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
    bool isUpdated;
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
    bool isFree;
    bool isUpdated;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 startTime;
    uint256 endTime;
    uint256 purchaseStartTime;
    uint256 maxTickets;
    uint256 soldTickets;
    string name;
    string symbol;
    string uri;
}

enum FeeType {
    ETH,
    WETH,
    USDT,
    USDC,
    EURC,
    USDT0,
    GHO,
    LINK,
    LSK
}
