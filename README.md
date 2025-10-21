# NFT Staking System on ONUS Chain

A complete **NFT Staking System** with ERC721 NFTs and ERC20 reward distribution mechanism built on ONUS Chain.

## 🎯 System Overview

This project demonstrates a DeFi staking system where users can:
1. 🎨 **Mint NFTs** from an ERC721 collection
2. 🏦 **Stake NFTs** into a staking pool
3. 💰 **Earn ERC20 Rewards** based on time and number of NFTs staked
4. 🎁 **Claim Rewards** anytime
5. 🔓 **Unstake NFTs** back to their wallet

```
User mints NFTs → Stakes into Pool → Earns Reward Tokens → Claims & Unstakes
```

---

## 📋 Quick Start

### Prerequisites
- Node.js >= 20.0.0
- npm or yarn
- Metamask wallet
- ONUS tokens (for gas fees)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd build-onus-chain

# Install dependencies
npm install

# Setup environment variables
cp .env.example .env
# Edit .env with your PRIVATE_KEY and OWNER_WALLET

# Compile contracts
npm run compile
```

### Deployment

```bash
# Deploy to ONUS Testnet
npm run deploy:testnet ignition/modules/MyNFT.ts
npm run deploy:testnet ignition/modules/RewardToken.ts

# Update .env with deployed addresses
# Then deploy StakingPool
npm run deploy:testnet ignition/modules/StakingPool.ts

# Deploy to ONUS Mainnet
npm run deploy:mainnet ignition/modules/MyNFT.ts
```

---

## 🛠️ System Requirements

- **Node.js**: v20.0.0 or higher
- **Hardhat**: ^2.26.3
- **OpenZeppelin Contracts**: ^5.4.0
- **Solidity**: ^0.8.22

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
│   ├── MyNFT.sol                # ERC721 NFT collection (file: MyToken)
│   ├── RewardToken.sol          # ERC20 reward token (file: MyToken)
│   └── StakingPool.sol          # NFT staking pool (contract: ERC721Staking)
│
├── ignition/modules/            # Deployment Scripts
│   ├── MyNFT.ts                 # Deploy NFT collection
│   ├── RewardToken.ts           # Deploy reward token
│   └── StakingPool.ts           # Deploy staking pool
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
ERC721 NFT collection for staking.

**Features:**
- Mint NFTs with custom tokenIds
- Standard ERC721 functions
- Owner-controlled (should add `onlyOwner` to mint)

**Metadata:**
- Name: `"MyNFT"`
- Symbol: `"MNFT"`

**Key Functions:**
```solidity
mint(address to, uint256 tokenId)  // Mint NFT to address
```

---

### 2. RewardToken.sol (Contract: `MyToken`)
ERC20 token used as staking rewards.

**Features:**
- Standard ERC20 fungible token
- Mintable by owner
- 18 decimals (standard)

**Metadata:**
- Name: `"MyToken"`
- Symbol: `"MYT"`
- Decimals: `18`

**Key Functions:**
```solidity
mint(address to, uint256 amount)  // Mint reward tokens
```

---

### 3. StakingPool.sol (Contract: `ERC721Staking`)
NFT staking pool with time-based ERC20 rewards.

**Features:**
- ✅ Stake multiple NFTs at once
- ✅ Real-time reward calculation
- ✅ Time-based rewards (per second per NFT)
- ✅ Pausable (emergency stop)
- ✅ ReentrancyGuard protection
- ✅ Emergency unstake by owner
- ✅ IERC721Receiver implementation

**Reward Formula:**
```
Rewards = (NFTs staked) × (time elapsed) × (reward rate)
```

**Example:**
- Staked: 3 NFTs
- Time: 100 seconds
- Rate: 0.1 token/second/NFT
- **Rewards**: `3 × 100 × 0.1 = 30 tokens`

**Key Functions:**
```solidity
// User functions
stake(uint256[] calldata tokenIds)        // Stake NFTs
unstake(uint256[] calldata tokenIds)      // Unstake NFTs
claim()                                   // Claim rewards
earned(address account) view              // View pending rewards

// Admin functions
setRewardRate(uint256 newRate)           // Update reward rate
pause() / unpause()                      // Emergency control
emergencyUnstake(uint256[] tokenIds)     // Force unstake
```

**State Variables:**
- `rewardRatePerSecond`: Rewards per second per NFT (scaled by 1e18)
- `balanceOf[address]`: Number of NFTs staked by address
- `lastUpdate[address]`: Last reward update timestamp
- `rewardsAccrued[address]`: Accumulated rewards (scaled by 1e18)
- `stakedOwnerOf[tokenId]`: Owner of staked NFT

---

## 🔧 Available Scripts

```bash
# Compile contracts
npm run compile

# Deploy to Testnet
npm run deploy:testnet ignition/modules/<ModuleName>.ts

# Deploy to Mainnet
npm run deploy:mainnet ignition/modules/<ModuleName>.ts

# Run Hardhat console
npx hardhat console --network onusTestnet

# Verify contract
npx hardhat verify --network onusTestnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 🚀 Deployment Flow

### Step-by-Step Guide

#### 1️⃣ Deploy MyNFT
```bash
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet
```
Save the deployed address to `.env`:
```env
STAKING_NFT_ADDRESS=0xYourNFTAddress
```

#### 2️⃣ Deploy RewardToken
```bash
npx hardhat ignition deploy ignition/modules/RewardToken.ts --network onusTestnet
```
Save the address:
```env
REWARD_TOKEN_ADDRESS=0xYourRewardTokenAddress
```

#### 3️⃣ Deploy StakingPool
```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```

#### 4️⃣ Fund the Pool
```javascript
// In Hardhat console
const rewardToken = await ethers.getContractAt("RewardToken", "<REWARD_TOKEN_ADDRESS>");
await rewardToken.mint("<STAKING_POOL_ADDRESS>", ethers.parseEther("10000"));
```

#### 5️⃣ Verify Contracts
```bash
npx hardhat verify --network onusTestnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 💡 Usage Examples

### Mint NFTs
```javascript
const nft = await ethers.getContractAt("MyNFT", "<NFT_ADDRESS>");
await nft.mint(userAddress, 1);  // Mint tokenId 1
await nft.mint(userAddress, 2);  // Mint tokenId 2
```

### Approve Staking Pool
```javascript
await nft.setApprovalForAll("<STAKING_POOL_ADDRESS>", true);
```

### Stake NFTs
```javascript
const pool = await ethers.getContractAt("StakingPool", "<POOL_ADDRESS>");
await pool.stake([1, 2]);  // Stake tokenIds 1 and 2
```

### Check Rewards
```javascript
const earned = await pool.earned(userAddress);
console.log("Earned:", ethers.formatEther(earned), "tokens");
```

### Claim Rewards
```javascript
await pool.claim();
```

### Unstake NFTs
```javascript
await pool.unstake([1, 2]);  // Unstake tokenIds 1 and 2
```

---

## ⚠️ Important Notes

### Security
- ⚠️ **NEVER** commit `.env` file to Git
- ⚠️ **NEVER** share your private key
- ⚠️ Test thoroughly on Testnet before Mainnet deployment
- ⚠️ Consider adding `onlyOwner` modifier to mint functions
- ⚠️ Ensure StakingPool has enough reward tokens funded

### Best Practices
- ✅ Verify contracts on explorer after deployment
- ✅ Use hardware wallet for Mainnet
- ✅ Audit contracts before production use
- ✅ Monitor pool balance regularly
- ✅ Set reasonable reward rates
- ✅ Batch stake/unstake operations to save gas

---

## 📚 Learn More

### Documentation
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts
- **Hardhat**: https://hardhat.org/docs
- **ERC721 Standard**: https://eips.ethereum.org/EIPS/eip-721
- **ERC20 Standard**: https://eips.ethereum.org/EIPS/eip-20
- **ONUS Chain Docs**: https://docs.onuschain.io

### Tutorials
- See `TUTORIAL.md` for comprehensive Vietnamese guide
- Detailed explanations of each contract
- Step-by-step practical exercises

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🆘 Support

For questions or issues:
- Open an issue on GitHub
- Contact ONUS Chain support
- Check `TUTORIAL.md` for detailed troubleshooting

---

**Built with ❤️ for ONUS Chain community**
