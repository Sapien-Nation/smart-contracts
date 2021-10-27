import { ethers, upgrades } from 'hardhat';

async function main() {
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Passport NFT', 'SPASS', 'https://sapien.network/metadata/passport/', '0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA']);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
