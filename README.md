# Build Onus Chain Contracts

## Prerequisites

- Node.js >= 20.0.0
- Hardhat >= 2.26.3
- Onus Chain Testnet RPC URL in .env file
- Onus Chain Mainnet RPC URL in .env file
- Owner Wallet Address in .env file
- Private Key in .env file
- ONUS token amount in wallet of deployer on Metamask for paying gas fees

## Setup

```shell
cp .env.example .env
```

Fill in the values in the .env file.

Install dependencies:

```shell
npm install
```

## Usage

```shell
npm run compile
npm run deploy:testnet
npm run deploy:mainnet
```
