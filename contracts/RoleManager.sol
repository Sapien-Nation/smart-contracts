// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IRoleManager.sol";

contract RoleManager is IRoleManager, AccessControlEnumerable {
  bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
  // Sapien governance address
  address public override governance;

  event LogGovernanceSet(address prev, address next);

  modifier onlyGovernance() {
    require(msg.sender == governance, "RoleManager: CALLER_NO_GOVERNANCE");
    _;
  }

  constructor() {
    governance = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    emit LogGovernanceSet(address(0), msg.sender);
  }

  /**
   * @dev Transfer governance role to `_newGov`
   * Accessible by only Sapien governance
   * `_newGov` must not be zero address
   */
  function transferGovernance(address _newGov) external override onlyGovernance {
    require(_newGov != address(0), "RoleManager: NEW_GOVERNANCE_ADDRESS_INVALID");
    _setGovernance(_newGov);
  }

  /**
   * @dev Renounce governance role
   * Accessible by only Sapien governance
   */
  function renounceGovernance() external override onlyGovernance {
    _setGovernance(address(0));
  }

  function _setGovernance(address _newGov) private {
    address gov = governance;
    if (_newGov != address(0)) {
      grantRole(DEFAULT_ADMIN_ROLE, _newGov);
    }
    revokeRole(DEFAULT_ADMIN_ROLE, gov);
    governance = _newGov;

    emit LogGovernanceSet(gov, _newGov);
  }

  /**
  * @dev Add an `_account` to the `MARKETPLACE` role.
  */
  function addMarketplace(address _account) external override onlyGovernance {
    grantRole(MARKETPLACE_ROLE, _account);
  }

  /**
  * @dev Remove an `_account` from the `MARKETPLACE` role.
  */
  function removeMarketplace(address _account) public override onlyGovernance {
    revokeRole(MARKETPLACE_ROLE, _account);
  }

  /**
    * @dev Check if an `_account` has `MARKETPLACE` role.
    */
  function isMarketplace(address _account) public override view returns (bool) {
    return hasRole(MARKETPLACE_ROLE, _account);
  }
}
