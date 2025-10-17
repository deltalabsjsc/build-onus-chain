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
