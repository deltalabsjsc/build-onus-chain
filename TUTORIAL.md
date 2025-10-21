# Hướng Dẫn Xây Dựng NFT Staking System Trên ONUS Chain

## Giới Thiệu

Tài liệu này hướng dẫn chi tiết cách xây dựng và deploy một **NFT Staking System hoàn chỉnh** lên ONUS Chain, bao gồm:
- 🎨 **MyNFT**: ERC721 NFT collection có thể mint
- 🪙 **RewardToken**: ERC20 token dùng làm rewards
- 🏦 **StakingPool**: Stake NFTs để nhận ERC20 rewards theo thời gian

**Hệ thống hoạt động:**
```
User mint NFTs → Stake NFTs vào Pool → Nhận Reward Tokens theo thời gian
```

Bạn sẽ học cách:
- Thiết lập môi trường phát triển blockchain
- Hiểu cấu trúc của ERC721 NFTs và ERC20 Tokens
- Xây dựng staking pool với reward mechanism
- Deploy contracts lên ONUS Chain Testnet và Mainnet
- Tương tác với NFT staking system

---

## 1. Chuẩn Bị Kỹ Thuật

### 1.1. Yêu Cầu Hệ Thống

#### **Node.js và npm**
- **Phiên bản**: Node.js >= 20.0.0
- **Kiểm tra**:
  ```bash
  node --version
  npm --version
  ```
- **Tải về**: https://nodejs.org/

#### **Git**
```bash
git --version
```
- **Tải về**: https://git-scm.com/downloads

#### **Code Editor**
- Visual Studio Code: https://code.visualstudio.com/
- Extension: Solidity (Juan Blanco)

#### **Ví Crypto (Metamask)**
- Tải extension: https://metamask.io/
- Cấu hình network ONUS Chain

---

### 1.2. Cấu Hình Metamask Cho ONUS Chain

#### **ONUS Chain Testnet**
1. Mở Metamask → Settings → Networks → Add Network
2. Điền thông tin:
   - **Network Name**: ONUS Chain Testnet
   - **RPC URL**: `https://rpc-testnet.onuschain.io`
   - **Chain ID**: `1945`
   - **Currency Symbol**: ONUS
   - **Block Explorer**: `https://explorer-testnet.onuschain.io`

#### **ONUS Chain Mainnet**
1. Mở Metamask → Settings → Networks → Add Network
2. Điền thông tin:
   - **Network Name**: ONUS Chain Mainnet
   - **RPC URL**: `https://rpc.onuschain.io`
   - **Chain ID**: `1975`
   - **Currency Symbol**: ONUS
   - **Block Explorer**: `https://explorer.onuschain.io`

---

### 1.3. Chuẩn Bị ONUS Token

#### **Testnet (miễn phí)**
- Liên hệ ONUS Chain support hoặc faucet để nhận test ONUS
- Hoặc chuyển từ ví khác trên Testnet

#### **Mainnet (chi phí thực)**
- Mua ONUS token từ sàn giao dịch
- Chuyển về địa chỉ ví Metamask
- **Khuyến nghị**: Dự trữ ít nhất 0.1 ONUS cho deployment

⚠️ **LƯU Ý BẢO MẬT**:
- **TUYỆT ĐỐI KHÔNG** chia sẻ private key
- **TUYỆT ĐỐI KHÔNG** commit file `.env` lên Git
- Sử dụng ví test riêng cho development

---

### 1.4. Clone và Cài Đặt

#### **Clone Repository**
```bash
git clone <repository-url>
cd build-onus-chain
```

#### **Cài Đặt Dependencies**
```bash
npm install
```

Các package chính:
- `hardhat`: Framework phát triển smart contract
- `@openzeppelin/contracts` ^5.0.0: Library contracts chuẩn
- `@nomicfoundation/hardhat-toolbox`: Hardhat tools
- `dotenv`: Quản lý environment variables

#### **Cấu Hình Environment Variables**

Tạo file `.env`:
```bash
touch .env
```

Nội dung file `.env`:
```env
# Private key của ví Metamask (KHÔNG có tiền tố 0x)
PRIVATE_KEY=your_private_key_here

# Địa chỉ ví sẽ làm owner của contracts
OWNER_WALLET=0xYourWalletAddress

# Addresses sau khi deploy (sẽ điền sau)
STAKING_NFT_ADDRESS=0xMyNFTAddress
REWARD_TOKEN_ADDRESS=0xRewardTokenAddress
```

**Cách lấy Private Key**:
1. Mở Metamask → 3 chấm → Account Details
2. Export Private Key → Nhập password
3. Copy (bỏ "0x" nếu có)

**Cách lấy Wallet Address**:
1. Mở Metamask
2. Click vào tên account → Address được copy

⚠️ **CẢNH BÁO**: KHÔNG share private key với ai!

#### **Compile Contracts**
```bash
npm run compile
```

Kết quả:
```
Compiled 3 Solidity files successfully (evm target: paris).
```

---

## 2. Kiến Trúc Hệ Thống

### 2.1. Tổng Quan NFT Staking System

```
┌─────────────────────────────────────────────┐
│        NFT Staking System Flow              │
└─────────────────────────────────────────────┘

      ┌──────────┐
      │  MyNFT   │ ← ERC721 NFT Collection
      └────┬─────┘
           │
           │ Users mint NFTs
           │
      ┌────▼─────┐
      │  Users   │
      └────┬─────┘
           │
           │ Stake NFTs
           │
      ┌────▼──────────┐        ┌───────────────┐
      │ StakingPool   │ ◄────► │ RewardToken   │
      │ (ERC721Staking│        │ (ERC20)       │
      └───────────────┘        └───────────────┘
           │
           │ Earn rewards over time
           │
      ┌────▼─────┐
      │ Claim &  │
      │ Unstake  │
      └──────────┘
```

### 2.2. Cấu Trúc Dự Án

```
build-onus-chain/
├── contracts/              # Smart contracts
│   ├── MyNFT.sol          # ERC721 NFT collection
│   ├── RewardToken.sol    # ERC20 reward token
│   └── StakingPool.sol    # NFT staking pool
├── ignition/modules/      # Deployment scripts
│   ├── MyNFT.ts
│   ├── RewardToken.ts
│   └── StakingPool.ts
├── hardhat.config.ts      # Hardhat configuration
├── package.json           # Dependencies
├── tsconfig.json          # TypeScript config
├── .env                   # Environment variables (KHÔNG commit)
├── .gitignore
├── TUTORIAL.md            # File này
└── README.md
```

### 2.3. Giải Thích Từng Component

#### **contracts/**
- **`MyNFT.sol`**: ERC721 NFT contract
  - Mint NFTs với tokenId tùy chỉnh
  - Owner có quyền mint
  - Dùng để stake trong pool

- **`RewardToken.sol`**: ERC20 token
  - Token dùng làm rewards
  - Owner có thể mint để fund pool
  - Tên: "MyToken", Symbol: "MYT"

- **`StakingPool.sol`**: NFT staking pool
  - Stake NFTs để nhận rewards
  - Reward tính theo: tokenPerSecond × NFTs staked × time
  - Pausable, ReentrancyGuard
  - Emergency functions

#### **ignition/modules/**
- **`MyNFT.ts`**: Deploy NFT contract
- **`RewardToken.ts`**: Deploy reward token
- **`StakingPool.ts`**: Deploy staking pool
  - Cần NFT và RewardToken addresses

---

## 3. Mô Tả Chi Tiết Smart Contracts

### 3.1. MyNFT.sol - ERC721 NFT Collection

#### **Tổng Quan**
Contract ERC721 đơn giản để mint NFTs. Mỗi NFT có một tokenId duy nhất.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, Ownable {
    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}
```

#### **Giải Thích Từng Dòng**

##### **Dòng 1-2: License và Version**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
```
- `MIT`: Open-source license
- `^0.8.22`: Solidity version 0.8.22 trở lên

##### **Dòng 4-5: Import OpenZeppelin**
```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
```
- `ERC721`: Standard NFT contract (Non-Fungible Token)
- `Ownable`: Access control (owner management)

##### **Dòng 7: Contract Declaration**
```solidity
contract MyToken is ERC721, Ownable {
```
- Tên contract: `MyToken` (Lưu ý: thực ra là NFT, không phải ERC20 token)
- Kế thừa từ `ERC721` và `Ownable`

##### **Dòng 8-11: Constructor**
```solidity
constructor(address initialOwner)
    ERC721("MyNFT", "MNFT")
    Ownable(initialOwner)
{}
```

**Parameters:**
- `initialOwner`: Địa chỉ sẽ là owner của contract

**Initialization:**
- `ERC721("MyNFT", "MNFT")`:
  - `"MyNFT"`: Tên collection (như "Bored Ape Yacht Club")
  - `"MNFT"`: Symbol (như "BAYC")
- `Ownable(initialOwner)`: Set owner

##### **Dòng 13-15: Mint Function**
```solidity
function mint(address to, uint256 tokenId) public {
    _safeMint(to, tokenId);
}
```

**Function mint():**
- `address to`: Địa chỉ nhận NFT
- `uint256 tokenId`: ID của NFT (phải unique)
- `public`: **BẤT KỲ AI** cũng có thể gọi (⚠️ security issue!)
- `_safeMint()`: Function internal của ERC721
  - Check `to` không phải address(0)
  - Check `tokenId` chưa tồn tại
  - Mint NFT và emit Transfer event
  - Call `onERC721Received` nếu `to` là contract

**⚠️ Lưu ý bảo mật:**
Nên thêm `onlyOwner` modifier:
```solidity
function mint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
}
```

#### **ERC721 Functions Có Sẵn**

```solidity
// View functions
function balanceOf(address owner) public view returns (uint256)
// Số lượng NFTs của owner

function ownerOf(uint256 tokenId) public view returns (address)
// Chủ sở hữu của tokenId

function tokenURI(uint256 tokenId) public view returns (string memory)
// Metadata URI của NFT

// Transfer functions
function transferFrom(address from, address to, uint256 tokenId) public
function safeTransferFrom(address from, address to, uint256 tokenId) public

// Approval functions
function approve(address to, uint256 tokenId) public
function setApprovalForAll(address operator, bool approved) public
function getApproved(uint256 tokenId) public view returns (address)
function isApprovedForAll(address owner, address operator) public view returns (bool)
```

---

### 3.2. RewardToken.sol - ERC20 Reward Token

#### **Tổng Quan**
Contract ERC20 đơn giản dùng làm reward token cho staking pool.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "MYT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
```

#### **Giải Thích Chi Tiết**

##### **Import và Inheritance**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
```
- `ERC20`: Standard fungible token
- `Ownable`: Access control

##### **Constructor**
```solidity
constructor(
    address initialOwner
) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
```
- `ERC20("MyToken", "MYT")`:
  - Token name: `"MyToken"`
  - Token symbol: `"MYT"`
  - Decimals: `18` (mặc định)
- Initial supply: `0` (sẽ mint sau)

##### **Mint Function**
```solidity
function mint(address to, uint256 amount) public {
    _mint(to, amount);
}
```
- `public`: Bất kỳ ai cũng mint được (⚠️ security issue!)
- Nên thêm `onlyOwner`:
```solidity
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

#### **ERC20 Functions Có Sẵn**

```solidity
// View functions
function totalSupply() public view returns (uint256)
function balanceOf(address account) public view returns (uint256)
function allowance(address owner, address spender) public view returns (uint256)

// Transfer functions
function transfer(address to, uint256 amount) public returns (bool)
function transferFrom(address from, address to, uint256 amount) public returns (bool)

// Approval functions
function approve(address spender, uint256 amount) public returns (bool)
```

---

### 3.3. StakingPool.sol - NFT Staking với ERC20 Rewards

#### **Tổng Quan**
Contract phức tạp nhất - cho phép stake NFTs và nhận ERC20 rewards theo thời gian.

**Tính năng chính:**
- 🏦 Stake multiple NFTs cùng lúc
- 💰 Rewards tính theo: `rewardRate × NFTs staked × time`
- ⏱️ Real-time reward calculation
- 🔒 ReentrancyGuard protection
- ⏸️ Pausable (emergency stop)
- 🚨 Emergency unstake by owner

#### **Contract Structure**

```solidity
contract ERC721Staking is IERC721Receiver, Ownable, Pausable, ReentrancyGuard {
    IERC721 public immutable nft;
    IERC20 public immutable rewardToken;
    
    uint256 public rewardRatePerSecond; // scaled 1e18
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public rewardsAccrued;
    mapping(uint256 => address) public stakedOwnerOf;
}
```

#### **Constructor**
```solidity
constructor(
    address _nft,
    address _rewardToken,
    address initialOwner,
    uint256 _rewardRatePerSecond
) Ownable(initialOwner) {
    require(_nft != address(0) && _rewardToken != address(0), "zero addr");
    nft = IERC721(_nft);
    rewardToken = IERC20(_rewardToken);
    rewardRatePerSecond = _rewardRatePerSecond;
}
```

**Parameters:**
- `_nft`: Địa chỉ NFT contract (MyNFT)
- `_rewardToken`: Địa chỉ reward token (RewardToken)
- `initialOwner`: Owner của staking pool
- `_rewardRatePerSecond`: Reward rate (scaled by 1e18)
  - Ví dụ: `1e17` = 0.1 tokens/second/NFT
  - Ví dụ: `1e18` = 1 token/second/NFT

**Why scaled 1e18?**
- Tránh mất precision trong tính toán
- Solidity không có floating point
- 1e18 = 1,000,000,000,000,000,000

#### **Reward Calculation Logic**

##### **Internal View Function**
```solidity
function _earned(address account) internal view returns (uint256) {
    uint256 dt = block.timestamp - lastUpdate[account];
    return
        rewardsAccrued[account] +
        (balanceOf[account] * dt * rewardRatePerSecond);
}
```

**Formula:**
```
earned = rewardsAccrued + (NFTs staked × time elapsed × reward rate)
```

**Example:**
- User stakes 3 NFTs
- Reward rate: 1e17 (0.1 token/second/NFT)
- Time elapsed: 100 seconds
```
earned = 0 + (3 × 100 × 1e17)
       = 3e19
       = 30 tokens (after dividing by 1e18)
```

##### **External View Function**
```solidity
function earned(address account) external view returns (uint256) {
    return _earned(account) / 1e18;
}
```
- Chia cho 1e18 để trả về số tokens readable
- Không tốn gas (view function)

##### **Update Rewards**
```solidity
function _updateRewards(address account) internal {
    rewardsAccrued[account] = _earned(account);
    lastUpdate[account] = block.timestamp;
}
```
- Snapshot rewards hiện tại
- Reset timer để tính reward mới

#### **Stake Function**

```solidity
function stake(
    uint256[] calldata tokenIds
) external whenNotPaused nonReentrant {
    require(tokenIds.length > 0, "empty");
    _updateRewards(msg.sender);

    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tid = tokenIds[i];
        nft.safeTransferFrom(msg.sender, address(this), tid);
        stakedOwnerOf[tid] = msg.sender;
        emit Staked(msg.sender, tid);
    }
    balanceOf[msg.sender] += tokenIds.length;
}
```

**Flow:**
1. Check array không rỗng
2. Update rewards trước khi stake (snapshot)
3. Foreach tokenId:
   - Transfer NFT từ user vào contract
   - Record user là owner của tokenId
   - Emit event
4. Increase balance của user

**Modifiers:**
- `whenNotPaused`: Chỉ chạy khi contract không paused
- `nonReentrant`: Prevent reentrancy attacks

**Requirements:**
- User phải approve contract trước:
```javascript
await nft.setApprovalForAll(stakingPoolAddress, true);
```

#### **Unstake Function**

```solidity
function unstake(uint256[] calldata tokenIds) external nonReentrant {
    require(tokenIds.length > 0, "empty");
    _updateRewards(msg.sender);

    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tid = tokenIds[i];
        require(stakedOwnerOf[tid] == msg.sender, "not staker");
        stakedOwnerOf[tid] = address(0);
        nft.safeTransferFrom(address(this), msg.sender, tid);
        emit Unstaked(msg.sender, tid);
    }
    balanceOf[msg.sender] -= tokenIds.length;
}
```

**Flow:**
1. Update rewards (snapshot trước khi unstake)
2. Foreach tokenId:
   - Verify user là owner
   - Clear ownership record
   - Transfer NFT back to user
   - Emit event
3. Decrease balance

**Note:** Rewards vẫn giữ trong `rewardsAccrued`, cần gọi `claim()` để nhận

#### **Claim Function**

```solidity
function claim() external nonReentrant {
    _updateRewards(msg.sender);

    uint256 amountScaled = rewardsAccrued[msg.sender];
    uint256 amount = amountScaled / 1e18;
    require(amount > 0, "nothing to claim");

    rewardsAccrued[msg.sender] = amountScaled % 1e18;

    require(rewardToken.transfer(msg.sender, amount), "transfer failed");
    emit Claimed(msg.sender, amount);
}
```

**Flow:**
1. Update rewards (tính toán final)
2. Get scaled rewards
3. Convert to actual tokens (chia 1e18)
4. Require amount > 0
5. Reset rewards (giữ lại phần lẻ)
6. Transfer reward tokens
7. Emit event

**Important:**
- Contract phải có đủ reward tokens!
- Owner cần fund pool trước:
```javascript
await rewardToken.mint(stakingPoolAddress, ethers.parseEther("10000"));
```

#### **Admin Functions**

##### **Set Reward Rate**
```solidity
function setRewardRate(uint256 newRate) external onlyOwner {
    rewardRatePerSecond = newRate;
    emit RewardRateUpdated(newRate);
}
```
- Change reward rate
- ⚠️ Recommend: pause pool → update rate → unpause

##### **Pause/Unpause**
```solidity
function pause() external onlyOwner {
    _pause();
}

function unpause() external onlyOwner {
    _unpause();
}
```
- Emergency stop all operations
- Users vẫn có thể unstake khi paused

##### **Emergency Unstake**
```solidity
function emergencyUnstake(uint256[] calldata tokenIds) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tid = tokenIds[i];
        address owner_ = stakedOwnerOf[tid];
        if (owner_ != address(0)) {
            stakedOwnerOf[tid] = address(0);
            balanceOf[owner_] -= 1;
            nft.safeTransferFrom(address(this), owner_, tid);
            emit EmergencyUnstake(owner_, tid);
        }
    }
}
```
- Owner có thể force unstake NFTs về chủ cũ
- ⚠️ Không claim rewards cho user
- Chỉ dùng trong emergency

##### **Admin Recover NFT**
```solidity
function adminRecoverNFT(uint256 tokenId, address to) external onlyOwner {
    require(stakedOwnerOf[tokenId] == address(0), "token is staked");
    nft.safeTransferFrom(address(this), to, tokenId);
}
```
- Recover NFTs gửi nhầm vào contract
- Chỉ được recover NFTs KHÔNG đang stake

#### **IERC721Receiver Implementation**

```solidity
function onERC721Received(
    address /*operator*/,
    address from,
    uint256 tokenId,
    bytes calldata /*data*/
) external override returns (bytes4) {
    require(msg.sender == address(nft), "unknown nft");
    require(stakedOwnerOf[tokenId] == from || paused(), "use stake()");
    return IERC721Receiver.onERC721Received.selector;
}
```

**Purpose:**
- Cho phép contract nhận NFTs qua `safeTransferFrom`
- Validate chỉ nhận NFTs từ `stake()` function
- Prevent NFTs bị kẹt trong contract

---

## 4. Deployment Guide

### 4.1. Deployment Order

**Thứ tự quan trọng vì contracts phụ thuộc lẫn nhau:**

```
1. Deploy MyNFT (NFT Collection) ✓
   ↓
2. Deploy RewardToken (ERC20) ✓
   ↓
3. Deploy StakingPool
   → Cần: MyNFT address + RewardToken address
   ↓
4. Fund StakingPool với RewardTokens
5. Approve StakingPool để transfer NFTs
```

### 4.2. Step-by-Step Deployment

#### **Step 1: Deploy MyNFT**

```bash
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet
```

**Kết quả:**
```
✅ MyNFTModule#MyNFT deployed at: 0xABC123...
```

**Lưu lại address:**
```env
STAKING_NFT_ADDRESS=0xABC123...
```

#### **Step 2: Deploy RewardToken**

```bash
npx hardhat ignition deploy ignition/modules/RewardToken.ts --network onusTestnet
```

**Kết quả:**
```
✅ RewardTokenModule#RewardToken deployed at: 0xDEF456...
```

**Lưu lại address:**
```env
REWARD_TOKEN_ADDRESS=0xDEF456...
```

#### **Step 3: Update .env File**

File `.env` hoàn chỉnh:
```env
PRIVATE_KEY=your_private_key
OWNER_WALLET=0xYourWallet
STAKING_NFT_ADDRESS=0xABC123...
REWARD_TOKEN_ADDRESS=0xDEF456...
```

#### **Step 4: Deploy StakingPool**

```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```

**Kết quả:**
```
✅ StakingPoolModule#StakingPool deployed at: 0xGHI789...
```

#### **Step 5: Fund StakingPool**

Pool cần reward tokens để trả cho stakers:

```javascript
// Trong Hardhat console
npx hardhat console --network onusTestnet

const rewardToken = await ethers.getContractAt("RewardToken", "0xDEF456...");

// Mint 10,000 reward tokens cho pool
await rewardToken.mint("0xGHI789...", ethers.parseEther("10000"));

// Verify
const poolBalance = await rewardToken.balanceOf("0xGHI789...");
console.log("Pool balance:", ethers.formatEther(poolBalance), "tokens");
```

#### **Step 6: Verify Contracts**

```bash
# Verify MyNFT
npx hardhat verify --network onusTestnet <MYNFT_ADDRESS> "<OWNER_WALLET>"

# Verify RewardToken
npx hardhat verify --network onusTestnet <REWARD_TOKEN_ADDRESS> "<OWNER_WALLET>"

# Verify StakingPool
npx hardhat verify --network onusTestnet <STAKING_POOL_ADDRESS> \
  "<MYNFT_ADDRESS>" \
  "<REWARD_TOKEN_ADDRESS>" \
  "<OWNER_WALLET>" \
  "100000000000000000"
```

---

## 5. Bài Tập Thực Hành

### 5.1. Bài Tập 1: Deploy Toàn Bộ System

#### **Mục tiêu:**
Deploy tất cả 3 contracts theo đúng thứ tự

#### **Checklist:**
- [ ] Deploy MyNFT
- [ ] Deploy RewardToken
- [ ] Update .env với addresses
- [ ] Deploy StakingPool
- [ ] Fund pool với reward tokens
- [ ] Verify tất cả contracts

---

### 5.2. Bài Tập 2: Mint và Stake NFTs

#### **Mục tiêu:**
Mint NFTs và stake chúng vào pool

#### **Steps:**

**1. Mint NFTs:**
```javascript
const nft = await ethers.getContractAt("MyNFT", "0xABC123...");
const [owner] = await ethers.getSigners();

// Mint 3 NFTs với tokenIds: 1, 2, 3
await nft.mint(owner.address, 1);
await nft.mint(owner.address, 2);
await nft.mint(owner.address, 3);

// Verify
console.log("Balance:", await nft.balanceOf(owner.address)); // 3
```

**2. Approve StakingPool:**
```javascript
const pool = await ethers.getContractAt("StakingPool", "0xGHI789...");

// Approve pool để transfer NFTs
await nft.setApprovalForAll(pool.address, true);

// Verify
console.log("Approved:", await nft.isApprovedForAll(owner.address, pool.address));
```

**3. Stake NFTs:**
```javascript
// Stake tokenIds: 1, 2, 3
await pool.stake([1, 2, 3]);

// Verify
console.log("Staked NFTs:", await pool.balanceOf(owner.address)); // 3
console.log("Owner of tokenId 1:", await pool.stakedOwnerOf(1)); // owner.address
```

---

### 5.3. Bài Tập 3: Earn và Claim Rewards

#### **Mục tiêu:**
Kiếm rewards và claim chúng

#### **Steps:**

**1. Wait (hoặc Fast Forward):**
```javascript
// Skip 1 day trong test environment
await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
await ethers.provider.send("evm_mine");
```

**2. Check Rewards:**
```javascript
const earned = await pool.earned(owner.address);
console.log("Earned rewards:", ethers.formatEther(earned), "tokens");

// Calculate expected:
// 3 NFTs × 86400 seconds × 0.1 token/second = 25,920 tokens
```

**3. Claim Rewards:**
```javascript
const rewardToken = await ethers.getContractAt("RewardToken", "0xDEF456...");

// Balance before
const balanceBefore = await rewardToken.balanceOf(owner.address);

// Claim
await pool.claim();

// Balance after
const balanceAfter = await rewardToken.balanceOf(owner.address);
console.log("Claimed:", ethers.formatEther(balanceAfter - balanceBefore));
```

---

### 5.4. Bài Tập 4: Unstake NFTs

#### **Mục tiêu:**
Unstake NFTs về ví

#### **Steps:**

```javascript
// Check NFT ownership trước unstake
console.log("NFT owner:", await nft.ownerOf(1)); // StakingPool address

// Unstake tokenIds: 1, 2
await pool.unstake([1, 2]);

// Verify
console.log("Staked remaining:", await pool.balanceOf(owner.address)); // 1
console.log("NFT owner:", await nft.ownerOf(1)); // owner.address (đã về)
console.log("NFT balance:", await nft.balanceOf(owner.address)); // 2
```

---

### 5.5. Bài Tập 5: Test Edge Cases

#### **Mục tiêu:**
Test các trường hợp đặc biệt

#### **Test Cases:**

**1. Unstake NFT không sở hữu:**
```javascript
const [owner, attacker] = await ethers.getSigners();

try {
    await pool.connect(attacker).unstake([3]); // tokenId 3 của owner
    console.log("❌ BUG: Should not allow");
} catch (error) {
    console.log("✅ Correctly prevented:", error.message);
}
```

**2. Claim khi không có rewards:**
```javascript
const [_, newUser] = await ethers.getSigners();

try {
    await pool.connect(newUser).claim();
    console.log("❌ BUG: Should not allow");
} catch (error) {
    console.log("✅ Correctly prevented: nothing to claim");
}
```

**3. Stake khi paused:**
```javascript
// Pause pool
await pool.pause();

try {
    await pool.stake([4]);
    console.log("❌ BUG: Should not allow");
} catch (error) {
    console.log("✅ Correctly prevented: paused");
}

// Unpause
await pool.unpause();
```

**4. Change reward rate:**
```javascript
// Check old rate
const oldRate = await pool.rewardRatePerSecond();
console.log("Old rate:", ethers.formatEther(oldRate * BigInt(1e18)));

// Change rate (1 token/second/NFT)
await pool.setRewardRate(ethers.parseEther("1"));

// Check new rate
const newRate = await pool.rewardRatePerSecond();
console.log("New rate:", ethers.formatEther(newRate * BigInt(1e18)));
```

---

## 6. Các Lỗi Thường Gặp

### 6.1. "STAKING_NFT_ADDRESS is not set"

**Nguyên nhân:** Chưa deploy MyNFT hoặc chưa update .env

**Fix:**
1. Deploy MyNFT trước
2. Copy address vào .env:
```env
STAKING_NFT_ADDRESS=0xYourNFTAddress
```

---

### 6.2. "transfer failed" khi claim

**Nguyên nhân:** Pool không có reward tokens

**Fix:**
```javascript
// Mint reward tokens cho pool
await rewardToken.mint(poolAddress, ethers.parseEther("10000"));
```

---

### 6.3. "not staker" khi unstake

**Nguyên nhân:** Đang unstake NFT không thuộc sở hữu

**Fix:**
- Check ownership: `await pool.stakedOwnerOf(tokenId)`
- Chỉ unstake NFTs của mình

---

### 6.4. "ERC721: transfer from incorrect owner"

**Nguyên nhân:** Chưa approve pool hoặc không own NFT

**Fix:**
```javascript
// Check owner
console.log("Owner:", await nft.ownerOf(tokenId));

// Approve
await nft.setApprovalForAll(poolAddress, true);
```

---

### 6.5. "unknown nft" trong onERC721Received

**Nguyên nhân:** Đang transfer NFT từ contract khác

**Fix:**
- Chỉ stake NFTs từ MyNFT contract được configure
- Không gửi trực tiếp NFTs vào pool

---

## 7. Best Practices

### 7.1. Security

- [ ] Thêm `onlyOwner` cho mint functions
- [ ] Test trên Testnet kỹ trước Mainnet
- [ ] Verify contracts trên explorer
- [ ] Fund pool đủ reward tokens
- [ ] Monitor pool balance thường xuyên
- [ ] Use hardware wallet cho Mainnet
- [ ] Audit code trước khi deploy production

### 7.2. Gas Optimization

- [ ] Stake/unstake multiple NFTs cùng lúc (batch)
- [ ] Claim rewards periodically, không quá thường xuyên
- [ ] Approve một lần cho tất cả NFTs (`setApprovalForAll`)

### 7.3. User Experience

- [ ] Set reward rate hợp lý (không quá cao/thấp)
- [ ] Fund pool đủ rewards cho thời gian dài
- [ ] Document rõ cách tính rewards
- [ ] Provide calculator trên frontend

---

## 8. Tài Nguyên Học Thêm

### Documentation
- **OpenZeppelin**: https://docs.openzeppelin.com/contracts
- **ERC721**: https://eips.ethereum.org/EIPS/eip-721
- **ERC20**: https://eips.ethereum.org/EIPS/eip-20
- **Hardhat**: https://hardhat.org/docs
- **ONUS Chain**: https://docs.onuschain.io

### Tools
- **Remix**: https://remix.ethereum.org
- **OpenSea Testnet**: https://testnets.opensea.io
- **NFT Metadata Standards**: https://docs.opensea.io/docs/metadata-standards

---

## 9. Kết Luận

Bạn đã học được cách xây dựng một **NFT Staking System hoàn chỉnh**:
- ✅ ERC721 NFT Collection
- ✅ ERC20 Reward Token
- ✅ NFT Staking Pool với time-based rewards
- ✅ Security best practices
- ✅ Deployment trên ONUS Chain

**Next Steps:**
1. Deploy lên Testnet và test kỹ
2. Build frontend để interact
3. Add features: rarities, boosted rewards, etc.
4. Deploy lên Mainnet

**Happy Building! 🚀**
