# iCash - Experimental smart contracts for educational purposes. 
Use at your own risk, I am not the original authors nor the bearer of the rights to this technology. 
It's been provided to me for educational purposes, during research and development. 
The code is live on Main Polygon for testing. Beware there are several contracts with the same names and not all are valid instances or representations of the iCash smart contracts experiment(s).
DO YOUR OWN RESEARCH. This contract could be risky, or it could be amazing.. To be continued...

This is not a solicitation, nor advertisement. 
If you're interested in collaborating and learning about cryptocurrency development contact Interchained @ https://t.me/interchained
#Cryptocurrencydev

Steps to redeploy are below. Will update more later if necessary.

## Depends:
NPM / Yarn & NodeJS. 

Step 1) ```yarn``` or ```npm i``` 

Step 2) Change or verify the smart contract addresses in iCash.sol & DividendDistributor.sol

This was tested on Polygon, so the contracts for USDT and WETH are set to USDT(Pos) and WMatic on Polygon. 
The router below is Quickswap. In Main net ethereum for example, one would change these values to deploy 

iCash.sol >> Line 8
    ```address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    ```
    
    ```address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    ```
    
DividendDistributor.sol >> Line 20
    ```IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    ```
    
    ```address WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    ```
    
    ```IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    ```

Step 3) open truffle console with the --network flag to specify which network to deploy contracts on example; 
```npx truffle console --network polygon```

Step 4) compile, and/or migrate. So we need to type in to truffle console ```compile``` to compile smart contracts, and then ```migrate``` to deploy /migrations to the --network selected.

Step 5) we are still learning, what does this button do?....

# Disclaimer

All claims, content, designs, algorithms, and performance measurements described in this project are done with good faith efforts. It is up to the reader to check and validate their accuracy and truthfulness. Furthermore, nothing in this project constitutes a solicitation for investment. For educational purposes. Join the movement! https://t.me/cryptocurrencydevs
