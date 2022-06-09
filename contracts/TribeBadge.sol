// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TribeBadge is Ownable, ERC1155Burnable, ERC2771Context {
	using ECDSA for bytes32;

	// Latest badge id starting from 1
	uint256 public badgeID;
	// Sapien signer address
	address public signer;
  // Biconomy forwarder contract address
  address public trustedForwarder;
	
  event LogURISet(string uri);
	event LogSignerSet(address indexed signer);
  event LogTrustedForwarderSet(address indexed trustedForwarder);
	event LogMint(address indexed account, uint256 tokenID);
	event LogBurn(address indexed account, uint256 tokenID);
	event LogCreate(uint256 badgeID);
  
	constructor(
		string memory _uri, 
		address _signer,
    address _trustedForwarder
	) ERC1155(_uri) ERC2771Context(_trustedForwarder) {
    _setSigner(_signer);
    _setTrustedForwarder(_trustedForwarder);
	}

  /** 
	 * @dev Set contract URI
	 * Accessible by only contract owner
	 */
  function setURI(string memory _uri) external onlyOwner {
    require(bytes(_uri).length > 0, "TribeBadge: EMPTY_STRING");
    super._setURI(_uri);

    emit LogURISet(_uri);
  }

	/** 
	 * @dev Set `signer` wallet
	 * Accessible by only contract owner
	 */
	function setSigner(address _signer) external onlyOwner {
		_setSigner(_signer);
	}

  /** 
	 * @dev Set `trustedForwarder` address
	 * Accessible by only contract owner
	 */
  function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
    _setTrustedForwarder(_trustedForwarder);
  }

	/**
	 * @dev Mint new badges
	 * If caller is contract owner, `_sig` must be empty ("")
	 * Else `_sig` must be checked validity
	 * Length of `_accounts` and `_tokenIDs` must be the same
   * Each account must not have more than 1 badge
	 */
	function mintBatch(
		address[] calldata _accounts,
		uint256[] calldata _tokenIDs,
		bytes calldata _sig
	) external {
		require(_accounts.length == _tokenIDs.length, "TribeBadge: ARRAY_LENGTH_MISMATCH");
    if (msg.sender != owner()) {
      bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, _accounts, _tokenIDs));
			require(_verify(msgHash, _sig), "TribeBadge: SIG_VERIFY_FAILED");
    }
    for(uint256 i = 0; i < _tokenIDs.length; i++) {
      require(0 < _tokenIDs[i] && _tokenIDs[i] <= badgeID, "TribeBadge: TOKEN_ID_INVALID");
      require(balanceOf(_accounts[i], _tokenIDs[i]) == 0, "TribeBadge: TOKEN_ALREADY_OWN");
      super._mint(_accounts[i], _tokenIDs[i], 1, "");

      emit LogMint(_accounts[i], _tokenIDs[i]);
    }
	}
  
  /**
   * @dev Create and mint new badges
   * Accessible by only non multi sig owners
   */
  function createBatch(
    address[] calldata _accounts,
    bytes calldata _sig
  ) external {
    require(msg.sender != owner(), "TribeBadge: MULTISIG_NOT_ALLOWED");
    bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, _accounts));
    require(_verify(msgHash, _sig), "TribeBadge: SIG_VERIFY_FAILED");
    uint256 newBadgeID = badgeID + 1;
		badgeID = newBadgeID;
		emit LogCreate(newBadgeID);
    for(uint256 i = 0; i < _accounts.length; i++) {
      super._mint(_accounts[i], newBadgeID, 1, "");

      emit LogMint(_accounts[i], newBadgeID);
    }
  }

  /**
   * @dev Override {ERC2771Context-isTrustedForwarder}
   * Compare with `trustedForwarder`
   * We want flexibility to update biconomy forwarder address
   */
  function isTrustedForwarder(address _forwarder) public view override returns (bool) {
    return _forwarder == trustedForwarder;
  }

  /**
   * @dev Verify signature
   */
	function _verify(
		bytes32 _msgHash,
		bytes memory _sig
	) private view returns (bool) {
		return _msgHash.toEthSignedMessageHash().recover(_sig) == signer;
	}

  /**
   * @dev Override {ERC1155-_safeTransferFrom}
   * Transfer is disabled
   */
  function _safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) internal virtual override {
    require(false, "TribeBadge: TRANSFER_DISABLED");
  }

  function _setSigner(address _signer) private {
    require(_signer != address(0), "TribeBadge: ZERO_ADDRESS");
		signer = _signer;

		emit LogSignerSet(_signer);
  }

  function _setTrustedForwarder(address _trustedForwarder) private {
    require(_trustedForwarder != address(0), "TribeBadge: ZERO_ADDRESS");
    trustedForwarder = _trustedForwarder;

    emit LogTrustedForwarderSet(_trustedForwarder);
  }

  /**
    * @dev Override {ERC2771Context-_msgSender}
    */
  function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
    return ERC2771Context._msgSender();
  }

  /**
    * @dev Override {ERC2771Context-_msgData}
    */
  function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
    return ERC2771Context._msgData();
  }
}
