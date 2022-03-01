import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
import { duration } from './helpers/time';

import IPassport from '../artifacts/contracts/interfaces/IPassport.sol/IPassport.json';
import IRoleManager from '../artifacts/contracts/interfaces/IRoleManager.sol/IRoleManager.json';
import IERC20 from '../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json';

async function setup() {
  const [owner, gov, alice, bob, carol] = await ethers.getSigners();
  // mocks
  const roleManager = await deployMockContract(gov, IRoleManager.abi);
  const passport = await deployMockContract(owner, IPassport.abi);
  const weth = await deployMockContract(owner, IERC20.abi);
  const spn = await deployMockContract(owner, IERC20.abi);

  const PassportSale = await ethers.getContractFactory('PassportSale');
  const passSale = await PassportSale.deploy(roleManager.address, passport.address, weth.address, spn.address, Math.floor(Date.now() / 1000) + 10);
  await passSale.deployed();
  return {roleManager, passport, weth, spn, passSale, owner, gov, alice, bob, carol};
}

describe('PassportSale', async () => {
  let roleManager: any, passport: any, weth: any, spn: any, passSale: any;
  let owner: any, gov: any, alice: any, bob: any, carol: any;

  describe('Open for sale', async () => {
    it('expect to open token for sale', async () => {
      ({roleManager, passport, weth, spn, passSale, owner, gov, alice, bob, carol} = await setup());
      // mocks
      await roleManager.mock.governance.returns(gov.address);
      await passport.mock.ownerOf.withArgs(1).returns(alice.address);
      await passport.mock.isSigned.withArgs(1).returns(false);
      // set sale start date `current time + 10 seconds`
      const currentTime = Math.floor(Date.now() / 1000);
      await passSale.connect(gov).setSaleStartDate(currentTime + 10);
      await ethers.provider.send('evm_increaseTime', [duration.seconds(10)]);
      // open for sale
      await passSale.connect(alice).openForSale(1, ethers.utils.parseEther('1'), 0);
      await passSale.passportSales(1).then((res: any) => {
        expect(res.seller).to.eq(alice.address);
        expect(res.priceEth.toString()).to.eq('1000000000000000000');
        expect(res.priceSPN.toString()).to.eq('0');
        expect(res.isOpenForSale).to.be.true;
      });
    });
    describe('reverts if', async () => {
      it('non token owner call', async () => {
        await expect(passSale.openForSale(1, ethers.utils.parseEther('1'), ethers.utils.parseEther('1000')))
          .to.be.revertedWith('PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID');
      });
      it('token id does not exist', async () => {
        // mocks
        await passport.mock.ownerOf.withArgs(3).returns(ethers.constants.AddressZero);
        await passport.mock.isSigned.withArgs(3).returns(false);

        await expect(passSale.openForSale(3, ethers.utils.parseEther('1'), ethers.utils.parseEther('1000')))
          .to.be.revertedWith('PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID');
      });
      it('passport is signed', async () => {
        // mocks
        await passport.mock.ownerOf.withArgs(2).returns(bob.address);
        await passport.mock.isSigned.withArgs(2).returns(true);

        await expect(passSale.connect(bob).openForSale(2, ethers.utils.parseEther('1'), ethers.utils.parseEther('1000')))
          .to.be.revertedWith('PassportSale: PASSPORT_SIGNED');
      });
      it('prices are both zero', async () => {
        await expect(passSale.connect(alice).openForSale(1, 0, 0))
          .to.be.revertedWith('PassportSale: PRICES_INVALID');
      });
    });
  });

  describe('Set price', async () => {
    it('expect to set price', async () => {
      await passSale.connect(alice).setPrice(1, ethers.utils.parseEther('2'), 0);
    });
    describe('reverts if', async () => {
      it('token id does not exist', async () => {
        await expect(passSale.setPrice(3, ethers.utils.parseEther('1.5'), 0))
          .to.be.revertedWith('PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID');
      });
      it('non token owner call', async () => {
        await expect(passSale.setPrice(1, ethers.utils.parseEther('1.5'), 0))
          .to.be.revertedWith('PassportSale: CALLER_NO_TOKEN_OWNER__ID_INVALID');
      });
      it('passport is signed', async () => {
        await expect(passSale.connect(bob).setPrice(2, ethers.utils.parseEther('1.5'), 0))
          .to.be.revertedWith('PassportSale: PASSPORT_SIGNED');
      });
      it('prices are both zero', async () => {
        await expect(passSale.connect(alice).openForSale(1, 0, 0))
          .to.be.revertedWith('PassportSale: PRICES_INVALID');
      });
    });
  });

  describe('Purchase', async () => {
    it('expect to purchase', async () => {
      // mocks
      await weth.mock.transferFrom.reverts();
      await passport.mock.creators.reverts();

      await expect(passSale.connect(carol).purchase(1, 0))
        .to.be.revertedWith('Mock revert');
    });
    describe('reverts if', async () => {
      it('token id does not exist', async () => {
        await expect(passSale.purchase(3, 0))
          .to.be.revertedWith('PassportSale: PASSPORT_ID_INVALID');
      });
      it('token owner call', async () => {
        await expect(passSale.connect(alice).purchase(1, 0))
          .to.be.revertedWith('PassportSale: NO_SELF_PURCHASE');
      });
      it('token owner changed', async () => {
        // mocks
        await passport.mock.ownerOf.withArgs(1).returns(carol.address);

        await expect(passSale.connect(alice).purchase(1, 0))
          .to.be.revertedWith('PassportSale: OWNERSHIP_CHANGED');

        // mocks
        await passport.mock.ownerOf.withArgs(1).returns(alice.address);
      });
      it('eth or spn flag is greater than 2', async () => {
        await expect(passSale.connect(carol).purchase(1, 3))
          .to.be.revertedWith('PassportSale: ETH_OR_SPN_FLAG_INVALID');
      });
      it('picked price is zero', async () => {
        await expect(passSale.connect(carol).purchase(1, 1))
          .to.be.revertedWith('PassportSale: PASSPORT_PRICE_INVALID');
      });
    });
  });

  describe('Sweep', async () => {
    it('expect to sweep', async () => {
      // mocks
      await weth.mock.balanceOf.reverts();

      await expect(passSale.connect(gov).sweep(weth.address, gov.address))
        .to.be.revertedWith('Mock revert');
    });
  });
});
