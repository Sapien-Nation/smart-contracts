// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPassport.sol";
import "./interfaces/IRoleManager.sol";

contract PassportAuction is Ownable, Pausable, ReentrancyGuard {
  using Address for address;
  using SafeERC20 for IERC20;

  // Passport contract address
  IPassport public passContract;
  // Role Manager contract address
  IRoleManager public roleManager;
  // SPN token address
  IERC20 public spn;

  struct AuctionInfo {
    address owner;
    uint256 floorPrice;
    uint256 startTime;
    uint256 endTime;
  }

  struct BidInfo {
    address bidder;
    uint256 bidAmount;
    uint256 bidTime;
  }

  // Passport id => auction info
  mapping(uint256 => AuctionInfo) public auctions;
  // Passport id => bid info (first element is empty)
  mapping(uint256 => BidInfo[]) public bids;
  // Passport id => bidder address => bid info index
  mapping(uint256 => mapping(address => uint256)) public bidIds;

  event LogAuctionCreate(uint256 indexed tokenID, address indexed owner, uint256 floorPrice);
  event LogAuctionDelete(uint256 indexed tokenID, address indexed owner);
  event LogAuctionEnd(uint256 indexed tokenID, address indexed bidder);
  event LogBidPlace(uint256 indexed tokenID, address indexed bidder, uint256 bidAmount);
  event LogBidCancel(uint256 indexed tokenID, address indexed bidder);

  constructor(
    IRoleManager _roleManager,
    IPassport _passContract,
    IERC20 _spn
  ) {
    require(address(_roleManager) != address(0), "PassportAuction: ROLE_MANAGER_ADDRESS_INVALID");
    require(address(_passContract) != address(0), "PassportAuction: PASSPORT_ADDRESS_INVALID");
    require(address(_spn) != address(0), "PassportAuction: SPN_ADDRESS_INVALID");
    roleManager = _roleManager;
    passContract = _passContract;
    spn = _spn;
  }

  modifier onlyGovernance() {
    require(msg.sender == roleManager.governance(), "PassportAuction: CALLER_NO_GOVERNANCE");
    _;
  }

  /**
    * @dev Set Role Manager contract address
    * Accessible by only `owner`
    * `_roleManager` must not be zero address
    */
  function setRoleManager(address _roleManager) external onlyOwner {
    require(_roleManager != address(0), "PassportAuction: ROLE_MANAGER_ADDRESS_INVALID");
    roleManager = IRoleManager(_roleManager);
  }

  /**
    * @dev Create auction for `_tokenID`
    * `_startTime` and `_endTime` must be valid
    */
  function createAuction(
    uint256 _tokenID,
    uint256 _floorPrice,
    uint256 _startTime,
    uint256 _endTime
  ) external whenNotPaused nonReentrant {
    require(passContract.ownerOf(_tokenID) == msg.sender, "PassportAuction: CALLER_NO_TOKEN_OWNER");
    _createAuction(_tokenID, msg.sender, _floorPrice, _startTime, _endTime);
  }

  function _createAuction(
    uint256 _tokenID,
    address _tokenOwner,
    uint256 _floorPrice,
    uint256 _startTime,
    uint256 _endTime
  ) private {
    // check if auction already exists
    require(auctions[_tokenID].owner == address(0), "PassportAuction: AUCTION_ALREADY_CREATED");
    require(_startTime >= block.timestamp, "PassportAuction: START_TIME_INVALID");
    // TODO check minimum auction duration
    require(_endTime > _startTime, "PassportAuction: END_TIME_INVALID");
    auctions[_tokenID] = AuctionInfo({
      owner: _tokenOwner,
      floorPrice: _floorPrice,
      startTime: _startTime,
      endTime: _endTime
    });

    if (bids[_tokenID].length != 0) {
      delete bids[_tokenID];
    }

    bids[_tokenID].push(BidInfo({
      bidder: address(0),
      bidAmount: 0,
      bidTime: 0
    }));

    // lock token in the contract
    passContract.safeTransferFrom(_tokenOwner, address(this), _tokenID);

    emit LogAuctionCreate(_tokenID, _tokenOwner, _floorPrice);
  }

  /**
    * @dev Place bid for `_tokenID`
    * `_tokenID` must be auctioned
   */
  function placeBid(
    uint256 _tokenID,
    uint256 _bidAmount
  ) external whenNotPaused nonReentrant {
    AuctionInfo memory auction = auctions[_tokenID];
    require(auction.owner != address(0), "PassportAuction: AUCTION_NOT_EXIST");
    require(auction.endTime > block.timestamp, "PassportAuction: AUCTION_ENDED");
    require(msg.sender != auction.owner, "PassportAuction: SELF_BID_NOT_ALLOWED");
    require(bidIds[_tokenID][msg.sender] == 0, "PassportAuction: CALLER_ALREADY_BID");
    require(_bidAmount >= auction.floorPrice, "PassportAuction: BID_AMOUNT_INVALID");
    bids[_tokenID].push(BidInfo({
      bidder: msg.sender,
      bidAmount: _bidAmount,
      bidTime: block.timestamp
    }));
    spn.safeTransferFrom(msg.sender, address(this), _bidAmount);

    emit LogBidPlace(_tokenID, msg.sender, _bidAmount);
  }

  /**
    * @dev Place bid for `_tokenID`
    * `_tokenID` must be auctioned
   */
  function cancelBid(uint256 _tokenID) external nonReentrant {
    AuctionInfo memory auction = auctions[_tokenID];
    require(auction.owner != address(0), "PassportAuction: AUCTION_NOT_EXIST");
    require(auction.endTime > block.timestamp, "PassportAuction: AUCTION_ENDED");
    uint256 bidID = bidIds[_tokenID][msg.sender];
    require(bidID != 0, "PassportAuction: CALLER_NO_BID");
    BidInfo[] storage bidList = bids[_tokenID];
    uint256 bidAmount = bidList[bidID].bidAmount;
    // never leave hole in array
    bidList[bidID] = bidList[bidList.length - 1];
    bidList.pop();
    bidIds[_tokenID][msg.sender] = 0;
    // refund
    spn.safeTransfer(msg.sender, bidAmount);

    emit LogBidCancel(_tokenID, msg.sender);
  }

  /**
    * @dev Cancel auction for `_tokenID`
    * `_tokenID` must be auctioned
   */
  function cancelAuction(uint256 _tokenID) external nonReentrant {
    AuctionInfo memory auction = auctions[_tokenID];
    require(auction.owner == msg.sender, "PassportAuction: CALLER_NO_AUCTION_OWNER__TOKEN_ID_INVALID");
    require(auction.endTime > block.timestamp, "PassportAuction: AUCTION_ENDED");
    // delete bid ids
    BidInfo[] memory bidList = bids[_tokenID];

    for (uint256 i = 0; i < bidList.length; i++) {
      delete bidIds[_tokenID][bidList[i].bidder];
      // refund
      // TODO check pull-over-push pattern
      spn.safeTransfer(bidList[i].bidder, bidList[i].bidAmount);
    }

    // delete bid list
    delete bids[_tokenID];
    // delete auction
    delete auctions[_tokenID];
    // return passport
    passContract.safeTransferFrom(address(this), auction.owner, _tokenID);

    emit LogAuctionDelete(_tokenID, auction.owner);
  }

  /**
    * @dev End auction for `_tokenID`
    * `_tokenID` must be auctioned
    * token owner must pick winning bid
    */
  function endAuction(
    uint256 _tokenID,
    uint256 _bidID
  ) external nonReentrant {
    AuctionInfo memory auction = auctions[_tokenID];
    require(auction.owner == msg.sender, "PassportAuction: CALLER_NO_AUCTION_OWNER__TOKEN_ID_INVALID");
    require(auction.endTime > block.timestamp, "PassportAuction: AUCTION_ENDED");
    BidInfo[] memory bidList = bids[_tokenID];
    require(_bidID < bidList.length, "PassportAuction: BID_ID_INVALID");
    BidInfo memory bid = bidList[_bidID];
    require(bid.bidder != address(0), "PassportAuction: BID_ID_INVALID");

    for (uint256 i = 0; i < bidList.length; i++) {
      delete bidIds[_tokenID][bidList[i].bidder];
      if (i != _bidID) {
        // refund
        // TODO check pull-over-push pattern
        spn.safeTransfer(bidList[i].bidder, bidList[i].bidAmount);
      }
    }

    // delete bid list
    delete bids[_tokenID];
    // delete auction
    delete auctions[_tokenID];

    spn.safeTransfer(auction.owner, bid.bidAmount);
    passContract.safeTransferFrom(address(this), bid.bidder, _tokenID);

    emit LogAuctionEnd(_tokenID, bid.bidder);
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
}
