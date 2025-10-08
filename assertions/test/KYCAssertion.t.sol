// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {OnlyAccreditedCanMintAssertion as KYCAssertion} from "../src/KYCAssertion.a.sol";
import {OnlyAccreditedCanMint} from "../../src/OnlyAccreditedCanMint.sol";
import {AccreditedInvestorRegistry} from "../../src/AccreditedInvestorRegistry.sol";

contract KYCAssertionTest is Test, CredibleTest {
    AccreditedInvestorRegistry internal registry;
    OnlyAccreditedCanMint internal token;

    address internal constant ADMIN = address(0xA11CE);
    address internal constant RECIPIENT = address(0xCAFE);
    address internal constant ACCREDITED = address(0xACCE);
    address internal constant NON_ACCREDITED = address(0xBEEF);

    function setUp() public virtual {
        registry = new AccreditedInvestorRegistry(ADMIN);
        token = new OnlyAccreditedCanMint("Phylax", "PHYX", registry);
        vm.deal(ADMIN, 100 ether);
        vm.deal(ACCREDITED, 100 ether);
        vm.deal(NON_ACCREDITED, 100 ether);
    }

    // allow cl.assertion to access variables in the constructor
    function _createData() private view returns (bytes memory) {
        return
            abi.encodePacked(
                type(KYCAssertion).creationCode,
                abi.encode(address(registry))
            );
    }

    function testMintAllowsAccreditedCaller() public {
        vm.prank(ADMIN);
        registry.addInvestor(ACCREDITED);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedMint.selector
        });

        vm.prank(ACCREDITED);
        token.mint(RECIPIENT, 1 ether);
    }

    function testMintRevertsForNonAccreditedCaller() public {
        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedMint.selector
        });

        vm.expectRevert("caller is not accredited");
        vm.prank(NON_ACCREDITED);
        token.mint(RECIPIENT, 1 ether);
    }

    function testTransferAllowsAccreditedCaller() public {
        vm.prank(ADMIN);
        registry.addInvestor(ACCREDITED);
        vm.prank(ADMIN);
        token.mint(ACCREDITED, 5 ether);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedTransfer.selector
        });

        vm.prank(ACCREDITED);
        token.transfer(RECIPIENT, 2 ether);
    }

    function testTransferRevertsForNonAccreditedCaller() public {
        vm.prank(ADMIN);
        token.mint(NON_ACCREDITED, 5 ether);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedTransfer.selector
        });

        vm.expectRevert("caller is not accredited");
        vm.prank(NON_ACCREDITED);
        token.transfer(RECIPIENT, 1 ether);
    }

    function testMintRevertsAfterRevocation() public {
        vm.prank(ADMIN);
        registry.addInvestor(ACCREDITED);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedMint.selector
        });

        vm.prank(ACCREDITED);
        token.mint(RECIPIENT, 1 ether);

        vm.prank(ADMIN);
        registry.removeInvestor(ACCREDITED);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedMint.selector
        });

        vm.expectRevert("caller is not accredited");
        vm.prank(ACCREDITED);
        token.mint(RECIPIENT, 1 ether);
    }

    function testTransferRevertsAfterRevocation() public {
        vm.prank(ADMIN);
        registry.addInvestor(ACCREDITED);
        vm.prank(ADMIN);
        token.mint(ACCREDITED, 5 ether);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedTransfer.selector
        });

        vm.prank(ACCREDITED);
        token.transfer(RECIPIENT, 2 ether);

        vm.prank(ADMIN);
        registry.removeInvestor(ACCREDITED);

        cl.assertion({
            adopter: address(token),
            createData: _createData(),
            fnSelector: KYCAssertion.assertOnlyAccreditedTransfer.selector
        });

        vm.expectRevert("caller is not accredited");
        vm.prank(ACCREDITED);
        token.transfer(RECIPIENT, 1 ether);
    }
}
