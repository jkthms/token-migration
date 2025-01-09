// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Migration, ValiDAO} from "../src/Migration.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MigrationTest is Test {
    Migration public migration;
    MockERC20 public oldToken;
    ValiDAO public newToken;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);
        oldToken = new MockERC20();
        migration = new Migration(address(oldToken), true);
        newToken = migration.newToken();

        // Send some V1 tokens to the user for testing
        oldToken.transfer(user, 100 * 1e18);
        vm.stopPrank();
    }

    function test_newToken() public {
        assertEq(newToken.name(), "ValiDAO");
        assertEq(newToken.symbol(), "VDO");
        assertEq(newToken.decimals(), 18);
    }

    function test_deployMigration() public {
        // Test that the balances are as expected initially
        assertEq(oldToken.balanceOf(user), 100 * 1e18);
        assertEq(newToken.balanceOf(user), 0);

        // Check that the owner of Migration is the owner
        assertEq(migration.owner(), owner);

        // Check that the new token is minted correctly
        uint256 totalSupply = oldToken.totalSupply();
        assertEq(newToken.balanceOf(address(migration)), totalSupply);
        assertEq(newToken.balanceOf(owner), totalSupply * 2 / 10);

        // Check that the user has the correct amount of tokens
        assertEq(oldToken.balanceOf(user), 100 * 1e18);
        assertEq(newToken.balanceOf(user), 0);
    }

    function test_toggleMigrationDirection() public {
        bool currentDirection = migration.bidirectional();

        // Modify the direction to the opposite value
        vm.startPrank(owner);
        migration.toggleMigrationDirection(!currentDirection);
        vm.stopPrank();
        assertEq(migration.bidirectional(), !currentDirection);

        // Modify the direction back to the original
        vm.startPrank(owner);
        migration.toggleMigrationDirection(currentDirection);
        vm.stopPrank();
        assertEq(migration.bidirectional(), currentDirection);
    }

    function test_toggleMigrationDirection_OwnerOnly() public {
        // Only the contract owner can change the direction of the migration
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        migration.toggleMigrationDirection(true);
        vm.stopPrank();
    }

    function test_migrate() public {
        uint256 userOldTokenBalance = oldToken.balanceOf(user);
        uint256 userNewTokenBalance = newToken.balanceOf(user);
        uint256 migrationOldTokenBalance = oldToken.balanceOf(address(migration));
        uint256 migrationNewTokenBalance = newToken.balanceOf(address(migration));

        // Check that the user can migrate forwards
        vm.startPrank(user);
        oldToken.approve(address(migration), 100);
        migration.migrate(100, true);
        vm.stopPrank();

        // Check the accounting logic is 1:1
        assertEq(oldToken.balanceOf(user), userOldTokenBalance - 100);
        assertEq(oldToken.balanceOf(address(migration)), migrationOldTokenBalance + 100);
        assertEq(newToken.balanceOf(user), userNewTokenBalance + 100);
        assertEq(newToken.balanceOf(address(migration)), migrationNewTokenBalance - 100);

        // Check that the user can also migrate backwards
        vm.startPrank(user);
        newToken.approve(address(migration), 50);
        migration.migrate(50, false);
        vm.stopPrank();

        // Check the accounting logic is 1:1
        assertEq(oldToken.balanceOf(user), userOldTokenBalance - 50);
        assertEq(newToken.balanceOf(user), userNewTokenBalance + 50);
        assertEq(oldToken.balanceOf(address(migration)), migrationOldTokenBalance + 50);
        assertEq(newToken.balanceOf(address(migration)), migrationNewTokenBalance - 50);
    }

    function test_migrate_Bidirectional() public {
        // Modify the direction to be unidirectional
        vm.startPrank(owner);
        migration.toggleMigrationDirection(false);
        vm.stopPrank();

        assertEq(migration.bidirectional(), false);

        // User migrates V1 tokens to the new token
        vm.startPrank(user);
        oldToken.approve(address(migration), 100);
        migration.migrate(100, true);
        vm.stopPrank();

        // User attempts to migrate new tokens back to V1
        vm.startPrank(user);
        newToken.approve(address(migration), 100);
        vm.expectRevert("Backward migration is not permitted");
        migration.migrate(100, false);
        vm.stopPrank();
    }
}
