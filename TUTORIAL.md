# Hướng Dẫn Xây Dựng dApp Trên ONUS Chain

## Giới Thiệu

Tài liệu này hướng dẫn chi tiết cách xây dựng và deploy các smart contracts lên ONUS Chain, bao gồm:
- 🪙 **MyToken**: ERC20 token với mint và burn functions
- 🏦 **StakingPool**: Staking pool với APY-based rewards

Bạn sẽ học cách:
- Thiết lập môi trường phát triển blockchain
- Hiểu cấu trúc của smart contracts ERC20 và Staking
- Deploy contracts lên ONUS Chain Testnet và Mainnet
- Stake tokens và nhận rewards
- Tùy chỉnh và mở rộng contracts theo nhu cầu

---

## 1. Chuẩn Bị Kỹ Thuật

### 1.1. Yêu Cầu Hệ Thống

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt:

#### **Node.js và npm**
- **Phiên bản**: Node.js >= 20.0.0
- **Kiểm tra phiên bản**:
  ```bash
  node --version
  npm --version
  ```
- **Tải về**: https://nodejs.org/ (khuyến nghị bản LTS)

#### **Git**
- **Kiểm tra cài đặt**:
  ```bash
  git --version
  ```
- **Tải về**: https://git-scm.com/downloads

#### **Code Editor**
- Khuyến nghị: Visual Studio Code (https://code.visualstudio.com/)
- Extension hữu ích: Solidity (Juan Blanco)

#### **Ví Crypto (Metamask)**
- Tải extension: https://metamask.io/
- Cấu hình network ONUS Chain (hướng dẫn bên dưới)

---

### 1.2. Cấu Hình Metamask Cho ONUS Chain

#### **ONUS Chain Testnet**
1. Mở Metamask → Settings → Networks → Add Network
2. Điền thông tin:
   - **Network Name**: ONUS Chain Testnet
   - **RPC URL**: `https://rpc-testnet.onuschain.io`
   - **Chain ID**: 1945
   - **Currency Symbol**: ONUS
   - **Block Explorer**: `https://explorer-testnet.onuschain.io`

#### **ONUS Chain Mainnet**
1. Mở Metamask → Settings → Networks → Add Network
2. Điền thông tin:
   - **Network Name**: ONUS Chain Mainnet
   - **RPC URL**: `https://rpc.onuschain.io`
   - **Chain ID**: 1975
   - **Currency Symbol**: ONUS
   - **Block Explorer**: `https://explorer.onuschain.io`

---

### 1.3. Chuẩn Bị ONUS Token

Để deploy smart contract, bạn cần ONUS token trong ví để trả phí gas:

#### **Testnet (miễn phí)**
- Truy cập faucet (nếu có) hoặc liên hệ ONUS Chain support để nhận test ONUS
- Hoặc chuyển ONUS từ ví khác trên Testnet

#### **Mainnet (chi phí thực)**
- Mua ONUS token từ sàn giao dịch
- Chuyển về địa chỉ ví Metamask của bạn
- **Khuyến nghị**: Dự trữ ít nhất 0.1 ONUS cho việc deploy

⚠️ **Lưu ý bảo mật**: 
- **KHÔNG BAO GIỜ** chia sẻ private key của bạn
- **KHÔNG** commit file `.env` lên Git
- Sử dụng ví Testnet riêng, không dùng ví chính có tài sản thực

---

### 1.4. Clone Repository và Cài Đặt

#### **Bước 1: Clone Repository**
```bash
# Clone dự án về máy
git clone <repository-url>
cd build-onus-chain
```

#### **Bước 2: Cài Đặt Dependencies**
```bash
# Cài đặt tất cả các package cần thiết
npm install
```

Các package chính được cài đặt:
- `hardhat`: Framework phát triển smart contract
- `@openzeppelin/contracts`: Thư viện smart contract chuẩn và bảo mật
- `@nomicfoundation/hardhat-toolbox`: Bộ công cụ Hardhat đầy đủ
- `dotenv`: Quản lý biến môi trường
- TypeScript và các type definitions

#### **Bước 3: Cấu Hình Biến Môi Trường**

Tạo file `.env` trong thư mục gốc của dự án:

```bash
# Tạo file .env
touch .env
```

Mở file `.env` và thêm nội dung sau:

```env
# Private key của ví Metamask (không có tiền tố 0x)
# Ví này sẽ được dùng để deploy smart contract và trả phí gas
PRIVATE_KEY=your_private_key_here

# Địa chỉ ví sẽ làm owner của smart contract
# Đây là địa chỉ có quyền quản trị contract (ví dụ: mint token)
OWNER_WALLET=0xYourWalletAddressHere
```

**Cách lấy Private Key từ Metamask**:
1. Mở Metamask
2. Click vào 3 chấm → Account Details
3. Click "Export Private Key"
4. Nhập mật khẩu Metamask
5. Copy private key (bỏ phần "0x" ở đầu nếu có)

**Cách lấy Wallet Address**:
1. Mở Metamask
2. Click vào tên account phía trên
3. Address sẽ được copy vào clipboard

⚠️ **BẢO MẬT QUAN TRỌNG**:
- **TUYỆT ĐỐI KHÔNG** commit file `.env` lên Git
- **TUYỆT ĐỐI KHÔNG** share private key với ai
- File `.gitignore` đã được cấu hình để ignore `.env`
- Nên tạo ví test riêng cho development

#### **Bước 4: Kiểm Tra Cài Đặt**
```bash
# Compile smart contract để kiểm tra
npm run compile
```

Nếu thành công, bạn sẽ thấy:
```
Compiled 2 Solidity files successfully (evm target: paris).
```

---

## 2. Cấu Trúc Dự Án

Dự án bao gồm 2 smart contracts chính:
- **MyToken.sol**: ERC20 token với mint/burn
- **StakingPool.sol**: Staking pool với APY-based rewards

```
build-onus-chain/
├── contracts/              # Smart contracts
│   ├── MyToken.sol        # Contract ERC20 token
│   └── StakingPool.sol    # Contract Staking pool
├── ignition/              # Deployment scripts
│   └── modules/
│       ├── MyToken.ts     # Script deploy MyToken
│       └── StakingPool.ts # Script deploy StakingPool
├── hardhat.config.ts      # Cấu hình Hardhat
├── package.json           # Dependencies và scripts
├── tsconfig.json          # Cấu hình TypeScript
├── .env                   # Biến môi trường (không commit)
├── .gitignore             # Files cần ignore
├── TUTORIAL.md            # Tài liệu hướng dẫn chi tiết (file này)
└── README.md              # Tài liệu tổng quan
```

### Giải Thích Từng Folder/File

#### **contracts/**
Chứa tất cả smart contracts (file .sol):
- **`MyToken.sol`**: Contract ERC20 token 
  - Token cơ bản với mint và burn functions
  - Dùng làm token để stake trong StakingPool
- **`StakingPool.sol`**: Contract Staking pool
  - Cho phép users stake ERC20 tokens
  - Nhận rewards dựa trên APY
  - Lock period 7 ngày
  - Pool limits configurable

#### **ignition/modules/**
Chứa deployment scripts (TypeScript):
- **`MyToken.ts`**: Script deploy MyToken
  - Deploy với owner wallet từ .env
- **`StakingPool.ts`**: Script deploy StakingPool  
  - Deploy với token address, APY, owner
  - Auto-setup pool sau khi deploy

#### **hardhat.config.ts**
- File cấu hình chính của Hardhat
- Định nghĩa networks (Testnet, Mainnet)
- Cấu hình compiler Solidity
- Cấu hình verification

#### **package.json**
- Quản lý dependencies (thư viện cần thiết)
- Định nghĩa các npm scripts (compile, deploy)

#### **.env**
- Chứa thông tin nhạy cảm (private key, wallet address)
- **KHÔNG được commit lên Git**

#### **.gitignore**
- Liệt kê files/folders không commit lên Git
- Bao gồm: `.env`, `node_modules/`, `artifacts/`, `cache/`

---

## 3. Mô Tả Chi Tiết Smart Contract

### 3.1. File `contracts/MyToken.sol`

Đây là smart contract chính - một ERC20 token đơn giản nhưng đầy đủ tính năng.

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

#### **Giải Thích Từng Dòng Code**

##### **Dòng 1-2: License và Version**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
```
- `// SPDX-License-Identifier: MIT`: Khai báo license mã nguồn
  - `MIT`: License open-source, cho phép sử dụng tự do
  - Bắt buộc phải có để compiler không warning
- `pragma solidity ^0.8.22;`: Chỉ định phiên bản Solidity compiler
  - `^0.8.22`: Sử dụng version 0.8.22 trở lên, nhưng dưới 0.9.0
  - Version 0.8.x có built-in overflow/underflow protection

##### **Dòng 4-5: Import Thư Viện OpenZeppelin**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```
- `ERC20.sol`: Contract cơ bản cho token ERC20
  - Chuẩn token phổ biến nhất trên Ethereum và EVM chains
  - Có sẵn các functions: `transfer()`, `approve()`, `balanceOf()`, etc.
  - Đã được audit và tested kỹ lưỡng
- `Ownable.sol`: Quản lý quyền sở hữu contract
  - Cho phép chỉ định một address là "owner"
  - Có modifier `onlyOwner` để giới hạn quyền truy cập functions
  - Có thể transfer ownership sang address khác

##### **Dòng 7: Khai Báo Contract**
```solidity
contract MyToken is ERC20, Ownable {
```
- `contract MyToken`: Tên contract của chúng ta
- `is ERC20, Ownable`: Kế thừa (inheritance) từ 2 contracts
  - Kế thừa tất cả functions và features từ ERC20 và Ownable
  - Giống như class inheritance trong lập trình hướng đối tượng

##### **Dòng 8-11: Constructor (Hàm Khởi Tạo)**
```solidity
constructor(
    address initialOwner
) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
```

Giải thích chi tiết:

**`constructor(`**: 
- Hàm đặc biệt được gọi **MỘT LẦN DUY NHẤT** khi deploy contract
- Không thể gọi lại sau khi deploy

**`address initialOwner`**: 
- Tham số: địa chỉ ví sẽ là owner của contract
- Type `address`: kiểu dữ liệu đặc biệt trong Solidity (địa chỉ Ethereum)

**`ERC20("MyToken", "MYT")`**: 
- Gọi constructor của contract cha ERC20
- `"MyToken"`: Tên đầy đủ của token (hiển thị trên wallet, explorer)
- `"MYT"`: Symbol của token (ký hiệu ngắn gọn, như BTC, ETH)

**`Ownable(initialOwner)`**: 
- Gọi constructor của contract cha Ownable
- Đặt `initialOwner` làm owner của contract

**`{}`**: 
- Body của constructor rỗng vì chỉ cần gọi constructors của contracts cha

##### **Dòng 13-15: Function Mint**
```solidity
function mint(address to, uint256 amount) public {
    _mint(to, amount);
}
```

Giải thích chi tiết:

**`function mint(`**: 
- Khai báo function tên là `mint`
- Mục đích: Tạo (đúc) token mới

**`address to`**: 
- Tham số 1: địa chỉ ví sẽ nhận token mới
- Type: `address`

**`uint256 amount`**: 
- Tham số 2: số lượng token cần mint
- Type: `uint256` (unsigned integer 256-bit, số nguyên dương lớn)
- Đơn vị: wei (1 token = 10^18 wei do decimals mặc định = 18)

**`public`**: 
- Visibility modifier
- Nghĩa: **BẤT KỲ AI** cũng có thể gọi function này
- ⚠️ **Vấn đề bảo mật**: Nên thêm `onlyOwner` để chỉ owner mới mint được

**`_mint(to, amount);`**: 
- Gọi function internal `_mint()` từ contract ERC20
- Function này:
  - Tăng `totalSupply` thêm `amount`
  - Tăng balance của địa chỉ `to` thêm `amount`
  - Emit event `Transfer(address(0), to, amount)`

---

### 3.2. Các Function Có Sẵn Từ ERC20

Khi kế thừa từ `ERC20`, contract của bạn tự động có các function sau:

#### **Xem Thông Tin (View Functions)**

```solidity
function name() public view returns (string memory)
```
- **Mục đích**: Trả về tên đầy đủ của token
- **Return**: `"MyToken"`
- **Gas**: 0 (read-only)
- **Ví dụ sử dụng**: Hiển thị tên token trên UI

```solidity
function symbol() public view returns (string memory)
```
- **Mục đích**: Trả về symbol của token
- **Return**: `"MYT"`
- **Gas**: 0 (read-only)

```solidity
function decimals() public view returns (uint8)
```
- **Mục đích**: Trả về số chữ số thập phân
- **Return**: `18` (mặc định)
- **Ý nghĩa**: 1 token = 10^18 wei
- **Ví dụ**: Để hiển thị 1 token, backend cần chia số wei cho 10^18

```solidity
function totalSupply() public view returns (uint256)
```
- **Mục đích**: Tổng số token đang lưu hành
- **Return**: Tổng số token đã mint (tính bằng wei)

```solidity
function balanceOf(address account) public view returns (uint256)
```
- **Mục đích**: Xem số dư token của một địa chỉ
- **Tham số**: `account` - địa chỉ cần kiểm tra
- **Return**: Số token (tính bằng wei)

#### **Chuyển Token (State-Changing Functions)**

```solidity
function transfer(address to, uint256 amount) public returns (bool)
```
- **Mục đích**: Chuyển token từ người gọi đến địa chỉ `to`
- **Tham số**:
  - `to`: địa chỉ nhận
  - `amount`: số lượng token (wei)
- **Yêu cầu**: 
  - Người gọi phải có đủ balance
  - `to` không được là address(0)
- **Return**: `true` nếu thành công
- **Events**: Emit `Transfer(msg.sender, to, amount)`

```solidity
function transferFrom(address from, address to, uint256 amount) public returns (bool)
```
- **Mục đích**: Chuyển token từ `from` đến `to` (thay mặt người khác)
- **Yêu cầu**: 
  - Người gọi phải được `from` approve trước
  - `from` phải có đủ balance
- **Use case**: DEX, staking contracts

#### **Phê Duyệt (Approval System)**

```solidity
function approve(address spender, uint256 amount) public returns (bool)
```
- **Mục đích**: Cho phép `spender` sử dụng tối đa `amount` token của bạn
- **Use case**: 
  - Approve cho DEX để swap token
  - Approve cho staking contract
- **Events**: Emit `Approval(msg.sender, spender, amount)`

```solidity
function allowance(address owner, address spender) public view returns (uint256)
```
- **Mục đích**: Kiểm tra số token mà `spender` được phép sử dụng từ `owner`
- **Return**: Số token được approve

---

### 3.3. File `ignition/modules/MyToken.ts`

Script deploy contract tự động sử dụng Hardhat Ignition.

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import dotenv from "dotenv";
dotenv.config();

const OWNER_WALLET: string = process.env.OWNER_WALLET ?? "";
if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set in .env file");

const MyTokenModule = buildModule("MyTokenModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", OWNER_WALLET);
  const myTokenContract = m.contract("MyToken", [initialOwner]);
  return { myTokenContract };
});

export default MyTokenModule;
```

#### **Giải Thích Từng Dòng**

##### **Dòng 1-3: Import và Load Environment**
```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import dotenv from "dotenv";
dotenv.config();
```
- `buildModule`: Function để tạo deployment module
- `dotenv`: Library để đọc file `.env`
- `dotenv.config()`: Load biến môi trường từ `.env` vào `process.env`

##### **Dòng 5-6: Đọc Owner Wallet**
```typescript
const OWNER_WALLET: string = process.env.OWNER_WALLET ?? "";
if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set in .env file");
```
- `process.env.OWNER_WALLET`: Đọc biến `OWNER_WALLET` từ `.env`
- `?? ""`: Nếu undefined, dùng empty string
- `if (!OWNER_WALLET)`: Check nếu không có giá trị
- `throw new Error()`: Throw error sớm để dễ debug

##### **Dòng 8-12: Tạo Deployment Module**
```typescript
const MyTokenModule = buildModule("MyTokenModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", OWNER_WALLET);
  const myTokenContract = m.contract("MyToken", [initialOwner]);
  return { myTokenContract };
});
```

**`buildModule("MyTokenModule", ...)`**:
- Tạo deployment module với tên "MyTokenModule"
- Tên này sẽ hiển thị trong logs

**`(m) => { ... }`**: 
- Callback function với module builder `m`

**`m.getParameter("initialOwner", OWNER_WALLET)`**:
- Lấy parameter `initialOwner`
- Default value: `OWNER_WALLET` từ `.env`
- Có thể override khi deploy bằng CLI flags

**`m.contract("MyToken", [initialOwner])`**:
- Deploy contract tên "MyToken"
- `[initialOwner]`: Mảng các tham số constructor
- Return: Contract instance

**`return { myTokenContract }`**:
- Export contract để có thể tương tác sau này

---

### 3.4. File `hardhat.config.ts`

Cấu hình toàn bộ dự án Hardhat.

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY: string = process.env.PRIVATE_KEY ?? "";
if (!PRIVATE_KEY) throw new Error("PRIVATE_KEY is not set in .env file");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    onusTestnet: {
      url: 'https://rpc-testnet.onuschain.io',
      accounts: [PRIVATE_KEY],
      chainId: 1945,
    },
    onusMainnet: {
      url: 'https://rpc.onuschain.io',
      accounts: [PRIVATE_KEY],
      chainId: 1975,
    },
  },

  etherscan: {
    apiKey: {
      onusTestnet: "NONEED",
      onusMainnet: "NONEED",
    },
    customChains: [
      {
        network: "onusTestnet",
        chainId: 1945,
        urls: {
          apiURL: "https://explorer-testnet.onuschain.io/api",
          browserURL: "https://explorer-testnet.onuschain.io",
        },
      },
      {
        network: "onusMainnet",
        chainId: 1975,
        urls: {
          apiURL: "https://explorer.onuschain.io/api",
          browserURL: "https://explorer.onuschain.io",
        },
      },
    ],
  },
};

export default config;
```

#### **Cấu Hình Compiler**
```typescript
solidity: {
  version: "0.8.22",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
}
```
- `version: "0.8.22"`: Phiên bản Solidity compiler
- `optimizer.enabled: true`: Bật tối ưu hóa code
  - Giảm kích thước bytecode
  - Giảm gas cost khi execute
- `runs: 200`: Số lần chạy optimizer
  - Trade-off: deployment cost vs execution cost
  - 200: Cân bằng (phù hợp hầu hết trường hợp)
  - 1: Optimize cho deployment (deploy rẻ, chạy đắt)
  - 999999: Optimize cho execution (deploy đắt, chạy rẻ)

#### **Cấu Hình Networks**
```typescript
networks: {
  onusTestnet: {
    url: 'https://rpc-testnet.onuschain.io',
    accounts: [PRIVATE_KEY],
    chainId: 1945,
  },
  onusMainnet: {
    url: 'https://rpc.onuschain.io',
    accounts: [PRIVATE_KEY],
    chainId: 1975,
  },
}
```

**onusTestnet**:
- `url`: RPC endpoint để kết nối blockchain
- `accounts`: Array các private keys để deploy
- `chainId: 1945`: Chain ID của ONUS Testnet
  - Unique identifier cho blockchain
  - Prevent replay attacks giữa các chains

**onusMainnet**:
- Tương tự Testnet nhưng là production
- `chainId: 1975`: Chain ID của ONUS Mainnet

#### **Cấu Hình Block Explorer (Verify Contract)**
```typescript
etherscan: {
  apiKey: {
    onusTestnet: "NONEED",
    onusMainnet: "NONEED",
  },
  customChains: [ /* ... */ ]
}
```
- Cho phép verify contract source code trên explorer
- ONUS Chain không yêu cầu API key (dùng "NONEED")
- `customChains`: Định nghĩa custom blockchain không có sẵn trong Hardhat

---

### 3.5. Contract StakingPool.sol - Token Staking với Rewards

#### **Tổng Quan**
StakingPool là contract cho phép users stake ERC20 tokens để nhận rewards dựa trên APY (Annual Percentage Yield).

**Tính năng chính:**
- 🏦 Stake tokens để nhận rewards
- 💰 APY-based reward calculation
- 🔒 Lock period (mặc định 7 ngày)
- 🎯 Pool limits (tổng và per user)
- ⏸️ Pausable (emergency stop)
- 🚨 Emergency withdrawal (owner only)

```solidity
contract StakingPool is Context, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    struct StakedItem {
        uint amount;
        uint stakedAt;
        uint totalRewardPaid;
    }

    IERC20 public token;
    uint256 public apy;
    uint256 public stakingPeriod = 7 days;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    uint256 public totalStakedAmount;
    uint256 public limitStakedAmount = 10 ether;
    uint256 public limitStakedAmountPerUser = 1 ether;
    
    mapping(address => StakedItem) public stakes;
    mapping(address => bool) public isHarvestEnd;
}
```

#### **Giải Thích Các Components Chính**

##### **Constants**
```solidity
uint256 private constant _SCALING = 1e18;
uint256 private constant _ONE_YEAR = 365;
uint256 private constant _ONE_YEAR_SECONDS = 365 days;
```
- `_SCALING`: Dùng để tính toán chính xác với decimals
- `_ONE_YEAR`: 365 ngày (để tính APY)
- `_ONE_YEAR_SECONDS`: 365 days trong giây

##### **State Variables**
```solidity
IERC20 public token;                    // Token được stake
uint256 public apy;                     // Annual Percentage Yield (ví dụ: 5 * 1e18 = 5%)
uint256 public stakingPeriod = 7 days;  // Thời gian lock tối thiểu
uint256 public poolStartTime;           // Khi nào pool bắt đầu
uint256 public poolEndTime;             // Khi nào pool kết thúc
uint256 public totalStakedAmount;       // Tổng token đang stake
uint256 public limitStakedAmount;       // Max total pool capacity
uint256 public limitStakedAmountPerUser; // Max per user
```

##### **Struct StakedItem**
```solidity
struct StakedItem {
    uint amount;           // Số lượng token đang stake
    uint stakedAt;         // Timestamp khi stake
    uint totalRewardPaid;  // Tổng rewards đã nhận
}
```

#### **Constructor**
```solidity
constructor(
    address _initialOwner,
    address _master,
    IERC20 _token,
    uint256 _apy
) Ownable(_initialOwner) {
    _masterWallet = _master;
    apy = _apy * _SCALING;
    token = _token;
}
```
**Parameters:**
- `_initialOwner`: Owner của contract
- `_master`: Master wallet (dự phòng)
- `_token`: Địa chỉ ERC20 token để stake
- `_apy`: APY percentage (ví dụ: 5 = 5%)

**Lưu ý:** APY được nhân với `_SCALING` (1e18) để tính toán chính xác

#### **Reward Calculation - Logic Quan Trọng Nhất**

```solidity
function _calculateReward(
    uint256 _stakedTime,
    uint256 _quantity,
    uint256 _endTime
) internal view returns (uint256) {
    uint256 stakedDay = _calcDays(_endTime, _stakedTime);
    uint256 reward = ((apy / 100) * (stakedDay / _ONE_YEAR) * _quantity) /
        _SCALING /
        _SCALING;
    return reward;
}
```

**Formula phân tích:**
```
reward = (APY / 100) × (stakedDays / 365) × stakedAmount / 1e18 / 1e18

Ví dụ:
- APY = 5% (5 * 1e18)
- Staked = 100 tokens
- Duration = 30 days

stakedDay = 30 * 1e18
reward = ((5e18 / 100) * (30e18 / 365) * 100) / 1e18 / 1e18
       = (0.05e18 * 0.082e18 * 100) / 1e18 / 1e18
       = 0.41 tokens (4.1% sau 30 ngày)
```

#### **Main Functions Chi Tiết**

##### **stakeToken() - Stake Tokens**
```solidity
function stakeToken(uint256 _amount) external whenNotPaused
```

**Flow hoạt động:**

1. **Validate Amount**
```solidity
if (_amount <= 0) {
    revert ContractInsufficientBalance();
}
```

2. **Check Pool Status**
```solidity
if (isPoolNotActivated()) {
    revert PoolEndedOrNotStarted();
}
```

3. **Check Limits**
```solidity
StakedItem storage staking = stakes[_msgSender()];
require(
    staking.amount + _amount <= limitStakedAmountPerUser,
    "stakeToken: you have exceeded the limit"
);
require(
    totalStakedAmount + _amount <= limitStakedAmount,
    "stakeToken: exceeded pool limit"
);
```

4. **Transfer Tokens**
```solidity
token.safeTransferFrom(_msgSender(), address(this), _amount);
totalStakedAmount += _amount;
```

5. **Handle Existing Stake (Auto-compound)**
```solidity
if (staking.amount > 0) {
    // Calculate pending rewards
    uint256 rewardAmount = _calculateReward(
        staking.stakedAt,
        staking.amount,
        _currentTime() > poolEndTime ? poolEndTime : _currentTime()
    );
    
    // Transfer rewards immediately
    if (rewardAmount > 0) {
        token.safeTransfer(_msgSender(), rewardAmount);
    }
    
    // Add new amount and reset timer
    staking.amount += _amount;
    staking.stakedAt = _currentTime();
    staking.totalRewardPaid += rewardAmount;
}
```

6. **First Time Stake**
```solidity
else {
    stakes[_msgSender()] = StakedItem(_amount, _currentTime(), 0);
}
```

**Đặc điểm quan trọng:**
- ✅ Auto-harvest rewards khi stake thêm
- ✅ Reset staked time mỗi lần stake
- ✅ Accumulate total rewards paid

##### **unstake() - Unstake Tokens và Claim Rewards**
```solidity
function unstake(uint256 _amount) external nonReentrant whenNotPaused
```

**Flow:**

1. **Validate**
```solidity
StakedItem storage staking = stakes[_msgSender()];
require(staking.amount > 0, "unstake: Not found your staked item");
require(_amount <= staking.amount, "unstake: amount is too high");
require(_amount > 0, "unstake: amount is too low");
```

2. **Check Lock Period**
```solidity
if (isLockedPeriod(staking.stakedAt)) {
    revert LockedPeriod();
}
```
- User không thể unstake trong 7 ngày đầu

3. **Calculate Rewards**
```solidity
uint256 rewardAmount = _calculateReward(
    staking.stakedAt,
    _amount,
    _currentTime() > poolEndTime ? poolEndTime : _currentTime()
);
```

4. **Transfer: Staked Amount + Rewards**
```solidity
uint256 totalStaked = _amount + rewardAmount;
token.safeTransfer(_msgSender(), totalStaked);
```

5. **Update State**
```solidity
staking.amount -= _amount;
staking.totalRewardPaid += rewardAmount;
totalStakedAmount -= _amount;
```

##### **harvest() - Claim Rewards Only**
```solidity
function harvest() external whenNotPaused
```
- Claim rewards mà không unstake
- Reset `stakedAt` để bắt đầu tính reward mới
- Hữu ích khi muốn giữ tokens stake lâu dài

**Flow:**
```solidity
StakedItem storage staking = stakes[_msgSender()];

// Check if can harvest
if (isHarvestEnd[_msgSender()]) {
    revert HarvestedOrPoolEnded();
}

// Calculate and transfer rewards
uint rewardAmount = _calculateReward(
    staking.stakedAt,
    staking.amount,
    _currentTime() > poolEndTime ? poolEndTime : _currentTime()
);

if (rewardAmount > 0) {
    token.safeTransfer(_msgSender(), rewardAmount);
    staking.totalRewardPaid += rewardAmount;
    staking.stakedAt = _currentTime(); // Reset để tính reward mới
}
```

##### **estimateReward() - View Pending Rewards**
```solidity
function estimateReward(address _staker) external view returns (uint)
```
- View function (không tốn gas)
- Return pending rewards hiện tại
- Hữu ích cho frontend để hiển thị

#### **Admin Functions**

##### **setupPool() - Setup Pool Duration**
```solidity
function setupPool(
    uint256 _startTime,
    uint256 _endTime
) external onlyOwner
```
- `_startTime = 0`: Start ngay
- `_endTime = 0`: End sau 1 năm

##### **Configuration Functions**
```solidity
function setApy(uint256 apy_) external onlyOwner
function setLimitStakedAmount(uint256 _limitAmount) external onlyOwner
function setLimitStakedAmountPerUser(uint256 _limitAmount) external onlyOwner
function setStakingPeriod(uint256 _newPeriod) external onlyOwner
```

##### **Emergency Functions**
```solidity
function pause() external onlyOwner
function unpause() external onlyOwner

function emergencyWithdrawal(address _recipient) external onlyOwner {
    if (_recipient == address(0)) {
        revert InvalidRecipientAddress();
    }
    token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
}
```
- `pause()`: Dừng tất cả staking operations
- `emergencyWithdrawal()`: Rút tất cả tokens trong emergency

#### **View Functions**

```solidity
function getMyStaked(address _stakerWallet) external view returns (uint256)
function isLockedPeriod(uint256 _startAt) public view returns (bool)
function getUserLockPeriod(address _stakerWallet) public view returns (uint256)
function isNotStartedPool() public view returns (bool)
function isEndPool() public view returns (bool)
```

#### **Custom Errors**
```solidity
error ContractInsufficientRewardAmount();
error ContractInsufficientBalance();
error NotFoundStakedItem();
error PoolNotStarted();
error PoolEndedOrNotStarted();
error PoolEnded();
error LockedPeriod();
error YourInsufficientBalance();
error InvalidRecipientAddress();
error HarvestedOrPoolEnded();
```
- Modern Solidity style (saves gas vs require strings)
- Clear error messages

---

### 3.6. File `ignition/modules/StakingPool.ts`

Script deploy StakingPool contract.

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = "0x304E7F5D7e57eA97E2aE40E8aa26C3b8f2b2eC6d";
const MASTER_WALLET: string = process.env.MASTER_WALLET || OWNER_WALLET;
const STAKING_TOKEN: string = "0x9D3ABf2e534b13085590000F3EEdf6B7e1d7411E";

const StakingPoolModule = buildModule("StakingPoolModule", (m) => {
  const initialOwner = m.getParameter("_initialOwner", OWNER_WALLET);
  const master = m.getParameter("_master", MASTER_WALLET);
  const token = m.getParameter("_token", STAKING_TOKEN);
  const apy = m.getParameter("_apy", 5); // 5% APY
  
  const poolContract = m.contract("StakingPool", [
    initialOwner,
    master,
    token,
    apy
  ]);
  
  // Auto-setup pool: start now, end after 1 day
  const startPool = Math.floor(Date.now() / 1000);
  const endPool = startPool + 24 * 60 * 60;
  m.call(poolContract, "setupPool", [startPool, endPool]);
  
  return { poolContract };
});

export default StakingPoolModule;
```

**Giải thích:**
- `STAKING_TOKEN`: Address của token để stake (MyToken hoặc token khác)
- `apy: 5`: APY 5%
- Auto-call `setupPool()` sau khi deploy
- Pool duration: 1 ngày (để test)

**Deploy với custom parameters:**
```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet \
  --parameters '{"StakingPoolModule":{"_token":"0xYourTokenAddress","_apy":"10"}}'
```

---

## 4. Các Bước Thực Hành

### 4.1. Bài Tập 1: Deploy Contract Mặc Định Lên Testnet

#### **Mục tiêu**: 
- Deploy contract MyToken lên ONUS Chain Testnet
- Kiểm tra contract trên explorer
- Tương tác với contract qua Hardhat console

#### **Các bước thực hiện**:

**Bước 1: Compile Contract**
```bash
npm run compile
```

Kết quả mong đợi:
```
Compiled 1 Solidity file successfully (evm target: paris).
```

Lệnh này:
- Compile file `contracts/MyToken.sol` sang bytecode
- Tạo artifacts trong folder `artifacts/`
- Tạo typechain types trong folder `typechain-types/`
- Check syntax errors và warnings

**Bước 2: Kiểm Tra File .env**

Đảm bảo file `.env` có đầy đủ thông tin:
```env
PRIVATE_KEY=abc123def456...
OWNER_WALLET=0x1234567890abcdef...
```

**Bước 3: Deploy Lên Testnet**
```bash
npm run deploy:testnet ignition/modules/MyToken.ts
```

Kết quả mong đợi:
```
Hardhat Ignition 🚀

Deploying [ MyTokenModule ]

Batch #1
  Executed MyTokenModule#MyToken

[ MyTokenModule ] successfully deployed 🚀

Deployed Addresses

MyTokenModule#MyToken - 0xABCD1234567890abcdef1234567890ABCDEF1234
```

**Quan trọng**: Lưu lại contract address!

**Bước 4: Kiểm Tra Trên Explorer**

1. Copy contract address vừa deploy
2. Truy cập: https://explorer-testnet.onuschain.io
3. Paste address vào search box
4. Xem thông tin:
   - Contract creation transaction
   - Contract code (bytecode)
   - Balance
   - Transactions

**Bước 5: Tương Tác Với Contract (Hardhat Console)**

```bash
npx hardhat console --network onusTestnet
```

Trong console, gõ các lệnh sau:

```javascript
// Lấy contract factory
const MyToken = await ethers.getContractFactory("MyToken");

// Attach vào contract đã deploy
const token = await MyToken.attach("0xDiaChiContractCuaBan");

// Kiểm tra thông tin
await token.name();      // "MyToken"
await token.symbol();    // "MYT"
await token.decimals();  // 18
await token.totalSupply(); // 0n (BigInt 0)

// Lấy địa chỉ ví hiện tại
const [signer] = await ethers.getSigners();
console.log("My address:", signer.address);

// Mint 1000 tokens cho chính mình
const mintTx = await token.mint(signer.address, ethers.parseEther("1000"));
await mintTx.wait(); // Đợi transaction confirm

// Check số dư
const balance = await token.balanceOf(signer.address);
console.log("Balance:", ethers.formatEther(balance)); // "1000.0"

// Check total supply
const supply = await token.totalSupply();
console.log("Total Supply:", ethers.formatEther(supply)); // "1000.0"
```

**Giải thích**:
- `ethers.parseEther("1000")`: Convert 1000 tokens sang wei (1000 * 10^18)
- `ethers.formatEther(balance)`: Convert wei sang tokens (readable format)
- `await tx.wait()`: Đợi transaction được mine vào block

**Bước 6: Verify Contract (Optional)**

```bash
npx hardhat verify --network onusTestnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

Ví dụ:
```bash
npx hardhat verify --network onusTestnet 0xYourContractAddress "0xYourOwnerWallet"
```

Kết quả: Source code sẽ hiển thị trên explorer

---

### 4.2. Bài Tập 2: Tùy Chỉnh Token (Thay Đổi Tên và Symbol)

#### **Mục tiêu**: 
Tạo token của riêng bạn với tên và symbol tùy chỉnh

#### **Ví dụ**: 
Tạo "University Token" với symbol "UNI"

#### **Các bước thực hiện**:

**Bước 1: Chỉnh Sửa Contract**

Mở file `contracts/MyToken.sol`, tìm dòng:
```solidity
) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
```

Thay đổi thành:
```solidity
) ERC20("University Token", "UNI") Ownable(initialOwner) {}
```

**Giải thích**:
- `"University Token"`: Tên đầy đủ, có thể có khoảng trắng
- `"UNI"`: Symbol, thường là 3-5 ký tự viết hoa

**Bước 2: Compile Lại**
```bash
npm run compile
```

Lưu ý: Mỗi lần sửa contract phải compile lại

**Bước 3: Deploy Contract Mới**
```bash
npm run deploy:testnet ignition/modules/MyToken.ts
```

Lưu ý: Đây là contract mới, address khác với lần trước

**Bước 4: Kiểm Tra**

Truy cập explorer với địa chỉ contract mới:
```
https://explorer-testnet.onuschain.io/address/0xNewContractAddress
```

Hoặc dùng console:
```javascript
const MyToken = await ethers.getContractFactory("MyToken");
const token = await MyToken.attach("0xNewContractAddress");

await token.name();    // "University Token"
await token.symbol();  // "UNI"
```

**Bài tập mở rộng**:
- Thử tạo token với tên của bạn
- Thử symbol khác nhau: "ABC", "XYZ123", "TOKEN"
- Deploy nhiều tokens khác nhau

---

### 4.3. Bài Tập 3: Thêm Bảo Mật Cho Function Mint

#### **Mục tiêu**: 
Chỉ cho phép owner mint token (security best practice)

#### **Vấn đề hiện tại**: 
Function `mint()` là `public`, bất kỳ ai cũng có thể tạo token vô hạn → **Rất nguy hiểm!**

#### **Giải pháp**: 
Thêm modifier `onlyOwner`

#### **Các bước thực hiện**:

**Bước 1: Hiểu Vấn Đề**

Test với contract hiện tại:
```javascript
// Trong console, dùng một địa chỉ bất kỳ
const [owner, attacker] = await ethers.getSigners();

// Attacker có thể mint!
await token.connect(attacker).mint(attacker.address, ethers.parseEther("1000000"));
// ⚠️ Transaction thành công! Đây là bug bảo mật!
```

**Bước 2: Chỉnh Sửa Function**

Mở `contracts/MyToken.sol`, tìm:
```solidity
function mint(address to, uint256 amount) public {
    _mint(to, amount);
}
```

Thay đổi thành:
```solidity
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

**Giải thích**:
- `onlyOwner`: Modifier từ contract `Ownable`
- Kiểm tra `msg.sender == owner`
- Nếu không phải owner → revert transaction
- Code của `onlyOwner` modifier:
  ```solidity
  modifier onlyOwner() {
      require(owner() == msg.sender, "Ownable: caller is not the owner");
      _;
  }
  ```

**Bước 3: Compile và Deploy**
```bash
npm run compile
npm run deploy:testnet ignition/modules/MyToken.ts
```

**Bước 4: Test Bảo Mật**

```javascript
const MyToken = await ethers.getContractFactory("MyToken");
const token = await MyToken.attach("0xNewSecureContractAddress");

const [owner, attacker] = await ethers.getSigners();

// Test 1: Owner mint → Thành công
await token.connect(owner).mint(owner.address, ethers.parseEther("100"));
console.log("✅ Owner can mint");

// Test 2: Attacker mint → Thất bại
try {
    await token.connect(attacker).mint(attacker.address, ethers.parseEther("100"));
    console.log("❌ SECURITY BUG: Attacker can mint!");
} catch (error) {
    console.log("✅ Attacker cannot mint (as expected)");
    console.log("Error:", error.message);
    // Error: OwnableUnauthorizedAccount
}
```

**Kết quả mong đợi**:
```
✅ Owner can mint
✅ Attacker cannot mint (as expected)
Error: execution reverted: OwnableUnauthorizedAccount("0xAttackerAddress")
```

---

### 4.4. Bài Tập 4: Thêm Function Burn (Đốt Token)

#### **Mục tiêu**: 
Cho phép người dùng "đốt" (xóa) token của chính họ

#### **Use case**: 
- Giảm total supply
- Tăng giá trị token còn lại (deflationary token)
- User muốn giảm balance của mình

#### **Các bước thực hiện**:

**Bước 1: Thêm Function Mới**

Trong `contracts/MyToken.sol`, thêm function sau:

```solidity
contract MyToken is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "MYT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // ⬇️ THÊM FUNCTION NÀY
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
```

**Giải thích**:
- `function burn(uint256 amount)`: Function để đốt token
- `public`: Bất kỳ ai cũng có thể đốt token của chính mình
- `_burn(msg.sender, amount)`: Function internal của ERC20
  - Giảm balance của `msg.sender` đi `amount`
  - Giảm `totalSupply` đi `amount`
  - Emit event `Transfer(msg.sender, address(0), amount)`
  - Tự động check balance đủ không (revert nếu không đủ)

**Bước 2: Contract Hoàn Chỉnh**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "MYT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
```

**Bước 3: Compile và Deploy**
```bash
npm run compile
npm run deploy:testnet ignition/modules/MyToken.ts
```

**Bước 4: Test Function Burn**

```javascript
const MyToken = await ethers.getContractFactory("MyToken");
const token = await MyToken.attach("0xContractWithBurnFunction");

const [signer] = await ethers.getSigners();

// Mint 1000 tokens trước
await token.mint(signer.address, ethers.parseEther("1000"));
console.log("Balance after mint:", ethers.formatEther(await token.balanceOf(signer.address)));
console.log("Total supply:", ethers.formatEther(await token.totalSupply()));

// Burn 100 tokens
const burnTx = await token.burn(ethers.parseEther("100"));
await burnTx.wait();

// Check lại
console.log("Balance after burn:", ethers.formatEther(await token.balanceOf(signer.address)));
console.log("Total supply:", ethers.formatEther(await token.totalSupply()));
```

**Kết quả mong đợi**:
```
Balance after mint: 1000.0
Total supply: 1000.0
Balance after burn: 900.0
Total supply: 900.0
```

**Test edge cases**:

```javascript
// Test: Burn nhiều hơn balance
try {
    await token.burn(ethers.parseEther("10000")); // Chỉ có 900
} catch (error) {
    console.log("✅ Cannot burn more than balance");
    // Error: ERC20InsufficientBalance
}

// Test: Burn 0
await token.burn(0); // Không lỗi, nhưng không làm gì
```

---

### 4.5. Bài Tập 5: Deploy Lên Mainnet

#### **⚠️ CẢNH BÁO CỰC KỲ QUAN TRỌNG**

**Trước khi deploy lên Mainnet**:
- ✅ Mainnet sử dụng **tiền thật** (ONUS thật)
- ✅ **KHÔNG THỂ** rollback sau khi deploy
- ✅ **KHÔNG THỂ** sửa code sau khi deploy
- ✅ Bugs = mất tiền thật

**Checklist bắt buộc**:
- [ ] Đã test kỹ trên Testnet
- [ ] Contract không có bugs
- [ ] Đã review code nhiều lần
- [ ] Có đủ ONUS trong ví (≥ 0.1 ONUS)
- [ ] Backup private key an toàn
- [ ] Hiểu rõ contract làm gì
- [ ] Đã tính toán tokenomics (supply, distribution)

#### **Các bước thực hiện**:

**Bước 1: Final Review Code**

Đọc lại toàn bộ code lần cuối:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "MYT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
```

**Kiểm tra**:
- ✅ Token name và symbol đúng?
- ✅ Owner address đúng?
- ✅ Functions có security đúng?
- ✅ Không có unused code?

**Bước 2: Kiểm Tra Số Dư ONUS**

```javascript
// Trong console
const [signer] = await ethers.getSigners();
const balance = await ethers.provider.getBalance(signer.address);
console.log("ONUS balance:", ethers.formatEther(balance));
```

Đảm bảo ≥ 0.1 ONUS

**Bước 3: Double Check File .env**

```env
PRIVATE_KEY=your_real_private_key_here
OWNER_WALLET=0xYourRealOwnerWallet
```

**⚠️ Lưu ý**: Đây phải là private key của ví có ONUS thật

**Bước 4: Compile Lần Cuối**
```bash
npm run compile
```

Đảm bảo không có warnings

**Bước 5: Deploy Lên Mainnet**

**LẦN CUỐI HỎI CHÍNH MÌNH**:
- Tôi đã sẵn sàng deploy lên Mainnet chưa?
- Tôi hiểu rõ contract này làm gì?
- Tôi đã backup private key chưa?

Nếu trả lời YES cho tất cả:

```bash
npm run deploy:mainnet ignition/modules/MyToken.ts
```

**Bước 6: Verify Transaction**

1. Lưu lại contract address
2. Lưu lại transaction hash
3. Check trên explorer:
   ```
   https://explorer.onuschain.io/tx/0xYourTransactionHash
   ```

**Bước 7: Verify Contract Source Code**

```bash
npx hardhat verify --network onusMainnet <CONTRACT_ADDRESS> "<OWNER_WALLET>"
```

Ví dụ:
```bash
npx hardhat verify --network onusMainnet 0xYourMainnetContract "0xYourOwnerWallet"
```

**Lợi ích của verification**:
- Users có thể đọc source code trên explorer
- Tăng trust và transparency
- Có thể interact trực tiếp trên explorer

**Bước 8: Lưu Trữ Thông Tin**

Tạo file `DEPLOYMENT_INFO.md`:
```markdown
# Deployment Information

## Mainnet
- Contract Address: 0x...
- Deployment Transaction: 0x...
- Deployer Address: 0x...
- Owner Address: 0x...
- Deployment Date: 2024-XX-XX
- Block Number: XXXXX
- Gas Used: XXX ONUS

## Contract Details
- Name: MyToken
- Symbol: MYT
- Decimals: 18
- Initial Supply: 0

## Links
- Explorer: https://explorer.onuschain.io/address/0x...
- Source Code: Verified ✅
```

**Bước 9: Announcement**

Công bố contract address cho community:
- Twitter/X
- Discord/Telegram
- Website
- Documentation

---

### 4.6. Bài Tập 6: Deploy và Configure StakingPool

#### **Mục tiêu:**
Deploy StakingPool contract và cấu hình để stake tokens

#### **Prerequisites:**
- Đã deploy MyToken contract
- Có MyToken address

#### **Các bước thực hiện:**

**Bước 1: Update Deployment Script**

Mở `ignition/modules/StakingPool.ts` và update:
```typescript
const STAKING_TOKEN: string = "0xYourMyTokenAddress"; // Thay bằng MyToken address
const apy = m.getParameter("_apy", 10); // 10% APY
```

**Bước 2: Deploy StakingPool**
```bash
npx hardhat ignition deploy ignition/modules/StakingPool.ts --network onusTestnet
```

Lưu lại address của StakingPool!

**Bước 3: Verify Contract**
```bash
npx hardhat verify --network onusTestnet \
  <STAKING_POOL_ADDRESS> \
  "<OWNER_ADDRESS>" \
  "<MASTER_WALLET_ADDRESS>" \
  "<MYTOKEN_ADDRESS>" \
  "10"
```

**Bước 4: Configure Pool Limits**

```javascript
// Trong console
const pool = await ethers.getContractAt("StakingPool", "0xPoolAddress");

// Set limits
await pool.setLimitStakedAmount(ethers.parseEther("100")); // Pool max: 100 tokens
await pool.setLimitStakedAmountPerUser(ethers.parseEther("10")); // User max: 10 tokens

// Verify
console.log("Pool limit:", ethers.formatEther(await pool.limitStakedAmount()));
console.log("User limit:", ethers.formatEther(await pool.limitStakedAmountPerUser()));
```

**Bước 5: Transfer Rewards to Pool**

Pool cần tokens để trả rewards cho stakers:

```javascript
const myToken = await ethers.getContractAt("MyToken", "0xMyTokenAddress");

// Mint 1000 tokens for pool rewards
await myToken.mint("0xPoolAddress", ethers.parseEther("1000"));

// Verify pool balance
const poolBalance = await myToken.balanceOf("0xPoolAddress");
console.log("Pool balance:", ethers.formatEther(poolBalance));
```

**Bước 6: Verify Pool Status**

```javascript
// Check pool info
console.log("APY:", ethers.formatEther(await pool.apy()), "%");
console.log("Staking Period:", (await pool.stakingPeriod()).toString(), "seconds");
console.log("Pool Start:", new Date((await pool.poolStartTime()) * 1000));
console.log("Pool End:", new Date((await pool.poolEndTime()) * 1000));
```

---

### 4.7. Bài Tập 7: Stake Tokens và Nhận Rewards

#### **Mục tiêu:**
Thực hiện toàn bộ staking flow: stake, claim rewards, unstake

#### **Các bước thực hiện:**

**Bước 1: Prepare Tokens**

Mint tokens cho test user:

```javascript
const [owner, user1] = await ethers.getSigners();
const myToken = await ethers.getContractAt("MyToken", "0xMyTokenAddress");

// Mint 50 tokens for user1
await myToken.mint(user1.address, ethers.parseEther("50"));

// Check balance
console.log("User1 balance:", ethers.formatEther(await myToken.balanceOf(user1.address)));
```

**Bước 2: Approve Pool**

User phải approve pool trước khi stake:

```javascript
const pool = await ethers.getContractAt("StakingPool", "0xPoolAddress");

// User1 approves pool
await myToken.connect(user1).approve(pool.address, ethers.parseEther("50"));

// Verify allowance
const allowance = await myToken.allowance(user1.address, pool.address);
console.log("Allowance:", ethers.formatEther(allowance));
```

**Bước 3: Stake Tokens**

```javascript
// User1 stakes 10 tokens
await pool.connect(user1).stakeToken(ethers.parseEther("10"));

// Verify stake
const staked = await pool.getMyStaked(user1.address);
console.log("Staked amount:", ethers.formatEther(staked));

// Check total pool staked
const totalStaked = await pool.totalStakedAmount();
console.log("Total staked in pool:", ethers.formatEther(totalStaked));
```

**Bước 4: Wait & Check Lock Period**

```javascript
// Check when can unstake
const lockPeriod = await pool.getUserLockPeriod(user1.address);
const now = Math.floor(Date.now() / 1000);
console.log("Can unstake after:", new Date(lockPeriod * 1000));
console.log("Is locked?:", await pool.isLockedPeriod(lockPeriod - 7 * 24 * 60 * 60));
```

**Trong test environment, fast forward time:**
```javascript
// Skip 1 day
await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
await ethers.provider.send("evm_mine");
```

**Bước 5: Estimate Rewards**

```javascript
// Check pending rewards
const pendingReward = await pool.estimateReward(user1.address);
console.log("Pending rewards:", ethers.formatEther(pendingReward));

// Calculate expected reward
// Formula: (10% APY * 1 day / 365 days * 10 tokens)
// Expected: ~0.0027 tokens
```

**Bước 6: Harvest Rewards (Option 1)**

Claim rewards mà không unstake:

```javascript
// Check balance before
const balanceBefore = await myToken.balanceOf(user1.address);

// Harvest
await pool.connect(user1).harvest();

// Check balance after
const balanceAfter = await myToken.balanceOf(user1.address);
console.log("Rewards received:", ethers.formatEther(balanceAfter - balanceBefore));

// Staked amount vẫn giữ nguyên
console.log("Staked still:", ethers.formatEther(await pool.getMyStaked(user1.address)));
```

**Bước 7: Unstake (Option 2)**

Unstake và nhận cả principal + rewards:

```javascript
// Wait lock period (7 days)
await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
await ethers.provider.send("evm_mine");

// Check balance before
const balanceBefore = await myToken.balanceOf(user1.address);

// Unstake 5 tokens
await pool.connect(user1).unstake(ethers.parseEther("5"));

// Check balance after
const balanceAfter = await myToken.balanceOf(user1.address);
console.log("Received (principal + rewards):", ethers.formatEther(balanceAfter - balanceBefore));

// Check remaining staked
console.log("Remaining staked:", ethers.formatEther(await pool.getMyStaked(user1.address)));
```

**Bước 8: Test Stake Again (Auto-compound)**

```javascript
// Stake thêm 5 tokens
// Pool sẽ auto-harvest pending rewards trước
const balanceBefore = await myToken.balanceOf(user1.address);

await pool.connect(user1).stakeToken(ethers.parseEther("5"));

const balanceAfter = await myToken.balanceOf(user1.address);
console.log("Auto-harvested rewards:", ethers.formatEther(balanceBefore - balanceAfter - ethers.parseEther("5")));
```

**Bước 9: Test Edge Cases**

```javascript
// Test 1: Try unstake before lock period
try {
    await pool.connect(user1).unstake(ethers.parseEther("1"));
    console.log("❌ BUG: Should not allow unstake during lock period");
} catch (error) {
    console.log("✅ Correctly prevented: Locked period");
}

// Test 2: Try stake more than user limit
try {
    await pool.connect(user1).stakeToken(ethers.parseEther("20")); // User limit is 10
    console.log("❌ BUG: Should not allow exceeding user limit");
} catch (error) {
    console.log("✅ Correctly prevented: User limit exceeded");
}

// Test 3: Try stake when pool is full
// (Would need multiple users staking to fill pool)
```

**Bước 10: Monitor Pool Stats**

```javascript
// Pool statistics
const poolStats = {
    totalStaked: await pool.totalStakedAmount(),
    apy: await pool.apy(),
    limitTotal: await pool.limitStakedAmount(),
    limitPerUser: await pool.limitStakedAmountPerUser(),
    stakingPeriod: await pool.stakingPeriod()
};

console.log("Pool Stats:");
console.log("- Total Staked:", ethers.formatEther(poolStats.totalStaked));
console.log("- APY:", ethers.formatEther(poolStats.apy), "%");
console.log("- Capacity:", ethers.formatEther(poolStats.limitTotal));
console.log("- User Limit:", ethers.formatEther(poolStats.limitPerUser));
console.log("- Lock Period:", poolStats.stakingPeriod.toString(), "seconds");
```

#### **Kết quả mong đợi:**

✅ User có thể stake tokens vào pool  
✅ Rewards được tính đúng theo APY  
✅ Lock period được enforce  
✅ User có thể harvest hoặc unstake sau lock period  
✅ Auto-compound hoạt động khi stake thêm  
✅ Limits được enforce đúng  

---

## 5. Các Lỗi Thường Gặp và Cách Khắc Phục

### 5.1. Error: "PRIVATE_KEY is not set in .env file"

**Lỗi đầy đủ**:
```
Error: PRIVATE_KEY is not set in .env file
    at Object.<anonymous> (hardhat.config.ts:7:8)
```

**Nguyên nhân**: 
- File `.env` không tồn tại
- File `.env` có nhưng thiếu biến `PRIVATE_KEY`
- Tên biến sai (viết hoa/thường)

**Cách fix**:

1. Kiểm tra file `.env` có tồn tại không:
   ```bash
   ls -la .env
   ```

2. Nếu không có, tạo file:
   ```bash
   touch .env
   ```

3. Mở file `.env` và thêm:
   ```env
   PRIVATE_KEY=your_private_key_here
   OWNER_WALLET=0xYourWalletAddress
   ```

4. Đảm bảo không có khoảng trắng:
   ```env
   # ❌ SAI
   PRIVATE_KEY = abc123
   
   # ✅ ĐÚNG
   PRIVATE_KEY=abc123
   ```

5. Đảm bảo file .env ở đúng vị trí (thư mục gốc của project)

---

### 5.2. Error: "insufficient funds for gas"

**Lỗi đầy đủ**:
```
Error: insufficient funds for gas * price + value
```

**Nguyên nhân**: 
Ví không đủ ONUS để trả phí gas

**Cách fix**:

1. Kiểm tra balance:
   ```javascript
   // Trong console
   const [signer] = await ethers.getSigners();
   const balance = await ethers.provider.getBalance(signer.address);
   console.log("Balance:", ethers.formatEther(balance), "ONUS");
   ```

2. Nếu balance = 0 hoặc quá ít:
   - **Testnet**: Xin test ONUS từ faucet hoặc support
   - **Mainnet**: Mua ONUS và chuyển vào ví

3. Đảm bảo đang dùng đúng network:
   ```bash
   # Kiểm tra network trong command
   npm run deploy:testnet  # Testnet
   npm run deploy:mainnet  # Mainnet
   ```

4. Check địa chỉ ví đúng:
   ```javascript
   console.log("Deploying from:", signer.address);
   // So sánh với địa chỉ có ONUS
   ```

---

### 5.3. Error: "Nonce too high"

**Lỗi đầy đủ**:
```
Error: nonce too high. Expected nonce to be X but got Y
```

**Nguyên nhân**: 
- Hardhat cache bị lỗi đồng bộ nonce
- Pending transactions chưa được mine

**Cách fix**:

**Phương pháp 1: Clear Hardhat cache**
```bash
# Xóa cache và artifacts
npx hardhat clean

# Hoặc xóa thủ công
rm -rf artifacts cache

# Compile lại
npm run compile
```

**Phương pháp 2: Reset Metamask account**
1. Mở Metamask
2. Settings → Advanced
3. Clear activity tab data
4. Thử deploy lại

**Phương pháp 3: Đợi pending transactions**
- Check trên explorer xem có pending transactions không
- Đợi chúng được mine hoặc failed
- Thử lại

---

### 5.4. Error: "OWNER_WALLET is not set in .env file"

**Lỗi đầy đủ**:
```
Error: OWNER_WALLET is not set in .env file
```

**Nguyên nhân**: 
Tương tự PRIVATE_KEY, thiếu biến `OWNER_WALLET`

**Cách fix**:

1. Mở file `.env`
2. Thêm dòng:
   ```env
   OWNER_WALLET=0xYourWalletAddressHere
   ```

3. Đảm bảo có tiền tố "0x":
   ```env
   # ❌ SAI
   OWNER_WALLET=1234567890abcdef1234567890abcdef12345678
   
   # ✅ ĐÚNG
   OWNER_WALLET=0x1234567890abcdef1234567890abcdef12345678
   ```

4. Cách lấy wallet address:
   - Mở Metamask
   - Click vào tên account
   - Address được copy vào clipboard

---

### 5.5. Error: "Contract deployment failed"

**Các nguyên nhân có thể**:

**1. Gas limit quá thấp**
```typescript
// Trong hardhat.config.ts, thêm:
networks: {
  onusTestnet: {
    url: '...',
    accounts: [...],
    chainId: 1945,
    gas: 8000000,  // Tăng gas limit
  }
}
```

**2. Constructor parameters sai**
```bash
# Check logs để xem parameters nào được truyền
# Đảm bảo OWNER_WALLET là địa chỉ hợp lệ
```

**3. Network connection issues**
```bash
# Test connection
curl https://rpc-testnet.onuschain.io \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}'
```

---

### 5.6. Error: "Cannot find module"

**Lỗi đầy đủ**:
```
Error: Cannot find module '@nomicfoundation/hardhat-toolbox'
```

**Nguyên nhân**: 
Dependencies chưa được cài đặt

**Cách fix**:

```bash
# Cài đặt tất cả dependencies
npm install

# Hoặc cài riêng package bị thiếu
npm install @nomicfoundation/hardhat-toolbox

# Nếu vẫn lỗi, xóa node_modules và cài lại
rm -rf node_modules package-lock.json
npm install
```

---

### 5.7. Error: "Invalid private key"

**Lỗi đầy đủ**:
```
Error: invalid private key
```

**Nguyên nhân**: 
Private key không đúng format

**Cách fix**:

1. Private key phải là 64 ký tự hex (0-9, a-f):
   ```env
   # ✅ ĐÚNG
   PRIVATE_KEY=abc123def456789abc123def456789abc123def456789abc123def456789abc1
   ```

2. **KHÔNG có tiền tố "0x"**:
   ```env
   # ❌ SAI
   PRIVATE_KEY=0xabc123def456...
   
   # ✅ ĐÚNG
   PRIVATE_KEY=abc123def456...
   ```

3. Không có khoảng trắng hoặc ký tự đặc biệt:
   ```env
   # ❌ SAI
   PRIVATE_KEY=abc 123 def
   
   # ✅ ĐÚNG
   PRIVATE_KEY=abc123def
   ```

4. Cách lấy đúng từ Metamask:
   - Export private key từ Metamask
   - Copy toàn bộ (có thể có "0x")
   - Nếu có "0x", bỏ 2 ký tự đầu
   - Paste vào .env

---

## 6. Kiến Thức Nâng Cao

### 6.1. Gas Optimization Tips

#### **1. Sử dụng `uint256` thay vì `uint8`, `uint16`**

```solidity
// ❌ TỐN GAS HƠN (khi không pack)
uint8 count = 10;
uint16 value = 100;

// ✅ RẺ HƠN
uint256 count = 10;
uint256 value = 100;
```

**Lý do**: EVM làm việc với 256-bit words. Số nhỏ hơn cần thêm operations để convert.

#### **2. Pack Storage Variables**

```solidity
// ❌ Tốn 3 storage slots (96 gas * 3)
uint256 a;  // slot 0
uint256 b;  // slot 1  
uint256 c;  // slot 2

// ✅ Tốn 2 storage slots (96 gas * 2)
uint128 a;  // slot 0 (first 128 bits)
uint128 b;  // slot 0 (last 128 bits)
uint256 c;  // slot 1
```

#### **3. Use `calldata` for Read-Only Parameters**

```solidity
// ❌ Expensive
function process(string memory data) external {
    // ...
}

// ✅ Cheaper
function process(string calldata data) external {
    // ...
}
```

#### **4. Cache Array Length**

```solidity
// ❌ Đọc length mỗi iteration
for (uint256 i = 0; i < myArray.length; i++) {
    // ...
}

// ✅ Cache length
uint256 length = myArray.length;
for (uint256 i = 0; i < length; i++) {
    // ...
}
```

#### **5. Use Events Thay Vì Storage**

```solidity
// ❌ Expensive storage
string[] public logs;

function addLog(string memory log) public {
    logs.push(log);  // ~20,000 gas
}

// ✅ Cheap events
event Log(string message);

function addLog(string memory log) public {
    emit Log(log);  // ~1,000 gas
}
```

---

### 6.2. Testing Smart Contracts

Tạo file `test/MyToken.test.ts`:

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("MyToken", function () {
  it("Should have correct name and symbol", async function () {
    const [owner] = await ethers.getSigners();
    const MyToken = await ethers.getContractFactory("MyToken");
    const token = await MyToken.deploy(owner.address);
    
    expect(await token.name()).to.equal("MyToken");
    expect(await token.symbol()).to.equal("MYT");
  });

  it("Should mint tokens correctly", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const MyToken = await ethers.getContractFactory("MyToken");
    const token = await MyToken.deploy(owner.address);
    
    await token.mint(addr1.address, ethers.parseEther("100"));
    expect(await token.balanceOf(addr1.address)).to.equal(ethers.parseEther("100"));
  });

  it("Should only allow owner to mint", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const MyToken = await ethers.getContractFactory("MyToken");
    const token = await MyToken.deploy(owner.address);
    
    await expect(
      token.connect(addr1).mint(addr1.address, ethers.parseEther("100"))
    ).to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");
  });
});
```

**Chạy tests**:
```bash
npx hardhat test
```

---

## 7. Best Practices

### 7.1. Security Checklist

- [ ] Sử dụng OpenZeppelin contracts (đã audit)
- [ ] Thêm access control (Ownable, AccessControl)
- [ ] Validate inputs (require statements)
- [ ] Protect against reentrancy (ReentrancyGuard nếu cần)
- [ ] Test kỹ trước khi deploy mainnet
- [ ] Verify contract source code trên explorer
- [ ] Document code rõ ràng
- [ ] Consider audit từ bên thứ 3 (cho dự án lớn)
- [ ] Không hardcode addresses/values quan trọng
- [ ] Implement pause mechanism cho emergency

### 7.2. Code Quality

- [ ] Follow Solidity Style Guide
- [ ] Use meaningful variable names
- [ ] Comment các logic phức tạp
- [ ] Sử dụng events để log hành động quan trọng
- [ ] Version control với Git
- [ ] README documentation đầy đủ
- [ ] Consistent formatting
- [ ] Remove unused code

### 7.3. Deployment Checklist

- [ ] Test trên Testnet trước
- [ ] Verify đủ native tokens cho gas
- [ ] Backup private key an toàn
- [ ] Document contract address sau deploy
- [ ] Verify contract source code
- [ ] Monitor contract sau deploy
- [ ] Chuẩn bị plan cho emergency
- [ ] Thông báo cho community/users

---

## 8. Tài Nguyên Học Thêm

### Documentation
- **ONUS Chain**: https://docs.onuschain.io
- **Solidity**: https://docs.soliditylang.org
- **Hardhat**: https://hardhat.org/docs
- **OpenZeppelin**: https://docs.openzeppelin.com/contracts
- **ethers.js**: https://docs.ethers.org

### Tools
- **Remix IDE**: https://remix.ethereum.org (Online Solidity IDE)
- **Hardhat VS Code Extension**: Syntax highlighting và debugging
- **Tenderly**: Monitoring và debugging transactions
- **OpenZeppelin Wizard**: Tạo contract tự động

### Learning Resources
- **CryptoZombies**: https://cryptozombies.io
- **Solidity by Example**: https://solidity-by-example.org
- **Ethereum.org**: https://ethereum.org/developers

---

## 9. Kết Luận

Chúc mừng bạn đã hoàn thành tài liệu hướng dẫn này! Bạn đã học được:

✅ Thiết lập môi trường phát triển blockchain  
✅ Hiểu cấu trúc và cách hoạt động của ERC20 token  
✅ Deploy smart contract lên ONUS Chain  
✅ Tùy chỉnh và mở rộng contract  
✅ Best practices và security  

**Bước tiếp theo**:
1. Thực hành tất cả các bài tập
2. Tạo dự án token của riêng bạn
3. Tìm hiểu các contract patterns khác (NFT, DeFi, DAO)
4. Tham gia community và đóng góp

**Remember**: Blockchain development là hành trình dài, hãy kiên nhẫn và học hỏi liên tục!

---

## 📧 Liên Hệ và Hỗ Trợ

Nếu bạn gặp vấn đề hoặc có câu hỏi:
- Tạo Issue trên GitHub repository
- Tham gia ONUS Chain community
- Email: [support email]

**Happy Coding! 🚀**
