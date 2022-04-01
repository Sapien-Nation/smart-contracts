// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IPassport.sol";

contract Passport is IPassport, OwnableUpgradeable, PausableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable {
  // Latest passport id starting from 1
  uint256 public passportID;
  // Role Manager contract address
  IRoleManager public roleManager;
  // Bool flag that shows non-governance wallets can transfer tokens
  bool public NGTransferable;
  // Base token URI
  string public baseTokenURI;

  // Passport ID => passport sign status
  mapping(uint256 => bool) public override isSigned;
  // holder address => signed passport status, only 1 available
  mapping(address => bool) public override holdSigned;
  // Passport ID => passport creator address
  mapping(uint256 => address) public override creators;

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
    __ERC721Burnable_init();
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
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
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
    * @dev Set `NGTransferable`
    * Accessible by only Sapien governance
    */
  function setNGTransferable(bool _NGTransferable) external onlyGovernance {
    NGTransferable = _NGTransferable;
  }

  /**
    * @dev Sign the passport
    * Signed passports are not for sale
    * Accessible by only Sapien governance
    * `_tokenID` must exist
    * Every holder can own 1 signed passport at most
    */
  function sign(uint256 _tokenID) external override onlyGovernance {
    address tokenOwner = ownerOf(_tokenID);
    require(!holdSigned[tokenOwner], "Passport: ALREADY_HOLD_SIGNED_PASSPORT");

    isSigned[_tokenID] = true;
    holdSigned[tokenOwner] = true;

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
      super._safeMint(account, newID);
      creators[newID] = gov;
      passportID = newID;

      emit LogMint(newID, account);
    }
  }

  /**
    * @dev Burn passports
    * Signed passport is not burnable
    */
  function burn(uint256 _tokenId) public virtual override whenNotPaused {
    require(!isSigned[_tokenId], "Passport: SIGNED_NOT_BURNABLE");
    ERC721BurnableUpgradeable.burn(_tokenId);
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
    * - caller is non-governance && `NGTransferable` is false
    * - signed passport
    * - contract is paused
    */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenID
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
    if (_msgSender() != roleManager.governance() && !NGTransferable) {
      revert("Passport: NG_NOT_TRANSFERABLE");
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

  uint256[50] private __gap;
}
