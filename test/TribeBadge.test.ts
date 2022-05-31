import { ethers } from 'hardhat';
import { expect } from 'chai';

async function setup() {
  const [owner, alice, bob, carol] = await ethers.getSigners();
	const signer = ethers.Wallet.createRandom();
  const TribeBadge = await ethers.getContractFactory('TribeBadge');
  const tribeBadge = await TribeBadge.deploy('https://sapien.network/badges/{id}.json', signer.address);
  await tribeBadge.deployed();
  return {tribeBadge, owner, alice, bob, carol, signer};
}

describe('TribeBadge', async () => {
	let tribeBadge: any;
	let owner, alice: any, bob: any, carol: any, signer: any;
	
	describe('CreateBadge', async () => {
		it('expect to create a new badge', async () => {
			({tribeBadge, owner, alice, bob, carol, signer} = await setup());
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
			await tribeBadge.mintBatch([bob.address, carol.address], [1, 1], ethers.constants.HashZero);
			// non owner call
			let msgHash = ethers.utils.solidityKeccak256(
				['address', 'address[]', 'uint256[]'],
				[alice.address, [bob.address, carol.address], [1, 1]]
			);
			let msgHashBinary = ethers.utils.arrayify(msgHash);
			let sig = await signer.signMessage(msgHashBinary);
			await tribeBadge.connect(alice).mintBatch([bob.address, carol.address], [1, 1], sig);
			expect((await tribeBadge.balanceOf(bob.address, 1)).toString()).to.eq('2');
			expect((await tribeBadge.balanceOf(carol.address, 1)).toString()).to.eq('2');
		});
		describe('reverts if', async () => {
			it('tries to mint badges not created', async () => {
				await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 2], ethers.constants.HashZero)))
					.to.be.revertedWith('TribeBadge: TOKEN_ID_INVALID');
				});
				it('array params length mismatch', async () => {
					await expect((tribeBadge.mintBatch([bob.address, carol.address], [2, 2, 2], ethers.constants.HashZero)))
						.to.be.revertedWith('TribeBadge: ARRAY_LENGTH_MISMATCH');
			});
		});
	});

	describe('BurnBatch', async () => {
		it('expect to burn batch tokens', async () => {
			await tribeBadge.burnBatch([bob.address, carol.address], [1, 1]);
		});
		describe('reverts if', async () => {
			it('caller is not owner', async () => {
				await expect(tribeBadge.connect(alice).burnBatch([bob.address, carol.address], [1, 1]))
					.to.be.revertedWith('Ownable: caller is not the owner');
			});
		});
	});
});
