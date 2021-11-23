import { deployMockContract } from '@ethereum-waffle/mock-contract';
import { ethers } from 'hardhat';
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
  const spn = await deployMockContract(owner, IERC20.abi);

  const PassportAuction = await ethers.getContractFactory('PassportAuction');
  const auction = await PassportAuction.deploy(roleManager.address, passport.address, spn.address);
  await auction.deployed();
  return {roleManager, passport, spn, auction, owner, gov, alice, bob, carol};
}

describe('PassportAuction', async () => {
  let roleManager: any, passport: any, spn: any, auction: any;
  let owner: any, gov: any, alice: any, bob: any, carol: any;
  let currentTime: any;

  describe('Create auction', async () => {
    it('expect to create auction', async () => {
      ({roleManager, passport, spn, auction, owner, gov, alice, bob, carol} = await setup());
      // mocks
      await roleManager.mock.governance.returns(gov.address);
      await passport.mock.ownerOf.withArgs(1).returns(alice.address);
      await passport.mock.ownerOf.withArgs(2).returns(bob.address);
      await passport.mock['safeTransferFrom(address,address,uint256)'].withArgs(alice.address, auction.address, 1).returns();

      currentTime = Math.floor(Date.now() / 1000);
      await auction.connect(alice).createAuction(1, ethers.utils.parseEther('1000'), currentTime + 10, currentTime + 10 + duration.days(1));
      await auction.auctions(1).then((res: any) => {
        expect(res.owner).to.eq(alice.address);
        expect(res.floorPrice.toString()).to.eq('1000000000000000000000');
      });
    });
    describe('reverts if', async () => {
      it('non token owner call', async () => {
        await expect(auction.createAuction(2, ethers.utils.parseEther('1000'), currentTime + 10, currentTime + 10 + duration.days(1)))
          .to.be.revertedWith('PassportAuction: CALLER_NO_TOKEN_OWNER');
      });
      it('auction is already created', async () => {
        await expect(auction.connect(alice).createAuction(1, ethers.utils.parseEther('1000'), currentTime + 10, currentTime + 10 + duration.days(1)))
          .to.be.revertedWith('PassportAuction: AUCTION_ALREADY_CREATED');
      });
    });
  });

  describe('Place bid', async () => {
    it('expect to place a bid', async () => {
      // mocks
      await spn.mock.transferFrom.withArgs(bob.address, auction.address, ethers.utils.parseEther('1200')).returns(true);

      await auction.connect(bob).placeBid(1, ethers.utils.parseEther('1200'));
      await auction.bidIds(1, bob.address).then((res: any) => {
        expect(res.toString()).to.eq('1');
      });
      await auction.getBidList(1).then((res: any) => {
        expect(res.length).to.eq(2);
        expect(res[1]['bidder']).to.eq(bob.address);
      });
    });
    describe('reverts if', async () => {
      it('auction does not exist', async () => {
        await expect(auction.connect(bob).placeBid(2, ethers.utils.parseEther('1200')))
          .to.be.revertedWith('PassportAuction: AUCTION_NOT_EXIST');
      });
      it('auction owner place bid', async () => {
        await expect(auction.connect(alice).placeBid(1, ethers.utils.parseEther('1200')))
          .to.be.revertedWith('PassportAuction: SELF_BID_NOT_ALLOWED');
      });
      it('second bid', async () => {
        await expect(auction.connect(bob).placeBid(1, ethers.utils.parseEther('1200')))
          .to.be.revertedWith('PassportAuction: CALLER_ALREADY_BID');
      });
      it('bid amount is less than floor price', async () => {
        await expect(auction.connect(carol).placeBid(1, ethers.utils.parseEther('900')))
          .to.be.revertedWith('PassportAuction: BID_AMOUNT_INVALID');
      });
    });
  });

  describe('Cancel bid', async () => {
    it('expect to cancel bid', async () => {
      // mocks
      await spn.mock.transfer.withArgs(bob.address, ethers.utils.parseEther('1200')).returns(true);

      await expect(auction.connect(bob).cancelBid(1))
        .to.emit(auction, 'LogBidCancel');
      await auction.getBidList(1).then((res: any) => {
        expect(res.length).to.eq(1);
        expect(res[0]['bidder']).to.eq(ethers.constants.AddressZero);
      });
      await auction.bidIds(1, bob.address).then((res: any) => {
        expect(res.toString()).to.eq('0');
      });
    });
    describe('reverts if', async () => {
      it('auction does not exist', async () => {
        await expect(auction.connect(bob).cancelBid(2))
          .to.be.revertedWith('PassportAuction: AUCTION_NOT_EXIST');
      });
    });
    it('caller did not bid', async () => {
      await expect(auction.connect(bob).cancelBid(1))
        .to.be.revertedWith('PassportAuction: CALLER_NO_BID');
    });
  });

  describe('End auction', async () => {
    it('expect to end auction', async () => {
      // mocks
      await spn.mock.transfer.withArgs(alice.address, ethers.utils.parseEther('1140')).returns(true);
      await passport.mock['safeTransferFrom(address,address,uint256)'].withArgs(auction.address, bob.address, 1).returns();

      await auction.connect(bob).placeBid(1, ethers.utils.parseEther('1200'));
      await auction.connect(alice).endAuction(1, 1);
      await auction.getBidList(1).then((res: any) => {
        expect(res.length).to.eq(0);
      });
      await auction.auctions(1).then((res: any) => {
        expect(res.owner).to.eq(ethers.constants.AddressZero);
      });

    });
  });
});
