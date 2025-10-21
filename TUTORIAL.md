# Hướng Dẫn Xây Dựng NFT Ecosystem Trên ONUS Chain

## Giới Thiệu

Tài liệu này hướng dẫn chi tiết cách xây dựng và deploy một **NFT Ecosystem hoàn chỉnh** lên ONUS Chain, bao gồm:
- 🎨 **MyNFT**: ERC721 NFT collection có thể mint
- 🪙 **RewardToken**: ERC20 token dùng làm rewards
- 🏦 **StakingPool**: Stake NFTs để nhận ERC20 rewards theo thời gian
- 🛒 **NFTMarketplace**: Non-custodial marketplace với platform fee và ERC2981 royalty

**Hệ thống hoạt động:**
```
User mint NFTs → Stake NFTs để earn rewards → List/Sell NFTs trên Marketplace
```

Bạn sẽ học cách:
- Thiết lập môi trường phát triển blockchain
- Hiểu cấu trúc ERC721, ERC20, Staking, Marketplace
- Xây dựng NFT ecosystem với multiple contracts
- Deploy contracts lên ONUS Chain
- Tương tác với toàn bộ hệ thống

---

## 1. Chuẩn Bị Kỹ Thuật

### 1.1. Yêu Cầu Hệ Thống

#### **Node.js và npm**
- **Phiên bản**: Node.js >= 20.0.0
- **Kiểm tra**:
  ```bash
  node --version  # Should be >= v20.0.0
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
- Extension khuyến nghị: Solidity (Juan Blanco)

#### **Ví Crypto (Metamask)**
- Tải extension: https://metamask.io/
- Cần để interact với contracts

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
- Liên hệ ONUS Chain support để nhận test ONUS
- Cần cho gas fees khi deploy và test

#### **Mainnet (chi phí thực)**
- Mua ONUS token từ sàn giao dịch
- Chuyển về địa chỉ ví Metamask
- **Khuyến nghị**: Dự trữ ít nhất 0.1 ONUS cho deployment

⚠️ **LƯU Ý BẢO MẬT**:
- **TUYỆT ĐỐI KHÔNG** chia sẻ private key
- **TUYỆT ĐỐI KHÔNG** commit file `.env` lên Git  
- **TUYỆT ĐỐI KHÔNG** sử dụng ví chính cho testnet
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
- `hardhat` ^2.26.3: Framework phát triển smart contract
- `@openzeppelin/contracts` ^5.4.0: Library contracts chuẩn
- `@nomicfoundation/hardhat-toolbox`: Hardhat tools
- `dotenv`: Quản lý environment variables

#### **Cấu Hình Environment Variables**

Tạo file `.env`:
```bash
cp .env.example .env
```

Nội dung file `.env`:
```env
# Private key của ví Metamask (KHÔNG có tiền tố 0x)
PRIVATE_KEY=your_private_key_here

# Địa chỉ ví sẽ làm owner của contracts
OWNER_WALLET=0xYourWalletAddress

# Địa chỉ nhận platform fee (mặc định = OWNER_WALLET)
FEE_RECIPIENT=0xYourWalletAddress

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

#### **Compile Contracts**
```bash
npm run compile
```

Kết quả:
```
Compiled 4 Solidity files successfully
```

---

## 2. Kiến Trúc Hệ Thống

### 2.1. Tổng Quan NFT Ecosystem

```
┌────────────────────────────────────────────────────────┐
│              NFT Ecosystem Flow                        │
└────────────────────────────────────────────────────────┘

      ┌──────────┐
      │  MyNFT   │ ← Mint NFTs (ERC721)
      └────┬─────┘
           │
           ├──────────────┬─────────────────┐
           │              │                 │
      ┌────▼────────┐  ┌──▼───────────┐   │
      │ StakingPool │  │ NFTMarket-   │   │
      │ (Stake NFTs)│  │ place        │   │
      └─────┬───────┘  └──────────────┘   │
            │                              │
            │ Earn rewards                 │
            │                              │
      ┌─────▼─────┐                       │
      │ RewardToken│ ◄─────────────────────┘
      │ (ERC20)    │
      └────────────┘
```

**Flow chi tiết:**
1. 🎨 User **mint NFTs** từ MyNFT contract
2. 🏦 User **stake NFTs** vào StakingPool → earn RewardTokens
3. 🎁 User **claim rewards** từ staking
4. 🛒 User **list NFTs** trên NFTMarketplace để bán
5. 💰 Buyer **mua NFTs** bằng native ONUS token

### 2.2. Cấu Trúc Dự Án

```
build-onus-chain/
├── contracts/                 # Smart contracts
│   ├── MyNFT.sol             # ERC721 NFT collection
│   ├── RewardToken.sol       # ERC20 reward token
│   ├── StakingPool.sol       # NFT staking pool (ERC721Staking)
│   └── NFTMarketplace.sol    # NFT marketplace
│
├── ignition/modules/         # Deployment scripts
│   ├── MyNFT.ts
│   ├── RewardToken.ts
│   ├── StakingPool.ts
│   └── NFTMarketplace.ts
│
├── hardhat.config.ts         # Hardhat configuration
├── package.json              # Dependencies
├── tsconfig.json             # TypeScript config
├── .env                      # Environment variables (KHÔNG commit)
├── .gitignore
├── TUTORIAL.md               # File này
└── README.md                 # Quick reference
```

---

## 3. Mô Tả Chi Tiết Smart Contracts

### 3.1. MyNFT.sol - ERC721 NFT Collection

#### **Tổng Quan**
Contract ERC721 đơn giản để mint NFTs. Mỗi NFT có một `tokenId` duy nhất.

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

#### **Giải Thích Chi Tiết**

##### **License và Version**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
```
- `MIT`: Open-source license
- `^0.8.22`: Solidity compiler version

##### **Imports**
```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
```
- **ERC721**: Standard NFT implementation (Non-Fungible Token)
  - Mỗi token là unique, không thể thay thế
  - Ví dụ: CryptoPunks, Bored Apes
- **Ownable**: Contract có owner với quyền đặc biệt

##### **Contract Declaration**
```solidity
contract MyToken is ERC721, Ownable {
```
- Tên contract: `MyToken` (lưu ý: file là MyNFT.sol)
- Kế thừa từ `ERC721` và `Ownable`

##### **Constructor**
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
  - Collection name: `"MyNFT"`
  - Collection symbol: `"MNFT"`
- `Ownable(initialOwner)`: Set owner

##### **Mint Function**
```solidity
function mint(address to, uint256 tokenId) public {
    _safeMint(to, tokenId);
}
```

**Parameters:**
- `to`: Địa chỉ nhận NFT
- `tokenId`: ID của NFT (phải unique, chưa được mint)

**Visibility:**
- `public`: **BẤT KỲ AI** cũng có thể mint (⚠️ security issue!)

**Recommended fix:**
```solidity
function mint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
}
```

**`_safeMint()` internal function:**
- Check `to` không phải address(0)
- Check `tokenId` chưa tồn tại
- Mint NFT cho `to`
- Emit `Transfer` event
- Nếu `to` là contract, call `onERC721Received`

#### **ERC721 Functions Có Sẵn**

```solidity
// View functions
balanceOf(address owner) → uint256        // Số NFTs của owner
ownerOf(uint256 tokenId) → address        // Owner của tokenId
tokenURI(uint256 tokenId) → string        // Metadata URI

// Transfer functions
transferFrom(address from, address to, uint256 tokenId)
safeTransferFrom(address from, address to, uint256 tokenId)

// Approval functions
approve(address to, uint256 tokenId)
setApprovalForAll(address operator, bool approved)
getApproved(uint256 tokenId) → address
isApprovedForAll(address owner, address operator) → bool
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

##### **Imports và Inheritance**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
```
- **ERC20**: Standard fungible token (có thể thay thế)
  - Mỗi token có giá trị như nhau
  - Ví dụ: USDT, USDC, DAI

##### **Constructor**
```solidity
constructor(
    address initialOwner
) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
```

**Initialization:**
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

**⚠️ Security Issue:**
- `public`: Bất kỳ ai cũng mint được!

**Recommended fix:**
```solidity
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

#### **ERC20 Functions Có Sẵn**

```solidity
// View functions
totalSupply() → uint256                   // Tổng supply
balanceOf(address account) → uint256      // Balance của account
decimals() → uint8                        // Số decimals (18)
name() → string                           // Token name
symbol() → string                         // Token symbol

// Transfer functions
transfer(address to, uint256 amount) → bool
transferFrom(address from, address to, uint256 amount) → bool

// Approval functions
approve(address spender, uint256 amount) → bool
allowance(address owner, address spender) → uint256
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
    IERC721 public immutable nft;              // NFT collection
    IERC20 public immutable rewardToken;       // Reward token
    
    uint256 public rewardRatePerSecond;        // Scaled 1e18
    
    mapping(address => uint256) public balanceOf;        // NFTs staked
    mapping(address => uint256) public lastUpdate;       // Last update time
    mapping(address => uint256) public rewardsAccrued;   // Accrued rewards
    mapping(uint256 => address) public stakedOwnerOf;    // Owner of staked NFT
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
- `_nft`: Địa chỉ MyNFT contract
- `_rewardToken`: Địa chỉ RewardToken contract
- `initialOwner`: Owner của staking pool
- `_rewardRatePerSecond`: Reward rate (scaled by 1e18)

**Reward Rate Examples:**
- `1e17` = 0.1 tokens/second/NFT = **8,640 tokens/day/NFT**
- `1e18` = 1 token/second/NFT = **86,400 tokens/day/NFT**
- `1e16` = 0.01 tokens/second/NFT = **864 tokens/day/NFT**

**Why scaled 1e18?**
- Solidity không có floating point
- Scaling giúp tính toán chính xác
- Standard trong DeFi

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
- User stakes: **3 NFTs**
- Reward rate: **1e17** (0.1 token/second/NFT)
- Time elapsed: **1,000 seconds**

```
earned = 0 + (3 × 1000 × 1e17)
       = 3e20
       = 300 tokens (after dividing by 1e18)
```

##### **External View Function**
```solidity
function earned(address account) external view returns (uint256) {
    return _earned(account) / 1e18;
}
```
- Chia cho 1e18 để trả về số tokens readable
- `view`: Không tốn gas

##### **Update Rewards**
```solidity
function _updateRewards(address account) internal {
    rewardsAccrued[account] = _earned(account);
    lastUpdate[account] = block.timestamp;
}
```
- Snapshot rewards tại thời điểm hiện tại
- Reset timer

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
2. **Update rewards** trước (quan trọng!)
3. Foreach tokenId:
   - Transfer NFT vào contract
   - Record ownership
   - Emit event
4. Increase balance

**Modifiers:**
- `whenNotPaused`: Chỉ khi contract không paused
- `nonReentrant`: Chống reentrancy attacks

**Requirements:**
User phải approve trước:
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
1. Update rewards (snapshot)
2. Foreach tokenId:
   - Verify ownership
   - Clear record
   - Transfer NFT back
   - Emit event
3. Decrease balance

**Note:** Rewards vẫn trong `rewardsAccrued`, cần call `claim()` để nhận

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
1. Update rewards (tính final)
2. Get scaled rewards
3. Convert to actual tokens (÷ 1e18)
4. Check amount > 0
5. Reset rewards (giữ phần lẻ)
6. Transfer reward tokens
7. Emit event

**⚠️ Important:**
- Contract phải có đủ reward tokens!
- Owner cần fund pool:
```javascript
await rewardToken.mint(stakingPoolAddress, ethers.parseEther("100000"));
```

#### **Admin Functions**

```solidity
// Set reward rate
function setRewardRate(uint256 newRate) external onlyOwner

// Pause/unpause
function pause() external onlyOwner
function unpause() external onlyOwner

// Emergency unstake
function emergencyUnstake(uint256[] calldata tokenIds) external onlyOwner

// Recover NFTs gửi nhầm
function adminRecoverNFT(uint256 tokenId, address to) external onlyOwner
```

---

### 3.4. NFTMarketplace.sol - Non-Custodial NFT Marketplace

#### **Tổng Quan**
Marketplace cho phép mua/bán NFTs bằng native ONUS token, với platform fee và ERC2981 royalty support.

**Đặc điểm:**
- 🔓 **Non-custodial**: NFT vẫn ở ví seller cho đến khi sold
- 💰 **Native coin payment**: Mua bằng ONUS (không cần ERC20)
- 💵 **Platform fee**: Tính theo basis points (bps)
- 👑 **ERC2981 Royalty**: Tự động trả royalty cho creator
- ⏰ **Start time**: List với thời gian bắt đầu
- 🔒 **ReentrancyGuard**: Chống reentrancy attacks
- ⏸️ **Pausable**: Emergency stop

#### **Contract Structure**

```solidity
contract NFTMarketplace is Ownable, Pausable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint128 price;      // wei (native coin)
        uint64  startTime;  // unix timestamp
    }
    
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    uint96 public feeBps;           // Platform fee (basis points)
    address public feeRecipient;     // Fee recipient address
}
```

#### **Constructor**

```solidity
constructor(address initialOwner, uint96 _feeBps, address _feeRecipient) 
    Ownable(initialOwner) 
{
    require(_feeRecipient != address(0), "fee recipient zero");
    require(_feeBps <= 2_000, "fee too high");  // Max 20%
    feeBps = _feeBps;
    feeRecipient = _feeRecipient;
}
```

**Parameters:**
- `initialOwner`: Owner của marketplace
- `_feeBps`: Platform fee in basis points
  - 100 bps = 1%
  - 250 bps = 2.5%
  - 1000 bps = 10%
  - Max: 2000 bps = 20%
- `_feeRecipient`: Địa chỉ nhận platform fee

**Basis Points (bps) là gì?**
- 1 bps = 0.01% = 1/10000
- Dùng để tính phần trăm chính xác
- Standard trong finance

#### **List Function**

```solidity
function list(
    address nft, 
    uint256 tokenId, 
    uint256 price, 
    uint64 startTime
) external whenNotPaused {
    require(price > 0, "price=0");
    IERC721 erc = IERC721(nft);
    require(erc.ownerOf(tokenId) == msg.sender, "not owner");
    require(
        erc.getApproved(tokenId) == address(this) || 
        erc.isApprovedForAll(msg.sender, address(this)),
        "not approved"
    );

    listings[nft][tokenId] = Listing({
        seller: msg.sender,
        price: uint128(price),
        startTime: startTime
    });

    emit Listed(nft, tokenId, msg.sender, price, startTime);
}
```

**Parameters:**
- `nft`: Địa chỉ NFT contract
- `tokenId`: ID của NFT
- `price`: Giá bán (in wei)
- `startTime`: Unix timestamp khi có thể mua
  - `0` hoặc `block.timestamp`: Mua ngay
  - `future timestamp`: Scheduled listing

**Flow:**
1. Check price > 0
2. Verify seller owns NFT
3. Verify marketplace được approve
4. Save listing
5. Emit event

**Requirements:**
Seller phải approve trước:
```javascript
// Approve specific tokenId
await nft.approve(marketplaceAddress, tokenId);

// Hoặc approve all
await nft.setApprovalForAll(marketplaceAddress, true);
```

#### **Update Price Function**

```solidity
function updatePrice(address nft, uint256 tokenId, uint256 newPrice) external {
    require(newPrice > 0, "price=0");
    Listing storage lst = listings[nft][tokenId];
    require(lst.seller == msg.sender, "not seller");
    lst.price = uint128(newPrice);
    emit PriceUpdated(nft, tokenId, newPrice);
}
```

**Flow:**
1. Check price > 0
2. Verify caller là seller
3. Update price
4. Emit event

#### **Cancel Function**

```solidity
function cancel(address nft, uint256 tokenId) external {
    Listing memory lst = listings[nft][tokenId];
    require(lst.seller != address(0), "not listed");
    require(lst.seller == msg.sender || msg.sender == owner(), "no permission");
    delete listings[nft][tokenId];
    emit Cancelled(nft, tokenId, lst.seller);
}
```

**Who can cancel:**
- Seller (chủ sở hữu listing)
- Owner (admin)

#### **Buy Function**

```solidity
function buy(address nft, uint256 tokenId) external payable nonReentrant whenNotPaused {
    Listing memory lst = listings[nft][tokenId];
    require(lst.seller != address(0), "not listed");
    require(block.timestamp >= lst.startTime, "not started");

    IERC721 erc = IERC721(nft);
    require(erc.ownerOf(tokenId) == lst.seller, "seller not owner");
    require(
        erc.getApproved(tokenId) == address(this) || 
        erc.isApprovedForAll(lst.seller, address(this)),
        "not approved"
    );

    uint256 price = uint256(lst.price);
    require(msg.value >= price, "insufficient funds");

    delete listings[nft][tokenId];  // Delete trước để chống reentrancy

    // Tính fees
    uint256 platformFee = (price * feeBps) / 10_000;
    (address royaltyReceiver, uint256 royaltyAmount) = 
        _royaltyInfoIfSupported(nft, tokenId, price);
    
    require(platformFee + royaltyAmount <= price, "fees too high");
    uint256 sellerProceeds = price - platformFee - royaltyAmount;

    // Transfer NFT
    erc.safeTransferFrom(lst.seller, msg.sender, tokenId);

    // Payments
    if (platformFee > 0) _safePayout(feeRecipient, platformFee);
    if (royaltyAmount > 0 && royaltyReceiver != address(0)) 
        _safePayout(royaltyReceiver, royaltyAmount);
    _safePayout(lst.seller, sellerProceeds);

    // Refund tiền thừa
    if (msg.value > price) {
        _safePayout(msg.sender, msg.value - price);
    }

    emit Bought(nft, tokenId, lst.seller, msg.sender, price, 
                platformFee, royaltyReceiver, royaltyAmount);
}
```

**Flow:**
1. Verify listing tồn tại
2. Check đã đến startTime
3. Verify seller vẫn owns NFT
4. Verify approval vẫn valid
5. Check msg.value đủ
6. **Delete listing** (chống reentrancy)
7. **Tính fees:**
   - Platform fee
   - Royalty (nếu NFT support ERC2981)
   - Seller proceeds = price - fees
8. **Transfer NFT** cho buyer
9. **Distribute payments:**
   - Platform fee → feeRecipient
   - Royalty → creator
   - Proceeds → seller
   - Refund excess → buyer
10. Emit event

**Payment Distribution Example:**
```
Price: 1 ONUS (1e18 wei)
Platform fee: 250 bps = 2.5% = 0.025 ONUS
Royalty: 500 bps = 5% = 0.05 ONUS (if NFT supports ERC2981)
Seller proceeds: 1 - 0.025 - 0.05 = 0.925 ONUS
```

#### **ERC2981 Royalty Support**

```solidity
function _royaltyInfoIfSupported(
    address nft, 
    uint256 tokenId, 
    uint256 salePrice
) internal view returns (address receiver, uint256 amount) {
    try IERC165(nft).supportsInterface(type(IERC2981).interfaceId) 
        returns (bool ok) 
    {
        if (ok) {
            try IERC2981(nft).royaltyInfo(tokenId, salePrice) 
                returns (address rcv, uint256 amt) 
            {
                receiver = rcv;
                amount = amt;
            } catch { /* ignore */ }
        }
    } catch { /* ignore */ }
}
```

**ERC2981 là gì?**
- Royalty standard cho NFTs
- Creator set royalty % khi mint
- Marketplace tự động trả royalty khi bán
- Thường 5-10%

**If NFT không support:**
- `receiver` = address(0)
- `amount` = 0
- Không có royalty payment

#### **Admin Functions**

```solidity
// Update platform fee
function setFeeParams(uint96 _feeBps, address _feeRecipient) external onlyOwner {
    require(_feeRecipient != address(0), "fee recipient zero");
    require(_feeBps <= 2_000, "fee too high");
    feeBps = _feeBps;
    feeRecipient = _feeRecipient;
    emit FeeParamsUpdated(_feeBps, _feeRecipient);
}

// Pause/unpause
function pause() external onlyOwner { _pause(); }
function unpause() external onlyOwner { _unpause(); }
```

#### **View Functions**

```solidity
function getListing(address nft, uint256 tokenId) 
    external view returns (Listing memory) 
{
    return listings[nft][tokenId];
}
```

#### **Safe Payout Helper**

```solidity
function _safePayout(address to, uint256 amount) internal {
    if (amount == 0) return;
    (bool ok, ) = to.call{value: amount}("");
    if (!ok) {
        emit PayoutFailed(to, amount);
    }
}
```

**Why "safe"?**
- Không revert nếu transfer fail
- Emit event để admin biết
- Tránh DoS attack (malicious contract reject payment)

---

## 4. Deployment Scripts

### 4.1. MyNFT.ts

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import dotenv from "dotenv";
dotenv.config();

const OWNER_WALLET: string = process.env.OWNER_WALLET ?? "";
if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set in .env file");

const MyNFTModule = buildModule("MyNFTModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", OWNER_WALLET);
  const myNFTContract = m.contract("MyNFT", [initialOwner]);
  return { myNFTContract };
});

export default MyNFTModule;
```

### 4.2. RewardToken.ts

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import dotenv from "dotenv";
dotenv.config();

const OWNER_WALLET: string = process.env.OWNER_WALLET ?? "";
if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set in .env file");

const RewardTokenModule = buildModule("RewardTokenModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", OWNER_WALLET);
  const rewardTokenContract = m.contract("RewardToken", [initialOwner]);
  return { rewardTokenContract };
});

export default RewardTokenModule;
```

### 4.3. StakingPool.ts

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = process.env.OWNER_WALLET || "";
const STAKING_NFT_ADDRESS: string = process.env.STAKING_NFT_ADDRESS || "";
const REWARD_TOKEN_ADDRESS: string = process.env.REWARD_TOKEN_ADDRESS || "";

if (!STAKING_NFT_ADDRESS) 
    throw new Error("STAKING_NFT_ADDRESS is not set");
if (!REWARD_TOKEN_ADDRESS) 
    throw new Error("REWARD_TOKEN_ADDRESS is not set");
if (!OWNER_WALLET) 
    throw new Error("OWNER_WALLET is not set");

const StakingPoolModule = buildModule("StakingPoolModule", (m) => {
  const initialOwner = m.getParameter("_initialOwner", OWNER_WALLET);
  const nftStakingAddress = m.getParameter("_nftStakingAddress", STAKING_NFT_ADDRESS);
  const rewardTokenAddress = m.getParameter("_rewardTokenAddress", REWARD_TOKEN_ADDRESS);
  const rewardRatePerSecond = m.getParameter("_rewardRatePerSecond", 1e17); // 0.1 token/s/NFT
  
  const poolContract = m.contract("StakingPool", [
    nftStakingAddress,
    rewardTokenAddress,
    initialOwner,
    rewardRatePerSecond
  ]);
  
  return { poolContract };
});

export default StakingPoolModule;
```

### 4.4. NFTMarketplace.ts

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = process.env.OWNER_WALLET || "";
const PLATFORM_FEE: number = 100;  // 100 bps = 1%
const FEE_RECIPIENT: string = process.env.FEE_RECIPIENT || OWNER_WALLET;

if (!OWNER_WALLET) 
    throw new Error("OWNER_WALLET is not set");

const NFTMarketplaceModule = buildModule("NFTMarketplaceModule", (m) => {
  const initialOwner = m.getParameter("_initialOwner", OWNER_WALLET);
  const feeBps = m.getParameter("_feeBps", PLATFORM_FEE);
  const feeRecipient = m.getParameter("__feeRecipient", FEE_RECIPIENT);
  
  const contract = m.contract("NFTMarketplace", [
    initialOwner,
    feeBps,
    feeRecipient
  ]);
  
  return { contract };
});

export default NFTMarketplaceModule;
```

---

## 5. Deployment Guide

### 5.1. Deployment Order

**Thứ tự quan trọng vì contracts phụ thuộc lẫn nhau:**

```
1. Deploy MyNFT ✓
2. Deploy RewardToken ✓
3. Deploy NFTMarketplace (independent) ✓
4. Update .env với addresses ✓
5. Deploy StakingPool (cần MyNFT + RewardToken addresses) ✓
6. Fund StakingPool với RewardTokens ✓
```

### 5.2. Step-by-Step Deployment

#### **Step 1: Deploy MyNFT**

```bash
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet
```

**Output:**
```
✅ MyNFTModule#MyToken deployed at: 0xABC123...
```

**Save address:**
```env
STAKING_NFT_ADDRESS=0xABC123...
```

#### **Step 2: Deploy RewardToken**

```bash
npx hardhat ignition deploy ignition/modules/RewardToken.ts --network onusTestnet
```

**Output:**
```
✅ RewardTokenModule#MyToken deployed at: 0xDEF456...
```

**Save address:**
```env
REWARD_TOKEN_ADDRESS=0xDEF456...
```

#### **Step 3: Deploy NFTMarketplace**

```bash
npx hardhat ignition deploy ignition/modules/NFTMarketplace.ts --network onusTestnet
```

**Output:**
```
✅ NFTMarketplaceModule#NFTMarketplace deployed at: 0xGHI789...
```

#### **Step 4: Update .env File**

File `.env` hoàn chỉnh:
```env
PRIVATE_KEY=your_private_key
OWNER_WALLET=0xYourWallet
FEE_RECIPIENT=0xYourWallet
STAKING_NFT_ADDRESS=0xABC123...
REWARD_TOKEN_ADDRESS=0xDEF456...
```

#### **Step 5: Deploy StakingPool**

```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```

**Output:**
```
✅ StakingPoolModule#ERC721Staking deployed at: 0xJKL012...
```

#### **Step 6: Fund StakingPool**

```bash
npx hardhat console --network onusTestnet
```

```javascript
const rewardToken = await ethers.getContractAt("RewardToken", "0xDEF456...");

// Mint 100,000 reward tokens cho pool
await rewardToken.mint("0xJKL012...", ethers.parseEther("100000"));

// Verify balance
const balance = await rewardToken.balanceOf("0xJKL012...");
console.log("Pool balance:", ethers.formatEther(balance));
// Output: Pool balance: 100000.0
```

#### **Step 7: Verify Contracts**

```bash
# Verify MyNFT
npx hardhat verify --network onusTestnet <MYNFT_ADDRESS> "<OWNER_WALLET>"

# Verify RewardToken
npx hardhat verify --network onusTestnet <REWARD_TOKEN_ADDRESS> "<OWNER_WALLET>"

# Verify NFTMarketplace
npx hardhat verify --network onusTestnet <MARKETPLACE_ADDRESS> \
  "<OWNER_WALLET>" \
  "100" \
  "<FEE_RECIPIENT>"

# Verify StakingPool
npx hardhat verify --network onusTestnet <STAKING_POOL_ADDRESS> \
  "<MYNFT_ADDRESS>" \
  "<REWARD_TOKEN_ADDRESS>" \
  "<OWNER_WALLET>" \
  "100000000000000000"
```

---

## 6. Bài Tập Thực Hành

### 6.1. Bài Tập 1: Deploy Toàn Bộ Ecosystem

#### **Mục tiêu:**
Deploy tất cả 4 contracts theo đúng thứ tự

#### **Checklist:**
- [ ] Deploy MyNFT
- [ ] Deploy RewardToken
- [ ] Deploy NFTMarketplace
- [ ] Update .env với addresses
- [ ] Deploy StakingPool
- [ ] Fund pool với reward tokens
- [ ] Verify tất cả contracts

---

### 6.2. Bài Tập 2: Mint, Stake và Earn Rewards

#### **Mục tiêu:**
Test full staking flow

#### **Steps:**

**1. Setup contracts:**
```javascript
const nft = await ethers.getContractAt("MyNFT", "<MYNFT_ADDRESS>");
const rewardToken = await ethers.getContractAt("RewardToken", "<REWARD_TOKEN_ADDRESS>");
const pool = await ethers.getContractAt("StakingPool", "<POOL_ADDRESS>");
const [owner] = await ethers.getSigners();
```

**2. Mint NFTs:**
```javascript
// Mint 5 NFTs
for (let i = 1; i <= 5; i++) {
    await nft.mint(owner.address, i);
}

console.log("NFT balance:", await nft.balanceOf(owner.address));
// Output: NFT balance: 5
```

**3. Approve và Stake:**
```javascript
// Approve pool
await nft.setApprovalForAll(pool.address, true);

// Stake tokenIds: 1, 2, 3
await pool.stake([1, 2, 3]);

console.log("Staked:", await pool.balanceOf(owner.address));
// Output: Staked: 3
```

**4. Wait và Check Rewards:**
```javascript
// Wait 1 hour (in test environment, skip time)
await ethers.provider.send("evm_increaseTime", [3600]);
await ethers.provider.send("evm_mine");

// Check earned
const earned = await pool.earned(owner.address);
console.log("Earned:", ethers.formatEther(earned));

// Expected với rate 1e17 (0.1 token/s/NFT):
// 3 NFTs × 3600 seconds × 0.1 = 1,080 tokens
```

**5. Claim Rewards:**
```javascript
const balanceBefore = await rewardToken.balanceOf(owner.address);

await pool.claim();

const balanceAfter = await rewardToken.balanceOf(owner.address);
const claimed = balanceAfter - balanceBefore;

console.log("Claimed:", ethers.formatEther(claimed));
```

**6. Unstake:**
```javascript
// Unstake tokenIds: 1, 2
await pool.unstake([1, 2]);

console.log("Still staked:", await pool.balanceOf(owner.address));
// Output: Still staked: 1

console.log("NFT balance:", await nft.balanceOf(owner.address));
// Output: NFT balance: 4 (2 returned + 2 never staked)
```

---

### 6.3. Bài Tập 3: List và Sell NFTs trên Marketplace

#### **Mục tiêu:**
Test full marketplace flow

#### **Steps:**

**1. Setup:**
```javascript
const nft = await ethers.getContractAt("MyNFT", "<MYNFT_ADDRESS>");
const marketplace = await ethers.getContractAt("NFTMarketplace", "<MARKETPLACE_ADDRESS>");
const [seller, buyer] = await ethers.getSigners();
```

**2. Mint NFT (as seller):**
```javascript
await nft.connect(seller).mint(seller.address, 100);
console.log("Owner of #100:", await nft.ownerOf(100));
// Output: Owner of #100: <seller.address>
```

**3. Approve Marketplace:**
```javascript
// Option 1: Approve specific tokenId
await nft.connect(seller).approve(marketplace.address, 100);

// Option 2: Approve all (recommended)
await nft.connect(seller).setApprovalForAll(marketplace.address, true);
```

**4. List NFT:**
```javascript
const price = ethers.parseEther("1.0");  // 1 ONUS
const startTime = 0;  // Mua ngay

await marketplace.connect(seller).list(
    nft.address,
    100,
    price,
    startTime
);

// Check listing
const listing = await marketplace.getListing(nft.address, 100);
console.log("Seller:", listing.seller);
console.log("Price:", ethers.formatEther(listing.price), "ONUS");
```

**5. Buy NFT (as buyer):**
```javascript
// Check buyer balance trước
const buyerBalanceBefore = await ethers.provider.getBalance(buyer.address);

// Buy NFT
await marketplace.connect(buyer).buy(nft.address, 100, {
    value: ethers.parseEther("1.0")
});

// Verify ownership changed
console.log("New owner:", await nft.ownerOf(100));
// Output: New owner: <buyer.address>

// Check balances sau
const buyerBalanceAfter = await ethers.provider.getBalance(buyer.address);
const spent = ethers.formatEther(buyerBalanceBefore - buyerBalanceAfter);
console.log("Buyer spent:", spent, "ONUS");  // ~1.0 + gas

// Check seller received
// Price: 1 ONUS
// Platform fee (1%): 0.01 ONUS
// Seller receives: 0.99 ONUS (if no royalty)
```

**6. Test Update Price:**
```javascript
// List another NFT
await nft.connect(seller).mint(seller.address, 101);
await nft.connect(seller).setApprovalForAll(marketplace.address, true);
await marketplace.connect(seller).list(
    nft.address,
    101,
    ethers.parseEther("2.0"),
    0
);

// Update price
await marketplace.connect(seller).updatePrice(
    nft.address,
    101,
    ethers.parseEther("1.5")
);

const listing = await marketplace.getListing(nft.address, 101);
console.log("New price:", ethers.formatEther(listing.price));
// Output: New price: 1.5
```

**7. Test Cancel:**
```javascript
await marketplace.connect(seller).cancel(nft.address, 101);

const listing = await marketplace.getListing(nft.address, 101);
console.log("Seller after cancel:", listing.seller);
// Output: Seller after cancel: 0x0000000000000000000000000000000000000000
```

---

### 6.4. Bài Tập 4: Test Advanced Scenarios

#### **Scenario 1: Stake → List → Sell (with unstake)**

```javascript
// 1. Stake NFT
await nft.mint(owner.address, 200);
await nft.setApprovalForAll(pool.address, true);
await pool.stake([200]);

// 2. Wait to earn rewards
await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
await ethers.provider.send("evm_mine");

// 3. Unstake
await pool.unstake([200]);
await pool.claim();  // Claim rewards

// 4. List on marketplace
await nft.setApprovalForAll(marketplace.address, true);
await marketplace.list(nft.address, 200, ethers.parseEther("5.0"), 0);

// 5. Sell
const [_, buyer] = await ethers.getSigners();
await marketplace.connect(buyer).buy(nft.address, 200, {
    value: ethers.parseEther("5.0")
});
```

#### **Scenario 2: Multiple Users Staking**

```javascript
const [user1, user2, user3] = await ethers.getSigners();

// Mint NFTs cho mỗi user
await nft.mint(user1.address, 301);
await nft.mint(user2.address, 302);
await nft.mint(user3.address, 303);

// Mỗi user stake
await nft.connect(user1).setApprovalForAll(pool.address, true);
await pool.connect(user1).stake([301]);

await nft.connect(user2).setApprovalForAll(pool.address, true);
await pool.connect(user2).stake([302]);

await nft.connect(user3).setApprovalForAll(pool.address, true);
await pool.connect(user3).stake([303]);

// Wait
await ethers.provider.send("evm_increaseTime", [3600]);
await ethers.provider.send("evm_mine");

// Check rewards
console.log("User1 earned:", ethers.formatEther(await pool.earned(user1.address)));
console.log("User2 earned:", ethers.formatEther(await pool.earned(user2.address)));
console.log("User3 earned:", ethers.formatEther(await pool.earned(user3.address)));
// All should be ~same (1 NFT × 3600 seconds × 0.1 token/s = 360 tokens)
```

#### **Scenario 3: Platform Fee Distribution**

```javascript
const feeRecipient = await marketplace.feeRecipient();
const balanceBefore = await ethers.provider.getBalance(feeRecipient);

// Sell NFT với price 10 ONUS
await marketplace.connect(buyer).buy(nft.address, 400, {
    value: ethers.parseEther("10.0")
});

const balanceAfter = await ethers.provider.getBalance(feeRecipient);
const feeReceived = balanceAfter - balanceBefore;

console.log("Platform fee received:", ethers.formatEther(feeReceived));
// Expected: 10 ONUS × 1% = 0.1 ONUS
```

---

## 7. Các Lỗi Thường Gặp

### 7.1. Deployment Errors

#### **"STAKING_NFT_ADDRESS is not set"**

**Nguyên nhân:** Chưa deploy MyNFT hoặc chưa update .env

**Fix:**
```bash
# Deploy MyNFT trước
npx hardhat ignition deploy ignition/modules/MyNFT.ts --network onusTestnet

# Copy address vào .env
STAKING_NFT_ADDRESS=0x...
```

---

### 7.2. Staking Errors

#### **"ERC721: transfer from incorrect owner"**

**Nguyên nhân:** Chưa approve pool hoặc không own NFT

**Fix:**
```javascript
// Check owner
console.log("Owner:", await nft.ownerOf(tokenId));

// Approve
await nft.setApprovalForAll(poolAddress, true);
```

#### **"transfer failed" khi claim**

**Nguyên nhân:** Pool không có reward tokens

**Fix:**
```javascript
await rewardToken.mint(poolAddress, ethers.parseEther("100000"));
```

#### **"not staker" khi unstake**

**Nguyên nhân:** Đang unstake NFT không thuộc sở hữu

**Fix:**
```javascript
// Check ownership
const owner = await pool.stakedOwnerOf(tokenId);
console.log("Staked by:", owner);

// Only unstake own NFTs
await pool.unstake([yourTokenIds]);
```

---

### 7.3. Marketplace Errors

#### **"not approved" khi list**

**Nguyên nhân:** Chưa approve marketplace

**Fix:**
```javascript
await nft.setApprovalForAll(marketplaceAddress, true);
```

#### **"not listed" khi buy**

**Nguyên nhân:** NFT không được list hoặc đã bán

**Fix:**
```javascript
// Check listing
const listing = await marketplace.getListing(nftAddress, tokenId);
if (listing.seller === ethers.ZeroAddress) {
    console.log("Not listed");
}
```

#### **"insufficient funds" khi buy**

**Nguyên nhân:** msg.value < price

**Fix:**
```javascript
const listing = await marketplace.getListing(nftAddress, tokenId);
const price = listing.price;

// Send correct amount
await marketplace.buy(nftAddress, tokenId, {
    value: price  // Hoặc nhiều hơn
});
```

#### **"not started" khi buy**

**Nguyên nhân:** Listing có startTime trong tương lai

**Fix:**
```javascript
const listing = await marketplace.getListing(nftAddress, tokenId);
console.log("Start time:", new Date(Number(listing.startTime) * 1000));
console.log("Current time:", new Date());

// Wait until startTime
```

---

## 8. Best Practices

### 8.1. Security

**Contract Level:**
- [ ] Add `onlyOwner` to mint functions
- [ ] Test all functions thoroughly
- [ ] Verify contracts on explorer
- [ ] Audit code before mainnet
- [ ] Use ReentrancyGuard for payment functions
- [ ] Validate all inputs

**Deployment:**
- [ ] Test extensively on testnet first
- [ ] Use hardware wallet for mainnet
- [ ] Keep private keys secure
- [ ] Monitor contracts after deployment
- [ ] Have emergency pause mechanism

**Operations:**
- [ ] Fund staking pool adequately
- [ ] Monitor pool balance regularly
- [ ] Set reasonable reward rates
- [ ] Set reasonable platform fees
- [ ] Document all admin actions

### 8.2. Gas Optimization

**Staking:**
- [ ] Stake/unstake multiple NFTs at once (batch operations)
- [ ] Claim rewards periodically, not too frequently
- [ ] Use `setApprovalForAll` instead of approving individually

**Marketplace:**
- [ ] List multiple NFTs in separate transactions (no bulk list)
- [ ] Buy as soon as possible to avoid gas price changes
- [ ] Cancel listings before transferring NFTs

### 8.3. User Experience

**Clear Communication:**
- [ ] Document all fees clearly
- [ ] Show estimated rewards
- [ ] Provide transaction receipts
- [ ] Display all costs upfront

**Frontend (if building):**
- [ ] Show NFT metadata (images, names)
- [ ] Display staking APY
- [ ] Show pending rewards real-time
- [ ] Provide transaction history
- [ ] Handle errors gracefully
- [ ] Show loading states

---

## 9. Tài Nguyên Học Thêm

### Documentation
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts
- **ERC721 Standard**: https://eips.ethereum.org/EIPS/eip-721
- **ERC20 Standard**: https://eips.ethereum.org/EIPS/eip-20
- **ERC2981 Royalty**: https://eips.ethereum.org/EIPS/eip-2981
- **Hardhat**: https://hardhat.org/docs
- **ONUS Chain**: https://docs.onuschain.io
- **Ethers.js**: https://docs.ethers.org/v6/

### Tools
- **Remix IDE**: https://remix.ethereum.org
- **OpenZeppelin Wizard**: https://wizard.openzeppelin.com
- **Hardhat Network**: https://hardhat.org/hardhat-network/
- **ONUS Explorer**: https://explorer-testnet.onuschain.io

### Advanced Topics
- **NFT Metadata Standards**: https://docs.opensea.io/docs/metadata-standards
- **IPFS for NFT storage**: https://docs.ipfs.tech/
- **Gas Optimization**: https://www.alchemy.com/overviews/solidity-gas-optimization
- **Smart Contract Security**: https://consensys.github.io/smart-contract-best-practices/

---

## 10. Kết Luận

Bạn đã học được cách xây dựng một **NFT Ecosystem hoàn chỉnh**:
- ✅ ERC721 NFT Collection (MyNFT)
- ✅ ERC20 Reward Token (RewardToken)
- ✅ NFT Staking Pool với time-based rewards (StakingPool)
- ✅ Non-custodial NFT Marketplace với fees và royalty (NFTMarketplace)
- ✅ Security best practices
- ✅ Deployment và testing trên ONUS Chain

**Hệ thống này có thể:**
- Mint và quản lý NFT collections
- Stake NFTs để earn passive income
- Trade NFTs với platform fee và royalty support
- Scale cho thousands of users

**Next Steps:**
1. Deploy lên Testnet và test kỹ toàn bộ flow
2. Build frontend (React/Next.js + ethers.js)
3. Add advanced features:
   - NFT metadata và IPFS storage
   - Rarity system cho boosted rewards
   - Auction system trong marketplace
   - Governance với reward tokens
4. Audit smart contracts
5. Deploy lên Mainnet

**Happy Building! 🚀🎨💰**

