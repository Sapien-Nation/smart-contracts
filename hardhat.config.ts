import { HardhatUserConfig } from 'hardhat/types';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import 'solidity-coverage';

import * as dotenv from 'dotenv';
dotenv.config();

const { 
  DEPLOYER_PRIVATE_KEY,
  INFURA_KEY,
  ALCHEMY_KEY,
  CHAINSCAN_API_KEY
} = process.env;

const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    },
    matic: {
      url: "https://polygon-rpc.com",
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_KEY}`,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_KEY}`,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`]
    }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  },
  namedAccounts: {
    deployer: 0,
    spn: {
      default: 1,
      'testnet': '0x8174Ab11EEd70297311f7318a71d9e9f48466Fff',
      'mainnet': '0x3Cd92Be3Be24daf6D03c46863f868F82D74905bA'
    },
    revenueAddress: {
      default: 2,
      'testnet': '0xeF60a8E421639Fc8A63b98118c5b780579b1009A',
      'mainnet': '0x20e4c1b3c5513b5270a3e87ce75379244b361829'
    },
    governance: {
      default: 3,
      'testnet': '0xeF60a8E421639Fc8A63b98118c5b780579b1009A',
      'mainnet': '0x9ba109487226cb29e54d1fc55f5e55ebff3f0bfe'
    }
  },
  etherscan: {
    apiKey: CHAINSCAN_API_KEY,
 }
};

export default config;
