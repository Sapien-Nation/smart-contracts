// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract SapienTokenMock is Ownable, ERC20, ERC2771Context {
	// total cap 500M
	uint256 public constant CAP = 500000000 * 1e18;
	// Biconomy forwarder contract address
  address public trustedForwarder;

	constructor(address _trustedForwarder) ERC20("Sapien Token Mock", "SPNM") ERC2771Context(_trustedForwarder) { 
		super._mint(msg.sender, CAP);
		trustedForwarder = _trustedForwarder;
	}

	/**
    * @dev Set biconomy trusted forwarder
    * Accessible by only owner (for mock only)
    */
  function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
    trustedForwarder = _trustedForwarder;
  }

	/**
    * @dev Override {ERC2771Context-isTrustedForwarder}
    */
  function isTrustedForwarder(address _forwarder) public view virtual override returns (bool) {
    return _forwarder == trustedForwarder;
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
}