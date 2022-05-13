import { ethers, upgrades } from 'hardhat';

async function main() {
  const ROLE_MANAGER_ADDRESS = '0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA';
  const BICONOMY_TRUSTED_FORWARDER_ADDRESS = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';

  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, [
    'Sapien Nation Passport', 
    'SNP', 
    'ipfs://', 
    ROLE_MANAGER_ADDRESS, 
    BICONOMY_TRUSTED_FORWARDER_ADDRESS
  ]);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
