// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ValiDAO is ERC20, Ownable {
    constructor(string memory name, string memory symbol, IERC20 _oldToken) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(address(this), _oldToken.totalSupply());
        _mint(msg.sender, _oldToken.totalSupply() * 2 / 10);
    }
}

contract Migration is Ownable {
    IERC20 public immutable oldToken;
    ValiDAO public immutable newToken;
    bool public bidirectional;

    event Migrated(address indexed user, bool forward, uint256 amount);
    event DirectionChange(bool newValue);

    constructor(address _oldToken, bool _bidirectional) Ownable(msg.sender) {
        oldToken = IERC20(_oldToken);
        newToken = new ValiDAO("VDO", "ValiDAO", oldToken);
        bidirectional = _bidirectional;
    }

    function toggleMigrationDirection(bool _bidirectional) external onlyOwner {
        require(_bidirectional != bidirectional, "Direction is already set");
        bidirectional = _bidirectional;
        emit DirectionChange(bidirectional);
    }

    function migrate(uint256 amount, bool forward) external {
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
}
