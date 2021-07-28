// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC1155Tradable.sol";
import "./interfaces/IBadgeStore.sol";

contract BadgeStore is ERC1155Tradable, ReentrancyGuard, IBadgeStore {
    using SafeMath for uint256;

    struct BadgeProp {
        address admin;
        uint256 price; // priced in SPN
    }

    // SPN token address
    IERC20 public spn;
    // Address that collects platform fee.
    address public revenueAddress;
    // Platform governance account.
    address public governance;

    uint256 public platformFee = 5; // 100 percentage

    mapping(uint256 => BadgeProp) private _badgeProps;

    event BadgeCreate(address indexed admin, uint256 badgeId);

    event BadgePurchase(address indexed recipient, uint256 badgeId, uint256 amount);

    event BadgeGrant(address indexed recipient, uint256 badgeId, uint256 amount);

    constructor(
        string memory _name,
        string memory _uri,
        string memory _version,
        IERC20 _spn,
        address _revenueAddress,
        address _governance
    )
        ERC1155Tradable(_name, _uri, _version)
    {
        spn = _spn;
        revenueAddress = _revenueAddress;
        governance = _governance;
    }

    /**
     * @dev Return price of badge token.
     */
    function badgePrice(
        uint256 _badgeId
    )
        public
        virtual
        override
        view
        existentTokenOnly(_badgeId)
        returns (uint256)
    {
        return _badgeProps[_badgeId].price;
    }

    /**
     * @dev Return admin address of badge token.
     */
    function badgeAdminAddress(
        uint256 _badgeId
    )
        public
        virtual
        override
        view
        existentTokenOnly(_badgeId)
        returns (address)
    {
        return _badgeProps[_badgeId].admin;
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
     * @dev Set platform governance address.
     */
    function setGovernance(
        address _governance
    )
        external
        override
        onlyOwner
    {
        require(_governance != address(0), "BadgeStore#setGovernance: INVALID_ADDRESS");
        governance = _governance;
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
    {
        require(msgSender() == badgeAdminAddress(_badgeId), "BadgeStore#setBadgePrice: CALLER_NO_BADGE_ADMIN");
        _setBadgePrice(_badgeId, _price);
    }

    /**
     * @dev Set platform fee.
     */
    function setPlatformFee(
        uint256 _platformFee
    )
        external
        virtual
        override
        onlyOwner
    {
        platformFee = _platformFee;
    }

    /**
     * @dev Return admin address of badge token.
     */
    function setBadgeAdminAddress(
        address _badgeAdmin,
        uint256 _badgeId
    )
        public
        virtual
        override
        existentTokenOnly(_badgeId)
    {
        require(msgSender() == governance, "BadgeStore#setBadgeAdminAddress: CALLER_NO_GOVERNANCE");
        _setBadgeAdminAddress(_badgeAdmin, _badgeId);
    }

    /**
     * @dev Create new badge type.
     * Accessible only by governance.
     * `_badgeAdmin` cannot be the zero address.
     */
    function createBadge(
        address _badgeAdmin,
        uint256 _price
    )
        external
        virtual
        override
        returns (uint256)
    {
        require(msgSender() == governance, "BadgeStore#createBadge: CALLER_NO_GOVERNANCE");
        uint256 badgeId = _create(_badgeAdmin, 1, "");
        emit BadgeCreate(_badgeAdmin, badgeId);
        _setBadgePrice(badgeId, _price);
        _setBadgeAdminAddress(_badgeAdmin, badgeId);
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
     * @dev Grant badge for free.
     * Accessible only by badge token admin.
     * `_to` cannot be the zero address.
     */
    function grantBadge(
        address _to,
        uint256 _badgeId,
        uint256 _amount
    )
        external
        virtual
        override
        existentTokenOnly(_badgeId)
        nonReentrant
    {
        require(msgSender() == badgeAdminAddress(_badgeId), "BadgeStore#grantBadge: CALLER_NO_BADGE_ADMIN");
        require(_to != address(0), "BadgeStore#grantBadge: INVALID_ADDRESS");
        require(_amount > 0, "BadgeStore#grantBadge: INVALID_AMOUNT");
        _mint(_to, _badgeId, _amount, "");
        emit BadgeGrant(_to, _badgeId, _amount);
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
        if (_badgeProps[_badgeId].price > 0) {
            uint256 spnAmount = _badgeProps[_badgeId].price.mul(_amount);
            uint256 feeAmount = spnAmount.mul(platformFee).div(100);
            require(spn.balanceOf(_account) >= spnAmount, "BadgeStore#_purchaseBadge: INSUFFICIENT_FUNDS");
            spn.transferFrom(_account, revenueAddress, feeAmount);
            spn.transferFrom(_account, badgeAdminAddress(_badgeId), spnAmount.sub(feeAmount));
        }
        _mint(_account, _badgeId, _amount, "");
        emit BadgePurchase(_account, _badgeId, _amount);
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
        _badgeProps[_badgeId].price = _price;
    }

    function _setBadgeAdminAddress(
        address _badgeAdmin,
        uint256 _badgeId
    )
        internal
        virtual
    {
        _badgeProps[_badgeId].admin = _badgeAdmin;
    }
}
