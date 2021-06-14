// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISapienPlatformSPN.sol";
import "./ERC1155Tradable.sol";

contract SapienPlatformSPN is ERC1155Tradable, ISapienPlatformSPN {
    using SafeMath for uint256;

    constructor()
        ERC1155Tradable("https://sapien.network/api/sapien-erc1155")
    { }
}
