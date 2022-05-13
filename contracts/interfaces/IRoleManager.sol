// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IRoleManager is IAccessControlEnumerable {
  function transferGovernance(address _newGov) external;

  function renounceGovernance() external ;

  function governance() external view returns (address);

  function addMarketplace(address _account) external;

  function removeMarketplace(address _account) external;

  function isMarketplace(address _account) external view returns(bool);
}
