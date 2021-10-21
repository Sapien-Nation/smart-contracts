// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IRoleManager is IAccessControlEnumerable {
  function setGovernance(address _governance) external;

  function governance() external view returns (address governance);

  function addMarketplace(address _account) external;

  function removeMarketplace(address _account) external;

  function isMarketplace(address _account) external view returns(bool);
}
