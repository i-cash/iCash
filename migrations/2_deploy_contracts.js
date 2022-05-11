const Passive = artifacts.require("Passive");
module.exports = async function (deployer) {
  await deployer.deploy(Passive);
 };