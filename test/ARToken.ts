import { expect } from "chai";
import { ethers, deployments } from "hardhat";

// Token info
const _name = "AR Token";
const _symbol = "ART";
const _decimals = 2;
const _totalSupply = 100000;

describe("AR Token", () => {
    let artoken;
    let deployer, user1, user2, user3;
    let contractAddress;

    beforeEach(async () => {
        // Setup accounts
        [deployer, user1, user2, user3] = await ethers.getSigners();

        artoken = await ethers.deployContract(
            "ARToken"
        );

        await artoken.waitForDeployment();

        contractAddress = await artoken.getAddress();
    })

    describe("Deployment", () => {
        it("Owner is the deployer", async () => {
            expect(await artoken.owner()).to.equal(deployer.address)
        })
    })

    describe("Basic info", () => {
        it("has the correct name", async () => {
            expect(await artoken.name()).to.equal(_name)
        });
        
        it("has the correct symbol", async () => {
            expect(await artoken.symbol()).to.equal(_symbol)
        });
        
        it("has the correct decimals", async () => {
            expect(await artoken.decimals()).to.equal(_decimals)
        });
        
        it("has the correct total supply", async () => {
            expect(await artoken._totalSupply()).to.equal(_totalSupply)
        });
    })

    describe("Transfers", () => {
        beforeEach(async () => {
            // Distribute tokens
            await artoken.transfer(user1.address, 25000);
            await artoken.transfer(user2.address, 25000);
            await artoken.transfer(user3.address, 25000);
        });

        describe("Checking user's amounts", () =>{
            it("Owner has the correct amount", async () => {
                expect(await artoken.balanceOf(deployer.address)).to.equal(25000)
            });
            
            it("Owner has the correct amount", async () => {
                expect(await artoken.balanceOf(user1.address)).to.equal(25000)
            });
            
            it("Owner has the correct amount", async () => {
                expect(await artoken.balanceOf(user2.address)).to.equal(25000)
            });
            
            it("Owner has the correct amount", async () => {
                expect(await artoken.balanceOf(user3.address)).to.equal(25000)
            });
        })
        
    })
})
