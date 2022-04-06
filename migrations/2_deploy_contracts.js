const ICash = artifacts.require("ICash");
module.exports = async function (deployer) {
  await deployer.deploy(ICash);
 };