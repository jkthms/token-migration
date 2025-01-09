// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
A smart contract that migrates VDO V1 tokens to VDO V2 tokens using a 1:1 ratio.

It supports bi-directional migration, with an additional flag to make the migration one-way from V1 to V2 only.
*/

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Migration is Ownable {
    IERC20 public immutable oldToken;
    IERC20 public immutable newToken;
    bool public bidirectional;

    event MigratedToV2(address indexed user, uint256 amount);
    event MigratedToV1(address indexed user, uint256 amount);
    event DirectionChange(bool newValue);

    constructor(address _oldToken, bool _bidirectional) {
        oldToken = IERC20(_oldToken);

        // Deploy the V2 token at deployment time, and allow it to be mintable and burnable by the migration contract
        newToken = new ERC20("VDO", "Validao");

        // Mint the full amount of V2 tokens to the migration contract
        newToken.mint(address(this), oldToken.totalSupply());

        // Mint an additional 20% of tokens to the deployer
        newToken.mint(msg.sender, oldToken.totalSupply() * 2 / 10);

        // Set the direction flag
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
        // If the request is for a bac
        if (!forward) {
            require(bidirectional, "Migration direction must be permitted");
        }

        // Determine which direction the migration request is for
        IERC20 tokenFrom = forward ? oldToken : newToken;
        IERC20 tokenTo = forward ? newToken : oldToken;

        // Transfer V1 tokens from user to this contract
        require(tokenFrom.transferFrom(msg.sender, address(this), amount), "V1 transfer failed");

        // Transfer V2 tokens to user
        require(tokenTo.transfer(msg.sender, amount), "V2 transfer failed");

        emit MigratedToV2(msg.sender, amount);
    }
}
