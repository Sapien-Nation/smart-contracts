// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Avatar is ERC721Enumerable, Ownable, EIP712, ERC721URIStorage, ERC2771Context {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public avatarID;
    string public baseTokenURI;
    // Biconomy forwarder contract address
    address public trustedForwarder;

    event LogMint(uint256 indexed tokenID, address indexed account, string tokenURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _version,
        string memory _baseTokenURI,
        address _trustedForwarder
    ) ERC721(_name, _symbol) ERC2771Context(_trustedForwarder) EIP712(_name, _version) {
        baseTokenURI = _baseTokenURI;
        trustedForwarder = _trustedForwarder;
    }

    /**
      * @dev Override {supportsInterface}.
      */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
      baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setTokenURI(
      uint256 _tokenId,
      string memory _tokenURI
    ) external onlyOwner {
      ERC721URIStorage._setTokenURI(_tokenId, _tokenURI);
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
      return ERC721URIStorage.tokenURI(_tokenId);
    }

    function mint(
      address[] memory _accounts,
      string[] memory _tokenURIs
    ) external onlyOwner {
      require(_accounts.length == _tokenURIs.length, "Avatar: ARRAY_LENGTH_MISMATCH");
      for (uint256 i = 0; i < _accounts.length; i++) {
        require(balanceOf(_accounts[i]) < 1, "Each account can have only one avatar");
        address account = _accounts[i];
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(account, tokenId);
        _setTokenURI(tokenId, _tokenURIs[i]);
        avatarID = tokenId;

        emit LogMint(tokenId, account, _tokenURIs[i]);
      }
    }

    /**
      * @dev Override {ERC721URIStorage-_burn}
      */
    function _burn(uint256 _tokenId) internal virtual override(ERC721URIStorage, ERC721) {
      ERC721URIStorage._burn(_tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            from == address(0) && to != address(0),
            "Error: token is not transferable and burnable"
        );
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }
    
    /**
      * @dev Override {ERC2771Context-_msgSender}
      */
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
      return ERC2771Context._msgSender();
    }

    /**
      * @dev Override {ERC2771Context-_msgData}
      */
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
      return ERC2771Context._msgData();
    }

    uint256[50] private __gap;
}
