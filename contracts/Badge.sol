// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBadge.sol";
import "./ERC1155Tradable.sol";
import "./TribeToken.sol";

contract Badge is ERC1155Tradable, IBadge {
    using SafeMath for uint256;

    struct BadgeProp {
        uint256 tribeId;
        uint256 price;
        string uri;
    }

    mapping(uint256 => BadgeProp) _badgeProps;

    constructor()
        ERC1155Tradable("https://sapien.network/api/badge")
    { }

    /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        uint256 _tribeId,
        uint256 _price,
        string calldata _uri,
        bytes calldata _data
    )
        public
        virtual
        override
        returns (uint256)
    {
        uint256 id = super.create(_initialOwner, _initialSupply, _uri, _data);
        BadgeProp storage badgeProp = _badgeProps[id];
        if (bytes(_uri).length > 0) {
            badgeProp.tribeId = _tribeId;
            badgeProp.price = _price;
            badgeProp.uri = _uri;
        }
        return id;
    }
}
