// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ValiDAO} from "../src/ValiDAO.sol";
import {ValiDAOV2} from "../src/UpgradedValiDAO.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ValiDAOTest is Test {
    ValiDAO public valiDAO;
    address public treasury;
    address public deployer;

    function setUp() public {
        treasury = makeAddr("treasury");
        deployer = makeAddr("deployer");

        // Deploy the contract without initializing it
        vm.startPrank(deployer);
        valiDAO = new ValiDAO();
        vm.stopPrank();
    }

    function test_initialize() public {
        // Encode initialization data
        bytes memory initData =
            abi.encodeWithSelector(ValiDAO.initialize.selector, "ValiDAO", "VDO", treasury, 1_000_000_000 * 10 ** 18);

        // Deploy the proxy
        vm.startPrank(deployer);
        ERC1967Proxy proxy = new ERC1967Proxy(address(valiDAO), initData);
        vm.stopPrank();

        ValiDAO token = ValiDAO(address(proxy));

        // Check that the contract is initialized
        assertEq(token.name(), "ValiDAO");
        assertEq(token.symbol(), "VDO");
        assertEq(token.totalSupply(), 1_000_000_000 * 10 ** 18);
        assertEq(token.balanceOf(treasury), 1_000_000_000 * 10 ** 18);
        assertEq(token.owner(), deployer);
    }

    function test_upgrade() public {
        // Encode initialization data
        bytes memory initData =
            abi.encodeWithSelector(ValiDAO.initialize.selector, "ValiDAO", "VDO", treasury, 1_000_000_000 * 10 ** 18);

        // Deploy the proxy contract and initialize it
        vm.startPrank(deployer);
        ERC1967Proxy proxy = new ERC1967Proxy(address(valiDAO), initData);
        ValiDAO token = ValiDAO(address(proxy));

        // Now that the token is deployed and initialized, we try to upgrade it
        ValiDAOV2 implementationV2 = new ValiDAOV2();

        token.upgradeToAndCall(address(implementationV2), "");
        vm.stopPrank();

        // Create V2 interface
        ValiDAOV2 tokenV2 = ValiDAOV2(address(proxy));

        vm.stopPrank();

        // Test state preservation
        assertEq(token.name(), "ValiDAO V2");
        assertEq(token.symbol(), "VDO2");

        // Test that the contract address is the same as the proxy address
        assertEq(address(tokenV2), address(proxy));
        assertEq(address(token), address(proxy));
    }

    function test_upgrade_onlyOwner() public {
        // Encode initialization data
        bytes memory initData =
            abi.encodeWithSelector(ValiDAO.initialize.selector, "ValiDAO", "VDO", treasury, 1_000_000_000 * 10 ** 18);

        // Deploy the proxy contract and initialize it
        vm.startPrank(deployer);
        ERC1967Proxy proxy = new ERC1967Proxy(address(valiDAO), initData);
        ValiDAO token = ValiDAO(address(proxy));
        vm.stopPrank();

        // Try to upgrade the token without being the owner
        address attacker = makeAddr("attacker");

        vm.startPrank(attacker);
        ValiDAOV2 maliciousImplementation = new ValiDAOV2();
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, attacker));
        token.upgradeToAndCall(address(maliciousImplementation), "");
        vm.stopPrank();
    }
}
