// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PhylaxTestBase} from "./PhylaxTestBase.t.sol";
import {AccreditedInvestorRegistry} from "../src/AccreditedInvestorRegistry.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AccreditedInvestorRegistryTest is PhylaxTestBase {
    event InvestorAccredited(address indexed account);
    event InvestorRevoked(address indexed account);

    function setUp() public {
        deployRegistry();
    }

    function testConstructorSetsOwnerAndAccreditsAdmin() public {
        assertEq(registry.owner(), ADMIN);
        assertTrue(registry.isAccredited(ADMIN));
    }

    function testConstructorEmitsAccreditedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit InvestorAccredited(ADMIN);
        registry = new AccreditedInvestorRegistry(ADMIN);
    }

    function testConstructorRevertsZeroAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new AccreditedInvestorRegistry(address(0));
    }

    function testAddInvestorOnlyOwner() public {
        vm.prank(NON_ACCREDITED);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, NON_ACCREDITED));
        registry.addInvestor(NON_ACCREDITED);
    }

    function testAddInvestorZeroAddressReverts() public {
        vm.prank(ADMIN);
        vm.expectRevert(AccreditedInvestorRegistry.ZeroAddress.selector);
        registry.addInvestor(address(0));
    }

    function testAddInvestorSetsFlagAndEmits() public {
        vm.expectEmit(true, false, false, true);
        emit InvestorAccredited(ACCREDITED);

        vm.prank(ADMIN);
        registry.addInvestor(ACCREDITED);

        assertTrue(registry.isAccredited(ACCREDITED));
    }

    function testRemoveInvestorOnlyOwner() public {
        accredit(ACCREDITED);

        vm.prank(NON_ACCREDITED);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, NON_ACCREDITED));
        registry.removeInvestor(ACCREDITED);
    }

    function testRemoveInvestorClearsFlagAndEmits() public {
        accredit(ACCREDITED);

        vm.expectEmit(true, false, false, true);
        emit InvestorRevoked(ACCREDITED);

        vm.prank(ADMIN);
        registry.removeInvestor(ACCREDITED);

        assertFalse(registry.isAccredited(ACCREDITED));
    }

    function testRemoveInvestorIdempotent() public {
        accredit(ACCREDITED);

        vm.prank(ADMIN);
        registry.removeInvestor(ACCREDITED);

        vm.prank(ADMIN);
        registry.removeInvestor(ACCREDITED);

        assertFalse(registry.isAccredited(ACCREDITED));
    }

    function testIsAccreditedReflectsState() public {
        assertTrue(registry.isAccredited(ADMIN));
        assertFalse(registry.isAccredited(ACCREDITED));

        accredit(ACCREDITED);
        assertTrue(registry.isAccredited(ACCREDITED));

        revoke(ACCREDITED);
        assertFalse(registry.isAccredited(ACCREDITED));
    }
}
