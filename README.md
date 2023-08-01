# DappCommerce

This repository contains the smart contract of DappCommerce. DappCommerce is a decentralized e-commerce platform built on the blockchain. It allows users to buy and sell products using cryptocurrency and provides a secure and transparent way to conduct online transactions.

## Description

DappCommerce is a smart contract-based e-commerce platform that enables users to list and purchase products using Ethereum's blockchain. The platform is built on the Ethereum network and uses this smart contract to handle transactions securely and efficiently. Sellers can list their products on the platform, and buyers can purchase them using cryptocurrency. The platform also includes features like order authorization and transaction processing to ensure a smooth and reliable shopping experience.

## How it works

Anyone can sell or buy a product just by connecting a Ethereum wallet.
When a buyer places an order, he will transfer his funds to the smart contract and the seller will not receive the cryptocurrency until the buyer authorize. This is a security measure to prevent sellers from keep the product for himself after receiving the cryptocurrency. When the buyer receives the product he should authorize the transaction and then the seller can withdraw his funds. There is also a time limit, initially set to 30 days, within which the buyer must authorize the transaction. This time limit was implemented to handle situations where a buyer receives the product but forgets to authorize the transaction. The buyer should be able to mark the transaction with a black flag, otherwise, a seller could just wait for the 30 days to withdraw his money, but this part is not implemented yet.

## Future Updates

I want to add the following features in future updates:

- Seller will be able to withdraw funds of more than one order in one transaction
- Implement a trust system
- Launch a token that will allow the holders to participate in all the decision-making
- Integration with additional cryptocurrencies for payment.

I am open to feedback and suggestions from the community! If you have ideas for improvement, please let me know by opening an issue.

## Contact

Feel free to report any issues or suggest improvements in the [Issues](https://github.com/andreregosd/dapp-commerce-contract/issues) section.