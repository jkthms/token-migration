// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ValiDAO} from "../src/ValiDAO.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ValiDAOTest is Test {
    IERC20 public valiDAO;
    address public treasury;
    address public deployer;

    function setUp() public {
        treasury = makeAddr("treasury");
        deployer = makeAddr("deployer");
    }
}