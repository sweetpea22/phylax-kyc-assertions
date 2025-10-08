// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {OnlyAccreditedCanMint} from "../../src/OnlyAccreditedCanMint.sol";
import {AccreditedInvestorRegistry} from "../../src/AccreditedInvestorRegistry.sol";

/// @notice Assertions ensuring OnlyAccreditedCanMint restricts privileged actions to accredited callers
contract OnlyAccreditedCanMintAssertion is Assertion {
    AccreditedInvestorRegistry public immutable registry;

    constructor(address tokenAddress) {
        registry = AccreditedInvestorRegistry(tokenAddress);
    }

    // register the functions that will be called and used by the assertion functions below
    function triggers() external view override {
        registerCallTrigger(
            this.assertOnlyAccreditedMint.selector,
            OnlyAccreditedCanMint.mint.selector
        );
        registerCallTrigger(
            this.assertOnlyAccreditedTransfer.selector,
            OnlyAccreditedCanMint.transfer.selector
        );
    }

    /// @notice When msg.sender hits mint, if they are not in the registry, theycannot mint tokens
    function assertOnlyAccreditedMint() external {
        OnlyAccreditedCanMint token = OnlyAccreditedCanMint(
            ph.getAssertionAdopter()
        );

        PhEvm.CallInputs[] memory calls = ph.getCallInputs(
            address(token),
            OnlyAccreditedCanMint.mint.selector
        );

        for (uint256 i = 0; i < calls.length; i++) {
            // Bundle the accreditation check into any call
            require(
                registry.isAccredited(calls[i].caller),
                "caller is not accredited"
            );
        }
    }

    /// @notice Ensure that non-accredited callers cannot transfer tokens
    function assertOnlyAccreditedTransfer() external {
        OnlyAccreditedCanMint token = OnlyAccreditedCanMint(
            ph.getAssertionAdopter()
        );

        PhEvm.CallInputs[] memory calls = ph.getCallInputs(
            address(token),
            OnlyAccreditedCanMint.transfer.selector
        );

        for (uint256 i = 0; i < calls.length; i++) {
            // Bundle the accreditation check into any call
            require(
                registry.isAccredited(calls[i].caller),
                "caller is not accredited"
            );
        }
    }
}
