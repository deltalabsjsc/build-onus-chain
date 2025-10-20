// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// OpenZeppelin ^5.0.0
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ERC721 Staking với phần thưởng ERC20 theo thời gian
/// @notice Contract giữ NFT và trả thưởng theo rewardRate (token/giây/NFT)
contract ERC721Staking is IERC721Receiver, Ownable, Pausable, ReentrancyGuard {
    IERC721 public immutable nft; // bộ sưu tập NFT cần stake
    IERC20 public immutable rewardToken; // token dùng trả thưởng

    // rewardRate tính theo: số lượng rewardToken * 1e18 mỗi giây cho MỖI NFT
    uint256 public rewardRatePerSecond; // scaled 1e18 để tránh mất chính xác

    // số NFT đang stake của mỗi tài khoản
    mapping(address => uint256) public balanceOf;

    // thời điểm cuối cùng cập nhật thưởng cho mỗi tài khoản
    mapping(address => uint256) public lastUpdate;

    // thưởng tích lũy (chưa claim) của mỗi tài khoản (scaled 1e18)
    mapping(address => uint256) public rewardsAccrued;

    // chủ sở hữu của tokenId khi đang stake trong contract này
    mapping(uint256 => address) public stakedOwnerOf;

    // ======== Sự kiện ========
    event Staked(address indexed user, uint256 indexed tokenId);
    event Unstaked(address indexed user, uint256 indexed tokenId);
    event Claimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event EmergencyUnstake(address indexed user, uint256 indexed tokenId);

    constructor(
        address _nft,
        address _rewardToken,
        address initialOwner,
        uint256 _rewardRatePerSecond // ví dụ: 1e17 = 0.1 token/giây/NFT, nhớ scale 1e18
    ) Ownable(initialOwner) {
        require(_nft != address(0) && _rewardToken != address(0), "zero addr");
        nft = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    // ======== Logic tính thưởng ========

    function _earned(address account) internal view returns (uint256) {
        uint256 dt = block.timestamp - lastUpdate[account];
        // reward = rewardsAccrued + balance * dt * rate
        return
            rewardsAccrued[account] +
            (balanceOf[account] * dt * rewardRatePerSecond);
    }

    function earned(address account) external view returns (uint256) {
        return _earned(account) / 1e18; // trả về theo đơn vị token (không scale)
    }

    function _updateRewards(address account) internal {
        rewardsAccrued[account] = _earned(account);
        lastUpdate[account] = block.timestamp;
    }

    // ======== Hành vi staking ========

    /// @notice Stake một danh sách tokenId (mỗi tokenId phải thuộc về msg.sender)
    function stake(
        uint256[] calldata tokenIds
    ) external whenNotPaused nonReentrant {
        require(tokenIds.length > 0, "empty");
        _updateRewards(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tid = tokenIds[i];
            // chuyển NFT vào contract
            nft.safeTransferFrom(msg.sender, address(this), tid);
            stakedOwnerOf[tid] = msg.sender;
            emit Staked(msg.sender, tid);
        }
        balanceOf[msg.sender] += tokenIds.length;
    }

    /// @notice Unstake một danh sách tokenId (chỉ chủ sở hữu đã stake mới được rút)
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

    /// @notice Claim toàn bộ phần thưởng tích lũy
    function claim() external nonReentrant {
        _updateRewards(msg.sender);

        uint256 amountScaled = rewardsAccrued[msg.sender];
        uint256 amount = amountScaled / 1e18; // quy đổi về đơn vị token
        require(amount > 0, "nothing to claim");

        // giảm trước để tránh reentrancy logic
        rewardsAccrued[msg.sender] = amountScaled % 1e18; // giữ lại phần lẻ (nếu có)

        // chuyển phần thưởng; cần đảm bảo contract đã được nạp đủ rewardToken
        require(rewardToken.transfer(msg.sender, amount), "transfer failed");
        emit Claimed(msg.sender, amount);
    }

    // ======== Admin ========

    function setRewardRate(uint256 newRate) external onlyOwner {
        // cập nhật phần thưởng đang tích lũy cho mọi người là không khả thi on-chain,
        // nên chỉ cần không làm sai lệch người dùng kế tiếp claim:
        // khuyến nghị: tạm dừng, cập nhật rate, rồi mở lại.
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Rút nhầm NFT (không thuộc stake) – chỉ dành cho NFT không có stakedOwner
    function adminRecoverNFT(uint256 tokenId, address to) external onlyOwner {
        require(stakedOwnerOf[tokenId] == address(0), "token is staked");
        nft.safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice Trường hợp khẩn cấp: chủ sở hữu có thể cho rút NFT về chủ cũ (không claim)
    /// Lưu ý: dùng trong tình huống sự cố; có thể gây thiệt cho người dùng nếu lạm dụng.
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

    // ======== IERC721Receiver ========

    // Cho phép nhận NFT qua safeTransferFrom.
    // Chỉ chấp nhận nếu trước đó đã gọi stake để ghi nhận chủ sở hữu.
    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        // Nếu ai đó gửi thẳng NFT mà không gọi stake(), từ chối.
        // (Tránh trường hợp làm kẹt NFT trong contract.)
        require(msg.sender == address(nft), "unknown nft");
        require(stakedOwnerOf[tokenId] == from || paused(), "use stake()");
        return IERC721Receiver.onERC721Received.selector;
    }
}
