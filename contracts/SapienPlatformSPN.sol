// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./lib/TransactionLib.sol";

contract SapienPlatformSPN is ERC1155, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(string memory uri_) ERC1155(uri_) {}

    // Using a split bit id
    // Storing type in lower 128 bits
    uint256 constant TYPE_MASK = uint128(0xFFFFFFFFFFFFFFFF);

    // and non-fungible index in upper 128 bits
    uint256 constant NF_INDEX_MASK = uint256(uint128(0xFFFFFFFFFFFFFFFF)) << 128;

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    // mapping from token id to owner of token
    mapping(uint256 => address) owners;

    // mapping from address to set of token ids owned by holder
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // mapping from id to characteristics of nonFungible
    mapping(uint256 => TransactionLib.NonFungible) private _nonFungibles;

    // mapping from nf base to number of tokens
    mapping(uint256 => uint128) private _nfCounts;

    uint256 public nonce;

    event Created(
        uint256 id,
        bool nonFungible,
        uint256 initialSupply,
        bytes data
    );

    event Minted(
        uint256 id,
        address receiver,
        uint256 amount
    );

    event Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes data
    );

    event BatchReceived(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data
    );

    // Only to make code clearer. Should not be functions
    function isNonFungible(
        uint256 _id
    )
        public
        pure
        returns (bool)
    {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(
        uint256 _id
    )
        public
        pure
        returns (bool)
    {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(
        uint256 _id
    )
        public
        pure
        returns (uint256)
    {
        return _id & NF_INDEX_MASK;
    }

    function getType(
        uint256 _id
    )
        public
        pure
        returns (uint256)
    {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(
        uint256 _id
    )
        public
        pure
        returns (bool)
    {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(
        uint256 _id
    )
        public
        pure
        returns (bool)
    {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(
        uint256 _id
    )
        public
        view
        returns (address)
    {
        return owners[_id];
    }



    function nextId(
        bool nonFungible
    )
        internal
        returns(uint256)
    {
        if (nonFungible) {
            return TYPE_NF_BIT ^ (nonce++);
        }
        return nonce++;
    }

    function create(
        bool nonFungible,
        uint256 initialSupply,
        bytes calldata data
    )
        public
        onlyOwner
        returns(uint256 _id)
    {
        _id = nextId(nonFungible);
        if (!nonFungible) {
            super._mint(_msgSender(), _id, initialSupply, data);
        }

        owners[_id] = _msgSender();
        _holderTokens[_msgSender()].add(_id);

        emit Created(_id, nonFungible, initialSupply, data);
    }

    function nextNF(
        uint256 id
    )
        internal
        returns(uint256)
    {
        return TYPE_NF_BIT ^ uint256(_nfCounts[getType(id)]++);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    )
        public
        returns (uint256 newId)
    {
        require(_msgSender() == owner() || _msgSender() == address(this));

        TransactionLib.NonFungible memory nf = TransactionLib.nonFungibleFromBytes(0,data);

        uint256 _type = id;
        newId = id;

        if (isNonFungible(id)) {
            _type = getType(id);
            newId = nextNF(id);
            _nonFungibles[newId] = nf;
            owners[newId] = to;
        }

        _holderTokens[to].add(id);
        super._mint(to, _type, amount, data);
        emit Minted(id, to, amount);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        uint256 _id = id;

        if (isNonFungible(id)) {
            require(owners[id] == from);
            owners[id] = to;
            _id = getType(id);
        }

        super.safeTransferFrom(from,to,_id,amount,data);
    }
}
