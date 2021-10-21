// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IPassport.sol";

contract PassportSale is Ownable {
  using SafeERC20 for IERC20;
  // Role Manager contract address
  IRoleManager public roleManager;
  // Passport contract address
  IPassport public passContract;
  // Wrapped ETH token address
  IERC20 public weth;
  // SPN token address
  IERC20 public spn;
  // Royalty fee in BPS
  uint16 public royaltyFeeBps = 500;
  // Public sale start date, 11/19/2021
  uint256 public saleStartDate = 1637280000;

  // Passport ID => passport info
  mapping(uint256 => PassportSaleInfo) public passportSales;

  struct PassportSaleInfo {
    uint256 priceETH;
    uint256 priceSPN;
    bool isOpenForSale;
  }

  event LogOpenForSale(uint256 tokenID, uint256 price);
  event LogCloseForSale(uint256 indexed tokenID);
  event LogPriceSet(uint256 indexed tokenID, uint256 price);
  event LogPurchase(uint256 tokenID, address seller, address buyer, uint256 price);
  event LogSweep(address token, address to);

  constructor(
    IRoleManager _roleManager,
    IPassport _passContract,
    IERC20 _weth,
    IERC20 _spn
  ) {
    require(address(_roleManager) != address(0) && address(_passContract) != address(0) && address(_weth) != address(0) && address(_spn) != address(0), "PassportSale: ADDRESS_INVALID");
    roleManager = _roleManager;
    passContract = _passContract;
    weth = _weth;
    spn = _spn;
  }

  modifier onlyGovernance() {
    require(_msgSender() == roleManager.governance(), "PassportSale: CALLER_NO_GOVERNANCE");
    _;
  }

  /**
    * @dev Set `royaltyFeeBps`
    * Accessible by only Sapien governance
    * `_royaltyFeeBps` must not be zero
    */
  function setRoyaltyFee(uint16 _royaltyFeeBps) external onlyGovernance {
    require(_royaltyFeeBps > 0, "PassportSale: ROYALTY_FEE_INVALID");
    royaltyFeeBps = _royaltyFeeBps;
  }

  /**
    * @dev Set `saleStartDate`
    * Accessible by only Sapien governance
    * `saleStartDate` must be greater than current timestamp
    */
  function setSaleStartDate(uint256 _saleStartDate) external onlyGovernance {
    require(_saleStartDate > block.timestamp, "PassportSale: SALE_START_DATE_INVALID");
    saleStartDate = _saleStartDate;
  }

  /**
    * @dev Set passport price in ETH
    * Accessible by only passport owner
    * `_tokenID` must exist
    * `_tokenID` must not be signed
    */
  function setPriceETH(
    uint256 _tokenID,
    uint256 _price
  ) public {
    require(_msgSender() == passContract.ownerOf(_tokenID), "PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID");
    (, bool signed) = passContract.passports(_tokenID);
    require(!signed, "PassportSale: PASSPORT_SIGNED");
    passportSales[_tokenID].priceETH = _price;

    emit LogPriceSet(_tokenID, _price);
  }

  /**
    * @dev Close `_tokenID` for sale
    * Accessible by only passport owner
    * `_tokenID` must exist
    * `_tokenID` must not be signed
    */
  function closeForSale(
    uint256 _tokenID
  ) public {
    require(_msgSender() == passContract.ownerOf(_tokenID), "PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID");
    passportSales[_tokenID].isOpenForSale = false;

    emit LogCloseForSale(_tokenID);
  }

  /**
    * @dev Open `_tokenID` for sale
    * Accessible by only passport owner
    * `_tokenID` must exist
    * Passport must not be signed
    */
  function openForSale(
    uint256 _tokenID,
    uint256 _price
  ) external {
    require(block.timestamp >= saleStartDate, "PassportSale: SALE_NOT_STARTED");
    require(_msgSender() == passContract.ownerOf(_tokenID), "PassportSale: CALLER_NO_TOKEN_OWNER");
    (, bool isSigned) = passContract.passports(_tokenID);
    require(!isSigned, "PassportSale: PASSPORT_SIGNED");
    PassportSaleInfo storage pSale = passportSales[_tokenID];
    pSale.isOpenForSale = true;
    pSale.priceETH = _price;

    emit LogOpenForSale(_tokenID, _price);
  }

  /**
    * @dev Purchase `_tokenID`
    * Collect royalty fee and send to passport creator
    * `_tokenID` must exist
    * `_tokenID` must be open for sale
    */
  function purchase(uint256 _tokenID) external {
    require(block.timestamp >= saleStartDate, "PassportSale: SALE_NOT_STARTED");
    address passOwner = passContract.ownerOf(_tokenID);
    require(passOwner != address(0), "PassportSale: PASSPORT_ID_INVALID");
    require(passOwner != _msgSender(), "PassportSale: NO_SELF_PURCHASE");
    // (address creator, uint256 price, , bool isOpenForSale) = passContract.passports(_tokenID);
    (address creator, ) = passContract.passports(_tokenID);
    PassportSaleInfo storage pSale = passportSales[_tokenID];
    uint256 price = pSale.priceETH;
    bool isOpenForSale = pSale.isOpenForSale;
    require(isOpenForSale, "PassportSale: PASSPORT_CLOSED_FOR_SALE");
    uint256 royaltyFee = price * royaltyFeeBps / 10000;
    weth.safeTransferFrom(_msgSender(), creator, royaltyFee);
    weth.safeTransferFrom(_msgSender(), passOwner, price - royaltyFee);
    passContract.safeTransferFrom(passOwner, _msgSender(), _tokenID);
    pSale.isOpenForSale = false;

    emit LogPurchase(_tokenID, passOwner, _msgSender(), price);
  }

  function sweep(address _token, address _to) external onlyGovernance {
    require(_token != address(0), "PassportSale: TOKEN_ADDRESS_INVALID");
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(_to, amount);

    emit LogSweep(_token, _to);
  }
}
