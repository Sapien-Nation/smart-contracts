import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';

import IRoleManager from '../artifacts/contracts/interfaces/IRoleManager.sol/IRoleManager.json';

async function setup() {
  const [owner, gov, alice, bob, carol] = await ethers.getSigners();
  const roleManager = await deployMockContract(owner, IRoleManager.abi);
  await roleManager.mock.governance.returns(gov.address);
  await roleManager.mock.isMarketplace.withArgs(alice.address).returns(false);
  const Passport = await ethers.getContractFactory('Passport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Passport NFT', 'SPASS', 'https://sapien.network/metadata/passport/', roleManager.address]);
  await passport.deployed();
  return {roleManager, passport, owner, gov, alice, bob, carol};
}

describe('Passport', async () => {
  let passport:any, roleManager;
  let owner, gov:any, alice:any, bob:any, carol:any;

  describe('Mint', async () => {
    it('expect to mint', async () => {
      ({roleManager, passport, owner, gov, alice, bob, carol} = await setup());
      await passport.connect(gov).mint([alice.address, bob.address, carol.address, gov.address]);
      await passport.connect(gov).mint([alice.address, alice.address, alice.address, alice.address, alice.address, alice.address]);
      // alice account first mint limit exceeds and skips last 2 mints
      expect((await passport.firstPurchases(alice.address)).toString()).to.eq('5');
      expect((await passport.passportID()).toString()).to.eq('8');

      expect(await passport.ownerOf(1)).to.eq(alice.address);
      expect(await passport.ownerOf(2)).to.eq(bob.address);
      expect(await passport.tokenURI(1)).to.eq('https://sapien.network/metadata/passport/1');
      await passport.tokenByIndex(1).then((res: any) => {
        expect(res.toString()).to.eq('2');
      });
      await passport.tokenOfOwnerByIndex(alice.address, 0).then((res: any) => {
        expect(res.toString()).to.eq('1');
      });
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.mint([alice.address, bob.address]))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
    });
  });

  describe('Sign', async () => {
    it('expect to sign', async () => {
      await passport.connect(gov).sign(1);
      expect(await passport.isSigned(1)).to.be.true;
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.sign(1))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
    });
  });

  describe('Transfer', async () => {
    it('non-governance wallet can\'t transfer when \'NGTransferable\' is false', async () => {
      await expect(passport.connect(bob).transferFrom(bob.address, carol.address, 2))
        .to.be.revertedWith('Passport: NG_NOT_TRANSFERABLE');
    });
    it('governance wallet can transfer even when \'NGTransferable\' is false', async () => {
      await passport.connect(gov).transferFrom(gov.address, carol.address, 4);
      await passport.tokenOfOwnerByIndex(carol.address, 0).then((res: any) => {
        expect(res.toString()).to.eq('3');
      });
      await passport.tokenOfOwnerByIndex(carol.address, 1).then((res: any) => {
        expect(res.toString()).to.eq('4');
      });
    });
    it('signed passport is not transferable', async () => {
      await passport.connect(gov).setNGTransferable(true);
      await expect(passport.connect(alice).transferFrom(alice.address, carol.address, 1))
        .to.be.revertedWith('Passport: SIGNED_PASSPORT_NOT_TRANSFERABLE');
    });
  });

  describe('Pausability', async () => {
    it('expect to pause', async () => {
      await passport.connect(gov).pause();
      expect(await passport.paused()).to.be.true;
      await expect(passport.connect(gov).mint([alice.address, bob.address]))
        .to.be.revertedWith('Pausable: paused');
      await expect(passport.connect(carol).transferFrom(carol.address, bob.address, 4))
        .to.be.revertedWith('Pausable: paused');
    });
    it('expect to unpause', async () => {
      await passport.connect(gov).unpause();
      expect(await passport.paused()).to.be.false;
    });
  });
});
