// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Migration Contract
/// @author jkthms (https://github.com/jkthms)
/// @notice This contract enables token migration between old and new ERC-20 tokens
/// @dev Supports both unidirectional and bidirectional migration based on configuration
/// @custom:security-contact [TODO]

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Migration is Ownable {
    IERC20 public oldToken;
    IERC20 public newToken;
    bool public bidirectional;
    bool public initialized;

    event Migrated(address indexed user, bool forward, uint256 amount);
    event DirectionChange(bool newValue);

    constructor() Ownable(msg.sender) {
        initialized = false;
    }

    modifier isInitialized() {
        require(initialized, "Migration contract is not initialized yet");
        _;
    }

    function initialize(address _oldToken, address _newToken, bool _bidirectional) external onlyOwner {
        require(!initialized, "Migration contract is already initialized");
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        bidirectional = _bidirectional;
        initialized = true;
    }

    function toggleMigrationDirection(bool _bidirectional) external onlyOwner isInitialized {
        require(_bidirectional != bidirectional, "Direction is already set");
        bidirectional = _bidirectional;
        emit DirectionChange(bidirectional);
    }

    function migrate(uint256 amount, bool forward) external isInitialized {
        require(amount > 0, "Amount cannot be less than or equal to 0");

        // Check whether the migration direction is permitted
        // If the request is for a backward migration, the migration direction must be bidirectional
        if (!forward) {
            require(bidirectional, "Backward migration is not permitted");
        }

        // Determine which direction the migration request is for
        IERC20 tokenFrom = forward ? oldToken : newToken;
        IERC20 tokenTo = forward ? newToken : oldToken;

        // Transfer V1 tokens from user to this contract
        require(tokenFrom.transferFrom(msg.sender, address(this), amount), "Attempt to transfer VDO V1 tokens failed");
        require(tokenTo.transfer(msg.sender, amount), "Attempt to transfer VDO V2 tokens failed");

        emit Migrated(msg.sender, forward, amount);
    }

    function withdrawAll(IERC20 token) external onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Withdrawal failed of token failed");
    }

    function withdrawNative() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed of native token failed");
    }
}
