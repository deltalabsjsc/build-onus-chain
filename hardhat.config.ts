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
