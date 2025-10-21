# NFT Ecosystem on ONUS Chain

A complete **NFT Ecosystem** with staking rewards and marketplace functionality built on ONUS Chain.

## 🎯 System Overview

This project demonstrates a complete DeFi NFT ecosystem where users can:
1. 🎨 **Mint NFTs** from an ERC721 collection
2. 🏦 **Stake NFTs** to earn ERC20 rewards over time
3. 💰 **Earn Rewards** based on staking duration and number of NFTs
4. 🛒 **List/Sell NFTs** on a non-custodial marketplace
5. 👑 **Automatic Royalties** via ERC2981 standard

```
Mint NFTs → Stake to Earn Rewards → List/Sell on Marketplace
```

---

## 📋 Prerequisites

- Node.js >= 20.0.0
- Hardhat >= 2.26.3
- ONUS Chain Testnet/Mainnet RPC URL
- Owner Wallet Address
- Private Key
- ONUS tokens for gas fees (on Metamask)

---

## 🚀 Quick Start

### Setup

```shell
# Clone repository
git clone <repository-url>
cd build-onus-chain

# Copy environment file
cp .env.example .env
```

Fill in the values in the `.env` file:
```env
PRIVATE_KEY=your_private_key_without_0x
OWNER_WALLET=0xYourWalletAddress
FEE_RECIPIENT=0xYourWalletAddress

# Fill these after deployment
STAKING_NFT_ADDRESS=0xMyNFTAddress
REWARD_TOKEN_ADDRESS=0xRewardTokenAddress
```

### Installation

```shell
npm install
```

### Compile Contracts

```shell
npm run compile
```

### Deploy to Testnet

```shell
# Deploy in order:
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet
npx hardhat ignition deploy ignition/modules/RewardToken.ts --network onusTestnet
npx hardhat ignition deploy ignition/modules/NFTMarketplace.ts --network onusTestnet

# Update .env with deployed addresses, then:
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```

### Deploy to Mainnet

```shell
npm run deploy:mainnet ignition/modules/MyNFT.ts
npm run deploy:mainnet ignition/modules/RewardToken.ts
npm run deploy:mainnet ignition/modules/NFTMarketplace.ts
# Update .env, then:
npm run deploy:mainnet ignition/modules/StakingPool.ts
```

---

## 🌐 Network Configurations

### ONUS Chain Testnet
- **RPC URL**: `https://rpc-testnet.onuschain.io`
- **Chain ID**: `1945`
- **Currency**: ONUS
- **Explorer**: https://explorer-testnet.onuschain.io

### ONUS Chain Mainnet
- **RPC URL**: `https://rpc.onuschain.io`
- **Chain ID**: `1975`
- **Currency**: ONUS
- **Explorer**: https://explorer.onuschain.io

---

## 📁 Project Structure

```
build-onus-chain/
├── contracts/                    # Smart Contracts
│   ├── MyNFT.sol                # ERC721 NFT collection (contract: MyToken)
│   ├── RewardToken.sol          # ERC20 reward token (contract: MyToken)
│   ├── StakingPool.sol          # NFT staking pool (contract: ERC721Staking)
│   └── NFTMarketplace.sol       # Non-custodial marketplace
│
├── ignition/modules/            # Hardhat Ignition deployment scripts
│   ├── MyNFT.ts                 # Deploy NFT collection
│   ├── RewardToken.ts           # Deploy reward token
│   ├── StakingPool.ts           # Deploy staking pool
│   └── NFTMarketplace.ts        # Deploy marketplace
│
├── hardhat.config.ts            # Hardhat configuration
├── package.json                 # Dependencies and scripts
├── tsconfig.json                # TypeScript configuration
├── .env                         # Environment variables (DO NOT COMMIT)
├── .gitignore
├── TUTORIAL.md                  # Comprehensive guide (Vietnamese)
└── README.md                    # This file
```

---

## 📜 Smart Contracts

### 1. MyNFT.sol (Contract: `MyToken`)
**ERC721 NFT collection for minting and trading.**

**Features:**
- Standard ERC721 implementation
- Mint NFTs with custom tokenIds
- Public mint function (consider adding `onlyOwner` for production)

**Metadata:**
- Name: `"MyNFT"`
- Symbol: `"MNFT"`

**Key Functions:**
```solidity
mint(address to, uint256 tokenId)     // Mint new NFT
```

---

### 2. RewardToken.sol (Contract: `MyToken`)
**ERC20 token used as staking rewards.**

**Features:**
- Standard ERC20 fungible token
- Mintable (for funding staking pool)
- 18 decimals (standard)

**Metadata:**
- Name: `"MyToken"`
- Symbol: `"MYT"`
- Decimals: `18`

**Key Functions:**
```solidity
mint(address to, uint256 amount)      // Mint reward tokens
```

---

### 3. StakingPool.sol (Contract: `ERC721Staking`)
**NFT staking pool with time-based ERC20 rewards.**

**Features:**
- ✅ Stake multiple NFTs simultaneously
- ✅ Real-time reward calculation
- ✅ Time-based rewards (per second per NFT)
- ✅ Pausable (emergency stop)
- ✅ ReentrancyGuard protection
- ✅ Emergency unstake by owner
- ✅ IERC721Receiver implementation

**Reward Formula:**
```
Rewards = (NFTs staked) × (time elapsed in seconds) × (reward rate per second)
```

**Example:**
- Staked: **3 NFTs**
- Time: **1 hour** (3,600 seconds)
- Rate: **0.1 token/second/NFT** (1e17 scaled)
- **Rewards**: `3 × 3,600 × 0.1 = 1,080 tokens`

**Key Functions:**
```solidity
// User functions
stake(uint256[] calldata tokenIds)        // Stake NFTs to earn rewards
unstake(uint256[] calldata tokenIds)      // Unstake NFTs back to wallet
claim()                                   // Claim accumulated rewards
earned(address account) view              // View pending rewards

// Admin functions
setRewardRate(uint256 newRate)           // Update reward rate
pause() / unpause()                      // Emergency control
emergencyUnstake(uint256[] tokenIds)     // Force unstake (owner only)
adminRecoverNFT(uint256 tokenId, ...)    // Recover accidentally sent NFTs
```

**State Variables:**
- `rewardRatePerSecond`: Rewards per second per NFT (scaled by 1e18)
- `balanceOf[address]`: Number of NFTs staked by address
- `lastUpdate[address]`: Last reward update timestamp
- `rewardsAccrued[address]`: Accumulated rewards (scaled by 1e18)
- `stakedOwnerOf[tokenId]`: Owner of staked NFT

---

### 4. NFTMarketplace.sol
**Non-custodial marketplace for buying/selling NFTs with native ONUS token.**

**Features:**
- 🔓 **Non-custodial**: NFTs remain in seller's wallet until sold
- 💰 **Native coin payment**: Buy/sell with ONUS (not ERC20)
- 💵 **Platform fee**: Configurable fee in basis points (bps)
- 👑 **ERC2981 Royalty**: Automatic royalty distribution to creators
- ⏰ **Scheduled listings**: Start time for delayed sales
- 🔒 **ReentrancyGuard**: Protection against reentrancy attacks
- ⏸️ **Pausable**: Emergency stop mechanism

**Platform Fee (Basis Points):**
- 100 bps = 1%
- 250 bps = 2.5%
- 1000 bps = 10%
- Default: **100 bps (1%)**

**Payment Distribution Example:**
```
Sale Price: 10 ONUS
├─ Platform Fee (1%):     0.1 ONUS  → Fee Recipient
├─ Royalty (5%, if ERC2981): 0.5 ONUS  → Creator
└─ Seller Proceeds:       9.4 ONUS  → Seller
```

**Key Functions:**
```solidity
// User functions
list(address nft, uint256 tokenId, uint256 price, uint64 startTime)
                                          // List NFT for sale
updatePrice(address nft, uint256 tokenId, uint256 newPrice)
                                          // Update listing price
cancel(address nft, uint256 tokenId)     // Cancel listing
buy(address nft, uint256 tokenId) payable // Buy NFT with native coin

// View functions
getListing(address nft, uint256 tokenId) // Get listing details

// Admin functions
setFeeParams(uint96 _feeBps, address _feeRecipient)
                                          // Update platform fee
pause() / unpause()                       // Emergency control
```

**Struct Listing:**
```solidity
struct Listing {
    address seller;      // Seller address
    uint128 price;       // Price in wei (native coin)
    uint64  startTime;   // Unix timestamp when sale starts
}
```

---

## 🔧 Available Scripts

```shell
# Compile contracts
npm run compile

# Deploy to Testnet
npm run deploy:testnet

# Deploy to Mainnet
npm run deploy:mainnet

# Run Hardhat console
npx hardhat console --network onusTestnet

# Verify contract on explorer
npx hardhat verify --network onusTestnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 🚀 Deployment Flow

### Complete Deployment Steps

#### 1️⃣ Deploy MyNFT
```bash
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet
```
**Output**: `✅ MyNFTModule#MyToken deployed at: 0xABC...`

Save address to `.env`:
```env
STAKING_NFT_ADDRESS=0xABC...
```

#### 2️⃣ Deploy RewardToken
```bash
npx hardhat ignition deploy ignition/modules/RewardToken.ts --network onusTestnet
```
**Output**: `✅ RewardTokenModule#MyToken deployed at: 0xDEF...`

Save address to `.env`:
```env
REWARD_TOKEN_ADDRESS=0xDEF...
```

#### 3️⃣ Deploy NFTMarketplace
```bash
npx hardhat ignition deploy ignition/modules/NFTMarketplace.ts --network onusTestnet
```
**Output**: `✅ NFTMarketplaceModule#NFTMarketplace deployed at: 0xGHI...`

#### 4️⃣ Deploy StakingPool
After updating `.env` with NFT and RewardToken addresses:
```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```
**Output**: `✅ StakingPoolModule#ERC721Staking deployed at: 0xJKL...`

#### 5️⃣ Fund StakingPool
```javascript
// In Hardhat console
const rewardToken = await ethers.getContractAt("RewardToken", "<REWARD_TOKEN_ADDRESS>");
await rewardToken.mint("<STAKING_POOL_ADDRESS>", ethers.parseEther("100000"));
```

#### 6️⃣ Verify Contracts
```bash
npx hardhat verify --network onusTestnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 💡 Usage Examples

### Minting NFTs
```javascript
const nft = await ethers.getContractAt("MyNFT", "<NFT_ADDRESS>");
await nft.mint(userAddress, 1);  // Mint tokenId 1
await nft.mint(userAddress, 2);  // Mint tokenId 2
```

### Staking NFTs
```javascript
const pool = await ethers.getContractAt("StakingPool", "<POOL_ADDRESS>");

// Approve pool to transfer NFTs
await nft.setApprovalForAll(pool.address, true);

// Stake tokenIds: 1, 2, 3
await pool.stake([1, 2, 3]);

// Check staked balance
console.log(await pool.balanceOf(userAddress));  // 3
```

### Checking Rewards
```javascript
// View pending rewards (doesn't cost gas)
const earned = await pool.earned(userAddress);
console.log("Earned:", ethers.formatEther(earned), "tokens");
```

### Claiming Rewards
```javascript
await pool.claim();
```

### Unstaking NFTs
```javascript
// Unstake tokenIds: 1, 2
await pool.unstake([1, 2]);
```

### Listing NFT on Marketplace
```javascript
const marketplace = await ethers.getContractAt("NFTMarketplace", "<MARKETPLACE_ADDRESS>");

// Approve marketplace
await nft.setApprovalForAll(marketplace.address, true);

// List tokenId 1 for 10 ONUS
const price = ethers.parseEther("10.0");
const startTime = 0;  // 0 = immediate sale
await marketplace.list(nft.address, 1, price, startTime);
```

### Buying NFT
```javascript
// Buy tokenId 1
await marketplace.buy(nft.address, 1, {
    value: ethers.parseEther("10.0")  // Send ONUS with transaction
});
```

### Cancel Listing
```javascript
await marketplace.cancel(nft.address, 1);
```

---

## ⚠️ Important Notes

### Security
- ⚠️ **NEVER** commit `.env` file to Git
- ⚠️ **NEVER** share your private key
- ⚠️ Test thoroughly on Testnet before Mainnet deployment
- ⚠️ Consider adding `onlyOwner` modifier to mint functions in production
- ⚠️ Ensure StakingPool has sufficient reward tokens funded
- ⚠️ Monitor contract balances regularly

### Best Practices
- ✅ Verify all contracts on block explorer after deployment
- ✅ Use hardware wallet for Mainnet deployments
- ✅ Audit contracts before production use
- ✅ Set reasonable reward rates for sustainability
- ✅ Set reasonable platform fees (1-5% recommended)
- ✅ Batch stake/unstake operations to save gas
- ✅ Document all admin actions

### Gas Optimization
- Stake/unstake multiple NFTs in one transaction (batch operations)
- Claim rewards periodically, not after every action
- Use `setApprovalForAll` instead of individual approvals
- Consider gas prices when deploying on Mainnet

---

## 📚 Learn More

### Documentation
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts
- **Hardhat**: https://hardhat.org/docs
- **ERC721 Standard**: https://eips.ethereum.org/EIPS/eip-721
- **ERC20 Standard**: https://eips.ethereum.org/EIPS/eip-20
- **ERC2981 Royalty**: https://eips.ethereum.org/EIPS/eip-2981
- **ONUS Chain Docs**: https://docs.onuschain.io
- **Ethers.js**: https://docs.ethers.org/v6/

### Tutorials
- See **TUTORIAL.md** for comprehensive Vietnamese guide with:
  - Detailed contract explanations (line-by-line)
  - Step-by-step deployment guide
  - Practical exercises with code examples
  - Troubleshooting common errors
  - Advanced scenarios

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🆘 Support

For questions or issues:
- Open an issue on GitHub
- Contact ONUS Chain support: https://docs.onuschain.io
- Check **TUTORIAL.md** for detailed troubleshooting and examples

---

## 🎓 Educational Use

This project is designed for educational purposes to teach:
- Smart contract development with Solidity
- ERC721 (NFT) and ERC20 (Token) standards
- DeFi concepts (staking, rewards, APY)
- NFT marketplace mechanics
- Security best practices
- Deployment and verification processes

**Perfect for:**
- University blockchain courses
- Bootcamp projects
- Self-learning blockchain development
- Building portfolio projects

---

**Built with ❤️ for ONUS Chain community**

**System Architecture:**
```
┌──────────┐
│  MyNFT   │ ← Mint NFTs (ERC721)
└────┬─────┘
     │
     ├─────────────────┬──────────────────┐
     │                 │                  │
┌────▼────────┐   ┌───▼────────────┐    │
│StakingPool  │   │ NFTMarketplace │    │
│(Earn Rewards│   │ (Buy/Sell)     │    │
└─────┬───────┘   └────────────────┘    │
      │                                  │
┌─────▼─────┐                           │
│RewardToken│ ◄───────────────────────────┘
│ (ERC20)   │
└───────────┘
```
