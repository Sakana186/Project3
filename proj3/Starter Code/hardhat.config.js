require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.17",
  networks: {
    bscTestnet: {
      url : "http://localhost:8545",
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
