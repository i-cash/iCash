const PAPA = artifacts.require("PapaDollar");
module.exports = async function (deployer) {
  await deployer.deploy(PAPA);
 };