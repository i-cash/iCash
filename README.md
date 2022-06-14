# iReflect - Experimental smart contracts for educational purposes. 
Use at your own risk, I do not assume responsibility for your unauthorized deployment of this repository. I am studying, and this is a gift for the community I am not the bearer of the rights to this technology. 
This assignment has been provided to me for educational purposes, during research and development. 
 Beware there are several contracts with the same names, and not all are valid instances or representations of this variation of iCash collection of smart contracts / xAssets experiment(s). We have safety functions in place to rescue stuck tokens, or native ETH/MATIC/BNB coins in the contracts if there are any issues which arise contact support@electronero.org with proof of transaction and wallet dept will assist with recovery. Final contract would be deployed to Ethereum main net, so development began on Rinkeby and Polygon. DO YOUR OWN RESEARCH. Read the code, it's pretty neat. But hey, these smart contracts could be risky, or it could be amazing.. To be determined... This is not a solicitation, nor advertisement. 
If you're interested in collaborating and learning about cryptocurrency development contact Interchained and Cryptocurrency Devs!
https://t.me/interchained
https://t.me/cryptocurrencydevs

The steps to launch will be recorded as R&D progresses. 

## Donations 
 If you found this repository useful, I will leave my ETH address below for any readers who would like to donate some ether to help me fund this research & future xAssets experimental smart contracts. We are a small team, and with your help we can continue to grow. 

 Here is an ethereum public wallet address. An ethereum address is safe to use for Polygon, or Ethereum, or Binance smart chain, or any other EVM compatible private network. A public wallet address beginning with 0x and which is 42 characters ranging from a-f and 0-9 "should" work on any ethereum virtual machine compatible network. 
 Donation Public Wallet: ```0x972c56de17466958891BeDE00Fe68d24eAb8c2C4``` 
 
Currently "main" branch is fixed for Polygon, QuickSwap, with hard-coded variables. 
For redeployment assitance contact Interchained https://t.me/interchained

What we have here is a new style of stacking pools, I call them reflections pools. These smart contracts utilize Uniswap Factory v2, and Router v2, Address, a custom Auth (for decentralized, multi-level access control). The main goals of this set of smart contracts is to enable stacking of one token, and reflections in another. So each user will have their own "pool", and access to reflections from various clients. The possiblities are endless, and there is more to share regarding this experiment. We will continue to keep updating the information provided with best efforts.

DO NOT DEPLOY THIS TO MAIN NET WITHOUT TESTING THOROUGHLLY ON TESTNETS: such as ROPSTEN, RINKEBY, GOERLI, CRYSTALEUM or your own private network of Ethereum. 

## Depends:
NPM / Yarn & NodeJS. 

Step 1) ```yarn``` or ```npm i``` 

Step 2) update truffle-config.js >> edit infura key, and etherscan/polygonscan/bscscan api keys 

Step 3) open truffle console with the --network flag to specify which network to deploy contracts on example; 
```npx truffle console --network polygon```

Step 4) compile, and/or migrate. So we need to type in to truffle console ```compile``` to compile smart contracts, and then ```migrate``` to deploy /migrations to the --network selected.

Step 5) we are still learning, what does this button do?....

# Known Issues & Disclosures
The pools may need tweaking, it's not certain this strategy will produce the desired effect without modification and deep testing. It is not audited, yet. We've unlocked some truly interesting technology here while we learn from, and continue research & development. Otherwise if the code is not deemed stable the repository may be deprecated, in favor of other models, or further archived without notice. Would be great to have an audit, but we don't have funding for that, and this is for educational purposes. The repository will be maintained for a short while until code contained herein is deemed stable, deprecated, or sunsetted. This code is released open source for educational purposes. This message should not be considered permission to deploy, or redistribute the code found in this repository. Proceed at your own risk. Thanks!

# Disclaimer

All claims, content, designs, algorithms, and performance measurements described in this project are done with good faith efforts. It is up to the reader to check and validate their accuracy and truthfulness. Furthermore, nothing in this project constitutes a solicitation for investment. For educational purposes. Join the movement! https://t.me/cryptocurrencydevs
