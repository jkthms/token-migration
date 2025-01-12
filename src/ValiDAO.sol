// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ValiDAO Token Contract
/// @author jkthms (https://github.com/jkthms)
/// @notice This contract implements the new ValiDAO ERC-20 token
/// @dev This contract is upgradeable and uses the OpenZeppelin Upgradeable contracts for upgradability
/// @custom:security-contact [TODO]

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ValiDAO is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, address treasury, uint256 totalSupply)
        public
        initializer
    {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        _mint(treasury, totalSupply);
    }
}
