// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "hardhat/console.sol";

contract DappCommerce 
{
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
        address buyer;
        address seller;
        Product product;
        uint256 quantity;
        bool authorized;
        bool processed;
        uint256 lastUpdateTime;
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

    modifier onlyOwner() 
    {
        require(msg.sender == owner, "Only the owner can execute that action.");
        _;
    }

    constructor()
    {
        owner = msg.sender;
        transactionCounter = 0;
        lastInsertedProductId = 0;
        isListingEnabled = true;
        maxTransactionBlockedTime = 30 * 24 * 60 * 60; // 30 days in seconds
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

        require(product.stock > quantity, "There is not enough units of this product");
        require(msg.value >= quantity * product.cost, "Your funds are not enough");

        // Update stock
        products[productId].stock -= quantity;

        // Create transaction and add it to the mappings
        Transaction memory transaction = Transaction(msg.sender, product.owner, product, quantity, false, false, block.timestamp);
        uint transactionId = ++transactionCounter;
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
}