import { ethers, upgrades } from 'hardhat';

async function main() {
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Nation Passport', 'SNP', 'ipfs://', '0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA', '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b']);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
