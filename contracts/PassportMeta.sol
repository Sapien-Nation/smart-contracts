// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRoleManager.sol";

contract PassportMeta is ERC721URIStorage, Ownable {
  // Latest passport id starting from 1
  uint256 passportID;
  // Role Manager contract address
  IRoleManager roleManager;
  // Base token URI
  string public baseTokenURI;
  uint256 public constant META_TOKEN_CAP = 100;

  event LogMint(uint256 indexed tokenID, address indexed account);

  modifier onlyGovernance() {
    require(msg.sender == roleManager.governance(), "PassportMeta: CALLER_NO_GOVERNANCE");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _roleManager
  ) ERC721(_name, _symbol) {
    require(_roleManager != address(0), "PassportMeta: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
    baseTokenURI = _baseTokenURI;
  }

  /**
    * @dev Set Role Manager contract address
    * Accessible by only `owner`
    * `_roleManager` must not be zero address
    */
  function setRoleManager(address _roleManager) external onlyOwner {
    require(_roleManager != address(0), "PassportMeta: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
  }

  /**
    * @dev Set `baseTokenURI`
    * Accessible by only Sapien governance
    */
  function setBaseTokenURI(string memory _baseTokenURI) external onlyGovernance {
    baseTokenURI = _baseTokenURI;
  }

  /**
    * @dev Mint new passports
    * Accessible by only Sapien governance
    * Sapien governance become passport `creator`
    */
  function mint(address _account) external onlyGovernance {
    for (uint256 i = 0; i < META_TOKEN_CAP; i++) {
      super._mint(_account, ++passportID);

      emit LogMint(passportID, _account);
    }
  }

  /**
    * @dev Return base URI
    * Override {ERC721Upgradeable:_baseURI}
    */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }
}
