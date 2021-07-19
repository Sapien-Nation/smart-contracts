import { HardhatUserConfig } from 'hardhat/types';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';

import * as dotenv from 'dotenv';
dotenv.config();

const { DEPLOYER_PRIVATE_KEY } = process.env;

const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
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
      'matic': '0x8174Ab11EEd70297311f7318a71d9e9f48466Fff'
    },
    revenueAddress: {
      default: 2,
      'matic': '0xeF60a8E421639Fc8A63b98118c5b780579b1009A'
    }
  },
};

export default config;
