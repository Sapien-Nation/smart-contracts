// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IRoleManager.sol";

contract Passport is OwnableUpgradeable, ERC721URIStorageUpgradeable {
    mapping(uint256 => PassportInfo) public passports;

    uint256 passportID;

    address public feeTreasury;

    IRoleManager roleManager;

    uint8 public maxDeposit;

    uint256 public price;

    enum PassportState {
        BLANK,
        SIGNED
    }

    struct PassportInfo {
        address creator;
        uint256 depositTime;
        PassportState state;
    }

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __Passport_init_unchained();
    }

    function __Passport_init_unchained() internal initializer {
    }

    function purchase(string memory _uri) external {
        uint256 newID = ++passportID;
        super._mint(_msgSender(), newID);
        if (bytes(_uri).length > 0) {
            super._setTokenURI(newID, _uri);
        }
        PassportInfo storage passport = passports[newID];
        passport.creator = _msgSender();
        passport.depositTime = block.timestamp;
    }
}
