// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccreditedInvestorRegistry.sol";

/// @title OnlyAccreditedCanMint
/// @notice Simple token gated by an AccreditedInvestorRegistry
contract OnlyAccreditedCanMint {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    AccreditedInvestorRegistry public immutable registry;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    error NotAccredited();
    error ZeroAddress();
    error InsufficientBalance();

    constructor(
        string memory _name,
        string memory _symbol,
        AccreditedInvestorRegistry _registry
    ) {
        if (address(_registry) == address(0)) revert ZeroAddress();
        name = _name;
        symbol = _symbol;
        registry = _registry;
    }

    /// @notice Mint tokens to a recipient, caller must be accredited
    function mint(address to, uint256 amount) external {
        if (to == address(0)) revert ZeroAddress();
        require(amount > 0, "amount zero");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Mint(msg.sender, to, amount);
    }

    /// @notice Transfer tokens to another address, caller must be accredited
    function transfer(address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        uint256 senderBalance = balanceOf[msg.sender];
        if (senderBalance < amount) revert InsufficientBalance();

        balanceOf[msg.sender] = senderBalance - amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
