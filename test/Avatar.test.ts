import { ethers } from 'hardhat';
import { expect } from 'chai';

async function setup() {
  const [owner, alice, bob, carol, demon] = await ethers.getSigners();
  const name = 'Sapien Avatar';
  const symbol = 'SAvatar'; 
  const version = '1';
  const baseTokenURI = 'ipfs://';
  const trustedForwarder = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8';
  const Avatar = await ethers.getContractFactory('Avatar');
  const avatar = await Avatar.deploy(name, symbol, version, baseTokenURI, trustedForwarder);
  await avatar.deployed();
  return { avatar, owner, alice, bob, carol, demon };
}

describe('Avatar', async () => {
  let avatar:any;
  let owner, alice:any, bob:any, carol:any, demon: any;

  describe('Mint', async () => {
    it('expect to mint', async () => {
      ({ avatar, owner, alice, bob, carol, demon } = await setup());
      await avatar.mint(
        [alice.address, bob.address, carol.address, demon.address], 
        [
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX1',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX2',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX3',
          'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX4',
        ]
      );
      expect((await avatar.avatarID()).toString()).to.eq('3');

      expect(await avatar.ownerOf(0)).to.eq(alice.address);
      expect(await avatar.ownerOf(1)).to.eq(bob.address);
      
      await avatar.tokenByIndex(1).then((res: any) => {
        expect(res.toString()).to.eq('1');
      });
      await avatar.tokenOfOwnerByIndex(alice.address, 0).then((res: any) => {
        expect(res.toString()).to.eq('0');
      });
    });
    describe('reverts if', async () => {
      it('caller is not owner', async () => {
        await expect(avatar.connect(alice).mint(
          [alice.address, bob.address],
          [
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
            `QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX`,
          ]
        ))
          .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });

  describe('Token URI', async () => {
    it('expect the correct uri', async () => {
      expect(await avatar.tokenURI(0)).to.eq('ipfs://QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX1');
    });
    it('expect to set uri', async () => {
      await avatar.setTokenURI(1, 'QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX11');
      expect(await avatar.tokenURI(1)).to.eq('ipfs://QmXjadqm444yc1wS7U6R8dFyGFe5N6CZycFt5S4YUd3bSX11');
    });
    describe('reverts if', async () => {
      it('caller is not owner', async () => {
        await expect(avatar.connect(alice).setTokenURI(1, 'xxxxxxxxxxxxxxxxxxxx'))
          .to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });

  describe('Transfer', async () => {
    it('avatar is not transferable', async () => {
      await expect(avatar.connect(alice).transferFrom(alice.address, carol.address, 0))
        .to.be.revertedWith('Error: token is not transferable and burnable');
    });
  });
});
