// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Badge.sol";

contract BadgeStore is Badge {
    using SafeMath for uint256;

    IERC20 spn;

    address revenueAddress;

    uint256 fee = 5; // 100 percentage

    mapping(uint256 => uint256) private _badgePrices;

    constructor(
        IERC20 _spn,
        address _revenueAddress
    )
        Badge("Sapien Badge", "v3")
    {
        spn = _spn;
        revenueAddress = _revenueAddress;
    }

    function setRevenueAddress(
        address _revenueAddress
    )
        public
        onlyOwner
    {
        require(_revenueAddress != address(0), "BadgeStore#setRevenueAddress: INVALID_ADDRESS");
        revenueAddress = _revenueAddress;
    }

    function getRevenueAddress()
        public
        returns (address)
    {
        return revenueAddress;
    }

    function setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        public
        virtual
        existentTokenOnly(_badgeId)
        onlyCreator(_badgeId)
    {
        require(_price > 0, "TribeStore#setBadgePrice: INVALID_PRICE");
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
        uint256 _badgeId,
        uint256 _amount
    )
        public
        virtual
        existentTokenOnly(_badgeId)
    {
        require(_amount > 0, "TribeStore#purchase: INVALID_AMOUNT");
        uint256 spnAmount = _badgePrices[_badgeId].mul(_amount);
        uint256 feeAmount = spnAmount.mul(fee).div(100);
        require(spn.balanceOf(_msgSender()) >= spnAmount, "TribeStore#purchase: INSUFFICIENT_FUNDS");
        super.mint(_msgSender(), _badgeId, _amount, "");
        spn.transferFrom(_msgSender(), revenueAddress, feeAmount);
        spn.transferFrom(_msgSender(), getCreator(_badgeId), spnAmount.sub(feeAmount));
    }
}
