// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRoleManager.sol";

contract RoleManager is IRoleManager, AccessControlEnumerable, Ownable {
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
  // Sapien governance address
  address public override governance;

  event LogGovernanceSet(address prev, address next);

  constructor(address _governance) {
    require(_governance != address(0), "RoleManager: GOVERNANCE_ADDRESS_INVALID");
    governance = _governance;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(GOVERNANCE_ROLE, _governance);
  }

  function setGovernance(address _governance) external override onlyOwner {
    require(_governance != address(0), "RoleManager: GOVERNANCE_ADDRESS_INVALID");
    address currentGov = governance;
    revokeRole(GOVERNANCE_ROLE, currentGov);
    governance = _governance;
    grantRole(GOVERNANCE_ROLE, _governance);

    emit LogGovernanceSet(currentGov, _governance);
  }

  /**
  * @dev Add an `_account` to the `MARKETPLACE` role.
  */
  function addMarketplace(address _account) external override onlyOwner {
    grantRole(MARKETPLACE_ROLE, _account);
  }

  /**
  * @dev Remove an `_account` from the `MARKETPLACE` role.
  */
  function removeMarketplace(address _account) public override onlyOwner {
    revokeRole(MARKETPLACE_ROLE, _account);
  }

  /**
    * @dev Check if an `_account` is `MARKETPLACE`.
    */
  function isMarketplace(address _account) public override view returns (bool) {
    return hasRole(MARKETPLACE_ROLE, _account);
  }
}
