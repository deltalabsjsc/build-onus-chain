import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = process.env.OWNER_WALLET || "";
const STAKING_NFT_ADDRESS: string = process.env.STAKING_NFT_ADDRESS || "";
const REWARD_TOKEN_ADDRESS: string = process.env.REWARD_TOKEN_ADDRESS || "";

if (!STAKING_NFT_ADDRESS) throw new Error("STAKING_NFT_ADDRESS is not set. Please deploy the token first.");
if (!REWARD_TOKEN_ADDRESS) throw new Error("REWARD_TOKEN_ADDRESS is not set. Please deploy the token first.");
if (!OWNER_WALLET) throw new Error("OWNER_WALLET is not set. Please set the owner wallet in the .env file.");

const StakingPoolModule = buildModule("StakingPoolModule", (m) => {
  const initialOwner = m.getParameter("_initialOwner", OWNER_WALLET);
  const nftStakingAddress = m.getParameter("_nftStakingAddress", STAKING_NFT_ADDRESS);
  const rewardTokenAddress = m.getParameter("_rewardTokenAddress", REWARD_TOKEN_ADDRESS);
  const rewardRatePerSecond = m.getParameter("_rewardRatePerSecond", 1e17);
  const poolContract = m.contract("StakingPool", [
    nftStakingAddress,
    rewardTokenAddress,
    initialOwner,
    rewardRatePerSecond
  ]);
  return { poolContract };
});

export default StakingPoolModule;