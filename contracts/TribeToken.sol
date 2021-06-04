// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155Tradable.sol";

contract TribeToken is ERC1155Tradable {
    using SafeMath for uint256;

    constructor() ERC1155Tradable("https://sapien.com/api/tribe-erc1155") {}
}
