pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./ERC721Full.sol";

contract Trade_Template {

    address _owner = msg.sender;
    ERC20 erc20Contract;
    person[] public buyers;
    person[] public sellers;
    person[] public inspectors;
    uint public totalSales = 0;

    struct product {
        uint prodId;
        uint price;
        address seller;
    }

    struct sale {
        uint saleId;
        address buyer;
        address appointedInspector;
        uint quantity;
        product prod;
    }

    struct person {
        address personAcct;
        uint transactions;
    }

    product[] public productList;
    sale[] public saleList;

    constructor(ERC20 erc20Address) public {
        erc20Contract = erc20Address;
    }

  modifier onlyOwner() {
      require(msg.sender == _owner, "owner only action.");
      _;
  }

  modifier onlyBuyer() {
      require(checkIfUserExist('buyer', msg.sender), "Action can only be performed by buyers.");
    _;
  }

  modifier onlySeller() {
       require(checkIfUserExist('seller', msg.sender), "Action can only be performed by sellers.");
    _;
  }

  modifier onlyInspector() {
       require(checkIfUserExist('inspector', msg.sender), "Action can only be performed by inspectors.");
    _;
  }

  function checkIfUserExist(string memory userType, address user) internal view returns (bool) {
      bool userExist = false;
      person[] memory userArray;
      if (keccak256(abi.encodePacked(userType)) == keccak256(abi.encodePacked('buyer'))) {
          userArray = buyers;
      }
      else if (keccak256(abi.encodePacked(userType)) == keccak256(abi.encodePacked('seller'))) {
          userArray = sellers;
      }
      else if (keccak256(abi.encodePacked(userType)) == keccak256(abi.encodePacked('inspector'))) {
          userArray = inspectors;
      }
      else {
          revert("no such user type.");
      }

      for (uint i=0; i<userArray.length; i++) {
          if (userArray[i].personAcct == user) {
              userExist = true;
          }
      }
      return userExist;
  }

  function checkProductID(uint prodId) internal view returns (bool) {
      bool productExist = false;
      for (uint i=0; i<productList.length; i++) {
          if (productList[i].prodId == prodId) {
              productExist = true;
          }
      }
      return productExist;
  }

  function registerBuyer(address buyer) public onlyOwner{
      if (checkIfUserExist('buyer', buyer)) {
          revert("Buyer already exists.");
      }
      buyers.push(person(buyer, 0));
  }

  function registerSeller(address seller) public onlyOwner{
      if (checkIfUserExist('seller', seller)) {
          revert("Seller already exists.");
      }
      sellers.push(person(seller, 0));
  }

  function registerInspector(address inspector) public onlyOwner{
      if (checkIfUserExist('inspector', inspector)) {
          revert("Inspector already exists.");
      }
      inspectors.push(person(inspector, 0));
  }

  function listProduct(uint prodId, uint price) public onlySeller{
      require(!checkProductID(prodId), "product Id is in use.");
      require(price > 0, 'price must be > 0.');
      product memory newProduct = product(prodId, price, msg.sender);
      productList.push(newProduct);
  }

  function buyProduct(uint prodId, uint quantity, address appointedInspector) public onlyBuyer returns (uint saleId){
      require(checkProductID(prodId), 'product ID does not exist.');
      require(quantity>0, 'wtf bruh input in ur quantity');
      require(checkIfUserExist('inspector', appointedInspector), 'Appointed inspector doesnt exist.');
      product memory p;
      for (uint i=0; i<productList.length; i++) {
          if (productList[i].prodId == prodId) {
              p = productList[i];
          }
      }
      sale memory newSale = sale(totalSales, msg.sender, appointedInspector, quantity, p);
      saleList.push(newSale);
      erc20Contract.transferTokenFrom(msg.sender, address(this), p.price*quantity);
      return totalSales++;
  }

  function acceptSale(uint saleId) public onlyInspector{
      uint transferToSeller = saleList[saleId].prod.price * saleList[saleId].quantity;
      address buyer;
      address seller;
      erc20Contract.transferTokenFrom(address(this), saleList[saleId].prod.seller, transferToSeller);
      for (uint i=0; i<saleList.length; i++) {
          if (saleList[i].saleId == saleId) {
              buyer = saleList[i].buyer;
              seller = saleList[i].prod.seller;
              break;
          }
      }
      for (uint i=0; i<buyers.length; i++) {
          if (buyers[i].personAcct == buyer) {
              buyers[i].transactions++;
              break;
          }
      }
      for (uint i=0; i<sellers.length; i++) {
          if (sellers[i].personAcct == seller) {
              sellers[i].transactions++;
              break;
          }
      }
      delete saleList[saleId];
  }

  function rejectSale(uint saleId) public onlyInspector{
      uint transferBackToBuyer = saleList[saleId].prod.price * saleList[saleId].quantity;
      erc20Contract.transferTokenFrom(address(this), saleList[saleId].buyer, transferBackToBuyer);
      delete saleList[saleId];
  }

  function numBought(address buyer) public view returns (uint) { //number of successfully completed sales of each buyer
        for (uint i=0; i<buyers.length; i++) {
          if (buyers[i].personAcct == buyer) {
              return buyers[i].transactions;
          }
      }

  }

  function numSold(address seller) public view returns (uint) { //number of successfully completed sales of each seller
        for (uint i=0; i<sellers.length; i++) {
          if (sellers[i].personAcct == seller) {
              return sellers[i].transactions;
          }
      }

  }

}