// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract EarlyAccessTribeBadge is ERC1155, Ownable, Pausable, ERC2771Context {
	// Latest badge id starting from 1
	uint256 public badgeID;
  // Biconomy forwarder contract address
  address public trustedForwarder;
	
  event LogURISet(string uri);
  event LogTrustedForwarderSet(address indexed trustedForwarder);
	event LogMint(address indexed account, uint256 tokenID);
	event LogCreate(uint256 badgeID);
  
	constructor(
		string memory _uri, 
    address _trustedForwarder
	) ERC1155(_uri) ERC2771Context(_trustedForwarder) {
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
	 * @dev Mint new badges
	 * Only contract owner(Sapien Governance wallet) can access to this mintBatch method
	 * Length of `_accounts` and `_tokenIDs` must be the same
   * Each account must not have more than 1 badge
	 */
	function mintBatch(
		address[] calldata _accounts,
		uint256[] calldata _tokenIDs
	) external onlyOwner whenNotPaused {
		require(_accounts.length == _tokenIDs.length, "TribeBadge: ARRAY_LENGTH_MISMATCH");
    
    for(uint256 i = 0; i < _tokenIDs.length; i++) {
      require(0 < _tokenIDs[i] && _tokenIDs[i] <= badgeID, "TribeBadge: TOKEN_ID_INVALID");
      require(balanceOf(_accounts[i], _tokenIDs[i]) == 0, "TribeBadge: TOKEN_ALREADY_OWN");
      super._mint(_accounts[i], _tokenIDs[i], 1, "");

      emit LogMint(_accounts[i], _tokenIDs[i]);
    }
	}
  
  /**
   * @dev Create new badge
   * Accessible by only contract owner
   */
  function createBadge() external onlyOwner {
    uint256 newBadgeID = badgeID + 1;
		badgeID = newBadgeID;
		emit LogCreate(newBadgeID);
  }

  /**
   * @dev Pause the contract
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Unpause the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override whenNotPaused {
    require(
      from == address(0) && to != address(0),
      "Error: token is not transferable and burnable"
    );
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  
  /** 
	 * @dev Set `trustedForwarder` address
	 * Accessible by only contract owner
	 */
  function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
    _setTrustedForwarder(_trustedForwarder);
  }

  /**
   * @dev Override {ERC2771Context-isTrustedForwarder}
   * Compare with `trustedForwarder`
   * We want flexibility to update biconomy forwarder address
   */
  function isTrustedForwarder(address _forwarder) public view override returns (bool) {
    return _forwarder == trustedForwarder;
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
