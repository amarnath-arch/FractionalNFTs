/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");

require('dotenv').config();


const GOERLI_RPC_URL = process.env.RPCURL;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.17",
  networks:{
    hardhat:{},
    goerli:{
      url: GOERLI_RPC_URL,
      accounts: PRIVATE_KEY.split(',')
    }
  }
};
