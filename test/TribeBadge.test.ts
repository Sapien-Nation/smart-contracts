import { ethers } from 'hardhat';
import { expect } from 'chai';

async function setup() {
  const [owner, alice, bob, carol, darren, eric] = await ethers.getSigners();
	const signer = ethers.Wallet.createRandom();
  const TribeBadge = await ethers.getContractFactory('TribeBadge');
  const tribeBadge = await TribeBadge.deploy('https://sapien.network/badges/{id}.json', signer.address);
  await tribeBadge.deployed();
  return {tribeBadge, owner, alice, bob, carol, darren, eric, signer};
}

describe('TribeBadge', async () => {
	let tribeBadge: any;
	let owner, alice: any, bob: any, carol: any, darren: any, eric: any, signer: any;
	
	describe('CreateBatch', async () => {
		it('expect to create new badges', async () => {
			({tribeBadge, owner, alice, bob, carol, darren, eric, signer} = await setup());
      // signature
      let msgHash = ethers.utils.solidityKeccak256(
				['address', 'address[]'],
				[alice.address, [bob.address, carol.address]]
			);
			let msgHashBinary = ethers.utils.arrayify(msgHash);
			let sig = await signer.signMessage(msgHashBinary);
			await tribeBadge.connect(alice).createBatch([bob.address, carol.address], sig);
			expect((await tribeBadge.badgeID()).toString()).to.eq('1');
      expect((await tribeBadge.balanceOf(bob.address, 1)).toString()).to.eq('1');
      expect((await tribeBadge.balanceOf(carol.address, 1)).toString()).to.eq('1');
		});
		describe('reverts if', async () => {
			it('caller is owner', async () => {
				await expect(tribeBadge.createBatch([bob.address, carol.address], ethers.constants.HashZero))
					.to.be.revertedWith('TribeBadge: MULTISIG_NOT_ALLOWED');
			});
		});
	});

	describe('MintBatch', async () => {
		it('expect to mint batch tokens', async () => {
			// owner call
			await tribeBadge.mintBatch([darren.address], [1], ethers.constants.HashZero);
			// non owner call
			let msgHash = ethers.utils.solidityKeccak256(
				['address', 'address[]', 'uint256[]'],
				[alice.address, [eric.address], [1]]
			);
			let msgHashBinary = ethers.utils.arrayify(msgHash);
			let sig = await signer.signMessage(msgHashBinary);
			await tribeBadge.connect(alice).mintBatch([eric.address], [1], sig);
			expect((await tribeBadge.balanceOf(darren.address, 1)).toString()).to.eq('1');
			expect((await tribeBadge.balanceOf(eric.address, 1)).toString()).to.eq('1');
		});
    describe('reverts if', async () => {
      it('tries to mint badges not created', async () => {
        await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 0], ethers.constants.HashZero)))
          .to.be.revertedWith('TribeBadge: TOKEN_ID_INVALID');
      });
      it('array params length mismatch', async () => {
        await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 2, 2], ethers.constants.HashZero)))
          .to.be.revertedWith('TribeBadge: ARRAY_LENGTH_MISMATCH');
      });
      it('accounts already own at least 1 badge', async () => {
        await expect(tribeBadge.mintBatch([bob.address, carol.address], [1, 1], ethers.constants.HashZero))
          .to.be.revertedWith('TribeBadge: TOKEN_ALREADY_OWN');
      });
    });
	});

  describe('Setters for URI and signer address', async () => {
    it('expect to set new URI', async () => {
      await tribeBadge.setURI('https://sapien.network/badges/updated/{id}.json');
      expect(await tribeBadge.uri(1)).to.eq('https://sapien.network/badges/updated/{id}.json');
    });
    it('expect to set new signer', async () => {
      await expect(tribeBadge.setSigner(alice.address))
        .to.emit(tribeBadge, 'LogSignerSet').withArgs(alice.address);
    });
    describe('reverts if', async () => {
      it('caller is not owner', async () => {
        await expect(tribeBadge.connect(alice).setURI('https://sapien.network/badges/updated/{id}.json'))
          .to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('new URI is empty string', async () => {
        await expect(tribeBadge.setURI(''))
          .to.be.revertedWith('TribeBadge: EMPTY_STRING');
      });
      it('new signer is zero address', async () => {
        await expect(tribeBadge.setSigner(ethers.constants.AddressZero))
          .to.be.revertedWith('TribeBadge: ZERO_ADDRESS');
      });
    });
  });

  describe('Non transferable', async () => {
    it('expect to badge transfer disabled', async () => {
      await expect(tribeBadge.connect(darren).safeTransferFrom(darren.address, alice.address, 1, 1, ethers.constants.HashZero))
        .to.be.revertedWith('TribeBadge: TRANSFER_DISABLED');
    });
  })
});
