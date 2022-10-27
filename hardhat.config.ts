import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    version:"0.8.17",
    settings: {
     optimizer: {
       enabled: true,
       runs: 700
     }
    }
  },
  gasReporter: {
    outputFile: "gas-report.txt",
    enabled: true,
    currency: "USD",
    noColors: true,
    coinmarketcap: process.env.COIN_MARKETCAP_API_KEY || "",
    token: "ETH"
  }
};

export default config;
