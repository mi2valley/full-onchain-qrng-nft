require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;
const MATIC_PRIVATE_KEY = process.env.MATIC_PRIVATE_KEY;
const GOERLI_API_KEY = process.env.GOERLI_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${GOERLI_API_KEY}`,
      accounts: [`0x${GOERLI_PRIVATE_KEY}`],
    },
    matic: {
      url: "https://rpc-mainnet.maticvigil.com/",
      accounts: [`0x${MATIC_PRIVATE_KEY}`],
      gasPrice: 100000000000,
    },
  },
};
