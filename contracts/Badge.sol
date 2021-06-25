// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBadge.sol";
import "./ERC1155Tradable.sol";
import "./metatx-standard/EIP712MetaTransaction.sol";

contract Badge is ERC1155Tradable, EIP712MetaTransaction {
    using SafeMath for uint256;

    struct BadgeProp {
        string uri;
    }

    mapping(uint256 => BadgeProp) _badgeProps;

    event BadgeCreated(uint256 id, address indexed creator);
    event BadgeMinted(uint256 id, address indexed recipient, uint256 amount);

    constructor(
        string memory _name,
        string memory _version
    )
        ERC1155Tradable("https://sapien.network/api/badge")
        EIP712MetaTransaction(_name, _version)
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
            badgeProp.uri = _uri;
        }

        emit BadgeCreated(id, msgSender());
        return id;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        public
        virtual
        override
        existentTokenOnly(_id)
    {
        super.mint(_to, _id, _amount, _data);
        emit BadgeMinted(_id, _to, _amount);
    }
}
