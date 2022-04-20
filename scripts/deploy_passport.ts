import { ethers, upgrades } from 'hardhat';

async function main() {
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Passport NFT', 'SPASS', 'ipfs://', '0xb8CC7C13c47731d4c7970Af884923E5E41b97551']);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
