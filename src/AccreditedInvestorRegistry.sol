// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

/// @title AccreditedInvestorRegistry
/// @notice Maintains a list of addresses permitted to interact with gated tokens
contract AccreditedInvestorRegistry is Ownable {
    mapping(address => bool) private _accreditedInvestors;

    event InvestorAccredited(address indexed account);
    event InvestorRevoked(address indexed account);

    error ZeroAddress();

    constructor(address admin) Ownable(admin) {
        if (admin == address(0)) revert ZeroAddress();
        _accreditedInvestors[admin] = true;
        emit InvestorAccredited(admin);
    }

    /// @notice Add a new accredited investor, callable only by the registry owner
    function addInvestor(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        _accreditedInvestors[account] = true;
        emit InvestorAccredited(account);
    }

    /// @notice Remove an accredited investor, callable only by the registry owner
    function removeInvestor(address account) external onlyOwner {
        _accreditedInvestors[account] = false;
        emit InvestorRevoked(account);
    }

    /// @notice Check whether an account is accredited
    function isAccredited(address account) external view returns (bool) {
        return _accreditedInvestors[account];
    }
}
