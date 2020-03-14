const trade = artifacts.require("Trade");
const token = artifacts.require("ERC20");

module.exports = function(deployer) {
  deployer.deploy(token)
  .then(()=>{
    return deployer.deploy(trade, token.address)
  })
};
