// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IPassport.sol";

contract Passport is IPassport, OwnableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable {
  // Latest passport id starting from 1
  uint256 passportID;
  // Role Manager contract address
  IRoleManager roleManager;
  // Maximum number of passports that one user can purchase at the first sale
  uint16 public maxFirstPurchase;
  // Public sale start date, 11/19/2021
  uint256 public saleStartDate;

  struct PassportInfo {
    address creator;
    bool isSigned;
  }
  // Passport ID => passport info
  mapping(uint256 => PassportInfo) public override passports;
  // address => number of passports at the first sale
  mapping(address => uint256) public firstPurchases;

  event LogSign(uint256 indexed tokenID);
  event LogMint(uint256 indexed tokenID, address indexed account);

  function initialize(
    string memory _name,
    string memory _symbol,
    address _roleManager
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    __Passport_init_unchained(_roleManager);
  }

  function __Passport_init_unchained(
    address _roleManager
  ) internal initializer {
    require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
    saleStartDate = 1637280000;
    maxFirstPurchase = 5;
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
    * @dev Set `saleStartDate`
    * Accessible by only Sapien governance
    * `_saleStartDate` must be greater than current timestamp
    */
  function setSaleStartDate(uint256 _saleStartDate) external onlyGovernance {
    require(_saleStartDate > block.timestamp, "Passport: SALE_START_DATE_INVALID");
    saleStartDate = _saleStartDate;
  }

  /**
    * @dev Set `maxFirstPurchase` address
    * Accessible by only Sapien governance
    * `_maxPurchase` must not be zero
    */
  function setMaxPurchase(uint16 _maxPurchase) external override onlyGovernance {
    require(_maxPurchase > 0, "Passport: MAX_PURCHASE_INVALID");
    maxFirstPurchase = _maxPurchase;
  }

  /**
    * @dev Set token URI
    * Accessible by only Sapien governance
    */
  function setTokenURI(
    uint256 _tokenID,
    string memory _tokenURI
  ) external override onlyGovernance {
    super._setTokenURI(_tokenID, _tokenURI);
  }

  /**
    * @dev Sign the passport
    * Signed passports are not for sale
    * Accessible by only Sapien governance
    * `_tokenID` must exist
    */
  function sign(uint256 _tokenID) external override onlyGovernance {
    require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
    passports[_tokenID].isSigned = true;

    emit LogSign(_tokenID);
  }

  /**
    * @dev Mint new passports
    * Accessible by only Sapien governance
    * Sapien governance become passport `creator`
    * Params length must match
    */
  function mint(
    address[] memory _accounts,
    string[] memory _uris
  ) external override onlyGovernance {
    require(_accounts.length == _uris.length, "Passport: PARAM_LENGTH_MISMATCH");
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      uint256 newID = passportID + 1;
      // check first purchase limit for non-governance accounts
      if (account == roleManager.governance() || (account != roleManager.governance() && firstPurchases[account] + 1 <= maxFirstPurchase)) {
        super._mint(account, newID);
        if (bytes(_uris[i]).length > 0) {
            super._setTokenURI(newID, _uris[i]);
        }
        passportID++;
        PassportInfo storage passport = passports[newID];
        passport.creator = _msgSender();
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
    return roleManager.isMarketplace(_operator);
  }

  /**
    * @dev Pause the contract
    */
  function pause() external onlyOwner {
    _pause();
  }

  /**
    * @dev Unpause the contract
    */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
    * @dev Tokens are non-transferable when:
    * - caller is non-governance && the current timestamp < `saleStartDate`
    * - signed passport
    */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenID
  ) internal override {
    if (_msgSender() != roleManager.governance() && block.timestamp < saleStartDate) {
      revert("Passport: SALE_NOT_STARTED");
    }
    require(!passports[_tokenID].isSigned, "Passport: SIGNED_PASSPORT_NOT_TRANSFERABLE");
  }
}
