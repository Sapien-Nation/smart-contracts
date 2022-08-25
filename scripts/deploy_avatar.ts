import { ethers } from 'hardhat';

async function main() {
  const name = 'Sapien Avatar';
  const symbol = 'SAvatar'; 
  const version = '1';
  const baseTokenURI = 'ipfs://';
  const trustedForwarder = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8';

  const Avatar = await ethers.getContractFactory('Avatar');
  const avatar = await Avatar.deploy(name, symbol, version, baseTokenURI, trustedForwarder);
  await avatar.deployed();

  console.log('Avatar contract deployed to:', avatar.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });