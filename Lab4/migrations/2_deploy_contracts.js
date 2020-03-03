const ERC20 = artifacts.require("ERC20");
const ecosystem = artifacts.require("Trade_Template");

module.exports = function(deployer, network, accounts) {
  return deployer
      .then(() => {
        return deployer.deploy(ERC20);
      }).then(erc20Instance => {
        return deployer.deploy(ecosystem, erc20Instance.address);
      }).then( ex1Instance => {
        console.log("Marketplace deployed at address = "+ex1Instance.address);
      });
};