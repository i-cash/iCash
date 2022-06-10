const FELIX_acat = artifacts.require("Felix");

module.exports = async function (deployer) {
	// self initialized
  await deployer.deploy(FELIX_acat);
};