// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {OnlyAccreditedCanMint} from "../../src/OnlyAccreditedCanMint.sol";
import {AccreditedInvestorRegistry} from "../../src/AccreditedInvestorRegistry.sol";

/// @notice Assertions ensuring OnlyAccreditedCanMint restricts privileged actions to accredited callers
contract OnlyAccreditedCanMintAssertion is Assertion {
    OnlyAccreditedCanMint public immutable token;
    AccreditedInvestorRegistry public immutable registry;

    constructor(address tokenAddress) {
        token = OnlyAccreditedCanMint(tokenAddress);
        registry = token.registry();
    }

    // register the functions that will be called and used by the assertion functions below
    function triggers() external view override {
        registerCallTrigger(this.assertOnlyAccreditedMint.selector, OnlyAccreditedCanMint.mint.selector);
        registerCallTrigger(this.assertOnlyAccreditedTransfer.selector, OnlyAccreditedCanMint.transfer.selector);
    }

    /// @notice When msg.sender hits mint, if they are not in the registry, theycannot mint tokens
    function assertOnlyAccreditedMint() external {
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(token), OnlyAccreditedCanMint.mint.selector);

        for (uint256 i = 0; i < calls.length; i++) {
            // extract the specific call from calldata
            ph.forkPreCall(calls[i].id);
            // compare the caller to the registry to see if they are accredited
            bool isAccredited = registry.isAccredited(calls[i].caller);
            // get the payload for the mint call, which is the address to mint to  and the amount to mint
            (, address recipient,) = abi.decode(calls[i].input, (bytes4, address, uint256));
            // get the total supply and balance of the recipient before the call
            uint256 totalSupplyBefore = token.totalSupply();
            uint256 recipientBalanceBefore = token.balanceOf(recipient);

            // fork the post call to get the state after the call
            ph.forkPostCall(calls[i].id);

            // If the caller is not accredited, the total supply and balance of the recipient should not be different from the forkpreCall
            if (!isAccredited) {
                require(token.totalSupply() == totalSupplyBefore, "mint non-accredited total supply changed");
                require(token.balanceOf(recipient) == recipientBalanceBefore, "mint non-accredited balance changed");
            }
        }
    }

    /// @notice Ensure that non-accredited callers cannot transfer tokens
    function assertOnlyAccreditedTransfer() external {
        PhEvm.CallInputs[] memory calls = ph.getCallInputs(address(token), OnlyAccreditedCanMint.transfer.selector);

        for (uint256 i = 0; i < calls.length; i++) {
            // hm how do i know the call data is right?)
            ph.forkPreCall(calls[i].id);
            // compare the caller to the registry to see if they are accredited
            bool isAccredited = registry.isAccredited(calls[i].caller);
            // get the payload for the transfer call, which is the address to transfer to and the amount to transfer
            (, address recipient,) = abi.decode(calls[i].input, (bytes4, address, uint256));
            // get the balance of the sender and recipient before the call
            uint256 senderBalanceBefore = token.balanceOf(calls[i].caller);
            uint256 recipientBalanceBefore = token.balanceOf(recipient);

            // fork the post call to get the state after the call
            ph.forkPostCall(calls[i].id);

            // If the caller is not accredited, the balance of the sender and recipient should not be different from the forkpreCall
            if (!isAccredited) {
                require(
                    token.balanceOf(calls[i].caller) == senderBalanceBefore,
                    "transfer non-accredited sender balance changed"
                );
                require(
                    token.balanceOf(recipient) == recipientBalanceBefore,
                    "transfer non-accredited recipient balance changed"
                );
            }
        }
    }
}
