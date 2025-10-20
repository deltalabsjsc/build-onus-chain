import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = process.env.OWNER_WALLET || "";
const PLATFORM_FEE: number = 100; // platform fee (bps). 100 bps = 1%. Ví dụ 250 = 2.5%
const FEE_RECIPIENT: string = process.env.FEE_RECIPIENT || OWNER_WALLET;

if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set. Please set the owner wallet in the .env file.");

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