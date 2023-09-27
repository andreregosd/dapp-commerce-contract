import { expect } from "chai";
import { ethers, deployments } from "hardhat";

const toEther = (n) => {
    return ethers.formatEther(n.toString())
}

const toWei = (n) => {
    return ethers.parseEther(n.toString())
}

// Token info
const _totalSupply = 100000;

describe("AR Token Swaper", () => {
    let artoken, artokenSwaper;
    let deployer, user1, user2, user3;
    let artokenAddress, artokenSwaperAddress;

    beforeEach(async () => {
        // Setup accounts
        [deployer, user1, user2, user3] = await ethers.getSigners();

        // Deploy AR Token
        artoken = await ethers.deployContract(
            "ARToken"
        );

        await artoken.waitForDeployment();

        artokenAddress = await artoken.getAddress();

        // Deploy AR Token Swaper
        artokenSwaper = await ethers.deployContract(
            "ARTokenSwaper",
            [artokenAddress]
        );

        await artokenSwaper.waitForDeployment();

        artokenSwaperAddress = await artokenSwaper.getAddress();

        // Transfer all tokens to AR Token Swaper 
        await artoken.transfer(artokenSwaperAddress, _totalSupply);
    })

    describe("Deployment", () => {
        it("Owner is the deployer", async () => {
            expect(await artokenSwaper.owner()).to.equal(deployer.address)
        })
    })

    describe("Purchase tokens", () => {
        beforeEach(async () => {
            // Purchase tokens
            // 1 ETH = 10 tokens
            let buyerEthBalance2 = await ethers.provider.getBalance(deployer.address);
            console.log(toEther(buyerEthBalance2))

            await artokenSwaper.purchaseTokens({ value: toWei(10) });
            
            let buyerEthBalance3 = await ethers.provider.getBalance(deployer.address);
            console.log(toEther(buyerEthBalance3))
        });

        describe("Checking amounts", () => {
            it("Buyer has the correct amount of tokens", async () => {
                expect(await artoken.balanceOf(deployer.address)).to.equal(100)
            })
            
            it("Buyer has the correct amount of ETH", async () => {
                let buyerEthBalance = await ethers.provider.getBalance(deployer.address);
                expect(buyerEthBalance).to.equal(toWei(9990))
            })
            
            it("The swaper has the correct amount of tokens", async () => {
                expect(await artoken.balanceOf(artokenSwaperAddress)).to.equal(_totalSupply - 100)
            })
            
            it("The swaper has the correct amount of ETH", async () => {
                let contractEthBalance = await ethers.provider.getBalance(artokenSwaperAddress)
                expect(contractEthBalance).to.equal(toWei(10))
            })
        })
    })
})
