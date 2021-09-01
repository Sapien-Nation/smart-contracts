import { ethers } from 'hardhat';
import { expect } from 'chai';

describe('BadgeStore', () => {
  let BadgeStore, ERC20Mock;
  let badgeStore: any, spn: any;
  let owner: any, revenue: any, governance: any, addr1: any, addr2: any, addr3: any;

  describe('createBadge', async () => {
    it('governance should createBadge', async () => {
      [owner, revenue, governance, addr1, addr2, addr3] = await ethers.getSigners();
      console.log('owner:', owner.address);
      console.log('revenue:', revenue.address);
      console.log('governance:', governance.address);
      console.log('addr1:', addr1.address);
      console.log('addr2:', addr2.address);
      BadgeStore = await ethers.getContractFactory('BadgeStore');
      ERC20Mock = await ethers.getContractFactory('ERC20Mock');
      spn = await ERC20Mock.deploy('SPN', 'SPN');
      await spn.deployed();
      badgeStore = await BadgeStore.deploy('BadgeStore', 'https://sapien.network/badges/{id}.json', 'v3', spn.address, revenue.address, governance.address);
      await badgeStore.deployed();
      console.log('Deployed to:', badgeStore.address);

      await spn.mint(addr1.address, ethers.utils.parseEther('100'));
      await spn.connect(addr1).approve(badgeStore.address, ethers.utils.parseEther('100'));
      await spn.mint(addr2.address, ethers.utils.parseEther('100'));
      await spn.connect(addr2).approve(badgeStore.address, ethers.utils.parseEther('100'));
      await spn.mint(addr3.address, ethers.utils.parseEther('100'));
      await spn.connect(addr3).approve(badgeStore.address, ethers.utils.parseEther('100'));
      await expect(badgeStore.connect(governance).createBadge(addr1.address, ethers.utils.parseEther('5')))
        .to.emit(badgeStore, 'BadgeCreate')
        .withArgs(addr1.address, 1);
      expect(await badgeStore.balanceOf(addr1.address, ethers.BigNumber.from(1)))
        .to.equal(ethers.BigNumber.from(1));
      expect(await badgeStore.exists(ethers.BigNumber.from(1)))
        .to.equal(true);
      expect(await badgeStore.exists(ethers.BigNumber.from(2)))
        .to.equal(false);
    });
    describe('reverts if', async () => {
      it('non-governance calls createBadge', async () => {
        await expect(badgeStore.createBadge(addr1.address, ethers.utils.parseEther('10')))
          .to.be.revertedWith('BadgeStore#createBadge: CALLER_NO_GOVERNANCE');
      });
    });
  });

  describe('purchaseBadge', async () => {
    it('should purchaseBadge', async () => {
      console.log(await badgeStore.revenueAddress());
      console.log(await badgeStore.governance());
      await expect(badgeStore.connect(addr2).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(3)))
        .to.emit(badgeStore, 'BadgePurchase')
        .withArgs(addr2.address, ethers.BigNumber.from(1), ethers.BigNumber.from(3));
      expect(await spn.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('85'));
    });
    describe('reverts if', async () => {
      it('purchase amount <= 0', async () => {
        await expect(badgeStore.connect(addr2).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(0)))
          .to.be.revertedWith('BadgeStore#purchaseBadge: INVALID_AMOUNT');
      });
      it('caller\'s funds is not enough', async () => {
        await expect(badgeStore.connect(addr2).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(21)))
          .to.be.revertedWith('BadgeStore#_purchaseBadge: INSUFFICIENT_FUNDS');
      });
    });
  });

  describe('grantBadge', async () => {
    it('badge admin should grantBadge', async () => {
      await expect(badgeStore.connect(addr1).grantBadge(addr2.address, ethers.BigNumber.from(1), ethers.BigNumber.from(3)))
        .to.emit(badgeStore, 'BadgeGrant')
        .withArgs(addr2.address, ethers.BigNumber.from(1), ethers.BigNumber.from(3));
    });
  });

  describe('purchaseBadgeBatch', async () => {
    before(async () => {
      await badgeStore.connect(governance).createBadge(addr1.address, ethers.utils.parseEther('10'));
    });
    it('should purchaseBadgeBatch', async () => {
      await badgeStore.connect(addr3).purchaseBadgeBatch([ethers.BigNumber.from(1), ethers.BigNumber.from(2)], [ethers.BigNumber.from(3), ethers.BigNumber.from(6)]);
      expect(await spn.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther('25'));
      expect(await badgeStore.tokenSupply(ethers.BigNumber.from(1))).to.equal(ethers.BigNumber.from(10));
    });
    describe('reverts if', async () => {
      it('params length mismatch', async () => {
        await expect(
          badgeStore.connect(addr3).purchaseBadgeBatch([ethers.BigNumber.from(1), ethers.BigNumber.from(2), ethers.BigNumber.from(2)], [ethers.BigNumber.from(3), ethers.BigNumber.from(6)])
        ).to.be.revertedWith('BadgeStore#purchaseBadgeBatch: PARAMS_LENGTH_MISMATCH');
      });
    });
  });

  describe('creator', async () => {
    it('should set & get creator', async () => {
      expect(await badgeStore.creator(ethers.BigNumber.from(1)))
        .to.equal(governance.address);
      await badgeStore.setCreator(addr1.address, ethers.BigNumber.from(1));
      expect(await badgeStore.creator(ethers.BigNumber.from(1)))
        .to.equal(addr1.address);
    });
    describe('reverts if', async () => {
      it('non-owner call setCreator', async () => {
        await expect(badgeStore.connect(addr1).setCreator(addr2.address, ethers.BigNumber.from(1)))
        .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });

  describe('badgePrice', async () => {
    it('should set & get badgePrice', async () => {
      expect(await badgeStore.badgePrice(ethers.BigNumber.from(1))).to.equal(ethers.utils.parseEther('5'));
      await badgeStore.connect(addr1).setBadgePrice(ethers.BigNumber.from(1), ethers.utils.parseEther('6'));
      expect(await badgeStore.badgePrice(ethers.BigNumber.from(1))).to.equal(ethers.utils.parseEther('6'));
    });
    describe('reverts if', async () => {
      it('non-admin calls setBadgePrice', async () => {
        await expect(badgeStore.setBadgePrice(ethers.BigNumber.from(1), ethers.utils.parseEther('6')))
        .to.be.revertedWith('BadgeStore#setBadgePrice: CALLER_NO_BADGE_ADMIN');
      });
    });
  });

  describe('revenueAddress', async () => {
    it('should set & get revenueAddress', async () => {
      expect(await badgeStore.revenueAddress()).to.equal(revenue.address);
      await badgeStore.setRevenueAddress(addr1.address);
      expect(await badgeStore.revenueAddress()).to.equal(addr1.address);
    });
    describe('reverts if', async () => {
      it('non-owner calls setRevenueAddress', async () => {
        await expect(badgeStore.connect(addr1).setRevenueAddress(addr2.address))
        .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });
});
