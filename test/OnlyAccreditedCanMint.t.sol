// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PhylaxTestBase} from "./PhylaxTestBase.t.sol";
import {AccreditedInvestorRegistry} from "../src/AccreditedInvestorRegistry.sol";
import {OnlyAccreditedCanMint} from "../src/OnlyAccreditedCanMint.sol";

contract OnlyAccreditedCanMintTest is PhylaxTestBase {
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    address private constant RECIPIENT = address(0xCAFE);

    function setUp() public {
        deployRegistry();
        deployToken("Phylax", "PHYX");
    }

    function testConstructorInitializesMetadataAndRegistry() public {
        assertEq(token.name(), "Phylax");
        assertEq(token.symbol(), "PHYX");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(address(token.registry()), address(registry));
    }

    function testConstructorRevertsWithZeroRegistry() public {
        vm.expectRevert(OnlyAccreditedCanMint.ZeroAddress.selector);
        new OnlyAccreditedCanMint("Name", "SYM", AccreditedInvestorRegistry(address(0)));
    }

    function testMintByAccreditedIncreasesSupplyAndBalance() public {
        vm.expectEmit(true, true, false, true);
        emit Mint(ADMIN, RECIPIENT, 1 ether);

        mintAs(ADMIN, RECIPIENT, 1 ether);

        assertEq(token.totalSupply(), 1 ether);
        assertEq(token.balanceOf(RECIPIENT), 1 ether);
    }

    function testMintRevertsForNonAccreditedCaller() public {
        vm.expectRevert(OnlyAccreditedCanMint.NotAccredited.selector);
        mintAs(NON_ACCREDITED, RECIPIENT, 1 ether);
    }

    function testMintRevertsForZeroAddressRecipient() public {
        vm.expectRevert(OnlyAccreditedCanMint.ZeroAddress.selector);
        mintAs(ADMIN, address(0), 1 ether);
    }

    function testMintRevertsForZeroAmount() public {
        vm.expectRevert(bytes("amount zero"));
        mintAs(ADMIN, RECIPIENT, 0);
    }

    function testTransferByAccreditedUpdatesBalances() public {
        accredit(ACCREDITED);
        mintAs(ADMIN, ACCREDITED, 10 ether);

        vm.expectEmit(true, true, false, true);
        emit Transfer(ACCREDITED, RECIPIENT, 4 ether);

        transferAs(ACCREDITED, RECIPIENT, 4 ether);

        assertEq(token.balanceOf(ACCREDITED), 6 ether);
        assertEq(token.balanceOf(RECIPIENT), 4 ether);
    }

    function testTransferRevertsForNonAccreditedCaller() public {
        mintAs(ADMIN, NON_ACCREDITED, 5 ether);

        vm.expectRevert(OnlyAccreditedCanMint.NotAccredited.selector);
        transferAs(NON_ACCREDITED, RECIPIENT, 1 ether);
    }

    function testTransferRevertsForZeroRecipient() public {
        accredit(ACCREDITED);
        mintAs(ADMIN, ACCREDITED, 5 ether);

        vm.expectRevert(OnlyAccreditedCanMint.ZeroAddress.selector);
        transferAs(ACCREDITED, address(0), 1 ether);
    }

    function testTransferRevertsOnInsufficientBalance() public {
        accredit(ACCREDITED);
        mintAs(ADMIN, ACCREDITED, 2 ether);

        vm.expectRevert(OnlyAccreditedCanMint.InsufficientBalance.selector);
        transferAs(ACCREDITED, RECIPIENT, 3 ether);
    }

    function testTransferRequiresCallerRemainAccredited() public {
        accredit(ACCREDITED);
        mintAs(ADMIN, ACCREDITED, 7 ether);

        revoke(ACCREDITED);

        vm.expectRevert(OnlyAccreditedCanMint.NotAccredited.selector);
        transferAs(ACCREDITED, RECIPIENT, 1 ether);

        accredit(ACCREDITED);
        transferAs(ACCREDITED, RECIPIENT, 1 ether);

        assertEq(token.balanceOf(ACCREDITED), 6 ether);
        assertEq(token.balanceOf(RECIPIENT), 1 ether);
    }
}
