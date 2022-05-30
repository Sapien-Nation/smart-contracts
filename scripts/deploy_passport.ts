import { ethers, upgrades } from 'hardhat';

async function main() {
  const ROLE_MANAGER_ADDRESS_MUMBAI = '0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA';
  const ROLE_MANAGER_ADDRESS_RINKEBY = '0xb8CC7C13c47731d4c7970Af884923E5E41b97551';

  const BICONOMY_TRUSTED_FORWARDER_ADDRESS_MUMBAI = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  const BICONOMY_TRUSTED_FORWARDER_ADDRESS_RINKEBY = '0xFD4973FeB2031D4409fB57afEE5dF2051b171104';

  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, [
    'Sapien Nation Passport', 
    'SNP', 
    'ipfs://', 
    ROLE_MANAGER_ADDRESS_RINKEBY, 
    BICONOMY_TRUSTED_FORWARDER_ADDRESS_RINKEBY
  ]);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
