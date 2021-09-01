// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Tradable is IERC1155 {
    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     */
    function exists(
        uint256 _id
    )
        external
        view
        returns (bool);

    /**
     * @dev Sets creator of token type `_id` to `_to`.
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
     * @dev Burn token.
     */
    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    )
        external;

    /**
     * @dev Batched version of {burn}.
     */
    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    )
        external;
}
