import { ethers } from 'hardhat';

async function main() {
  const PassportAuction = await ethers.getContractFactory('PassportAuction');
  const passportAuction = await PassportAuction.deploy('0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA', '0x6b0fb07235c94fc922d8e141133280f5bbebe3c3', '0x8174Ab11EEd70297311f7318a71d9e9f48466Fff');

  console.log('Passport auction contract deployed to:', passportAuction.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
