import { ethers } from 'hardhat';
import { expect } from 'chai';

async function setup() {
  const [owner, alice, bob, carol, darren, eric] = await ethers.getSigners();
  const trustedForwarder:string = '0xeF60a8E421639Fc8A63b98118c5b780579b1009A';
  const TribeBadge = await ethers.getContractFactory('EarlyAccessTribeBadge');
  const tribeBadge = await TribeBadge.deploy('https://sapien.network/badges/{id}.json', trustedForwarder);
  await tribeBadge.deployed();
  return {tribeBadge, owner, alice, bob, carol, darren, eric};
}

describe('TribeBadge', async () => {
	let tribeBadge: any;
	let owner: any, alice: any, bob: any, carol: any, darren: any, eric: any;
	
	describe('CreateBadge', async () => {
		it('expect to create new badge', async () => {
			({tribeBadge, owner, alice, bob, carol, darren, eric} = await setup());
			await tribeBadge.createBadge();
			expect((await tribeBadge.badgeID()).toString()).to.eq('1');
		});
		describe('reverts if', async () => {
			it('caller is not owner', async () => {
				await expect(tribeBadge.connect(alice).createBadge())
					.to.be.revertedWith('Ownable: caller is not the owner');
			});
		});
	});

	describe('MintBatch', async () => {
		it('expect to mint batch tokens', async () => {
			// owner call
			await tribeBadge.mintBatch([darren.address], [1]);
			expect((await tribeBadge.balanceOf(darren.address, 1)).toString()).to.eq('1');
		});
    describe('reverts if', async () => {
      it('tries to mint badges not created', async () => {
        await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 0])))
          .to.be.revertedWith('TribeBadge: TOKEN_ID_INVALID');
      });
      it('array params length mismatch', async () => {
        await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 2, 2])))
          .to.be.revertedWith('TribeBadge: ARRAY_LENGTH_MISMATCH');
      });
      it('accounts already own at least 1 badge', async () => {
        await expect(tribeBadge.mintBatch([darren.address], [1]))
          .to.be.revertedWith('TribeBadge: TOKEN_ALREADY_OWN');
      });
    });
	});

  describe('Setters for URI', async () => {
    it('expect to set new URI', async () => {
      await tribeBadge.setURI('https://sapien.network/badges/updated/{id}.json');
      expect(await tribeBadge.uri(1)).to.eq('https://sapien.network/badges/updated/{id}.json');
    });
    describe('reverts if', async () => {
      it('setURI() caller is not owner', async () => {
        await expect(tribeBadge.connect(alice).setURI('https://sapien.network/badges/updated/{id}.json'))
          .to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('new URI is empty string', async () => {
        await expect(tribeBadge.setURI(''))
          .to.be.revertedWith('TribeBadge: EMPTY_STRING');
      });
    });
  });

  describe('Non transferable', async () => {
    it('expect to badge transfer disabled', async () => {
      await expect(tribeBadge.connect(darren).safeTransferFrom(darren.address, alice.address, 1, 1, ethers.constants.HashZero))
        .to.be.revertedWith('Error: token is not transferable and burnable');
    });
  })

  describe('Pausability', async () => {
    it('expect to pause', async () => {
      await tribeBadge.pause();
      expect(await tribeBadge.paused()).to.be.true;
      await expect(tribeBadge.mintBatch(
        [alice.address, bob.address],
        [1, 1]
      ))
        .to.be.revertedWith('Pausable: paused');
      await expect(tribeBadge.connect(darren).safeTransferFrom(darren.address, bob.address, 1, 1, ethers.constants.HashZero))
        .to.be.revertedWith('Pausable: paused');
    });
    it('expect to unpause', async () => {
      await tribeBadge.unpause();
      expect(await tribeBadge.paused()).to.be.false;
    });
  });
});
