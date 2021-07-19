require("@nomiclabs/hardhat-waffle");
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {},
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  }
};
