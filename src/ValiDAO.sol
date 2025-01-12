// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ValiDAO Token Contract
/// @author jkthms (https://github.com/jkthms)
/// @notice This contract implements the new ValiDAO ERC-20 token
/// @dev Mints initial supply to deployer and to the migration contract
/// @custom:security-contact [TODO]

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ValiDAO is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    constructor(string memory name, string memory symbol, address treasury, uint256 totalSupply) ERC20(name, symbol) {
        // Mint the total supply to the treasury
        _mint(treasury, totalSupply);
    }
}
