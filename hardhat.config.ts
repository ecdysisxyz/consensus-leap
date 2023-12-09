import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require('dotenv').config();

const PRIVATE_KEY=process.env.PRIVATE_KEY as string;
const ETHERSCAN_KEY=process.env.ETHERSCAN_KEY as string;
const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    basegoerli: {
      chainId: 84531,
      url: `https://goerli.base.org`,
      accounts: [PRIVATE_KEY]
    },
    sepolia: {
      chainId: 11155111,
      url: `https://1rpc.io/sepolia`,
      accounts: [PRIVATE_KEY]
    }

  },
  etherscan: {
    apiKey: {
     "basegoerli": "PLACEHOLDER_STRING",
     "sepolia": ETHERSCAN_KEY,
    },
    customChains: [
      {
        network: "basegoerli",
        chainId: 84531,
        urls: {
         apiURL: "https://api-goerli.basescan.org/api",
         browserURL: "https://goerli.basescan.org"
        }
      },
      {
        network: "sepolia",
        chainId: 11155111,
        urls: {
         apiURL: "https://api-sepolia.etherscan.io/api",
         browserURL: "https://sepolia.etherscan.io/"
        }
      }
    ]
  },
};

export default config;
