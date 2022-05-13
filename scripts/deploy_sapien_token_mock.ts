import { ethers } from 'hardhat';

async function main() {
  const BICONOMY_TRUSTED_FORWARDER_ADDRESS = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  const SapienTokenMock = await ethers.getContractFactory('SapienTokenMock');
  const sapienTokenMock = await SapienTokenMock.deploy(BICONOMY_TRUSTED_FORWARDER_ADDRESS);

  console.log('Sapien Token Mock deployed to:', sapienTokenMock.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
