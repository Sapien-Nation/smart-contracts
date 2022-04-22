# Sapien Smart Contract
This repo includes smart contracts for:
- Role management
- Passport token (ERC721)
- Passport sale and auction

## RoleManager
- Manage Sapien governance and other roles like marketplaces, tokens
- Core part in Sapien DAO

## Passport
- ERC721 upgradeable
- Mint passport
- Sign passport
- URI management

## PassportSale
- Direct sale for passport NFT
- Put up for sale, set price (SPN, Eth), purchase (SPN, Eth), close
  - Passport is not locked
  - If NFT ownership changes while being open for sale, it can't be purchased
  - Putting up 1 passport in multiple marketplaces is possible
- Sapien governance can set sale starting date and royalties, pause and unpause

## PassportAuction
- Public auction for passport NFT
- Create auction
  - Passport is locked in the contract
- Bid
  - Users can place bids with sufficient funds (>= floor price)
  - Funds are locked in the contract
  - Users can't bid twice for 1 NFT
  - Users can cancel bid before auction ends
- End auction
  - Auction creator can end auction after auction ends
  - Auction creator can select winning bid
  - NFT and funds transfer happen
- Cancel auction
  - Auction creator can cancel before auction ends
  - NFT and all bid funds are returned
- Sapien governance can set maximum auction duration and royalties, pause and unpause

# Development

## Dependencies
- NPM: https://nodejs.org
- Hardhat: https://hardhat.org/

## Step 1. Clone the project
`git clone https://gitlab.tooling-sapien.network/group-backend/smartcontracts.git`

## Step 2. Install dependencies
`$ npm install`

## Step 3. Compile & Test
```
$ npx hardhat compile
$ npx hardhat test
```

## Step 4. Deploy
### Polygon mainnet
`$ npx hardhat --network mainnet deploy`
#### RoleManager
`$ npx hardhat run scripts/deploy_role_manager.ts --network mainnet`
#### Passport NFT
`$ npx hardhat run scripts/deploy_passport.ts --network mainnet`

### Mumbai testnet
`$ npx hardhat --network testnet deploy`
