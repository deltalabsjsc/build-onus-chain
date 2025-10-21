# Hướng Dẫn Xây Dựng dApp Trên ONUS Chain

## Giới Thiệu

Tài liệu này hướng dẫn chi tiết cách xây dựng và deploy một smart contract ERC20 token lên ONUS Chain. Bạn sẽ học cách:
- Thiết lập môi trường phát triển blockchain
- Hiểu cấu trúc của smart contract ERC20
- Deploy contract lên ONUS Chain Testnet và Mainnet
- Tùy chỉnh và mở rộng contract theo nhu cầu

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
```bash
# Copy file cấu hình mẫu
cp .env.example .env
```

Mở file `.env` và điền các giá trị:

```env
# Private key của ví Metamask (không có tiền tố 0x)
PRIVATE_KEY=abc123def456...

# Địa chỉ ví sẽ làm owner của smart contract
OWNER_WALLET=0x1234567890abcdef...
```

**Cách lấy Private Key từ Metamask**:
1. Mở Metamask
2. Click vào 3 chấm → Account Details
3. Click "Export Private Key"
4. Nhập mật khẩu Metamask
5. Copy private key (bỏ phần "0x" ở đầu nếu có)

#### **Bước 4: Kiểm Tra Cài Đặt**
```bash
# Compile smart contract để kiểm tra
npm run compile
```

Nếu thành công, bạn sẽ thấy:
```
Compiled 1 Solidity file successfully
```

---

## 2. Cấu Trúc Dự Án

```
build-onus-chain/
├── contracts/              # Smart contracts
│   └── MyToken.sol        # Contract ERC20 token
├── ignition/              # Deployment scripts
│   └── modules/
│       └── MyToken.ts     # Script deploy MyToken
├── hardhat.config.ts      # Cấu hình Hardhat
├── package.json           # Dependencies và scripts
├── tsconfig.json          # Cấu hình TypeScript
├── .env                   # Biến môi trường (không commit)
├── .env.example           # Mẫu file cấu hình
└── README.md              # Tài liệu cơ bản
```

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

#### **Giải Thích Code**

##### **License và Version**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
```
- `SPDX-License-Identifier`: Khai báo license mã nguồn (MIT là open-source)
- `pragma solidity ^0.8.22`: Chỉ định phiên bản Solidity compiler (0.8.22 trở lên)

##### **Import Thư Viện OpenZeppelin**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```
- `ERC20.sol`: Contract cơ bản cho token ERC20 (chuẩn token phổ biến nhất)
- `Ownable.sol`: Quản lý quyền sở hữu (chỉ owner mới thực hiện được một số hành động)

##### **Kế Thừa Contract**
```solidity
contract MyToken is ERC20, Ownable {
```
- `MyToken`: Tên contract của bạn
- `is ERC20, Ownable`: Kế thừa từ 2 contract OpenZeppelin

##### **Constructor (Hàm Khởi Tạo)**
```solidity
constructor(
    address initialOwner
) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
```
- Được gọi **MỘT LẦN** khi deploy contract
- `initialOwner`: Địa chỉ ví sẽ là owner của contract
- `ERC20("MyToken", "MYT")`: 
  - `"MyToken"`: Tên đầy đủ của token
  - `"MYT"`: Symbol (ký hiệu ngắn gọn, hiển thị trên ví)
- `Ownable(initialOwner)`: Đặt owner cho contract

##### **Function `mint()`**
```solidity
function mint(address to, uint256 amount) public {
    _mint(to, amount);
}
```
- **Mục đích**: Tạo (đúc) token mới
- **Tham số**:
  - `to`: Địa chỉ ví nhận token
  - `amount`: Số lượng token (tính theo wei, 1 token = 10^18 wei)
- **Quyền truy cập**: `public` - bất kỳ ai cũng có thể gọi
- ⚠️ **Lưu ý bảo mật**: Function này nên có modifier `onlyOwner` để chỉ owner mới mint được

---

### 3.2. Các Function Có Sẵn Từ ERC20

Khi kế thừa từ `ERC20`, contract của bạn tự động có các function sau:

#### **Xem Thông Tin**
```solidity
function name() public view returns (string memory)
// Trả về: "MyToken"

function symbol() public view returns (string memory)
// Trả về: "MYT"

function decimals() public view returns (uint8)
// Trả về: 18 (mặc định)

function totalSupply() public view returns (uint256)
// Trả về: Tổng số token đang lưu hành

function balanceOf(address account) public view returns (uint256)
// Trả về: Số dư token của một địa chỉ
```

#### **Chuyển Token**
```solidity
function transfer(address to, uint256 amount) public returns (bool)
// Chuyển token từ người gọi đến địa chỉ 'to'

function transferFrom(address from, address to, uint256 amount) public returns (bool)
// Chuyển token thay mặt người khác (cần approve trước)
```

#### **Phê Duyệt (Approval)**
```solidity
function approve(address spender, uint256 amount) public returns (bool)
// Cho phép 'spender' sử dụng tối đa 'amount' token của bạn

function allowance(address owner, address spender) public view returns (uint256)
// Kiểm tra số token mà 'spender' được phép sử dụng từ 'owner'
```

---

### 3.3. File `ignition/modules/MyToken.ts`

Script deploy contract tự động.

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

#### **Giải Thích Code**

1. **Import và Load Environment**
   ```typescript
   import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
   import dotenv from "dotenv";
   dotenv.config();
   ```
   - Load biến môi trường từ file `.env`

2. **Lấy Owner Wallet**
   ```typescript
   const OWNER_WALLET: string = process.env.OWNER_WALLET ?? "";
   if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set in .env file");
   ```
   - Đọc địa chỉ owner từ `.env`
   - Throw error nếu không có (bắt lỗi sớm)

3. **Tạo Deployment Module**
   ```typescript
   const MyTokenModule = buildModule("MyTokenModule", (m) => {
     const initialOwner = m.getParameter("initialOwner", OWNER_WALLET);
     const myTokenContract = m.contract("MyToken", [initialOwner]);
     return { myTokenContract };
   });
   ```
   - `buildModule`: Tạo module deployment
   - `m.getParameter`: Lấy tham số (có thể override khi deploy)
   - `m.contract("MyToken", [initialOwner])`: Deploy contract với tham số
   - Return contract đã deploy để có thể tương tác sau này

---

### 3.4. File `hardhat.config.ts`

Cấu hình toàn bộ dự án Hardhat.

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
- `version`: Phiên bản Solidity
- `optimizer.enabled`: Tối ưu hóa code (giảm gas fee)
- `runs: 200`: Số lần chạy tối ưu (cân bằng giữa deployment cost và execution cost)

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
- Định nghĩa các blockchain network có thể deploy
- `url`: RPC endpoint để kết nối
- `accounts`: Private keys dùng để deploy
- `chainId`: ID duy nhất của blockchain

#### **Cấu Hình Block Explorer (Verify Contract)**
```typescript
etherscan: {
  apiKey: { onusTestnet: "NONEED", onusMainnet: "NONEED" },
  customChains: [ /* ... */ ]
}
```
- Cho phép verify contract source code trên explorer
- ONUS Chain không yêu cầu API key (dùng "NONEED")

---

## 4. Các Bước Thực Hành

### 4.1. Bài Tập 1: Deploy Contract Mặc Định

#### **Mục tiêu**: Deploy contract MyToken lên Testnet

#### **Các bước thực hiện**:

1. **Compile Contract**
   ```bash
   npm run compile
   ```
   - Kiểm tra syntax lỗi
   - Tạo artifacts (bytecode để deploy)

2. **Deploy Lên Testnet**
   ```bash
   npm run deploy:testnet ignition/modules/MyToken.ts
   ```
   
   Kết quả mong đợi:
   ```
   ✅ Successfully deployed MyToken to: 0xABCD1234...
   ```

3. **Kiểm Tra Trên Explorer**
   - Truy cập: https://explorer-testnet.onuschain.io
   - Paste địa chỉ contract vừa deploy
   - Xem thông tin: transaction, contract code, events

4. **Tương Tác Với Contract (Hardhat Console)**
   ```bash
   npx hardhat console --network onusTestnet
   ```
   
   Trong console:
   ```javascript
   // Lấy contract instance
   const MyToken = await ethers.getContractFactory("MyToken");
   const token = await MyToken.attach("0xDiaChiContractCuaBan");
   
   // Kiểm tra thông tin
   await token.name();      // "MyToken"
   await token.symbol();    // "MYT"
   await token.totalSupply(); // 0
   
   // Mint token
   await token.mint("0xDiaChiViNhan", ethers.parseEther("1000"));
   
   // Kiểm tra số dư
   await token.balanceOf("0xDiaChiViNhan");
   ```

---

### 4.2. Bài Tập 2: Tùy Chỉnh Token (Thay Đổi Tên và Symbol)

#### **Mục tiêu**: Tạo token của riêng bạn với tên và symbol khác

#### **Ví dụ**: Tạo "University Token" với symbol "UNI"

#### **Các bước thực hiện**:

1. **Chỉnh Sửa Contract**
   
   Mở file `contracts/MyToken.sol`, tìm dòng:
   ```solidity
   ) ERC20("MyToken", "MYT") Ownable(initialOwner) {}
   ```
   
   Thay đổi thành:
   ```solidity
   ) ERC20("University Token", "UNI") Ownable(initialOwner) {}
   ```

2. **Compile Lại**
   ```bash
   npm run compile
   ```

3. **Deploy Contract Mới**
   ```bash
   npm run deploy:testnet ignition/modules/MyToken.ts
   ```

4. **Kiểm Tra**
   - Truy cập explorer với địa chỉ contract mới
   - Xem name và symbol đã thay đổi

---

### 4.3. Bài Tập 3: Thêm Bảo Mật Cho Function Mint

#### **Mục tiêu**: Chỉ cho phép owner mint token

#### **Vấn đề hiện tại**: 
Function `mint()` hiện tại là `public`, bất kỳ ai cũng có thể tạo token vô hạn → không an toàn!

#### **Giải pháp**: Thêm modifier `onlyOwner`

#### **Các bước thực hiện**:

1. **Chỉnh Sửa Function**
   
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

2. **Giải Thích**:
   - `onlyOwner`: Modifier từ contract `Ownable`
   - Chỉ cho phép address owner gọi function này
   - Nếu người khác gọi → transaction sẽ revert (thất bại)

3. **Compile và Deploy**
   ```bash
   npm run compile
   npm run deploy:testnet ignition/modules/MyToken.ts
   ```

4. **Test Bảo Mật**
   ```javascript
   // Trong Hardhat console với account owner
   await token.mint(address, amount); // ✅ Thành công
   
   // Trong Hardhat console với account khác
   await token.mint(address, amount); // ❌ Lỗi: "Ownable: caller is not the owner"
   ```

---

### 4.4. Bài Tập 4: Thêm Function Burn (Đốt Token)

#### **Mục tiêu**: Cho phép người dùng "đốt" (xóa) token của chính họ

#### **Use case**: Giảm total supply, tăng giá trị token còn lại

#### **Các bước thực hiện**:

1. **Thêm Function Mới**
   
   Trong `contracts/MyToken.sol`, thêm function sau vào trong contract:
   ```solidity
   function burn(uint256 amount) public {
       _burn(msg.sender, amount);
   }
   ```

2. **Giải Thích**:
   - `_burn()`: Function internal của ERC20
   - `msg.sender`: Người gọi function
   - Chỉ có thể burn token của chính mình

3. **Contract Hoàn Chỉnh**:
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

4. **Compile và Deploy**
   ```bash
   npm run compile
   npm run deploy:testnet ignition/modules/MyToken.ts
   ```

5. **Test Function**
   ```javascript
   // Mint token trước
   await token.mint(myAddress, ethers.parseEther("1000"));
   console.log(await token.balanceOf(myAddress)); // 1000 tokens
   
   // Burn 100 tokens
   await token.burn(ethers.parseEther("100"));
   console.log(await token.balanceOf(myAddress)); // 900 tokens
   console.log(await token.totalSupply()); // Giảm 100
   ```

---

### 4.5. Bài Tập 5: Deploy Lên Mainnet

#### **⚠️ CHÚ Ý QUAN TRỌNG**:
- Mainnet sử dụng tiền thật (ONUS thật)
- Hãy đảm bảo đã test kỹ trên Testnet
- Kiểm tra kỹ code, không thể rollback sau khi deploy
- Backup private key an toàn

#### **Các bước thực hiện**:

1. **Kiểm Tra Số Dư ONUS**
   - Đảm bảo ví có đủ ONUS để trả gas fee
   - Dự trữ ít nhất 0.1 ONUS

2. **Double Check Code**
   - Review lại toàn bộ contract
   - Chạy test cases (nếu có)
   - Compile thành công

3. **Deploy Lên Mainnet**
   ```bash
   npm run deploy:mainnet ignition/modules/MyToken.ts
   ```

4. **Verify Contract (Optional nhưng Recommended)**
   - Làm cho code contract public trên explorer
   - Người dùng có thể tin tưởng vào contract
   
   ```bash
   npx hardhat verify --network onusMainnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
   ```

5. **Lưu Trữ Thông Tin**
   - Contract address
   - Transaction hash khi deploy
   - Owner wallet address
   - Backup toàn bộ code và cấu hình

---

## 5. Các Lỗi Thường Gặp và Cách Khắc Phục

### 5.1. Error: "PRIVATE_KEY is not set in .env file"

**Nguyên nhân**: File `.env` không có hoặc thiếu biến

**Cách fix**:
```bash
# Tạo file .env từ template
cp .env.example .env

# Mở file .env và điền private key
```

---

### 5.2. Error: "insufficient funds for gas"

**Nguyên nhân**: Ví không đủ ONUS để trả phí gas

**Cách fix**:
- Chuyển thêm ONUS vào ví
- Kiểm tra balance trên Metamask
- Đảm bảo đang dùng đúng network (Testnet/Mainnet)

---

### 5.3. Error: "Nonce too high"

**Nguyên nhân**: Hardhat cache bị lỗi đồng bộ nonce

**Cách fix**:
```bash
# Clear cache và compile lại
rm -rf artifacts cache
npm run compile
```

---

### 5.4. Contract Deploy Thành Công Nhưng Không Tương Tác Được

**Nguyên nhân**: Có thể do network congestion hoặc cấu hình sai

**Cách fix**:
1. Đợi vài phút để blockchain xác nhận transaction
2. Kiểm tra transaction status trên explorer
3. Verify contract address đúng
4. Kiểm tra lại ABI (artifacts/contracts/MyToken.sol/MyToken.json)

---

### 5.5. Error: "Ownable: caller is not the owner"

**Nguyên nhân**: Đang gọi function `onlyOwner` từ account không phải owner

**Cách fix**:
- Đảm bảo sử dụng đúng ví owner khi gọi function
- Kiểm tra owner hiện tại: `await token.owner()`
- Nếu cần, transfer ownership: `await token.transferOwnership(newOwner)`

---

## 6. Kiến Thức Nâng Cao

### 6.1. Gas Optimization Tips

1. **Sử dụng `uint256` thay vì `uint8`, `uint16`**
   - EVM làm việc với 256-bit words
   - Packing nhỏ hơn 256-bit thực ra tốn gas hơn

2. **Minimize Storage Writes**
   - Storage (biến state) rất đắt
   - Memory và calldata rẻ hơn nhiều

3. **Use Events Thay Vì Storage**
   - Để log data, dùng events thay vì lưu vào storage

---

### 6.2. Thêm Các Function Hữu Ích

#### **Pause/Unpause Contract**
```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC20, Ownable, Pausable {
    // ... existing code ...
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // Override transfer để respect pause
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```

#### **Cap (Giới Hạn Total Supply)**
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract MyToken is ERC20Capped, Ownable {
    constructor(
        address initialOwner
    ) ERC20("MyToken", "MYT") ERC20Capped(1000000 * 10**18) Ownable(initialOwner) {}
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

---

### 6.3. Testing Smart Contract

#### **Tạo File Test**
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

  it("Should fail if non-owner tries to mint", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const MyToken = await ethers.getContractFactory("MyToken");
    const token = await MyToken.deploy(owner.address);
    
    await expect(
      token.connect(addr1).mint(addr1.address, ethers.parseEther("100"))
    ).to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");
  });
});
```

#### **Chạy Test**
```bash
npx hardhat test
```

---

## 7. Best Practices

### 7.1. Security Checklist

- [ ] Sử dụng OpenZeppelin contracts đã audit
- [ ] Thêm access control (Ownable, AccessControl)
- [ ] Validate inputs (require, revert)
- [ ] Reentrancy protection nếu có external calls
- [ ] Test kỹ trước khi deploy mainnet
- [ ] Verify contract source code trên explorer
- [ ] Document code rõ ràng
- [ ] Audit code bởi bên thứ 3 (cho dự án lớn)

### 7.2. Code Quality

- [ ] Follow style guide (Solidity Style Guide)
- [ ] Use meaningful variable names
- [ ] Comment các logic phức tạp
- [ ] Sử dụng events để log các hành động quan trọng
- [ ] Version control với Git
- [ ] README documentation đầy đủ

### 7.3. Deployment Checklist

- [ ] Test trên Testnet trước
- [ ] Verify đủ ONUS cho gas
- [ ] Backup private key an toàn
- [ ] Document contract address sau khi deploy
- [ ] Verify contract source code
- [ ] Monitor contract sau khi deploy
- [ ] Chuẩn bị plan cho emergency (pause, upgrade)

---

## 8. Tài Nguyên Học Thêm

### 8.1. Documentation

- **ONUS Chain**: https://docs.onuschain.io
- **Solidity**: https://docs.soliditylang.org
- **Hardhat**: https://hardhat.org/docs
- **OpenZeppelin**: https://docs.openzeppelin.com/contracts
- **Ethers.js**: https://docs.ethers.org

### 8.2. Tools

- **Remix IDE**: https://remix.ethereum.org (Online Solidity IDE)
- **Hardhat VS Code Extension**: Syntax highlighting và debugging
- **Tenderly**: Monitoring và debugging transactions
- **OpenZeppelin Wizard**: Tạo contract tự động

### 8.3. Communities

- **ONUS Chain Community**: [Discord/Telegram links]
- **Ethereum Stack Exchange**: Hỏi đáp về Solidity
- **Reddit r/ethdev**: Developer community

---

## 9. Bài Tập Tự Luyện

### Cấp Độ Dễ
1. Deploy token với tên và symbol của bạn
2. Mint 1000 tokens cho chính mình
3. Transfer 100 tokens cho địa chỉ khác
4. Thêm function burn vào contract

### Cấp Độ Trung Bình
5. Tạo contract có cap (giới hạn max supply)
6. Thêm pause/unpause functionality
7. Viết 5 test cases cho contract
8. Deploy và verify contract trên Mainnet

### Cấp Độ Khó
9. Tạo token có vesting (mở khóa dần theo thời gian)
10. Implement fee on transfer (phí khi chuyển token)
11. Tạo staking contract (stake token để nhận reward)
12. Tạo DEX đơn giản để swap token

---

## 10. Kết Luận

Chúc mừng bạn đã hoàn thành tài liệu hướng dẫn này! Bạn đã học được:

✅ Thiết lập môi trường phát triển blockchain  
✅ Hiểu cấu trúc và cách hoạt động của ERC20 token  
✅ Deploy smart contract lên ONUS Chain  
✅ Tùy chỉnh và mở rộng contract  
✅ Best practices và security  

**Bước tiếp theo**:
1. Thực hành tất cả các bài tập
2. Tạo dự án token của riêng bạn
3. Tìm hiểu các contract pattern khác (NFT, DeFi, DAO)
4. Tham gia community và đóng góp

**Remember**: Blockchain development là hành trình dài, hãy kiên nhẫn và học hỏi liên tục!

---

## 📧 Liên Hệ và Hỗ Trợ

Nếu bạn gặp vấn đề hoặc có câu hỏi:
- Tạo Issue trên GitHub repository
- Tham gia ONUS Chain community
- Email: [support email]

**Happy Coding! 🚀**

