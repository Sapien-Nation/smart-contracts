// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IPassport.sol";

contract Passport is IPassport, OwnableUpgradeable, PausableUpgradeable, ERC721EnumerableUpgradeable {
  // Latest passport id starting from 1
  uint256 public passportID;
  // Role Manager contract address
  IRoleManager public roleManager;
  // Maximum number of passports that one wallet can purchase at the first sale
  uint16 public maxFirstMintPerAddress;
  // Non-governance wallets can transfer tokens flag
  bool public isTransferable;
  // Base token URI
  string public baseTokenURI;

  // Passport ID => passport sign status
  mapping(uint256 => bool) public override isSigned;
  // Passport ID => passport creator address
  mapping(uint256 => address) public override creators;
  // address => number of passports at the first sale
  mapping(address => uint256) public firstPurchases;

  event LogSign(uint256 indexed tokenID);
  event LogMint(uint256 indexed tokenID, address indexed account);

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _roleManager
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init();
    __Ownable_init();
    __Pausable_init();
    __Passport_init_unchained(_baseTokenURI, _roleManager);
  }

  function __Passport_init_unchained(
    string memory _baseTokenURI,
    address _roleManager
  ) internal initializer {
    require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
    baseTokenURI = _baseTokenURI;
    maxFirstMintPerAddress = 5;
  }

  modifier onlyGovernance() {
    require(_msgSender() == roleManager.governance(), "Passport: CALLER_NO_GOVERNANCE");
    _;
  }

  /**
    * @dev Set Role Manager contract address
    * Accessible by only `owner`
    * `_roleManager` must not be zero address
    */
  function setRoleManager(address _roleManager) external override onlyOwner {
    require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
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
    * @dev Set `isTransferable`
    * Accessible by only Sapien governance
    */
  function setIsTransferable(bool _isTransferable) external onlyGovernance {
    isTransferable = _isTransferable;
  }

  /**
    * @dev Set `maxFirstMintPerAddress`
    * Accessible by only Sapien governance
    * `_maxFirstMintPerAddress` must not be zero
    */
  function setMaxFirstMintPerAddress(uint16 _maxFirstMintPerAddress) external override onlyGovernance {
    require(_maxFirstMintPerAddress > 0, "Passport: MAX_FIRST_MINT_INVALID");
    maxFirstMintPerAddress = _maxFirstMintPerAddress;
  }

  /**
    * @dev Sign the passport
    * Signed passports are not for sale
    * Accessible by only Sapien governance
    * `_tokenID` must exist
    */
  function sign(uint256 _tokenID) external override onlyGovernance {
    require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
    isSigned[_tokenID] = true;

    emit LogSign(_tokenID);
  }

  /**
    * @dev Mint new passports
    * Accessible by only Sapien governance
    * Sapien governance become passport `creator`
    */
  function mint(address[] memory _accounts) external override onlyGovernance whenNotPaused {
    address gov = roleManager.governance();
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      uint256 newID = passportID + 1;
      // check first purchase limit for non-governance accounts
      if (account == gov || (account != gov && firstPurchases[account] + 1 <= maxFirstMintPerAddress)) {
        super._safeMint(account, newID);
        creators[newID] = gov;
        passportID++;
        // increase first purchased amount
        firstPurchases[account]++;

        emit LogMint(newID, account);
      }
    }
  }

  /**
    * @dev Override {ERC721Upgradeable-isApprovedForAll}.
    */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override(ERC721Upgradeable, IERC721Upgradeable) returns (bool) {
    if (roleManager.isMarketplace(_operator)) {
      return true;
    } else {
      return ERC721Upgradeable.isApprovedForAll(_owner, _operator);
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
    * @dev Tokens are non-transferable when:
    * - caller is non-governance && `isTransferable` is false
    * - signed passport
    * - contract is paused
    */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenID
  ) internal override whenNotPaused {
    if (_msgSender() != roleManager.governance() && !isTransferable) {
      revert("Passport: TOKEN_NOT_TRANSFERABLE");
    }

    require(!isSigned[_tokenID], "Passport: SIGNED_PASSPORT_NOT_TRANSFERABLE");
    ERC721EnumerableUpgradeable._beforeTokenTransfer(_from, _to, _tokenID);
  }

  /**
    * @dev Return base URI
    * Override {ERC721Upgradeable:_baseURI}
    */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }
}
