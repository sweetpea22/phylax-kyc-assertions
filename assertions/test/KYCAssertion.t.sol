// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OnlyAccreditedCanMintAssertion as KYCAssertion} from "../src/KYCAssertion.a.sol";
import {PhylaxTestBase, MockOnlyAccreditedCanMint} from "./PhylaxTestBase.t.sol";

contract KYCAssertionTest is PhylaxTestBase {
    address private constant RECIPIENT = address(0xCAFE);

    function _createData() private view returns (bytes memory) {
        return abi.encodePacked(type(KYCAssertion).creationCode, abi.encode(address(token)));
    }

    function testMintAllowsAccreditedCaller() public {
        accredit(ACCREDITED);

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
        accredit(ACCREDITED);
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
}
