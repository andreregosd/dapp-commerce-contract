import { expect } from "chai";
import { ethers, deployments } from "hardhat";

const tokens = (n) => {
    return ethers.parseEther(n.toString())
}

// Global constants for listing an item
const product1Name = "T-shirt";
const product2Name = "Jeans";
const CATEGORY = "Clothing"
const IMAGE = ""
const COST = tokens(1)
const STOCK = 5

describe("DappCommerce", () => {
    let dappcommerce;
    let deployer, buyer, seller1, seller2
    let contractAddress;

    beforeEach(async () => {
        // Setup accounts
        [deployer, buyer, seller1, seller2] = await ethers.getSigners();

        dappcommerce = await ethers.deployContract(
            "DappCommerce"
        );

        await dappcommerce.waitForDeployment();

        contractAddress = await dappcommerce.getAddress();
    })

    describe("Deployment", () => {
        it("Owner is the deployer", async () => {
            expect(await dappcommerce.owner()).to.equal(deployer.address)
        })
    })

    describe("Owner permissions", () =>{
        it("should only allow the owner to enable listing", async () => {
            await expect(dappcommerce.connect(buyer).enableListing(false)).to.be.reverted;
        
            await dappcommerce.enableListing(false);
            expect(await dappcommerce.isListingEnabled()).to.be.false;
        
            await expect(dappcommerce.connect(buyer).enableListing(true)).to.be.reverted;
        
            await dappcommerce.enableListing(true);
            expect(await dappcommerce.isListingEnabled()).to.be.true;
        });
    })

    describe("Listing permission", () =>{
        it("should not allow listings when listing is disabled", async () =>{
            await dappcommerce.enableListing(false);
            await expect(dappcommerce.connect(seller1)
                .addProduct(product1Name, CATEGORY, IMAGE, COST, STOCK)).to.be.reverted;
        })
    })

    describe("Add products", () => {
        beforeEach(async () => {
            // List a item
            let transaction = await dappcommerce.connect(seller1).addProduct(product1Name, CATEGORY, IMAGE, COST, STOCK)
            let transaction2 = await dappcommerce.connect(seller2).addProduct(product2Name, CATEGORY, IMAGE, COST, STOCK)
            await transaction.wait()
            await transaction2.wait()
        })

        it("adds successfully", async () => {
            let product1 = await dappcommerce.products(1);
            let product2 = await dappcommerce.products(2);

            expect(product1.name).to.equal(product1Name)
            expect(product1.category).to.equal(CATEGORY)
            expect(product1.cost).to.equal(COST)
            expect(product1.owner).to.equal(seller1.address)
            expect(product1.stock).to.equal(STOCK)
            
            expect(product2.name).to.equal(product2Name)
            expect(product2.category).to.equal(CATEGORY)
            expect(product2.cost).to.equal(COST)
            expect(product2.owner).to.equal(seller2.address)
            expect(product2.stock).to.equal(STOCK)
        })

        describe("Adding stock", () =>{
            let productId = 1
            let quantityToAdd = 2
            it("adds stock successfully", async () => {
                await dappcommerce.connect(seller1).addStock(productId, quantityToAdd);
                let product = await dappcommerce.products(1);
                expect(product.stock).to.equal(STOCK + quantityToAdd);
            })
            it("only the product seller can add stock", async () => {
                await expect(dappcommerce.connect(buyer).addStock(productId, quantityToAdd)).to.be.reverted;
            })
        })

        describe("Buys a product", () =>{
            let productId = 1
            let quantityToBuy = 1
            let totalCost = COST// * BigInt(quantityToBuy);
            beforeEach(async () => {
                // Buy the first item
                let transaction = await dappcommerce.connect(buyer).order(productId, quantityToBuy, { value: totalCost });
                await transaction.wait();
            })
    
            it("updated the contract balance correctly", async () => {
                let totalCost = COST * BigInt(quantityToBuy);
                let contractBalance = await ethers.provider.getBalance(contractAddress);

                expect(contractBalance).to.equal(totalCost);
            })

            it("updates the stock", async () => {
                let product = await dappcommerce.products(1);
        
                expect(product.stock).to.equal(STOCK - quantityToBuy);
            })

            it("creates the transaction successfully", async () => {
                let transaction = await dappcommerce.transactions(1);
            
                expect(transaction.buyer).to.equal(buyer.address);
                expect(transaction.seller).to.equal(seller1.address);
                expect(transaction.quantity).to.equal(quantityToBuy);
                expect(transaction.authorized).to.equal(false);
                expect(transaction.processed).to.equal(false);
                expect(transaction.product.id).to.equal(productId);
            })
    
            it("adds the transaction on buyers mapping", async () => {
                let buyerTransactionId = await dappcommerce.transactionByBuyers(buyer.address, 1);
            
                expect(buyerTransactionId).to.equal(1);
            })
            
            it("adds the transaction on sellers mapping", async () => {
                let sellerTransactionId = await dappcommerce.transactionBySellers(seller1.address, 1);
        
                expect(sellerTransactionId).to.equal(1);
            })

            it("only authorized transactions funds can be withdrawn", async () =>{
                await expect(dappcommerce.connect(seller1).withdrawTransactionFunds(1)).to.be.reverted;
            })
            
            it("updates sellers balance", async () =>{
                let transactionId = 1;
                let sellerBalanceBefore = await ethers.provider.getBalance(seller1.address);

                await dappcommerce.connect(buyer).authorizeTransaction(transactionId);
                let trx = await dappcommerce.connect(seller1).withdrawTransactionFunds(transactionId);

                let sellerBalanceAfter = await ethers.provider.getBalance(seller1.address);

                // Calculating gas cost
                let receipt = await trx.wait();
                let gasUsed = receipt.gasUsed;
                let gasPrice = trx.gasPrice;
                let gasCost = gasUsed * gasPrice;

                let sellerBalanceExpected = sellerBalanceBefore + totalCost - gasCost;
                
                await expect(sellerBalanceAfter).to.equal(sellerBalanceExpected);
            })

            it("updates contract balance", async () =>{
                let transactionId = 1;
                let contractBalanceBefore = await ethers.provider.getBalance(contractAddress);

                await dappcommerce.connect(buyer).authorizeTransaction(transactionId);
                await dappcommerce.connect(seller1).withdrawTransactionFunds(transactionId);
                let contractBalanceAfter = await ethers.provider.getBalance(contractAddress);
                
                await expect(contractBalanceAfter).to.equal(contractBalanceBefore - totalCost);
            })
        })
    })
})
