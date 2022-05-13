import { ethers } from 'hardhat';

async function main() {
  // deploy erc20mock
  const ERC20Mock = await ethers.getContractFactory('ERC20Mock');
  const erc20Mock = await ERC20Mock.deploy('ERC20Mock', 'mock');
  await erc20Mock.deployed();

  const PassportAuction = await ethers.getContractFactory('PassportAuction');
  const passportAuction = await PassportAuction.deploy('0xBac27Ed5d503b2F40C76Ff0c747bF55C753433DA', '0x6b0fb07235c94fc922d8e141133280f5bbebe3c3', erc20Mock.address);

  console.log('Passport auction contract deployed to:', passportAuction.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
