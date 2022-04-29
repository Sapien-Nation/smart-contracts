import { ethers } from 'hardhat';

async function main() {
  const BICONOMY_TRUSTED_FORWARDER_ADDRESS = '0x3D1D6A62c588C1Ee23365AF623bdF306Eb47217A';
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
