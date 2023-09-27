// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "hardhat/console.sol";

// TODO: IMPORT THIS
interface ERC20Interface {
    function balanceOf(address account) external view returns (uint);
}

contract DappCommerce 
{
    enum Entity {
        buyer,
        seller
    }

    struct Product {
        uint256 id;
        string name;
        string category;
        string image;
        uint256 cost;
        address owner;
        uint256 stock; // TODO: maybe not 256
    }
    
    struct Transaction {
        uint256 id;
        address buyer;
        address seller;
        Product product;
        uint256 quantity;
        bool authorized;
        bool processed;
        bool cancelled;
        bool disputeOngoing;
        uint256 lastUpdateTime;
    }

    struct Juror {
        address id;
        uint256 numCoherentVotes;
        uint256 numNonCoherentVotes;
    }

    struct VoteCounter {
        Entity winner;
        uint256 votesForBuyer;
        uint256 votesForSeller;
        mapping(address => Entity) votes;
        mapping(address => bool) hasVoted;
        bool tied;
    }

    struct Dispute
    {
        uint256 id;
        address owner;
        Entity ownersEntity;
        uint256 orderId;
        bool isResolved;
        Entity winner;
    }

    address public owner;
    mapping(uint256 => Product) public products;
    bool public isListingEnabled;
    uint256 private lastInsertedProductId;

    mapping(uint => Transaction) public transactions;
    uint public transactionCounter;
    mapping(address => uint256) public buysCounter;
    mapping(address => uint256) public sellsCounter;
    mapping(address => mapping(uint => uint)) public transactionByBuyers;
    mapping(address => mapping(uint => uint)) public transactionBySellers;
    uint256 maxTransactionBlockedTime;

    // Disputes
    uint private TOKEN_REQUIREMENT;
    address private arTokenAddress;
    mapping(address => Juror) public jurors;
    // dispute id => dispute
    mapping(uint256 => Dispute) public disputes; // TODO: Pass to array?
    // dispute id => vote counter
    mapping(uint256 => VoteCounter) private votingMachine;
    uint256 lastInsertedDisputeId;

    modifier onlyOwner() 
    {
        require(msg.sender == owner, "Only the owner can execute that action.");
        _;
    }

    constructor(address _tokenAddress)
    {
        owner = msg.sender;
        transactionCounter = 0;
        lastInsertedProductId = 0;
        isListingEnabled = true;
        maxTransactionBlockedTime = 30 * 24 * 60 * 60; // 30 days in seconds
        lastInsertedDisputeId = 0;
        arTokenAddress = _tokenAddress;
        TOKEN_REQUIREMENT = 8000;
    }

    function enableListing(bool toEnable) public onlyOwner
    {
        isListingEnabled = toEnable;
    }

    function addProduct(string memory name, string memory category, string memory image, uint256 cost, uint256 stock) public
    {
        require(isListingEnabled == true, "Listing products is currently unavailable");

        Product memory product = Product(++lastInsertedProductId, name, category, image, cost, msg.sender, stock);
        products[lastInsertedProductId] = product;
    }

    function addStock(uint256 productId, uint256 stockToAdd) public
    {
        require(msg.sender == products[productId].owner, "Only the owner of the product can add stock");
        
        products[productId].stock += stockToAdd;
    }

    function order(uint256 productId, uint256 quantity) public payable
    {
        Product memory product = products[productId];

        require(product.stock >= quantity, "There is not enough units of this product");
        require(msg.value >= quantity * product.cost, "Your funds are not enough");

        // Update stock
        products[productId].stock -= quantity;

        // Create transaction and add it to the mappings
        uint transactionId = ++transactionCounter;
        Transaction memory transaction = Transaction(transactionId, msg.sender, product.owner, product, quantity, false, false, false, false, block.timestamp);
        transactions[transactionId] = transaction;
        uint256 buyCounter = ++buysCounter[msg.sender];
        uint256 sellCounter = ++sellsCounter[product.owner];
        transactionByBuyers[msg.sender][buyCounter] = transactionId;
        transactionBySellers[product.owner][sellCounter] = transactionId;
    }

    function authorizeTransaction(uint256 transactionId) public
    {
        require(msg.sender == transactions[transactionId].buyer, "Only the buyers can authorize");
        
        transactions[transactionId].authorized = true;
    }

    function withdrawTransactionFunds(uint256 transactionId) public payable
    {
        Transaction memory transaction = transactions[transactionId];

        require(transaction.processed == false, "Order processed");
        require(msg.sender == transaction.seller, "Only the seller can perform this operation");
        require(
            transaction.authorized == true || block.timestamp > transaction.lastUpdateTime + maxTransactionBlockedTime, 
            "The buyer didnt approve the transaction"
        );
        
        // Transfer funds to seller wallet
        uint256 valueToTransfer = transaction.quantity * transaction.product.cost;
        (bool success, ) = msg.sender.call{value: valueToTransfer}("");
        require(success);
        
        transactions[transactionId].processed = true;
    }

    function recoverTransactionFunds(uint256 transactionId) public payable
    {
        Transaction memory transaction = transactions[transactionId];

        require(transaction.processed = true, "Order processed");
        require(msg.sender == transaction.buyer, "Only the buyer can perform this operation");
        require(transaction.cancelled == true, "Order is not cancelled");
        
        // Transfer funds to buyer wallet
        uint256 valueToTransfer = transaction.quantity * transaction.product.cost;
        (bool success, ) = msg.sender.call{value: valueToTransfer}("");
        require(success);
        
        transactions[transactionId].processed = true;
        transactions[transactionId].disputeOngoing = false;
    }

    // *Disputes*
    // A dispute can only be created when a buyer claims that he didnt receive the order
    // Both seller and buyer can create a dispute, but only one dispute per order can be created
    function createDispute(uint256 orderId) public
    {
        Transaction memory transaction = transactions[orderId];

        require(transaction.processed == false, "The order was processed");
        require(transaction.authorized == false, "The order is authorized");
        require(transaction.disputeOngoing == false, "Dispute already created for this order");
        require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "The sender did not participate in this order");

        lastInsertedDisputeId++;

        Entity ownersEntity = msg.sender == transaction.buyer ? Entity.buyer : Entity.seller;
        
        // Set dispute
        Dispute storage dispute = disputes[lastInsertedDisputeId];
        dispute.id = lastInsertedDisputeId;
        dispute.owner = msg.sender;
        dispute.ownersEntity = ownersEntity;
        dispute.orderId = orderId;
        dispute.isResolved = false;
        dispute.winner = Entity.buyer;
        // Add vote to voting machine
        VoteCounter storage voteCounter = votingMachine[lastInsertedDisputeId];
        voteCounter.winner = Entity.buyer;
        voteCounter.votesForBuyer = 0;
        voteCounter.votesForSeller = 0;
        voteCounter.tied = true;
        
        transactions[orderId].disputeOngoing = true;
    }

    function commitVote(uint256 disputeId, Entity vote) public
    {
        ERC20Interface token = ERC20Interface(arTokenAddress);
        require(token.balanceOf(msg.sender) > TOKEN_REQUIREMENT, "Not enough ART");
        require(disputes[disputeId].isResolved == false, "Dispute already resolved");
        
        VoteCounter storage voteCounter = votingMachine[disputeId];
        require(voteCounter.hasVoted[msg.sender] == false, "Already voted");

        if(vote == Entity.buyer){
            voteCounter.votesForBuyer++;
        }
        else{
            voteCounter.votesForSeller++;
        }

        if(voteCounter.tied){
            voteCounter.tied = false;
            voteCounter.winner = vote;
        }
        else{
            if(voteCounter.votesForBuyer == voteCounter.votesForSeller){
                voteCounter.tied = true;
            }
        }

        voteCounter.hasVoted[msg.sender] = true;
        voteCounter.votes[msg.sender] = vote;
    }
 
    function closeDispute(uint256 disputeId) public onlyOwner
    {
        disputes[disputeId].isResolved = true;
        disputes[disputeId].winner = votingMachine[disputeId].winner;
        if(!votingMachine[disputeId].tied){
            if(votingMachine[disputeId].winner == Entity.buyer){
                // Cancel the order so the buyer can get his money back
                transactions[disputes[disputeId].orderId].cancelled = true;
            }
            else{
                // Authorize the order so the seller can get his money
                transactions[disputes[disputeId].orderId].authorized = true;
            }
        }
    }
}