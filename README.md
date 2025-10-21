# Build Onus Chain Contracts

Dự án mẫu để học cách phát triển và deploy smart contracts lên ONUS Chain.

## 📚 Tài Liệu

- **[TUTORIAL.md](./TUTORIAL.md)** - Hướng dẫn chi tiết từng bước cho sinh viên (⭐ BẮT ĐẦU TẠI ĐÂY)
- **README.md** (file này) - Tổng quan nhanh về dự án

## 🚀 Quick Start

### 1. Yêu Cầu

- Node.js >= 20.0.0
- Git
- Metamask với ONUS token

### 2. Cài Đặt

```bash
# Clone repository
git clone <repository-url>
cd build-onus-chain

# Cài đặt dependencies
npm install
```

### 3. Cấu Hình .env

Tạo file `.env` trong thư mục gốc:

```env
PRIVATE_KEY=your_private_key_without_0x
OWNER_WALLET=0xYourWalletAddress
```

**Xem chi tiết**: [TUTORIAL.md](./TUTORIAL.md) - Section 1.4

### 4. Sử Dụng

```bash
# Compile contracts
npm run compile

# Deploy lên Testnet
npm run deploy:testnet ignition/modules/MyToken.ts

# Deploy lên Mainnet
npm run deploy:mainnet ignition/modules/MyToken.ts
```

## 📁 Cấu Trúc Dự Án

```
build-onus-chain/
├── contracts/              # Smart contracts
│   ├── MyToken.sol        # ERC20 token contract
│   └── StakingPool.sol    # Staking pool contract
├── ignition/modules/      # Deployment scripts
│   ├── MyToken.ts
│   └── StakingPool.ts
├── hardhat.config.ts      # Hardhat configuration
├── TUTORIAL.md            # 📚 Hướng dẫn chi tiết
└── .env                   # ⚠️ File cấu hình (không commit)
```

## 🎓 Dành Cho Sinh Viên

Đọc [TUTORIAL.md](./TUTORIAL.md) để có hướng dẫn đầy đủ từ A-Z và thực hành các bài tập.

## 🔗 Networks

### ONUS Chain Testnet
- RPC: `https://rpc-testnet.onuschain.io`
- Chain ID: `1945`
- Explorer: https://explorer-testnet.onuschain.io

### ONUS Chain Mainnet
- RPC: `https://rpc.onuschain.io`
- Chain ID: `1975`
- Explorer: https://explorer.onuschain.io

## 🛠️ Commands

```bash
# Development
npm run compile                    # Compile contracts
npx hardhat clean                  # Clean artifacts

# Deployment
npm run deploy:testnet             # Deploy to testnet
npm run deploy:mainnet             # Deploy to mainnet

# Interaction
npx hardhat console --network onusTestnet   # Interactive console
```

## 📝 Smart Contracts

### MyToken.sol - ERC20 Token
- ✅ Standard ERC20 (transfer, approve, transferFrom)
- ✅ Minting (tạo token mới - onlyOwner)
- ✅ Burning (đốt token)
- ✅ Ownable (quản lý quyền)

### StakingPool.sol - Token Staking
- ✅ Stake ERC20 tokens để nhận rewards
- ✅ APY-based reward calculation (configurable)
- ✅ Lock period (7 days mặc định)
- ✅ Pool limits (total & per user)
- ✅ Auto-compound khi stake thêm
- ✅ Harvest rewards hoặc unstake
- ✅ Pausable & Emergency withdrawal

Xem chi tiết trong [TUTORIAL.md](./TUTORIAL.md)

## ⚠️ Security

**QUAN TRỌNG**:
- **KHÔNG** commit file `.env`
- **KHÔNG** share private key
- Kiểm tra `.gitignore` đã có `.env`
- Sử dụng ví test riêng, không dùng ví chính

## 🤝 Hỗ Trợ

- Đọc [TUTORIAL.md](./TUTORIAL.md) để tìm hiểu các lỗi thường gặp
- Tạo Issue trên GitHub
- Liên hệ instructor hoặc TA

## 📚 Học Thêm

- [Solidity Documentation](https://docs.soliditylang.org)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [ONUS Chain Documentation](https://docs.onuschain.io)

---

**Happy Coding! 🚀**
