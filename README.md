# iCash / iSociety - Experimental smart contracts for educational purposes. 
Use at your own risk.
The code is live on Main Polygon for testing. Beware there are several contracts with the same names, and not all are valid instances or representations of the iCash smart contracts xAssets experiment(s). We have safety functions in place to rescue stuck tokens, or native ETH/MATIC/BNB in the contracts if there are any issues which arise contact support@electronero.org with proof of transaction and wallet dept will assist with recovery. Final contract would be deployed to Ethereum main net, so development began on Polygon main net. DO YOUR OWN RESEARCH. Read the code, it's pretty neat. But hey, these smart contracts could be risky, or it could be amazing.. To be determined... This is not a solicitation, nor advertisement. 
If you're interested in collaborating and learning about cryptocurrency development contact Interchained @ https://t.me/interchained
https://t.me/cryptocurrencydevs

The steps to launch will be recorded as R&D progresses. 

1) Ensure the contracts are fitted with the proper router address, and that the IERC20 of USDT, and WETH, REWARDS are initialized properly and set to the correct contract addresses based on the network deployed to. 
2) Correct the infura keys in truffle-config.js
3) Change the marketing/liquidity wallets or write after deployment
4) post-deployment then write launch() to the deployed contract (most other prerequisites, and launch phase steps have been automated in the constructor during the process of building the contracts)

## Donations 
 If you found this repository useful, I will leave my ETH address below for any readers who would like to donate some ether to help me fund this research & future xAssets experimental smart contracts. We are a small team, and with your help we can continue to grow. 

 Here is my ethereum address. An ethereum address is safe to use for Polygon, or Ethereum, or Binance smart chain, any address beginning with 0x and which is 42 characters ranging from a-f and 0-9 will work on any ethereum virtual machine compatible network. 
 Donation Public Wallet: ```0x972c56de17466958891BeDE00Fe68d24eAb8c2C4``` 
 
Currently "main" branch is fixed for Polygon, QuickSwap, with hard-coded variables. 
For redeployment assitance contact Interchained https://t.me/interchained

Deployed to Polygon: ```0xd88ad19e67238d8bc7a217913e8d8ccb983d8c30```
Contract on Polygonscan: https://polygonscan.com/address/0xd88ad19e67238d8bc7a217913e8d8ccb983d8c30

What we have here is a multi-currency reflections based set of smart contracts which utilizes Uniswap Factory v2, and Router v2, Address, SafeMath, a custom Auth (for multi-level access control), a rewards distributor with the option to change the rewards, an auto buy back and burn function, along with manual alias, and an auto sell back and reflect algo which exchanges the assets on contract balance for USDT, and during transactions produces rewards token distributions in USDT (with option to change for other assets such as USDC or otherwise at the operators or authorized parties descretion. There are several safeguards in place to help reduce the stress of the market pressure or accumulations such as anti-whale protections, max transaction limits, buy back spans, no sacrifices or fees on buy orders, and auto buy backs on sell orders, there's so much we can do with this contract strategy. The possiblities are endless, and there is more to share regarding this experiment. We will continue to keep updating the information provided with best efforts.

Steps to redeploy are below. Will update more later if necessary.

## Depends:
NPM / Yarn & NodeJS. 

Step 1) ```yarn``` or ```npm i``` 

Step 2) Change or verify the smart contract addresses in iCash.sol & DividendDistributor.sol

This was tested on Polygon, so the contracts for USDT and WETH are set to USDT(Pos) and WMatic on Polygon. 
The router below is Quickswap. In Main net ethereum for example, one would change these values to deploy 

iCash.sol >> Line 8
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    
    
DividendDistributor.sol >> Line 20
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    
update truffle-config.js >> edit infura key, and etherscan/polygonscan/bscscan api keys 

Step 3) open truffle console with the --network flag to specify which network to deploy contracts on example; 
```npx truffle console --network polygon```

Step 4) compile, and/or migrate. So we need to type in to truffle console ```compile``` to compile smart contracts, and then ```migrate``` to deploy /migrations to the --network selected.

Step 5) we are still learning, what does this button do?....

# Known Issues & Disclosures
The original authors code had an issue with removing liquidity, we fixed that in this implementation. We've unlocked some truly interesting technology here while we learn from, and continue research & development. Otherwise if the code is not deemed stable the repository may be deprecated, in favor of other models, or further archived without notice. Currently sorting out something to do with the fee structure, due to the original authors code being partially unusable researchers had to rewrite nearly everything. We got it working fairly well on Polygon, we may have something amazing here. Would be great to have an audit, but we don't have funding for that, this is for educational purposes. This code is a rescue mission to salvage what good may had been done during previous research & development on the public ether. The repository will be maintained for a short while until code contained herein is deemed stable or deprecated. This code is released open source for educational purposes. This message should not be considered permission to deploy, or redistribute the code found in this repository. Proceed at your own risk. Thanks!

# Disclaimer

All claims, content, designs, algorithms, and performance measurements described in this project are done with good faith efforts. It is up to the reader to check and validate their accuracy and truthfulness. Furthermore, nothing in this project constitutes a solicitation for investment. For educational purposes. Join the movement! https://t.me/cryptocurrencydevs
