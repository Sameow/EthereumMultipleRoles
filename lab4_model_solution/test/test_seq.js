const ERC20 = artifacts.require("ERC20");
const Trade = artifacts.require("Trade");

contract("Trade", accounts => {
  let trade;
  let token;
  let prodId = 101;
  let prodId2 = 105;
  let startingBal = 3000;
  let newBal;
  let listPrice = 200;
  let qty = 2;
  const platform = accounts[0];
  const buyer = accounts[1];
  const seller = accounts[2];
  const inspector = accounts[3];
  const inspector2 = accounts[4];

  it("mint tokens to buyer", () =>
      ERC20.deployed()
      .then((_inst) => {
        token = _inst;
        return token.mintToken(buyer, startingBal);
      }).then(() => {
        return token.balanceOf.call(buyer);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), startingBal, "Incorrect starting balance");
      })
  );

  it("Platform registers buyer, seller, inspector", () =>
      Trade.deployed()
      .then(_inst => {
        trade = _inst;
        return trade.registerBuyer(buyer);
      }).then(() => {
        return trade.registerSeller(seller);
      }).then(() => {
        return trade.registerInspector(inspector);
      })
  );

  it("Sale cycle", () =>
      trade.listProduct(prodId, listPrice, {from: seller})
      .then(() => {
        return token.approve(trade.address, listPrice * qty, {from: buyer})
      }).then(() => {
        return trade.buyProduct(prodId, qty, inspector, {from: buyer})
      }).then(() => {
        let saleId = 0;
        return trade.acceptSale(saleId, {from: inspector})
      }).then(() => {
        return token.balanceOf.call(buyer);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), startingBal - (listPrice * qty), "Buyer fund not consumed");
      }).then(() => {
        return token.balanceOf.call(seller);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), listPrice * qty, "Seller not paid right amount");
      })
  );

  it("Sale rejection cycle", () =>
      token.balanceOf.call(buyer)
      .then((rsl) => {
        newBal = rsl.valueOf();
      }).then(() => {
        return trade.listProduct(prodId, listPrice, {from: seller})
      }).then(() => {
        assert.fail("Listing on the same product Id again should fail.")
      }).catch((err) => {
        return trade.listProduct(prodId2, listPrice, {from: seller})
      }).then(() => {
        return token.approve(trade.address, listPrice * qty, {from: buyer})
      }).then(() => {
        return trade.buyProduct(prodId2, qty, inspector, {from: buyer})
      }).then(() => {
        let saleId = 1;
        return trade.rejectSale(saleId, {from: inspector})
      }).then(() => {
        return token.balanceOf.call(buyer);
      }).then((rsl) => {
        assert.equal(rsl.valueOf().toNumber(), newBal, "Buyer's balance not refunded");   //all money is refunded
      }).then(() => {
        return token.balanceOf.call(seller);
      }).then((rsl) => {
        assert.equal(rsl.valueOf(), listPrice * qty, "Wrong seller balance"); //same amount from before
      })
  )

});
