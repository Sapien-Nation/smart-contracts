// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Tradable.sol";

interface IBadgeStore is IERC1155Tradable {
    function getRevenueAddress()
        external
        view
        returns (address);

    function getBadgePrice(
        uint256 _badgeId
    )
        external
        view
        returns (uint256);

    function getFee()
        external
        view
        returns (uint256);

    function setRevenueAddress(
        address _revenueAddress
    )
        external;

    function setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        external;

    function setFee(
        uint256 _fee
    )
        external;

    function createBadge(
        uint256 _price
    )
        external
        returns (uint256);

    function purchaseBadge(
        uint256 _badgeId,
        uint256 _amount
    )
        external;

    function purchaseBadgeBatch(
        uint256[] memory _badgeIds,
        uint256[] memory _amounts
    )
        external;
}
