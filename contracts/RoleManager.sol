// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoleManager is AccessControl, Ownable {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    address public governance;

    constructor(address _governance) {
        require(_governance != address(0), "RoleManager: GOVERNANCE_ZERO_ADDRESS");
        governance = _governance;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNANCE_ROLE, _governance);
    }

    function setGovernance(address _governance) public onlyOwner {
        require(_governance != address(0), "RoleManager: GOVERNANCE_ZERO_ADDRESS");
        revokeRole(GOVERNANCE_ROLE, governance);
        governance = _governance;
        grantRole(GOVERNANCE_ROLE, _governance);
    }
}
