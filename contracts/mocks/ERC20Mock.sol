// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol)
    { }

    function mint(
        address _account,
        uint256 _amount
    )
        public
    {
        _mint(_account, _amount);
    }

    function burn(
        address _account,
        uint256 _amount
    )
        public
    {
        _burn(_account, _amount);
    }

}
