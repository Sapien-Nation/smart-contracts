// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TribeBadge is Ownable, ERC1155Burnable {
	using ECDSA for bytes32;

	// Latest badge id starting from 1
	uint256 public badgeID;
	// Sapien signer address
	address public signer;
	
	event LogSignerSet(address indexed signer);
	event LogMint(address indexed account, uint256 tokenID);
	event LogBurn(address indexed account, uint256 tokenID);
	event LogCreate(uint256 badgeID);

	constructor(
		string memory _uri, 
		address _signer
	) ERC1155(_uri) {
		require(_signer != address(0), "TribeBadge: ZERO_ADDRESS");
		signer = _signer;

		emit LogSignerSet(_signer);
	}

	/** 
	 * @dev Set `signer` wallet
	 * Accessible by only contract owner
	 */
	function setSigner(address _signer) external onlyOwner {
		require(_signer != address(0), "TribeBadge: ZERO_ADDRESS");
		signer = _signer;

		emit LogSignerSet(_signer);
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
	 * @dev Burn badges
	 * Accessible by only contract owner
	 * Length of `_accounts` and `_tokenIDs` must be the same
   * 
   * {ERC1155Burnable-burn(address,uint256,uint256)}
   * {ERC1155Burnable-burnBatch(address,uint256[],uint256[])}
	 */
	function burnBadges(
		address[] calldata _accounts,
		uint256[] calldata _tokenIDs
	) external onlyOwner {
		require(_accounts.length == _tokenIDs.length, "TribeBadge: ARRAY_LENGTH_MISMATCH");
		for(uint256 i = 0; i < _tokenIDs.length; i++) {
			super._burn(_accounts[i], _tokenIDs[i], 1);

			emit LogBurn(_accounts[i], _tokenIDs[i]);
		}
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
}
