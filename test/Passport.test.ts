import {MockProvider} from '@ethereum-waffle/provider';
import {deployMockContract} from '@ethereum-waffle/mock-contract';
import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';

import IRoleManager from '../artifacts/contracts/interfaces/IRoleManager.sol/IRoleManager.json';

async function setup() {
  const [owner, gov, alice, bob, carol] = await ethers.getSigners();
  const roleManager = await deployMockContract(owner, IRoleManager.abi);
  await roleManager.mock.governance.returns(gov.address);
  await roleManager.mock.isMarketplace.withArgs(alice.address).returns(false);
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Passport NFT', 'SPASS', roleManager.address]);
  await passport.deployed();
  return {roleManager, passport, owner, gov, alice, bob, carol};
}

describe('Passport', async () => {
  let passport:any, roleManager;
  let owner, gov:any, alice:any, bob:any, carol:any;

  describe('Mint', async () => {
    it('expect to mint', async () => {
      ({roleManager, passport, owner, gov, alice, bob, carol} = await setup());
      await passport.connect(gov).mint([alice.address, bob.address], ['', '']);
      expect(await passport.ownerOf(1)).to.eq(alice.address);
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.mint([alice.address, bob.address], ['', '']))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
      it('params length mismatch', async () => {
        await expect(passport.connect(gov).mint([alice.address, bob.address, carol.address], ['', '']))
          .to.be.revertedWith('Passport: PARAM_LENGTH_MISMATCH');
      });
    });
  });

  describe('Sign', async () => {
    it('expect to sign', async () => {
      await passport.connect(gov).sign(1);
      await passport.passports(1).then((res: any) => {
        expect(res[1]).to.be.true;
      })
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.sign(1))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
    });
  });

  describe('Transfer', async () => {
    it('non-governance wallet can\'t transfer when \'isTransferable\' is false', async () => {
      await expect(passport.connect(bob).transferFrom(bob.address, carol.address, 2))
        .to.be.revertedWith('Passport: TOKEN_NOT_TRANSFERABLE');
    });
    it('signed passport is not transferable', async () => {
      await passport.connect(gov).setIsTransferable(true);
      await expect(passport.connect(alice).transferFrom(alice.address, carol.address, 1))
        .to.be.revertedWith('Passport: SIGNED_PASSPORT_NOT_TRANSFERABLE');
    });
  });
});
