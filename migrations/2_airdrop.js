const BN = require('bn.js');
const Airdrop = artifacts.require("Airdrop.sol");
const RenderTokenMock = artifacts.require("RenderTokenMock.sol");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(RenderTokenMock, accounts[0], new BN("331073260586440000000000"));
  await deployer.deploy(Airdrop, RenderTokenMock.address);
}