import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';

async function setup() {
  const [gov, newGov, alice, marketplace] = await ethers.getSigners();
  const RoleManager = await ethers.getContractFactory('RoleManager');
  const roleManager = await RoleManager.deploy();
  await roleManager.deployed();
  return {roleManager, gov, newGov, alice, marketplace};
}

describe('RoleManager', async () => {
  let roleManager: any;
  let gov: any, newGov: any, alice: any, marketplace: any;

  describe('Marketplace', async () => {
    it('expect to add marketplace', async () => {
      ({roleManager, gov, newGov, alice, marketplace} = await setup());
      await roleManager.addMarketplace(marketplace.address);
      expect(await roleManager.isMarketplace(marketplace.address)).to.be.true;
    });
    it('expect to remove marketplace', async () => {
      await roleManager.removeMarketplace(marketplace.address);
      expect(await roleManager.isMarketplace(marketplace.address)).to.be.false;
    });
    describe('reverts if', async () => {
      it('non-governance call', async () => {
        await expect(roleManager.connect(alice).addMarketplace(marketplace.address))
          .to.be.revertedWith('RoleManager: CALLER_NO_GOVERNANCE');
        await expect(roleManager.connect(alice).removeMarketplace(marketplace.address))
          .to.be.revertedWith('RoleManager: CALLER_NO_GOVERNANCE');
      });
    });

    describe('Governance', async () => {
      it('expect to transfer', async () => {
        await roleManager.transferGovernance(newGov.address);
        expect(await roleManager.governance()).to.eq(newGov.address);
      });
      it('expect to renounce', async () => {
        await roleManager.connect(newGov).renounceGovernance();
        expect(await roleManager.governance()).to.eq(ethers.constants.AddressZero);
      });
      describe('reverts if', async () => {
        it('non-governance call', async () => {
          await expect(roleManager.transferGovernance(alice.address))
            .to.be.revertedWith('RoleManager: CALLER_NO_GOVERNANCE');
          await expect(roleManager.renounceGovernance())
            .to.be.revertedWith('RoleManager: CALLER_NO_GOVERNANCE');
        });
      });
    });
  });
});
