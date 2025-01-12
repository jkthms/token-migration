// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ValiDAO} from "../src/ValiDAO.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Migration} from "../src/Migration.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IntegrationTest is Test {
    address public treasury;
    address public deployer;
    address public user;

    function setUp() public {
        treasury = makeAddr("treasury");
        deployer = makeAddr("deployer");
        user = makeAddr("user");
    }

    function test_integration() public {
        // Step-by-Step Integration Test
        // 1. Deploy an initial ValiDAO token (plain ERC-20)
        // 2. Deploy the Migration contract
        // 3. Deploy the ValiDAOV2 contract
        // 4. Initialize the ValiDAOV2 contract, test minting and name/symbol logic
        // 5. Initialize the Migration contract
        // 5. Migrate tokens from the initial token to the new token
        // 6. Check that the tokens have been migrated correctly
        // 7. Check that backwards migration functions correctly
        // 8. Toggle backwards migration off
        // 9. Check that the backwards migration is disabled

        // Steps 1, 2 & 3: Deploy all of the components
        vm.startPrank(deployer);
        IERC20 initialToken = new MockERC20();
        Migration migration = new Migration();
        ValiDAO _newToken = new ValiDAO();
        vm.stopPrank();

        // Step 4: Initialize the new token contract
        vm.startPrank(deployer);
        bytes memory initData =
            abi.encodeWithSelector(ValiDAO.initialize.selector, "ValiDAO", "VDO", treasury, 1_000_000_000 * 10 ** 18);

        ERC1967Proxy proxy = new ERC1967Proxy(address(_newToken), initData);

        ValiDAO newToken = ValiDAO(address(proxy));

        // Check that the contract is initialized
        assertEq(newToken.name(), "ValiDAO");
        assertEq(newToken.symbol(), "VDO");
        assertEq(newToken.totalSupply(), 1_000_000_000 * 10 ** 18);
        assertEq(newToken.balanceOf(treasury), 1_000_000_000 * 10 ** 18);
        assertEq(newToken.owner(), deployer);
        vm.stopPrank();

        // Step 5: Initialize the Migration contract
        vm.startPrank(deployer);
        migration.initialize(address(initialToken), address(newToken), true);
        vm.stopPrank();

        // Step 5.5: Transfer tokens to the Migration contract
        vm.startPrank(deployer);
        initialToken.transfer(address(user), 50 * 1e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        newToken.transfer(address(migration), 100 * 1e18);
        vm.stopPrank();

        assertEq(initialToken.balanceOf(user), 50 * 1e18);
        assertEq(newToken.balanceOf(user), 0);
        assertEq(initialToken.balanceOf(address(migration)), 0);
        assertEq(newToken.balanceOf(address(migration)), 100 * 1e18);

        // Pre-Migration Token Balances

        /////////////////////////////////////////////////
        //             // initial token // new token   //
        /////////////////////////////////////////////////
        // user       // 50             // 0           //
        // migration  // 0              // 100         //
        /////////////////////////////////////////////////

        // Step 6: Migrate tokens from the initial token to the new token
        vm.startPrank(user);
        initialToken.approve(address(migration), 25 * 1e18);
        migration.migrate(25 * 1e18, true);
        vm.stopPrank();

        // Post-Migration Expected Token Balances

        /////////////////////////////////////////////////
        //             // initial token // new token   //
        /////////////////////////////////////////////////
        // user       // 25             // 25          //
        // migration  // 25             // 75          //
        /////////////////////////////////////////////////

        assertEq(initialToken.balanceOf(user), 25 * 1e18);
        assertEq(newToken.balanceOf(user), 25 * 1e18);
        assertEq(initialToken.balanceOf(address(migration)), 25 * 1e18);
        assertEq(newToken.balanceOf(address(migration)), 75 * 1e18);

        // Step 7: Check that backwards migration is enabled
        vm.startPrank(user);
        newToken.approve(address(migration), 10 * 1e18);
        migration.migrate(10 * 1e18, false);
        vm.stopPrank();

        // Post-Backwards Migration Expected Token Balances

        /////////////////////////////////////////////////
        //             // initial token // new token   //
        /////////////////////////////////////////////////
        // user       // 35             // 15          //
        // migration  // 15             // 85          //
        /////////////////////////////////////////////////

        assertEq(initialToken.balanceOf(user), 35 * 1e18);
        assertEq(newToken.balanceOf(user), 15 * 1e18);
        assertEq(initialToken.balanceOf(address(migration)), 15 * 1e18);
        assertEq(newToken.balanceOf(address(migration)), 85 * 1e18);

        // Step 8: Disable the backwards migration
        vm.startPrank(deployer);
        migration.toggleMigrationDirection(false);
        vm.stopPrank();

        // Step 9: Check that the backwards migration is disabled
        vm.startPrank(user);
        newToken.approve(address(migration), 25 * 1e18);
        vm.expectRevert("Backward migration is not permitted");
        migration.migrate(25 * 1e18, false);
        vm.stopPrank();
    }
}
