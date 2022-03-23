// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IRoleManager.sol";

contract Avatar is ERC721Enumerable, Ownable, Pausable {
  // Latest avatar id starting from 1
  uint256 public avatarID;
  // Role Manager contract address
  IRoleManager public roleManager;
  // Base token URI
  string public baseTokenURI;
  
  event LogMint(uint256 indexed tokenID, address indexed account);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _roleManager
  ) ERC721(_name, _symbol) {
    require(_roleManager != address(0), "Avatar: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
    baseTokenURI = _baseTokenURI;
  }

  modifier onlyGovernance() {
    require(msg.sender == roleManager.governance(), "Avatar: CALLER_NO_GOVERNANCE");
    _;
  }

  /**
    * @dev Mint new avatars
    * Accessible by only Sapien governance
    */
  function mint(address[] memory _accounts) external onlyGovernance whenNotPaused {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      uint256 newID = avatarID + 1;
      super._safeMint(account, newID);
      avatarID = newID;

      emit LogMint(newID, account);
    }
  }

  /**
    * @dev Override {ERC721-isApprovedForAll}.
    */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override(ERC721, IERC721) returns (bool) {
    if (roleManager.isMarketplace(_operator)) {
      return true;
    } else {
      return ERC721.isApprovedForAll(_owner, _operator);
    }
  }

  /**
    * @dev Pause the contract
    */
  function pause() external onlyGovernance {
    _pause();
  }

  /**
    * @dev Unpause the contract
    */
  function unpause() external onlyGovernance {
    _unpause();
  }

  /**
    * @dev Tokens are non-transferable when contract is paused
    */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenID
  ) internal override whenNotPaused {
    ERC721Enumerable._beforeTokenTransfer(_from, _to, _tokenID);
  }

  /**
    * @dev Return base URI
    * Override {ERC721:_baseURI}
    */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }
}