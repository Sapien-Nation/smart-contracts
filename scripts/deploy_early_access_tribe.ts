import { ethers } from 'hardhat';

async function main() {
  const uri = 'https://sapien.network/badges/{id}.json';
  const trustedForwarder = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8'; // polygon mainnet
  // const trustedForwarder = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b'; // polygon mumbai

  const TribeBadge = await ethers.getContractFactory('EarlyAccessTribeBadge');
  const tribeBadge = await TribeBadge.deploy(uri, trustedForwarder);
  await tribeBadge.deployed();

  console.log('Early Access Badge contract deployed to:', tribeBadge.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });