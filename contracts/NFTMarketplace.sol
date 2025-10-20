// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// OpenZeppelin ^5.0.0
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Simple ERC721 Marketplace (Native coin, ERC2981 royalty, fee bps)
/// @author you
/// @notice Non-custodial: NFT vẫn ở ví người bán, marketplace chỉ chuyển khi mua.
contract NFTMarketplace is Ownable, Pausable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint128 price;      // tính bằng native coin (wei)
        uint64  startTime;  // thời điểm có thể mua (unix time)
    }

    // nft => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // platform fee (bps). 100 bps = 1%. Ví dụ 250 = 2.5%
    uint96 public feeBps;
    address public feeRecipient;

    // ======== Events ========
    event Listed(address indexed nft, uint256 indexed tokenId, address indexed seller, uint256 price, uint64 startTime);
    event PriceUpdated(address indexed nft, uint256 indexed tokenId, uint256 newPrice);
    event Cancelled(address indexed nft, uint256 indexed tokenId, address indexed seller);
    event Bought(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 platformFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event FeeParamsUpdated(uint96 feeBps, address feeRecipient);
    event PayoutFailed(address indexed to, uint256 amount); // fallback nếu gửi thất bại

    constructor(address initialOwner, uint96 _feeBps, address _feeRecipient) Ownable(initialOwner) {
        require(_feeRecipient != address(0), "fee recipient zero");
        require(_feeBps <= 2_000, "fee too high"); // chặn >20% (tùy bạn)
        feeBps = _feeBps;
        feeRecipient = _feeRecipient;
    }

    // ======== List / Update / Cancel ========

    /// @notice Niêm yết NFT. Người bán phải là owner và đã approve marketplace.
    function list(address nft, uint256 tokenId, uint256 price, uint64 startTime) external whenNotPaused {
        require(price > 0, "price=0");
        IERC721 erc = IERC721(nft);
        require(erc.ownerOf(tokenId) == msg.sender, "not owner");
        require(
            erc.getApproved(tokenId) == address(this) || erc.isApprovedForAll(msg.sender, address(this)),
            "not approved"
        );

        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            price: uint128(price),
            startTime: startTime
        });

        emit Listed(nft, tokenId, msg.sender, price, startTime);
    }

    /// @notice Cập nhật giá.
    function updatePrice(address nft, uint256 tokenId, uint256 newPrice) external {
        require(newPrice > 0, "price=0");
        Listing storage lst = listings[nft][tokenId];
        require(lst.seller == msg.sender, "not seller");
        lst.price = uint128(newPrice);
        emit PriceUpdated(nft, tokenId, newPrice);
    }

    /// @notice Hủy niêm yết.
    function cancel(address nft, uint256 tokenId) external {
        Listing memory lst = listings[nft][tokenId];
        require(lst.seller != address(0), "not listed");
        require(lst.seller == msg.sender || msg.sender == owner(), "no permission");
        delete listings[nft][tokenId];
        emit Cancelled(nft, tokenId, lst.seller);
    }

    // ======== Buy ========

    /// @notice Mua NFT bằng native coin. `msg.value` phải >= price (thừa sẽ hoàn lại).
    function buy(address nft, uint256 tokenId) external payable nonReentrant whenNotPaused {
        Listing memory lst = listings[nft][tokenId];
        require(lst.seller != address(0), "not listed");
        require(block.timestamp >= lst.startTime, "not started");

        IERC721 erc = IERC721(nft);

        // kiểm tra lại quyền & sở hữu ở thời điểm mua
        require(erc.ownerOf(tokenId) == lst.seller, "seller not owner");
        require(
            erc.getApproved(tokenId) == address(this) || erc.isApprovedForAll(lst.seller, address(this)),
            "not approved"
        );

        uint256 price = uint256(lst.price);
        require(msg.value >= price, "insufficient funds");

        // xoá listing trước khi gọi external (chống reentrancy)
        delete listings[nft][tokenId];

        // Tính phí & royalty
        uint256 platformFee = (price * feeBps) / 10_000;

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfoIfSupported(nft, tokenId, price);

        // Bảo vệ: tổng khấu trừ không vượt quá giá
        require(platformFee + royaltyAmount <= price, "fees too high");

        uint256 sellerProceeds = price - platformFee - royaltyAmount;

        // Chuyển NFT trước (nếu fail thì revert)
        erc.safeTransferFrom(lst.seller, msg.sender, tokenId);

        // Thanh toán: fee -> feeRecipient, royalty -> royaltyReceiver, phần còn lại -> seller
        if (platformFee > 0) _safePayout(feeRecipient, platformFee);
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) _safePayout(royaltyReceiver, royaltyAmount);
        _safePayout(lst.seller, sellerProceeds);

        // Hoàn lại tiền thừa (nếu có)
        if (msg.value > price) {
            _safePayout(msg.sender, msg.value - price);
        }

        emit Bought(nft, tokenId, lst.seller, msg.sender, price, platformFee, royaltyReceiver, royaltyAmount);
    }

    // ======== Admin ========

    function setFeeParams(uint96 _feeBps, address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "fee recipient zero");
        require(_feeBps <= 2_000, "fee too high");
        feeBps = _feeBps;
        feeRecipient = _feeRecipient;
        emit FeeParamsUpdated(_feeBps, _feeRecipient);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ======== Views ========

    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }

    // ======== Internal helpers ========

    function _royaltyInfoIfSupported(address nft, uint256 tokenId, uint256 salePrice)
        internal
        view
        returns (address receiver, uint256 amount)
    {
        // kiểm tra hỗ trợ ERC165 + ERC2981
        try IERC165(nft).supportsInterface(type(IERC2981).interfaceId) returns (bool ok) {
            if (ok) {
                try IERC2981(nft).royaltyInfo(tokenId, salePrice) returns (address rcv, uint256 amt) {
                    receiver = rcv;
                    amount = amt;
                } catch { /* ignore */ }
            }
        } catch { /* ignore */ }
    }

    function _safePayout(address to, uint256 amount) internal {
        if (amount == 0) return;
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) {
            // Nếu gửi thất bại (ví đích là contract không nhận ETH), giữ lại trong contract
            // Admin có thể xử lý thủ công bằng cách bổ sung hàm rút sau (nếu muốn).
            emit PayoutFailed(to, amount);
        }
    }

    // nhận ETH fallback
    receive() external payable {}
    fallback() external payable {}
}
