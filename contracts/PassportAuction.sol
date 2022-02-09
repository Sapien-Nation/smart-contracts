// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPassport.sol";
import "./interfaces/IRoleManager.sol";

contract PassportAuction is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
  using Address for address;
  using SafeERC20 for IERC20;

  // Passport contract address
  IPassport public passContract;
  // Role Manager contract address
  IRoleManager public roleManager;
  // SPN token address
  IERC20 public spn;
  // Basis Point
  uint16 public royaltyFee = 500;
  // Maximum auction duration
  uint256 public maxDuration = 183 days;

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
  // Passport id => bidder address => bid info id
  mapping(uint256 => mapping(address => uint256)) public bidIds;
  // wallet address => SPN amount available for claim
  mapping(address => uint256) public claimables;

  event LogAuctionCreate(uint256 indexed tokenID, address indexed owner, uint256 floorPrice);
  event LogAuctionDelete(uint256 indexed tokenID, address indexed owner);
  event LogAuctionEnd(uint256 indexed tokenID, address indexed winner);
  event LogBidPlace(uint256 indexed tokenID, address indexed bidder, uint256 bidAmount);
  event LogBidCancel(uint256 indexed tokenID, address indexed bidder);
  event LogSweep(address to, uint256 amount);
  event LogClaim(address to, uint256 amount);

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
    * @dev Override {IERC721Receiver-onERC721Received}
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
    * @dev Set auction max duration period in seconds
    * Accessible by only `owner`
    * `_maxDuration` must not be zero
    */
  function setMaxDuration(uint256 _maxDuration) external onlyGovernance {
    require(_maxDuration > 0, "PassportAuction: MAX_DURATION_INVALID");
    maxDuration = _maxDuration;
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
    * @dev Set royalty fee
    * Accessible by only governance
    * `_royaltyFee` must be less than 1000
    */
  function setRoyaltyFee(uint16 _royaltyFee) external onlyGovernance {
    require(_royaltyFee <= 1000, "PassportAuction: ROYALTY_FEE_INVALID");
    royaltyFee = _royaltyFee;
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
    require(!msg.sender.isContract(), "PassportAuction: CALLER_CONTRACT_ACCOUNT");
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
    require(_endTime > _startTime, "PassportAuction: END_TIME_INVALID");
    require(_startTime + maxDuration >= _endTime, "PassportAuction: MAX_DURATION_EXCEEDED");
    auctions[_tokenID] = AuctionInfo({
      owner: _tokenOwner,
      floorPrice: _floorPrice,
      startTime: _startTime,
      endTime: _endTime
    });

    if (bids[_tokenID].length != 0) {
      delete bids[_tokenID];
    }
    // Push first bid info empty
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
    require(!msg.sender.isContract(), "PassportAuction: CALLER_CONTRACT_ACCOUNT");
    require(msg.sender != auction.owner, "PassportAuction: SELF_BID_NOT_ALLOWED");
    require(bidIds[_tokenID][msg.sender] == 0, "PassportAuction: CALLER_ALREADY_BID");
    require(_bidAmount >= auction.floorPrice, "PassportAuction: BID_AMOUNT_INVALID");
    bids[_tokenID].push(BidInfo({
      bidder: msg.sender,
      bidAmount: _bidAmount,
      bidTime: block.timestamp
    }));
    bidIds[_tokenID][msg.sender] = bids[_tokenID].length - 1;

    spn.safeTransferFrom(msg.sender, address(this), _bidAmount);

    emit LogBidPlace(_tokenID, msg.sender, _bidAmount);
  }

  /**
    * @dev Cancel bid for `_tokenID`
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
    if (bidID != bidList.length - 1) {
      // never leave hole in array
      bidList[bidID] = bidList[bidList.length - 1];
      bidList.pop();
      // delete bid id
      bidIds[_tokenID][msg.sender] = 0;
      bidIds[_tokenID][bidList[bidID].bidder] = bidID;
    } else {
      // never leave hole in array
      bidList.pop();
      // delete bid id
      bidIds[_tokenID][msg.sender] = 0;
    }

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

    for (uint256 i = 1; i < bidList.length; i++) {
      delete bidIds[_tokenID][bidList[i].bidder];
      // refund
      claimables[bidList[i].bidder] += bidList[i].bidAmount;
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
    require(auction.endTime <= block.timestamp, "PassportAuction: AUCTION_GOING");
    BidInfo[] memory bidList = bids[_tokenID];
    require(_bidID < bidList.length, "PassportAuction: BID_ID_INVALID");
    BidInfo memory bid = bidList[_bidID];
    require(bid.bidder != address(0), "PassportAuction: BID_ID_INVALID");

    for (uint256 i = 1; i < bidList.length; i++) {
      delete bidIds[_tokenID][bidList[i].bidder];
      if (i != _bidID) {
        // refund
        claimables[bidList[i].bidder] += bidList[i].bidAmount;
      }
    }

    // delete bid list
    delete bids[_tokenID];
    // delete auction
    delete auctions[_tokenID];

    spn.safeTransfer(auction.owner, bid.bidAmount * (10000 - royaltyFee) / 10000);
    passContract.safeTransferFrom(address(this), bid.bidder, _tokenID);

    emit LogAuctionEnd(_tokenID, bid.bidder);
  }

  /**
    * @dev Claim funds from auction contract
   */
  function claim(uint256 _amount) external nonReentrant {
    uint256 availAmount = claimables[msg.sender];
    require(availAmount >= _amount, "PassportAuction: INSUFFICIENT_FUNDS");
    claimables[msg.sender] = availAmount - _amount;
    spn.safeTransfer(msg.sender, _amount);

    emit LogClaim(msg.sender, _amount);
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
   * @dev Transfer `_amount` to `_to`
   * Accessible by only Sapien governance
   */
  function sweep(
    address _to,
    uint256 _amount
  ) external onlyGovernance {
    require(_to != address(0), "PassportAuction: RECEIVER_ADDRESS_INVALID");
    require(_amount != 0, "PassportAuction: SWEEP_AMOUNT_INVALID");
    spn.safeTransfer(_to, _amount);

    emit LogSweep(_to, _amount);
  }

  /**
    * @dev Return bid list for `_tokenID`
   */
  function getBidList(uint256 _tokenID) external view returns(BidInfo[] memory) {
    return bids[_tokenID];
  }
}
