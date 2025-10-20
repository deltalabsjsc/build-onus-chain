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