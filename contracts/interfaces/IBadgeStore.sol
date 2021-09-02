// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Tradable.sol";

interface IBadgeStore is IERC1155Tradable {
    function badgePrice(
        uint256 _badgeId
    )
        external
        view
        returns (uint256);

    function badgeAdmin(
        uint256 _badgeId
    )
        external
        view
        returns (address);

    function setRevenueAddress(
        address _revenueAddress
    )
        external;

    function setGovernance(
        address _governance
    )
        external;

    function setBadgePrice(
        uint256 _badgeId,
        uint256 _price
    )
        external;

    function setPlatformFee(
        uint256 _fee
    )
        external;

    function setBadgeAdmin(
        address _badgeAdmin,
        uint256 _badgeId
    )
        external;

    function createBadge(
        address _badgeAdmin,
        uint256 _price
    )
        external
        returns (uint256);

    function purchaseBadge(
        uint256 _badgeId,
        uint256 _amount
    )
        external;

    function grantBadge(
        address _to,
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
