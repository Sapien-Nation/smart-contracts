const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('BadgeStore', () => {
  let BadgeStore, ERC20Mock;
  let badgeStore, spn;
  let owner, addr1, addr2;

  before(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    BadgeStore = await ethers.getContractFactory('BadgeStore');
    ERC20Mock = await ethers.getContractFactory('ERC20Mock');
    spn = await ERC20Mock.deploy('SPN', 'SPN');
    await spn.deployed();
    badgeStore = await BadgeStore.deploy('BadgeStore', 'https://sapien.network/badges/{id}.json', 'v3', spn.address, owner.address);
    await badgeStore.deployed();
    console.log('Deployed to:', badgeStore.address);

    await spn.mint(addr1.address, ethers.utils.parseEther('100'));
    await spn.connect(addr1).approve(badgeStore.address, ethers.utils.parseEther('100'));
    await spn.mint(addr2.address, ethers.utils.parseEther('100'));
    await spn.connect(addr2).approve(badgeStore.address, ethers.utils.parseEther('100'));
  });

  describe('createBadge', async () => {
    it('should createBadge', async () => {
      await expect(badgeStore.createBadge(ethers.utils.parseEther('5')))
        .to.emit(badgeStore, 'BadgeCreated')
        .withArgs(owner.address, 1);
      expect(await badgeStore.balanceOf(owner.address, ethers.BigNumber.from(1)))
        .to.equal(ethers.BigNumber.from(1));
      expect(await badgeStore.exists(ethers.BigNumber.from(1)))
        .to.equal(true);
      expect(await badgeStore.exists(ethers.BigNumber.from(2)))
        .to.equal(false);

    });
    describe('reverts if', async () => {
      it('price <= 0', async () => {
        await expect(badgeStore.createBadge(ethers.utils.parseEther('0')))
          .to.be.revertedWith('BadgeStore#createBadge: INVALID_PRICE');
      });
    });
  });

  describe('purchaseBadge', async () => {
    it('should purchaseBadge', async () => {
      await expect(badgeStore.connect(addr1).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(3)))
        .to.emit(badgeStore, 'BadgePurchased')
        .withArgs(addr1.address, ethers.BigNumber.from(1), ethers.BigNumber.from(3));
      expect(await spn.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('85'));
    });
    describe('reverts if', async () => {
      it('purchase amount <= 0', async () => {
        await expect(badgeStore.connect(addr1).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(0)))
          .to.be.revertedWith('BadgeStore#purchaseBadge: INVALID_AMOUNT');
      });
      it('caller\' funds is not enough', async () => {
        await expect(badgeStore.connect(addr1).purchaseBadge(ethers.BigNumber.from(1), ethers.BigNumber.from(21)))
          .to.be.revertedWith('BadgeStore#_purchaseBadge: INSUFFICIENT_FUNDS');
      });
    });
  });

  describe('purchaseBadgeBatch', async () => {
    before(async () => {
      await badgeStore.createBadge(ethers.utils.parseEther('10'));
    });
    it('should purchaseBadgeBatch', async () => {
      await badgeStore.connect(addr1).purchaseBadgeBatch([ethers.BigNumber.from(1), ethers.BigNumber.from(2)], [ethers.BigNumber.from(3), ethers.BigNumber.from(6)]);
      expect(await spn.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('10'));
      expect(await badgeStore.totalSupply(ethers.BigNumber.from(1))).to.equal(ethers.BigNumber.from(7));
    });
    describe('reverts if', async () => {
      it('params length mismatch', async () => {
        await expect(
          badgeStore.connect(addr1).purchaseBadgeBatch([ethers.BigNumber.from(1), ethers.BigNumber.from(2), ethers.BigNumber.from(2)], [ethers.BigNumber.from(3), ethers.BigNumber.from(6)])
        ).to.be.revertedWith('BadgeStore#purchaseBadgeBatch: PARAMS_LENGTH_MISMATCH');
      });
    });
  });

  describe('creator', async () => {
    it('should set & get creator', async () => {
      expect(await badgeStore.creator(ethers.BigNumber.from(1)))
        .to.equal(owner.address);
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
      expect(await badgeStore.getBadgePrice(ethers.BigNumber.from(1))).to.equal(ethers.utils.parseEther('5'));
      await badgeStore.connect(addr1).setBadgePrice(ethers.BigNumber.from(1), ethers.utils.parseEther('6'));
      expect(await badgeStore.getBadgePrice(ethers.BigNumber.from(1))).to.equal(ethers.utils.parseEther('6'));
    });
    describe('reverts if', async () => {
      it('non-creator calls setBadgePrice', async () => {
        await expect(badgeStore.setBadgePrice(ethers.BigNumber.from(1), ethers.utils.parseEther('6')))
        .to.be.revertedWith('ERC1155Tradable#onlyCreator: CALLER_NO_CREATOR');
      });
    });
  });

  describe('revenueAddress', async () => {
    it('should set & get revenueAddress', async () => {
      expect(await badgeStore.getRevenueAddress()).to.equal(owner.address);
      await badgeStore.setRevenueAddress(addr1.address);
      expect(await badgeStore.getRevenueAddress()).to.equal(addr1.address);
    });
    describe('reverts if', async () => {
      it('non-owner calls setRevenueAddress', async () => {
        await expect(badgeStore.connect(addr1).setRevenueAddress(addr2.address))
        .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });
});
