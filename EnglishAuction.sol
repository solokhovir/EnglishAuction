// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EnglishAuction {
    string public item;
    address payable public immutable seller;
    uint public endAt;
    bool public started;
    bool public ended;
    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;

    event Start(string _item, uint _currentPrice);
    event Bid(address _bidder, uint _bid);
    event End(address _highestBidder, uint _highestBid);
    event Withdraw(address _sender, uint _refundAmount);

    constructor(string memory _item, uint _startingBid) {
        item = _item;
        highestBid = _startingBid;
        seller = payable(msg.sender);

    }

    modifier onlySeller {
        require(msg.sender == seller, "Not a seller");
        _;
    }

    modifier hasStarted {
        require(started, "Has not started yet");
        _;
    }

    modifier notEnded {
        require(block.timestamp < endAt, "Has ended");
        _;
    }

    function start() external onlySeller {
        require(!started, "Has already started");
        
        started = true;
        endAt = block.timestamp + 30;
        emit Start(item, highestBid);
    }

    function bid() external payable hasStarted notEnded {
        require(msg.value > highestBid, "Too low");

        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    function end() external hasStarted {
        require(!ended, "Already ended");
        require(block.timestamp >= endAt, "Can't stop auction yet");
        
        ended = true;
        if(highestBidder != address(0)) {
            seller.transfer(highestBid);
        }

        emit End(highestBidder, highestBid);
    }

    function withdraw() external {
        uint refundAmount = bids[msg.sender];
        require(refundAmount > 0, "Incorrect refund amount");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        emit Withdraw(msg.sender, refundAmount);
    }
}