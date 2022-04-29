import { ethers, upgrades } from 'hardhat';

async function main() {
  const ROLE_MANAGER_ADDRESS = '0xD167923fe667060834a9BCcf832344B204c96D5c';
  const BICONOMY_TRUSTED_FORWARDER_ADDRESS = '0x3D1D6A62c588C1Ee23365AF623bdF306Eb47217A';

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
