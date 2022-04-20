const HealAngels = artifacts.require("HealAngelsFactory");

module.exports = async function (deployer) {
  await deployer.deploy(HealAngels);
};