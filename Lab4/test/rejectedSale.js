const ERC20 = artifacts.require("ERC20");
const Trade_Template = artifacts.require("Trade_Template");

contract("Rejected sale", async accounts => {
    let token;
    let savedTokenState; //save state for scenarios
    let ecosystem;
    let savedEcosystemState;
    let listPrice = 2000;
    let startingBal = 3000;
    const owner = accounts[0];
    const buyer = accounts[1];
    const seller = accounts[2];
    const inspector = accounts[3];

    it("Registering buyer", async () => {
        token = await ERC20.deployed();
        ecosystem = await Trade_Template.deployed();
        await ecosystem.registerBuyer(buyer, {from: owner});
        let actualAnswer = await ecosystem.buyers.call(0);
        assert.equal(buyer, actualAnswer.personAcct, "Buyer not registered");
    });

    it("Registering seller", async () => {
        await ecosystem.registerSeller(seller, {from: owner});
        let actualAnswer = await ecosystem.sellers.call(0);
        assert.equal(seller, actualAnswer.personAcct, "Seller not registered");
    });

    it("Registering inspector", async () => {
        await ecosystem.registerInspector(inspector, {from: owner});
        let actualAnswer = await ecosystem.inspectors.call(0);
        assert.equal(inspector, actualAnswer.personAcct, "Inspector not registered");
    });

    it("Seller list a product.", async () => {
        await ecosystem.listProduct(0, listPrice, {from: seller});
        let actualAnswer = await ecosystem.productList.call(0);
        assert.equal(0, actualAnswer.prodId, "Wrong ProductID.");
        assert.equal(listPrice, actualAnswer.price, "Wrong list price.");
        assert.equal(seller, actualAnswer.seller, "Wrong seller.");
    });

    it("Buyer offers to buy the product.", async () => {
        await token.mintToken(buyer, startingBal);
        await ecosystem.buyProduct(0, 1, inspector, {from: buyer});
        let actualAnswer = await ecosystem.saleList.call(0);
        assert.equal(0, actualAnswer.saleId, "Wrong saleID.");
        assert.equal(buyer, actualAnswer.buyer, "Wrong buyer recorded.");
        assert.equal(inspector, actualAnswer.appointedInspector, "Wrong inspector.");
        assert.equal(1, actualAnswer.quantity, "Wrong quantity recorded.");
        assert.equal(0, actualAnswer.prod.prodId, "Wrong ProductID.");
        assert.equal(listPrice, actualAnswer.prod.price, "Wrong list price.");
        assert.equal(seller, actualAnswer.prod.seller, "Wrong seller.");
        actualAnswer = await token.balanceOf.call(buyer);
        assert.equal(actualAnswer.valueOf(), 1000, "Buyer should have 1000 left.");
        actualAnswer = await token.balanceOf.call(ecosystem.address);
        assert.equal(actualAnswer.valueOf(), 2000, "Ecosystem should have 2000.");
    });

    it("Inspector rejects.", async () => {
        await ecosystem.rejectSale(0, {from: inspector});
        let actualAnswer = await token.balanceOf.call(buyer);
        assert.equal(actualAnswer.valueOf(), startingBal, "Buyer not refunded.");
        actualAnswer = await token.balanceOf.call(ecosystem.address);
        assert.equal(actualAnswer.valueOf(), 0, "Ecosystem should have transferred everything.");
        assert.equal(ecosystem.saleList.length, 0, "There should not be anymore sales.");
    });
});