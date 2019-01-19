pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// Copied and modified from: https://github.com/dev-bootcamp-2019/supply-chain-PEshwar/blob/83833f44dfeae44239113fda7338a25c9c10cf50/test/TestSupplyChain.sol

contract TestSupplyChain {

    // Test for failing conditions in this contracts
    // test that every modifier is working
    uint public initialBalance  = 10 ether;

    SupplyChain public supplyChain;
    Player public seller;
    Player public buyer;
    Player public enemy; 

    string itemName = "books";
    uint itemPrice = 1 wei;
    uint itemSku = 0;
    uint secondItemSku = 1;

    function testInitialization() public{
        supplyChain = new SupplyChain();
        seller = new Player(address(supplyChain));
        buyer = new Player(address(supplyChain));
        enemy = new Player(address(supplyChain));

        //send some money to the buyer
        uint buyerCash = itemPrice + 5 wei;
        address(buyer).transfer(buyerCash);

        //add item to the supplychain
        bool item1Added = seller.addItem(itemName, itemPrice);
        bool item2Added = seller.addItem("Pride and Prejudice", itemPrice);
        bool item3Added = seller.addItem("Zero to one", itemPrice);
        
        Assert.isTrue(item1Added, "First Item should be added sucessfuly...");
        Assert.isTrue(item2Added, "Second Item should be added sucessfuly...");
        Assert.isTrue(item3Added, "Third Item should be added sucessfuly...");
    }

    //test for added items
    function testFetchItems() public {

        uint256 expectedState = 0;
        uint256 expectedBuyerAddress = 0;
        (string memory name, uint recievedSku, uint receivedPrice, uint receivedState, address receivedSeller, address receivedBuyer) = supplyChain.fetchItem(itemSku);

        Assert.equal(name, itemName, "Should be name of added item");
        Assert.equal(recievedSku, itemSku, "Sku should be correct");
        Assert.equal(receivedPrice, itemPrice, "Price should be 1 wei");
        Assert.equal(receivedState, expectedState, "State should be ForSale");
        Assert.equal(receivedSeller, address(seller), "Address should be seller address");
        Assert.equal(receivedBuyer, address(expectedBuyerAddress), "Buyer should be 0x0000...");
    }

    // buyItem

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale
    function testItemCannotBePurchased() public {
        bool result = buyer.buyItem(itemSku, itemPrice - 1);
        Assert.isFalse(result, "Cannot buy item with insufficient funds");

        uint256 missingItem = 100;
        result = buyer.buyItem(missingItem, itemPrice);
        Assert.isFalse(result, "Cannot buy item that is not available");
    }

    function testItemCanBePurchased() public  {
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Buyer can purchase item with the right price");

        result = buyer.buyItem(secondItemSku, itemPrice);
        Assert.isTrue(result, "Buyer can purchase item with the right price");

        uint256 expectedState = 1;
        address expectedBuyer = address(buyer);
        ( , , , uint receivedState, , address receivedBuyer) = supplyChain.fetchItem(itemSku);
        Assert.equal(receivedState, expectedState, "State should be sold");
        Assert.equal(receivedBuyer, expectedBuyer, "Should be equal to expected buyer");

        uint256 expectedBalance = 4 wei;
        uint256 receivedBalance = address(buyer).balance;
        Assert.equal(receivedBalance, expectedBalance, "Buyer balance should reduce by price of item");
    }

    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold
    function testItemCannotBeShipped() public {
        uint256 unavailableItem = 5;
        bool result = seller.shipItem(unavailableItem);
        Assert.isFalse(result, "Cannot ship missing item");

        uint256 skuForItemNotSold = 2;
        result = seller.shipItem(skuForItemNotSold);
        Assert.isFalse(result, "Item not sold cannot be shipped, even if added by seller.");

        result = buyer.shipItem(itemSku);
        Assert.isFalse(result, "Buyer cannot ship any item.");

        result = enemy.shipItem(itemSku);
        Assert.isFalse(result, "Enemy cannot ship any item.");
    }

    function testItemCanBeShipped() public {
        bool result = seller.shipItem(itemSku);
        Assert.isTrue(result, "Seller can ship sold item");
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped

    function testItemCannotBeReceived() public {
        uint256 unavailableItem = 5;                
        bool result = buyer.receiveItem(unavailableItem);
        Assert.isFalse(result, "Buyer cannot ship unavailable item");

        result = seller.receiveItem(itemSku);
        Assert.isFalse(result, "Seller cannot receive item, if she is not the buyer");

        result = buyer.receiveItem(secondItemSku);
        Assert.isFalse(result, "Buyer cannot receive item not marked shipped");

        result = enemy.receiveItem(secondItemSku);
        Assert.isFalse(result, "Enemy cannot receive item not marked shipped");
    }


    function testItemCanBeReceived() public {
        bool result = buyer.receiveItem(itemSku);
        Assert.isTrue(result, "Buyer can receive item she bought");
    }

    function() external payable{

    }
}


contract Player {

    address public supplyChain;

    constructor(address _supplyChain) public{
        supplyChain = _supplyChain;
    }

    function addItem(string memory name, uint price) public returns(bool){
        return SupplyChain(supplyChain).addItem(name, price);
    }

    function buyItem(uint256 sku, uint256 amount) public returns(bool) {
    
        (bool retval, ) = address(supplyChain).call.value(amount)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return retval;
    }

    function shipItem(uint256 sku) public returns(bool){

        (bool retval, )= address(supplyChain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return retval;
    }

    function receiveItem(uint256 sku) public returns(bool){
        (bool retval,  )= address(supplyChain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return retval;
    }

    function() external payable{

    }
}
