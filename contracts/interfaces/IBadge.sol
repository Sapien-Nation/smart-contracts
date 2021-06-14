// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Tradable.sol";

interface IBadge is IERC1155Tradable {
    /**
    * @dev Creates a new token type.
    */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        uint256 _tribeId,
        uint256 _price,
        string calldata _uri,
        bytes calldata _data
    )
        external
        returns (uint256);
}
