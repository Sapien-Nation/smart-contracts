// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoleManager is AccessControl, Ownable {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    // Sapien governance address
    address public governance;

    event GovernanceSet(address prev, address next);

    constructor(address _governance) {
        require(_governance != address(0), "RoleManager: GOVERNANCE_ZERO_ADDRESS");
        governance = _governance;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNANCE_ROLE, _governance);
    }

    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "RoleManager: GOVERNANCE_ZERO_ADDRESS");
        address currentGov = governance;
        revokeRole(GOVERNANCE_ROLE, currentGov);
        governance = _governance;
        grantRole(GOVERNANCE_ROLE, _governance);

        emit GovernanceSet(currentGov, _governance);
    }
}
