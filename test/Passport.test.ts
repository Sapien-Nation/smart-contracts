import {MockProvider} from '@ethereum-waffle/provider';
import {deployMockContract} from '@ethereum-waffle/mock-contract';
import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';

import IRoleManager from '../artifacts/contracts/interfaces/IRoleManager.sol/IRoleManager.json';

async function setup() {
  const [owner, gov, alice, bob, carol] = new MockProvider().getWallets();
  const roleManager = await deployMockContract(owner, IRoleManager.abi);
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Passport NFT', 'SPASS', roleManager.address]);
  await roleManager.mock.governance.returns(gov.address);
  // const contractFactory = new ContractFactory(AmIRichAlready.abi, AmIRichAlready.bytecode, owner);
  // const contract = await contractFactory.deploy(mockERC20.address);
  // return {owner, receiver, contract, mockERC20};
  return {roleManager, passport, owner, gov, alice, bob, carol};
}

describe('Passport', async () => {
  let Passport;
  let passport, roleManager;
  let owner, gov, alice, bob, carol;

  describe('Mint', async () => {
    it('expect to mint', async () => {
      ({roleManager, passport, owner, gov, alice, bob, carol} = await setup());
      await passport.mint([alice.address, bob.address], ['', ''], [ethers.utils.parseEther('1'), ethers.utils.parseEther('1'), 123]);
      // expect(await passport.ownerOf(1)).to.eq(alice.address);
    });
  });
});
