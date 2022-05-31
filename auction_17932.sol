// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract auction {
    
    address payable public owner;
    uint public startingDate;
    uint public endingDate;
    bool cancelled;
    mapping (address => uint) public bids;
    uint public increment;
    uint public highestBiddingBid;
    address payable public highestBidder;

    constructor() {
        owner = payable(msg.sender);
        startingDate = block.timestamp;
        // Will end after a week
        endingDate = startingDate + 604800;
        cancelled = false;
        increment = 1 ether; 
    }

    function cancel() public onlyOwner {
        cancelled = true;
    }

    function minimum(uint a, uint b) pure private returns (uint) {
        if(a < b) return a;
        return b;
    }

    function placeBid() payable public onlyBidder beforeLastDate isNotCancelled{
        require(msg.value >= 1 ether);
        uint newBid = bids[msg.sender] + msg.value;
        require(newBid > highestBiddingBid, "You cannot bid less than the highest bidding bid");
        bids[msg.sender] = newBid;
        if(newBid < bids[highestBidder]) {
            highestBiddingBid = minimum((newBid + increment), bids[highestBidder]);
        }
        else {
            highestBiddingBid = minimum(newBid, (bids[highestBidder] + increment));
            highestBidder = payable(msg.sender);
        }
    }

    function auctionEnd() public {
        require(!cancelled || block.timestamp > endingDate, "huhihu");
        require(msg.sender == owner || bids[msg.sender] > 0);
        address payable account;
        uint val;
    
        if(cancelled) {
            account = payable(msg.sender);
            val = bids[msg.sender];
        }
        else {
            if(msg.sender == highestBidder) {
                account = highestBidder;
                val = bids[highestBidder] - highestBiddingBid;
            }
            else {
                account = payable(msg.sender);
                val = bids[msg.sender];
            }
        }
        account.transfer(val);
    }

        modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotCancelled {
        require(!cancelled);
        _;
    }

    modifier onlyBidder() {
        require(msg.sender != owner);
        _;
    }

    modifier beforeLastDate() {
        require(block.timestamp > startingDate && block.timestamp < endingDate);
        _;
    }

}