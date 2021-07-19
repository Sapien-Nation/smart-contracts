// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC1155Tradable.sol";
import "./interfaces/IBadgeStore.sol";

contract BadgeStore is ERC1155Tradable, ReentrancyGuard, IBadgeStore {
    using SafeMath for uint256;

    IERC20 spn;

    address revenueAddress;

    uint256 fee = 5; // 100 percentage

    mapping(uint256 => uint256) private _badgePrices;

    event BadgeCreated(address indexed account, uint256 badgeId);

    event BadgePurchased(address indexed account, uint256 badgeId, uint256 amount);

    constructor(
        string memory _name,
        string memory _uri,
        string memory _version,
        IERC20 _spn,
        address _revenueAddress
    )
        ERC1155Tradable(_name, _uri, _version)
    {
        spn = _spn;
        revenueAddress = _revenueAddress;
    }

    /**
     * @dev Return revenue address.
     */
    function getRevenueAddress()
        external
        view
        override
        returns (address)
    {
        return revenueAddress;
    }

    /**
     * @dev Return price of badge token.
     */
    function getBadgePrice(
        uint256 _badgeId
    )
        external
        virtual
        override
        view
        existentTokenOnly(_badgeId)
        returns (uint256)
    {
        return _badgePrices[_badgeId];
    }

    /**
     * @dev Return platform fee.
     */
    function getFee()
        external
        virtual
        override
        view
        returns (uint256)
    {
        return fee;
    }

    /**
     * @dev Set revenue address.
     */
    function setRevenueAddress(
        address _revenueAddress
    )
        external
        override
        onlyOwner
    {
        require(_revenueAddress != address(0), "BadgeStore#setRevenueAddress: INVALID_ADDRESS");
        revenueAddress = _revenueAddress;
    }

    /**
     * @dev Set price of badge token.
     */
    function setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        external
        override
        virtual
        existentTokenOnly(_badgeId)
        onlyCreator(_badgeId)
    {
        _setBadgePrice(_badgeId, _price);
    }

    /**
     * @dev Set platform fee.
     */
    function setFee(
        uint256 _fee
    )
        external
        virtual
        override
        onlyOwner
    {
        require(_fee > 0, "BadgeStore#setFee: INVALID_FEE");
        fee = _fee;
    }

    /**
     * @dev Create badge.
     * msgSender() becomes badge creator.
     */
    function createBadge(
        uint256 _price
    )
        external
        virtual
        override
        returns (uint256)
    {
        require(_price > 0, "BadgeStore#createBadge: INVALID_PRICE");
        uint256 badgeId = _create(msgSender(), 1, "");
        emit BadgeCreated(msgSender(), badgeId);
        _setBadgePrice(badgeId, _price);
        return badgeId;
    }

    /**
     * @dev Purchase badge token.
     */
    function purchaseBadge(
        uint256 _badgeId,
        uint256 _amount
    )
        external
        virtual
        override
        existentTokenOnly(_badgeId)
        nonReentrant
    {
        require(_amount > 0, "BadgeStore#purchaseBadge: INVALID_AMOUNT");
        _purchaseBadge(msgSender(), _badgeId, _amount);
    }

    /**
     * @dev Batch version of {purchaseBadge}.
     */
    function purchaseBadgeBatch(
        uint256[] memory _badgeIds,
        uint256[] memory _amounts
    )
        external
        virtual
        override
        nonReentrant
    {
        require(_badgeIds.length == _amounts.length, "BadgeStore#purchaseBadgeBatch: PARAMS_LENGTH_MISMATCH");
        for (uint256 i = 0; i < _badgeIds.length; i++) {
            _purchaseBadge(msgSender(), _badgeIds[i], _amounts[i]);
        }
    }

    /**
     * @dev Purchase badge.
     */
    function _purchaseBadge(
        address _account,
        uint256 _badgeId,
        uint256 _amount
    )
        internal
        virtual
    {
        uint256 spnAmount = _badgePrices[_badgeId].mul(_amount);
        uint256 feeAmount = spnAmount.mul(fee).div(100);
        require(spn.balanceOf(_account) >= spnAmount, "BadgeStore#_purchaseBadge: INSUFFICIENT_FUNDS");
        spn.transferFrom(_account, revenueAddress, feeAmount);
        spn.transferFrom(_account, creator(_badgeId), spnAmount.sub(feeAmount));
        _mint(_account, _badgeId, _amount, "");
        emit BadgePurchased(_account, _badgeId, _amount);
    }

    /**
     * @dev Set price of badge token.
     */
    function _setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        internal
        virtual
    {
        require(_price > 0, "BadgeStore#_setBadgePrice: INVALID_PRICE");
        _badgePrices[_badgeId] = _price;
    }
}
