require('chai/register-should');
const solcStable = {
  version: '0.8.3',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
const solcPre = {
  version: '0.6.12',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
const solcNightly = {
  version: 'nightly',
  docker: true,
};

const useSolcNightly = process.env.SOLC_NIGHTLY === 'false';
const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');
const privateKey = fs.readFileSync(".pk").toString().trim() || "01234567890123456789";
const ethereum_privateKey = fs.readFileSync("ethereum.pk").toString().trim() || "01234567890123456789";
const goerli_privateKey = fs.readFileSync("goerli.pk").toString().trim() || "01234567890123456789";
const polygon_privateKey = fs.readFileSync("poly.pk").toString().trim() || "01234567890123456789";
const mnemonic = fs.readFileSync(".secret").toString().trim();
const ethereum_privateKeys = [
  ethereum_privateKey
];
const goerli_privateKeys = [
  goerli_privateKey
];
const polygon_privateKeys = [
  polygon_privateKey
];
module.exports = {  
  networks: {
    localhost: {
      host : "localhost",
      port: 8545,
      network_id: 1337,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ethereum: {
      host : "https://mainnet.infura.io/v3/",
      port: 8545,
      network_id: 1,
      chain_id: 1,
      provider: () =>
        new HDWalletProvider({
          privateKeys: ethereum_privateKeys,
          providerOrUrl: "https://mainnet.infura.io/v3/",
      }),
    },
    goerli: {
      host : "https://goerli.infura.io/v3/",
      port: 8545,
      network_id: 5,
      chain_id: 5,
      provider: () =>
        new HDWalletProvider({
          privateKeys: goerli_privateKeys,
          providerOrUrl: "https://goerli.infura.io/v3/",
      }),
    },
    polygon: {
      host : "https://polygon-mainnet.infura.io/v3/",
      port: 8545,
      network_id: 137,
      chain_id: 137,
      provider: () =>
        new HDWalletProvider({
          privateKeys: polygon_privateKeys,
          providerOrUrl: "https://polygon-mainnet.infura.io/v3/",
      }),
    },
    hardhat: {
      chainId: 1337,
    },
  },
  compilers: {
    solc: solcStable
  },  
  api_keys: {
    etherscan: '',
    polygonscan: '',
    bscscan: ''
  },
  plugins: ['solidity-coverage', 'truffle-plugin-verify'],  

};
