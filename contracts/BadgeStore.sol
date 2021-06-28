// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Badge.sol";

contract BadgeStore is Badge {
    using SafeMath for uint256;

    IERC20 spn;

    address revenueAddress;

    mapping(uint256 => uint256) private _badgePrices;

    constructor(
        IERC20 _spn,
        address _revenueAddress
    )
        Badge("Sapien Badge", "0.3.0")
    {
        spn = _spn;
        revenueAddress = _revenueAddress;
    }

    function setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        public
        virtual
        onlyOwner()
        existentTokenOnly(_badgeId)
    {
        require(_price > 0, "TribeStore#setBadgePrice: ZERO_AMOUNT");
        _badgePrices[_badgeId] = _price;
    }

    function getBadgePrice(
        uint256 _badgeId
    )
        public
        virtual
        existentTokenOnly(_badgeId)
        returns (uint256)
    {
        return _badgePrices[_badgeId];
    }

    function purchase(
        address _account,
        uint256 _badgeId,
        uint256 _amount
    )
        public
        virtual
        existentTokenOnly(_badgeId)
        onlyOwner()
    {
        require(_account != address(0), "TribeStore#purchase: ZERO_ADDRESS");
        require(spn.balanceOf(_account) >= _badgePrices[_badgeId].mul(_amount), "TribeStore#purchase: INSUFFICIENT_BALANCE");
        super.mint(_account, _badgeId, _amount, "");
        spn.transferFrom(_account, revenueAddress, _amount);
    }
}
