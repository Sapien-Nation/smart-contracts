import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';

import IRoleManager from '../artifacts/contracts/interfaces/IRoleManager.sol/IRoleManager.json';

async function setup() {
  const [owner, gov, alice, bob, carol] = await ethers.getSigners();
  const roleManager = await deployMockContract(owner, IRoleManager.abi);
  await roleManager.mock.governance.returns(gov.address);
  await roleManager.mock.isMarketplace.withArgs(alice.address).returns(false);
  const Passport = await ethers.getContractFactory('DefaultPassport');
  const passport = await upgrades.deployProxy(Passport, ['Sapien Default Passport', 'SDP', 'ipfs://', roleManager.address, '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8']);
  await passport.deployed();
  return {roleManager, passport, owner, gov, alice, bob, carol};
}

describe('Passport', async () => {
  let passport:any, roleManager;
  let owner, gov:any, alice:any, bob:any, carol:any;

  describe('Mint', async () => {
    it('expect to mint', async () => {
      ({roleManager, passport, owner, gov, alice, bob, carol} = await setup());
      await passport.connect(gov).mint(
        [alice.address, bob.address, carol.address, gov.address], 
        [
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX1',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX2',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX3',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX4',
        ]
      );
      expect((await passport.passportID()).toString()).to.eq('4');

      expect(await passport.ownerOf(1)).to.eq(alice.address);
      expect(await passport.ownerOf(2)).to.eq(bob.address);
      
      await passport.tokenByIndex(1).then((res: any) => {
        expect(res.toString()).to.eq('2');
      });
      await passport.tokenOfOwnerByIndex(alice.address, 0).then((res: any) => {
        expect(res.toString()).to.eq('1');
      });
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.mint(
          [alice.address, bob.address],
          [
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
          ]
        ))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
      it('Recipient already has a default passport', async () => {
        await expect(passport.connect(gov).mint(
          [alice.address, bob.address],
          [
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
          ]
        ))
          .to.be.revertedWith('Each account can have only one passport');
      });
    });
  });

  describe('Token URI', async () => {
    it('expect the correct uri', async () => {
      expect(await passport.tokenURI(1)).to.eq('ipfs://QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX1');
    });
    it('expect to set uri', async () => {
      await passport.connect(gov).setTokenURI(1, 'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX11');
      expect(await passport.tokenURI(1)).to.eq('ipfs://QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX11');
    });
    describe('reverts if', async () => {
      it('caller is not governance', async () => {
        await expect(passport.setTokenURI(1, 'xxxxxxxxxxxxxxxxxxxx'))
          .to.be.revertedWith('Passport: CALLER_NO_GOVERNANCE');
      });
    });
  });

  describe('Transfer', async () => {
    it('default passport is not transferable and burnable', async () => {
      await expect(passport.connect(alice).transferFrom(alice.address, carol.address, 1))
      .to.be.revertedWith('Passport transfer is not available');
    });
  });

  describe('Pausability', async () => {
    it('expect to pause', async () => {
      await passport.connect(gov).pause();
      expect(await passport.paused()).to.be.true;
      await expect(passport.connect(gov).mint(
        [alice.address, bob.address],
        [
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX',
        ]
      ))
        .to.be.revertedWith('Pausable: paused');
    });
    it('expect to unpause', async () => {
      await passport.connect(gov).unpause();
      expect(await passport.paused()).to.be.false;
    });
  });
});
