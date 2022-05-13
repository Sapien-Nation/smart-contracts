// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TribeBadge is Ownable, ERC1155Supply {
	using ECDSA for bytes32;

	// Latest badge id starting from 1
	uint256 public badgeID;
	// Sapien signer address
	address public signer;
	
	event LogSignerSet(address indexed signer);
	event LogMint(address indexed account, uint256 tokenID);
	event LogNewBadgeID(uint256 badgeID);

	constructor(
		string memory _uri, 
		address _signer
	) ERC1155(_uri) {
		require(_signer != address(0), "TribeBadge: ZERO_ADDRESS");
		signer = _signer;

		emit LogSignerSet(_signer);
	}

	/**
	 * @dev Mint new badges
	 * If caller is contract owner, `_sig` must be empty ("")
	 * Else `_sig` must be checked validity
	 * Length of `_accounts` and `_tokenIDs` must be the same
	 */
	function mintBatch(
		address[] calldata _accounts,
		uint256[] calldata _tokenIDs,
		bytes calldata _sig
	) external {
		require(_accounts.length == _tokenIDs.length, "TribeBadge: ARRAY_LENGTH_MISMATCH");
		if (msg.sender == owner()) {
			for(uint256 i = 0; i < _tokenIDs.length; i++) {
				require(_tokenIDs[i] <= badgeID, "TribeBadge: TOKEN_ID_INVALID");
				super._mint(_accounts[i], _tokenIDs[i], 1, "");

				emit LogMint(_accounts[i], _tokenIDs[i]);
			}
		} else {
			bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, _accounts, _tokenIDs));
			require(_verify(msgHash, _sig), "TribeBadge: SIG_VERIFY_FAILED");
			for(uint256 i = 0; i < _tokenIDs.length; i++) {
				require(_tokenIDs[i] <= badgeID, "TribeBadge: TOKEN_ID_INVALID");
				// badges must be previously minted by multisig
				require(ERC1155Supply.totalSupply(_tokenIDs[i]) >= 1, "TribeBadge: TOKEN_ID_NOT_ISSUED");
				super._mint(_accounts[i], _tokenIDs[i], 1, "");

				emit LogMint(_accounts[i], _tokenIDs[i]);
			}
		}
	}

	/**
	 * @dev Burn badges
	 * Accessible by only contract owner
	 * Length of `_accounts` and `_tokenIDs` must be the same
	 */
	function burnBatch(
		address[] calldata _accounts,
		uint256[] calldata _tokenIDs
	) external onlyOwner {
		require(_accounts.length == _tokenIDs.length, "TribeBadge: ARRAY_LENGTH_MISMATCH");
		for(uint256 i = 0; i < _tokenIDs.length; i++) {
			super._burn(_accounts[i], _tokenIDs[i], 1);

			emit LogMint(_accounts[i], _tokenIDs[i]);
		}
	}

	/**
	 * @dev New `badgeID` added 1
	 * Accessible by only contract owner
	 */
	function newBadgeID() external onlyOwner {
		uint256 __badgeID = badgeID;
		badgeID = __badgeID + 1;

		emit LogNewBadgeID(__badgeID + 1);
	}

	function _verify(
		bytes32 _msgHash,
		bytes memory _sig
	) private view returns (bool) {
		return _msgHash.toEthSignedMessageHash().recover(_sig) == signer;
	}
}