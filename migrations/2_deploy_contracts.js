const FELIX_acat = artifacts.require("Felix");

module.exports = async function (deployer) {
  await deployer.deploy(FELIX_acat);
};