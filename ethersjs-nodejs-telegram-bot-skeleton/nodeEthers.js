
var EthersHeadsOrTails = require('./ethers.js');
 
function checkOddOrEven(){
  return EthersHeadsOrTails.getToken();
}

// function checkPrime(){
//   return EthersGetPrime.getPrime();
// }

setInterval(checkOddOrEven, 16000);
// setInterval(checkPrime, 16000);