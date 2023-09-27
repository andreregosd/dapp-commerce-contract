// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "hardhat/console.sol";

//ERC Token Standard #20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

//Actual token contract
contract ARToken is IERC20 {
    address public owner;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        owner = msg.sender;
        symbol = "ART";
        name = "AR Token";
        decimals = 2;
        _totalSupply = 100000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) external returns (bool) {
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) external view returns (uint) {
        return allowed[tokenOwner][spender];
    }

    receive() external payable {}
}