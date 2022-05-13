import { ethers } from 'hardhat';

async function main() {
  const PassportMeta = await ethers.getContractFactory('PassportMeta');
  const passportMeta = await PassportMeta.deploy('Sapien Tribe Passport', 'TRIBE', '', '');

  console.log('Passport meta contract deployed to:', passportMeta.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
