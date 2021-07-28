import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer, spn, revenueAddress, governance } = await getNamedAccounts();

  await deploy('BadgeStore', {
    from: deployer,
    args: ['Sapien Badge Store', 'https://sapien.network/badges/{id}.json', 'v3', spn, revenueAddress, governance],
    log: true,
  });
};

export default func;
func.tags = ['BadgeStore'];
