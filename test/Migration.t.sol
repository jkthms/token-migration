// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Migration, ValiDAO} from "../src/Migration.sol";
import {MockVDO} from "../src/mock/MockVDO.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MigrationTest is Test {
    Migration public migration;
    MockVDO public oldToken;
    ValiDAO public newToken;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);
        oldToken = new MockVDO();
        migration = new Migration(address(oldToken), true);
        newToken = migration.newToken();
        vm.stopPrank();
    }

    function test_pass() public {
        vm.startPrank(user);
        vm.stopPrank();
    }
}
