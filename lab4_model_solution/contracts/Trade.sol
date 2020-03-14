pragma solidity ^0.5.0;
import "./ERC20.sol";

contract Trade {

  address owner;
  ERC20 token;
  mapping(address => bool) public buyers;
  mapping(address => bool) public sellers;
  mapping(address => bool) public inspectors;
  mapping(uint => product) public products;

  mapping(uint => sale) public sales;
  mapping(address => uint) public bought;
  mapping(address => uint) public sold;

  struct product {
    uint price;
    address seller;
  }

  struct sale {
    uint prodId;
    uint price;
    uint quantity;
    address buyer;
    address seller;
    address inspector;
    bool completed;
  }

  uint nextSalesId;

  constructor(ERC20 _token) public {
      token = _token;
      owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyBuyer() {
    require(buyers[msg.sender]);
    _;
  }

  modifier onlySeller() {
    require(sellers[msg.sender]);
    _;
  }

  function registerBuyer(address buyer) public onlyOwner{
    buyers[buyer] = true;
  }

  function registerSeller(address seller) public onlyOwner{
    sellers[seller] = true;
  }

  function registerInspector(address inspector) public onlyOwner{
    inspectors[inspector] = true;
  }

  function listProduct(uint prodId, uint price) public onlySeller{
    require(price > 0);
    require(products[prodId].seller == address(0));

    products[prodId] = product(price, msg.sender);
  }

  function buyProduct(uint prodId, uint quantity, address appointedInspector) public onlyBuyer returns (uint saleId){
    require(quantity > 0, "Quantity has to be positive");
    require(products[prodId].seller != address(0), "Product undefined");
    require(inspectors[appointedInspector], "Inspector not registered");

    sales[nextSalesId] = sale(prodId, products[prodId].price, quantity, msg.sender, products[prodId].seller, appointedInspector, false);

    require(token.transferFrom(msg.sender, address(this),
            products[prodId].price * quantity), "Insufficient approval balance");

    return nextSalesId++;
  }

  function acceptSale(uint saleId) public{
    require(!sales[saleId].completed);
    require(sales[saleId].inspector == msg.sender, "Not appointed inspector");

    sales[saleId].completed = true;
    bought[sales[saleId].buyer]++;
    sold[sales[saleId].seller]++;

    require(token.transfer(sales[saleId].seller,
            sales[saleId].price * sales[saleId].quantity), "Payment failed"); //pay to seller
  }

  function rejectSale(uint saleId) public{
    require(!sales[saleId].completed);
    require(sales[saleId].inspector == msg.sender, "Not appointed inspector");

    sales[saleId].completed = true;

    require(token.transfer(sales[saleId].buyer,
            sales[saleId].price * sales[saleId].quantity), "Refund failed");  //refund to buyer
  }

  function numBought(address buyer) public view returns(uint){
    return bought[buyer];
  }

  function numSold(address seller) public view returns(uint){
    return sold[seller];
  }

}
