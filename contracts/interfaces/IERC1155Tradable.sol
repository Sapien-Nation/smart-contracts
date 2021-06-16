// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Tradable is IERC1155 {
    /**
     * @dev Emitted when `creator` created a new token type `id` with URI `uri`.
     */
    event TokenCreate(
        address indexed creator,
        uint256 id,
        string uri
    );

    /**
     * @dev Emitted when `quantity` tokens of token type `id` are minted to `to`.
     */
    event TokenMint(
        address indexed to,
        uint256 id,
        uint256 quantity
    );

    /**
     * @dev Equivalent to multiple {TokenMint} events, where `to` is the same for all transfers.
     */
    event TokenMintBatch(
        address to,
        uint256[] ids,
        uint256[] quantities
    );

    /**
     * @dev Returns the total quantity for a token ID.
     */
    function totalSupply(
        uint256 _id
    )
        external
        view
        returns (uint256);

    /**
     * @dev Creates a new token type.
     *
     * Emits a {TokenCreate} event.
     */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    )
        external
        returns (uint256);

    /**
     * @dev Mints `_quantity` tokens of token type `_id` to `_to`.
     *
     * Emits a {TokenMint} event.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    )
        external;

    /**
     * @dev Batched version of {mint}.
     *
     * Emits a {TokenMintBatch} event.
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    )
        external;

    /**
     * @dev Sets creator of token type `_id` to `_to`.
     * @param _to   Address of the new creator.
     * @param _id  Token ID to change creator of.
     */
    function setCreator(
        address _to,
        uint256 _id
    )
        external;

    /**
     * @dev Batched version of {setCreator}.
     */
    function setCreatorBatch(
        address _to,
        uint256[] memory _ids
    )
        external;

    /**
     * @dev Checks if token type `_id` exists.
     */
    function exists(
        uint256 _id
    )
        external
        returns (bool);
}
