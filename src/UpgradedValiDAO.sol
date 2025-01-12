// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ValiDAO.sol";

contract ValiDAOV2 is ValiDAO {
    // Modify the name of the token
    function name() public pure override returns (string memory) {
        return "ValiDAO V2";
    }

    function symbol() public pure override returns (string memory) {
        return "VDO2";
    }

    function version() public pure returns (uint256) {
        return 2;
    }
}
