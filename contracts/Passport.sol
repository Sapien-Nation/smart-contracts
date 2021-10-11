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
    uint16 public maxPurchase = 5;
    // Passport token price in ETH
    uint256 public firstPriceETH = 0.25 ether;
    // Fee in BPS
    uint16 public feeBps = 500;

    struct PassportInfo {
        address creator;
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
    function setRoleManager(address _roleManager) external onlyOwner {
        require(_roleManager != address(0), "Passport: ROLE_MANAGER_ADDRESS_INVALID");
        roleManager = IRoleManager(_roleManager);
    }

    function setFeeTreasury(address _feeTreasury) external onlyGovernance {
        require(_feeTreasury != address(0), "Passport: FEE_TREASURY_ADDRESS_INVALID");
        feeTreasury = _feeTreasury;
    }

    // TODO check
    function setMaxPurchase(uint16 _maxPurchase) external onlyGovernance {
        require(_maxPurchase > 0, "Passport: MAX_PURCHASE_INVALID");
        maxPurchase = _maxPurchase;
    }

    function setFirstPriceETH(uint16 _firstPriceETH) external onlyGovernance {
        require(_firstPriceETH > 0, "Passport: FIRST_PRICE_INVALID");
        firstPriceETH = _firstPriceETH;
    }

    function setFee(uint16 _feeBps) external onlyGovernance {
        require(_feeBps > 0, "Passport: FEE_INVALID");
        feeBps = _feeBps;
    }

    function setTokenURI(
        uint256 _tokenID,
        string memory _tokenURI
    ) external onlyGovernance {
        super._setTokenURI(_tokenID, _tokenURI);
    }

    function sign(uint256 _tokenID) external onlyGovernance {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        passports[_tokenID].isSigned = true;
        passports[_tokenID].isOpenForSale = false;
    }

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
    function purchase(uint256 _tokenID) external payable {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        PassportInfo memory p = passports[_tokenID];
        uint256 fee = p.priceETH * feeBps / 10000;
        require(msg.value == fee + p.priceETH, "Passport: INSUFFICIENT_FUNDS");
        require(firstPurchases[_msgSender()] + 1 <= maxPurchase, "Passport: FIRST_SALE_PURCHASE_LIMIT_EXCEEDED");
        (bool success, ) = payable(feeTreasury).call{value: fee}("");
        require(success, "Passport: FEE_TRANSFER_FAILED");
        firstPurchases[_msgSender()]++;
        super._transfer(ownerOf(_tokenID), _msgSender(), _tokenID);
    }

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

    function purchaseSecondary(uint256 _tokenID) external payable {
        require(_exists(_tokenID), "Passport: PASSPORT_ID_INVALID");
        PassportInfo storage p = passports[_tokenID];
        require(p.isOpenForSale, "Passport: PASSPORT_CLOSED_FOR_SALE");
        uint256 fee = p.priceETH * feeBps / 10000;
        require(msg.value == fee + p.priceETH, "Passport: INSUFFICIENT_FUNDS");
        (bool success, ) = payable(feeTreasury).call{value: fee}("");
        require(success, "Passport: FEE_TRANSFER_FAILED");
        (bool success1, ) = payable(ownerOf(_tokenID)).call{value: p.priceETH}("");
        require(success1, "Passport: PRICE_TRANSFER_FAILED");

        p.isOpenForSale = false;
        super._transfer(ownerOf(_tokenID), _msgSender(), _tokenID);
    }
}
