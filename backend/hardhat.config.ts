import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  // networks: {
  //   mumbai: {
  //     url: process.env.ALCHEMY_API_KEY_URL,
  //     accounts: [process.env.PRIVATE_KEY as string],
  //   },
  // },
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_KEY as string,
  // },
};

export default config;
