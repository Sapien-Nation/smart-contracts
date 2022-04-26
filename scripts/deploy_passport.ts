import { ethers, upgrades } from 'hardhat';

async function main() {
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Nation Passport', 'SNP', 'ipfs://', '0x34E8b95cD75e3b14447410F0038dF4BA42512543', '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8']);
  await passport.deployed();
  console.log('Passport deployed to:', passport.address);
}

main();
