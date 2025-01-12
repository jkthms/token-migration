// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ValiDAO} from "../src/ValiDAO.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
}
