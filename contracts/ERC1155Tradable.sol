// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IERC1155Tradable.sol";
import "./metatx-standard/EIP712MetaTransaction.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
 like exists() and totalSupply()
 */
contract ERC1155Tradable is ERC1155, Ownable, EIP712MetaTransaction, IERC1155Tradable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenID;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _tokenSupply;

    constructor(
        string memory _name,
        string memory _uri,
        string memory _version
    )
        ERC1155(_uri)
        EIP712MetaTransaction(_name, _version)
    { }

    /**
     * @dev Require msgSender() to be the creator of the token id.
     */
    modifier onlyCreator(
        uint256 _id
    )
    {
        require(_creators[_id] == msgSender(), "ERC1155Tradable#onlyCreator: CALLER_NO_CREATOR");
        _;
    }

    /**
     * @dev Require msgSender() to own at least 1 token.
     */
    modifier tokenOwnerOnly(
        uint256 _id
    )
    {
        require(balanceOf(msgSender(), _id) > 0, "ERC1155Tradable#tokenOwnerOnly: CALLER_NO_TOKEN_OWNER");
        _;
    }

    /**
     * @dev Require token is already minted.
     */
    modifier existentTokenOnly(
        uint256 _id
    )
    {
        require(exists(_id), "ERC1155Tradable#existentTokenOnly: NON_EXISTENT_TOKEN");
        _;
    }

    /**
     * @dev See {IERC1155Tradable-totalSupply}.
     */
    function totalSupply(
        uint256 _id
    )
        public
        override
        view
        returns (uint256)
    {
        return _tokenSupply[_id];
    }

    /**
     * @dev See {IERC1155Tradable-creator}.
     */
    function creator(
        uint256 _id
    )
        public
        override
        view
        returns (address)
    {
        return _creators[_id];
    }

    /**
     * @dev See {IERC1155Tradable-exists}.
     */
    function exists(
        uint256 _id
    )
        public
        override
        view
        virtual
        returns (bool)
    {
        return _creators[_id] != address(0);
    }

    /**
     * @dev See {IERC1155Tradable-setCreator}.
     */
    function setCreator(
        address _to,
        uint256 _id
    )
        public
        override
        existentTokenOnly(_id)
        onlyOwner
    {
        require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS");
        _setCreator(_to, _id);
    }

    /**
     * @dev See {IERC1155Tradable-setCreatorBatch}.
     */
    function setCreatorBatch(
        address _to,
        uint256[] memory _ids
    )
        public
        override
        onlyOwner
    {
        require(_to != address(0), "ERC1155Tradable#setCreatorBatch: INVALID_ADDRESS");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(exists(id), "ERC1155Tradable#setCreatorBatch: NON_EXISTENT_TOKEN");
            _setCreator(_to, id);
        }
    }

    /**
     * @dev See {IERC1155Tradable-burn}.
     */
    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    )
        public
        override
        virtual
    {
        require(
            _account == msgSender() || isApprovedForAll(_account, msgSender()),
            "ERC1155Tradable#burn: CALLER_NO_OWNER_NOR_APPROVED"
        );

        _burn(_account, _id, _value);
    }

    /**
     * @dev See {IERC1155Tradable-burnBatch}.
     */
    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    )
        public
        override
        virtual
    {
        require(
            _account == msgSender() || isApprovedForAll(_account, msgSender()),
            "ERC1155Tradable#burnBatch: CALLER_NO_OWNER_NOR_APPROVED"
        );

        _burnBatch(_account, _ids, _values);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address.
     * @param _initialOwner address of the first owner of the token.
     * @param _initialSupply amount to supply the first owner.
     * @param _data Data to pass if receiver is contract.
     * @return The newly created token ID.
     */
    function _create(
        address _initialOwner,
        uint256 _initialSupply,
        bytes memory _data
    )
        internal
        virtual
        returns (uint256)
    {
        _tokenID.increment();
        uint256 id = _tokenID.current();
        _creators[id] = msgSender();
        super._mint(_initialOwner, id, _initialSupply, _data);
        _tokenSupply[id] = _initialSupply;
        return id;
    }

    /**
     * @dev Mints some amount of tokens to an address.
     * @param _id          Token ID to mint.
     * @param _quantity    Amount of tokens to mint.
     * @param _data        Data to pass if receiver is contract.
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    )
        internal
        virtual
        override
        existentTokenOnly(_id)
    {
        super._mint(_to, _id, _quantity, _data);
        _tokenSupply[_id] = _tokenSupply[_id].add(_quantity);
    }

    /**
     * @dev Mint tokens for each id in _ids.
     * @param _ids         Array of ids to mint.
     * @param _quantities  Array of amounts of tokens to mint per id.
     * @param _data        Data to pass if receiver is contract.
     */
    function _mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    )
        internal
        virtual
        override
    {
        super._mintBatch(_to, _ids, _quantities, _data);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 quantity = _quantities[i];
            _tokenSupply[id] = _tokenSupply[id].add(quantity);
        }
    }

    /**
     * @dev Change the creator address for given token.
     * @param _to   Address of the new creator.
     * @param _id  Token IDs to change creator of.
     */
    function _setCreator(
        address _to,
        uint256 _id
    )
        internal
    {
        _creators[_id] = _to;
    }
}
