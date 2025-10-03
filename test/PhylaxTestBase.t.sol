// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {AccreditedInvestorRegistry} from "../src/AccreditedInvestorRegistry.sol";
import {OnlyAccreditedCanMint} from "../src/OnlyAccreditedCanMint.sol";

contract PhylaxTestBase is Test {
    AccreditedInvestorRegistry internal registry;
    OnlyAccreditedCanMint internal token;

    address internal constant ADMIN = address(0xA11CE);
    address internal constant ACCREDITED = address(0xACCE);
    address internal constant NON_ACCREDITED = address(0xBEEF);

    function deployRegistry() internal {
        registry = new AccreditedInvestorRegistry(ADMIN);
    }

    function deployToken(string memory name_, string memory symbol_) internal {
        token = new OnlyAccreditedCanMint(name_, symbol_, registry);
    }

    function accredit(address account) internal {
        vm.prank(ADMIN);
        registry.addInvestor(account);
    }

    function revoke(address account) internal {
        vm.prank(ADMIN);
        registry.removeInvestor(account);
    }

    function mintAs(address caller, address to, uint256 amount) internal {
        vm.prank(caller);
        token.mint(to, amount);
    }

    function transferAs(address caller, address to, uint256 amount) internal {
        vm.prank(caller);
        token.transfer(to, amount);
    }
}
