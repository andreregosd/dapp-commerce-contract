import { ethers } from "hardhat";
const hre = require("hardhat")

const { items } = require("./items.json")

const tokens = (n) => {
  return ethers.parseEther(n.toString())
}

// DEPLOY ON A ETHEREUM'S TESTNET
// npx hardhat run scripts/deploy.ts --network sepolia
// async function main() {
//   const DappCommerce = await ethers.getContractFactory("DappCommerce");
//   const dapp_commerce = await DappCommerce.deploy("Dapp Commerce");
//   console.log("Contract Deployed to Address:", dapp_commerce.address);
// }

// DEPLOY IN LOCAL BLOCKCHAIN AND INSERT SOME DATA
// npx hardhat run scripts/deploy.js --network localhost
async function main() {
  // Setup accounts
  const [deployer] = await ethers.getSigners()

  // Deploy ARToken
  const token = await ethers.deployContract(
    "ARToken"
  );
  await token.waitForDeployment();
  let tokenAddress = await token.getAddress();
  console.log(`Deployed ARToken Contract at: ${tokenAddress}\n`)

  // Deploy DappCommerce
  const dappCommerce = await ethers.deployContract(
    "DappCommerce",
    [tokenAddress]
  );
  await dappCommerce.waitForDeployment();
  let contractAddress = await dappCommerce.getAddress();
  console.log(`Deployed DappCommerce Contract at: ${contractAddress}\n`)

  // Deploy Token Swaper
  const tokenSwaper = await ethers.deployContract(
    "ARTokenSwaper",
    [tokenAddress]
  );
  await tokenSwaper.waitForDeployment();
  let tokenSwaperAddress = await tokenSwaper.getAddress();
  console.log(`Deployed Token Swaper Contract at: ${tokenSwaperAddress}\n`)

  // Log deployer
  console.log(`Deployer: ${deployer.address}`);

  // Transfer all token funds to token swaper
  let totalSupply = await token._totalSupply();
  await token.transfer(tokenSwaperAddress, totalSupply);

  // Listing items...
  for (let i = 0; i < items.length; i++) {
    const transaction = await dappCommerce.connect(deployer).addProduct(
      items[i].name,
      items[i].category,
      items[i].image,
      tokens(items[i].cost),
      items[i].stock,
    )

    await transaction.wait()
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });