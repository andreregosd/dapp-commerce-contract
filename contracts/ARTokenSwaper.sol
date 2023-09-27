// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "hardhat/console.sol";

// TODO: Change the name of the interface to ERC20Interface, but only after test (and fail)
// Interface for ERC20 tokens
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract ARTokenSwaper {
    address public owner;
    address public tokenAddress;
    // 10 tokens = 1 ETH
    uint256 private constant swapRate = 10; // has to be constant to avoid permanent loss  

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function purchaseTokens() external payable {
        console.log("PURCHASETOKENS");
        console.log(msg.value);
        require(msg.value > 0, "Must send ETH");
        uint256 tokenAmount = (msg.value * swapRate) / 1 ether; // TODO: CHECK THIS
        console.log(tokenAmount);
        require(tokenAmount > 0, "Token amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // TODO: CHECK THIS FUNCTION. Approves and stuff...
    function sellTokens(uint256 amount) external {
        uint256 ethValue = (amount / swapRate) * 1 ether;

        IERC20 token = IERC20(tokenAddress);

        require(token.allowance(msg.sender, address(this)) >= amount, "User didnt approve");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // also check this
        payable(msg.sender).transfer(ethValue);
    }

    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Other functions, such as emergency withdrawal or pausing the contract, can be added here.
}