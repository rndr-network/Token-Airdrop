const BigNumber = web3.BigNumber;
const AirDrop = artifacts.require("AirDrop.sol");
const RenderTokenMock = artifacts.require("RenderTokenMock.sol");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(RenderTokenMock, accounts[0], new BigNumber("331073260586440000000000"));
  await deployer.deploy(AirDrop, RenderTokenMock.address);
}