import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  const RoleManager = await ethers.getContractFactory('RoleManager');
  const roleManager = await RoleManager.deploy();

  console.log('Role manager contract deployed to:', roleManager.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
