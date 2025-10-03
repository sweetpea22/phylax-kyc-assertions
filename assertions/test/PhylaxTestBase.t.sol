// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {AccreditedInvestorRegistry} from "../../src/AccreditedInvestorRegistry.sol";

/// @dev Minimal OnlyAccreditedCanMint-compatible adopter without accreditation guards.
contract MockOnlyAccreditedCanMint {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    AccreditedInvestorRegistry public immutable registry;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(string memory _name, string memory _symbol, AccreditedInvestorRegistry _registry) {
        name = _name;
        symbol = _symbol;
        registry = _registry;
    }

    function mint(address to, uint256 amount) external {
        require(to != address(0), "zero to");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(msg.sender, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "zero to");
        require(balanceOf[msg.sender] >= amount, "insufficient");

        unchecked {
            balanceOf[msg.sender] -= amount;
        }
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }
}

contract PhylaxTestBase is CredibleTest, Test {
    AccreditedInvestorRegistry internal registry;
    MockOnlyAccreditedCanMint internal token;

    address internal constant ADMIN = address(0xA11CE);
    address internal constant ACCREDITED = address(0xACCE);
    address internal constant NON_ACCREDITED = address(0xBEEF);

    function setUp() public virtual {
        registry = new AccreditedInvestorRegistry(ADMIN);
        token = new MockOnlyAccreditedCanMint("Phylax", "PHYX", registry);
        vm.deal(ADMIN, 100 ether);
        vm.deal(ACCREDITED, 100 ether);
        vm.deal(NON_ACCREDITED, 100 ether);
    }

    function accredit(address account) internal {
        vm.prank(ADMIN);
        registry.addInvestor(account);
    }

    function revoke(address account) internal {
        vm.prank(ADMIN);
        registry.removeInvestor(account);
    }
}
