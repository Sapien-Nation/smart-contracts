// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IRoleManager.sol";

contract Passport is OwnableUpgradeable, ERC721URIStorageUpgradeable {
    // Latest passport id starting from 1
    uint256 passportID;
    // Role Manager contract address
    IRoleManager roleManager;
    // Fee collector address
    address public feeTreasury;
    // Maximum number of passports that one user can purchase at the first sale
    uint16 public maxPurchase;
    // Passport token price in ETH
    uint256 public firstPriceETH;
    // Fee in BPS
    uint16 public feeBps;
    // Royalty fee in BPS
    uint16 public royaltyFeeBps;

    struct PassportInfo {
        address creator;
        address initialOwner; // owner at the first sale
        uint256 priceETH;
        bool isSigned;
        bool isOpenForSale;
    }
    // Passport ID => passport info
    mapping(uint256 => PassportInfo) public passports;
    // address => number of passports at the first sale
    mapping(address => uint256) public firstPurchases;

    event ETHReceived(address indexed sender, uint256 amount);
    event PutForSale(uint256 indexed tokenID, uint256 price);
    event PriceSet(uint256 indexed tokenID, uint256 price);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _roleManager,
        address _feeTreasury
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __Passport_init_unchained(_roleManager, _feeTreasury);
    }

    function __Passport_init_unchained(
        address _roleManager,
        address _feeTreasury
    ) internal initializer {
        require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
        require(_feeTreasury != address(0), "Passport: FEE_TREASURY_ADDRESS_INVALID");
        roleManager = IRoleManager(_roleManager);
        feeTreasury = _feeTreasury;
        maxPurchase = 5;
        firstPriceETH = 0.25 ether;
        feeBps = 500;
        royaltyFeeBps = 300;
    }

    // TODO check msg.sender
    receive() external payable {
        emit ETHReceived(_msgSender(), msg.value);
    }

    modifier onlyGovernance() {
        require(_msgSender() == roleManager.governance(), "Passport: CALLER_NO_GOVERNANCE");
        _;
    }

    // Setters
    /**
     * @dev Set Role Manager contract address
     * Accessible by only `owner`
     * `_roleManager` must not be zero address
     */
    function setRoleManager(address _roleManager) external onlyOwner {
        require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
        roleManager = IRoleManager(_roleManager);
    }

    /**
     * @dev Set `feeTreasury` address
     * Accessible by only Sapien governance
     * `_feeTreasury` must not be zero address
     */
    function setFeeTreasury(address _feeTreasury) external onlyGovernance {
        require(_feeTreasury != address(0), "Passport: FEE_TREASURY_ADDRESS_INVALID");
        feeTreasury = _feeTreasury;
    }

    /**
     * @dev Set `maxPurchase` address
     * Accessible by only Sapien governance
     * `_maxPurchase` must not be zero
     */
    function setMaxPurchase(uint16 _maxPurchase) external onlyGovernance {
        require(_maxPurchase > 0, "Passport: MAX_PURCHASE_INVALID");
        maxPurchase = _maxPurchase;
    }

    /**
     * @dev Set `firstPriceETH` address
     * Accessible by only Sapien governance
     * `_firstPriceETH` must not be zero
     */
    function setFirstPriceETH(uint16 _firstPriceETH) external onlyGovernance {
        require(_firstPriceETH > 0, "Passport: FIRST_PRICE_INVALID");
        firstPriceETH = _firstPriceETH;
    }

    /**
     * @dev Set `feeBps` address
     * Accessible by only Sapien governance
     * `_feeBps` must not be zero
     */
    function setFee(uint16 _feeBps) external onlyGovernance {
        require(_feeBps > 0, "Passport: FEE_INVALID");
        feeBps = _feeBps;
    }

    /**
     * @dev Set `royaltyFeeBps` address
     * Accessible by only Sapien governance
     * `_royaltyFeeBps` must not be zero
     */
    function setRoyaltyFee(uint16 _royaltyFeeBps) external onlyGovernance {
        require(_royaltyFeeBps > 0, "Passport: ROYALTY_FEE_INVALID");
        royaltyFeeBps = _royaltyFeeBps;
    }

    /**
     * @dev Set token URI
     * Accessible by only Sapien governance
     */
    function setTokenURI(
        uint256 _tokenID,
        string memory _tokenURI
    ) external onlyGovernance {
        super._setTokenURI(_tokenID, _tokenURI);
    }

    /**
     * @dev Sign the passport
     * Signed passports are not for sale
     * Accessible by only Sapien governance
     * `_tokenID` must exist
     */
    function sign(uint256 _tokenID) external onlyGovernance {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        passports[_tokenID].isSigned = true;
        passports[_tokenID].isOpenForSale = false;
    }

    /**
     * @dev Set passport price
     * Accessible by only passport owner
     * `_tokenID` must exist
     * `_tokenID` must not be signed
     */
    function setPrice(
        uint256 _tokenID,
        uint256 _price
    ) external {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        require(_msgSender() == ownerOf(_tokenID), "Passport: CALLER_NO_TOKEN_OWNER");
        PassportInfo storage p = passports[_tokenID];
        require(!p.isSigned, "Passport: PASSPORT_SIGNED");
        p.priceETH = _price;

        emit PriceSet(_tokenID, _price);
    }

    // Create
    /**
     * @dev Create new passports
     * Accessible by only Sapien governance
     * Sapien governance become passport `creator`
     */
    function create(string[] memory _uris) external onlyGovernance {
        for (uint256 i = 0; i < _uris.length; i++) {
            uint256 newID = ++passportID;
            super._mint(_msgSender(), newID);
            if (bytes(_uris[i]).length > 0) {
                super._setTokenURI(newID, _uris[i]);
            }
            PassportInfo storage passport = passports[newID];
            passport.creator = _msgSender();
            passport.priceETH = firstPriceETH;
        }
    }

    // Sale
    /**
     * @dev Purchase `_tokenID` at the first sale
     * Transaction should hold enough ETH in `msg.value`
     * Collect fee and send to `feeTreasury`
     * `_tokenID` must exist
     */
    function purchase(uint256 _tokenID) external payable {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        PassportInfo storage p = passports[_tokenID];
        uint256 fee = p.priceETH * feeBps / 10000;
        require(msg.value >= p.priceETH + fee, "Passport: INSUFFICIENT_FUNDS");
        require(firstPurchases[_msgSender()] + 1 <= maxPurchase, "Passport: FIRST_SALE_PURCHASE_LIMIT_EXCEEDED");
        (bool feeSent, ) = payable(feeTreasury).call{value: fee}("");
        require(feeSent, "Passport: FEE_TRANSFER_FAILED");
        firstPurchases[_msgSender()]++;
        p.initialOwner = _msgSender();
        super._transfer(ownerOf(_tokenID), _msgSender(), _tokenID);
    }

    /**
     * @dev Put `_tokenID` up for sale
     * Accessible by only passport owner
     * `_tokenID` must exist
     * Passport must not be signed
     */
    function putForSale(
        uint256 _tokenID,
        uint256 _price
    ) external {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        require(_msgSender() == ownerOf(_tokenID), "Passport: CALLER_NO_TOKEN_OWNER");
        PassportInfo storage p = passports[_tokenID];
        require(!p.isSigned, "Passport: PASSPORT_SIGNED");
        p.isOpenForSale = true;
        p.priceETH = _price;

        emit PutForSale(_tokenID, _price);
    }

    /**
     * @dev Purchase `_tokenID` at the secondary sale
     * Transaction should hold enough ETH in `msg.value`
     * Collect royalty fee and send to first owner
     * Collect fee and send to `feeTreasury`
     * `_tokenID` must exist
     * `_tokenID` must be open for sale
     */
    function purchaseSecondary(uint256 _tokenID) external payable {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        PassportInfo storage p = passports[_tokenID];
        require(p.isOpenForSale, "Passport: PASSPORT_CLOSED_FOR_SALE");
        uint256 royaltyFee = p.priceETH * royaltyFeeBps / 10000;
        uint256 fee = p.priceETH * feeBps / 10000;
        require(msg.value >= p.priceETH + royaltyFee + fee, "Passport: INSUFFICIENT_FUNDS");
        (bool royaltyFeeSent, ) = payable(p.initialOwner).call{value: royaltyFee}("");
        require(royaltyFeeSent, "Passport: ROYALTY_FEE_TRANSFER_FAILED");
        (bool feeSent, ) = payable(feeTreasury).call{value: fee}("");
        require(feeSent, "Passport: FEE_TRANSFER_FAILED");
        (bool priceSent, ) = payable(ownerOf(_tokenID)).call{value: p.priceETH}("");
        require(priceSent, "Passport: PRICE_TRANSFER_FAILED");

        p.isOpenForSale = false;
        super._transfer(ownerOf(_tokenID), _msgSender(), _tokenID);
    }

    /**
     * @dev Signed passports are not transferable
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenID
    ) internal override {
        require(!passports[_tokenID].isSigned, "Passport: SIGNED_PASSPORT_NOT_TRANSFERABLE");
    }
}
