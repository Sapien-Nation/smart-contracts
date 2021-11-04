// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPassport is IERC721Upgradeable {
  function isSigned(uint256 _id) external view returns (bool);

  function creators(uint256 _id) external view returns (address);

  function setRoleManager(address _roleManager) external;

  function setMaxFirstMintPerAddress(uint16 _maxFirstMintPerAddress) external;

  function setTokenURI(uint256 _tokenID, string memory _tokenURI) external;

  function sign(uint256 _tokenID) external;

  function mint(address[] memory _accounts) external;
}
