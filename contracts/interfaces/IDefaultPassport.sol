// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IDefaultPassport is IERC721Upgradeable {
  function creators(uint256 _id) external view returns (address);

  function setRoleManager(address _roleManager) external;

  function mint(address[] memory _accounts, string[] memory _tokenURIs) external;
}
