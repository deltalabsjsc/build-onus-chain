import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OWNER_WALLET: string = "0x304E7F5D7e57eA97E2aE40E8aa26C3b8f2b2eC6d";
const MASTER_WALLET: string = process.env.MASTER_WALLET || OWNER_WALLET;
const STAKING_TOKEN: string = "0x9D3ABf2e534b13085590000F3EEdf6B7e1d7411E";

const StakingPoolModule = buildModule("StakingPoolModule", (m) => {
  const initialOwner = m.getParameter("_initialOwner", OWNER_WALLET);
  const master = m.getParameter("_master", MASTER_WALLET);
  const token = m.getParameter("_token", STAKING_TOKEN);
  const apy = m.getParameter("_apy", 5);
  const poolContract = m.contract("StakingPool", [initialOwner, master, token, apy]);
  const startPool = Math.floor(Date.now() / 1000);
  const endPool = startPool + 24 * 60 * 60; // 1 day
  m.call(poolContract, "setupPool", [startPool, endPool]);
  return { poolContract };
});

export default StakingPoolModule;
