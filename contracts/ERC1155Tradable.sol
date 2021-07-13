// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IERC1155Tradable.sol";

/**
* @title ERC1155Tradable
* ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
like _exists() and totalSupply()
*/
contract ERC1155Tradable is ERC1155, Ownable, IERC1155Tradable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenID;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _tokenSupply;

    constructor(
        string memory _uri
    )
        ERC1155(_uri)
    { }

    /**
    * @dev Require _msgSender() to be the creator of the token id
    */
    modifier onlyCreator(
        uint256 _id
    )
    {
        require(_creators[_id] == _msgSender(), "ERC1155Tradable#onlyCreator: CALLER_NO_CREATOR");
        _;
    }

    /**
    * @dev Require _msgSender() to own at least 1 token
    */
    modifier tokenOwnerOnly(
        uint256 _id
    )
    {
        require(balanceOf(_msgSender(), _id) > 0, "ERC1155Tradable#tokenOwnerOnly: CALLER_NO_TOKEN_OWNER");
        _;
    }

    modifier existentTokenOnly(
        uint256 _id
    )
    {
        require(exists(_id), "ERC1155Tradable#existentTokenOnly: NON_EXISTENT_TOKEN");
        _;
    }

    /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(
        uint256 _id
    )
        public
        view
        override
        returns (uint256)
    {
        return _tokenSupply[_id];
    }

    function getCreator(
        uint256 _id
    )
        public
        view
        returns (address)
    {
        return _creators[_id];
    }

//   /**
//    * @dev Will update the base URL of token's URI
//    * @param _newBaseMetadataURI New base URL of token's URI
//    */
//   function setBaseMetadataURI(
//     string memory _newBaseMetadataURI
//   ) public onlyOwner {
//     _setBaseMetadataURI(_newBaseMetadataURI);
//   }

    /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        bytes memory _data
    )
        public
        virtual
        override
        returns (uint256)
    {
        _tokenID.increment();
        uint256 id = _tokenID.current();
        _creators[id] = _msgSender();
        _mint(_initialOwner, id, _initialSupply, _data);
        _tokenSupply[id] = _initialSupply;
        return id;
    }

    /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    )
        public
        virtual
        override
        onlyCreator(_id)
    {
        _mint(_to, _id, _quantity, _data);
        _tokenSupply[_id] = _tokenSupply[_id].add(_quantity);
    }

    /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    )
        public
        virtual
        override
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(_creators[id] == _msgSender(), "ERC1155Tradable#mintBatch: ONLY_CREATOR_ALLOWED");
            uint256 quantity = _quantities[i];
            _tokenSupply[id] = _tokenSupply[id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    function setCreator(
        address _to,
        uint256 _id
    )
        public
        override
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
            require(_creators[id] == _msgSender(), "ERC1155Tradable#setCreatorBatch: CALLER_NO_CREATOR");
            _setCreator(_to, id);
        }
    }

    /**
    * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
    function _setCreator(
        address _to,
        uint256 _id
    )
        internal
    {
        _creators[_id] = _to;
    }

    /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function exists(
        uint256 _id
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return _creators[_id] != address(0);
    }
}
