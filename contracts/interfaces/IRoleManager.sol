// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoleManager {
    function setGovernance(address _governance) external;

    function governance() external returns (address governance);
}
