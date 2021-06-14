// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ITribeToken.sol";
import "./ERC1155Tradable.sol";

contract TribeToken is ERC1155Tradable, ITribeToken {
    using SafeMath for uint256;

    mapping(uint256 => string) internal _tribeURIs;

    constructor()
        ERC1155Tradable("https://sapien.network/api/tribe-token")
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
        override(ERC1155Tradable, IERC1155Tradable)
        returns (uint256)
    {
        uint256 id = super.create(_initialOwner, _initialSupply, _uri, _data);
        if (bytes(_uri).length > 0) {
            _tribeURIs[id] = _uri;
        }
        return id;
    }
}
