// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPassport is IERC721Upgradeable {
    function passports(uint256 _id) external view returns (address creator, uint256 priceETH, bool isSigned, bool isOpenForSale);

    function setRoleManager(address _roleManager) external;

    function setMaxPurchase(uint16 _maxPurchase) external;

    function setTokenURI(uint256 _tokenID, string memory _tokenURI) external;

    function sign(uint256 _tokenID) external;

    function setOpenForSale(uint256 _tokenID, bool _isOpenForSale) external;

    function setPrice(uint256 _tokenID, uint256 _price) external;

    function mint(address[] memory _accounts, string[] memory _uris, uint256[] memory _prices ) external;
}
