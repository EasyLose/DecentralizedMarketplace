pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable owner;

    struct Item {
        uint itemId;
        address payable seller;
        address buyer;
        uint price;
        bool listed;
    }

    uint public itemCount = 0;

    mapping(uint => Item) public items;

    event ItemListed(uint itemId, address seller, uint price);
    event ItemBought(uint itemId, address buyer, uint price);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlySeller(uint _itemId) {
        require(msg.sender == items[_itemId].seller, "Only seller can perform this action");
        _;
    }

    function listItem(uint _price) public returns (uint) {
        itemCount++;
        items[itemCount] = Item(itemCount, payable(msg.sender), address(0), _price, true);

        emit ItemListed(itemCount, msg.sender, _price);
        return itemCount;
    }

    function buyItem(uint _itemId) public payable {
        Item storage item = items[_itemId];

        require(item.listed, "Item is not listed");
        require(msg.value == item.price, "Incorrect value");
        require(item.seller != msg.sender, "Seller cannot buy their own item");
        
        item.seller.transfer(msg.value);
        item.buyer = msg.sender;
        item.listed = false;

        emit ItemBought(_itemId, msg.sender, msg.value);
    }

    function unlistItem(uint _itemId) public onlySeller(_itemId) {
        Item storage item = items[_itemId];
        require(item.listed, "Item is already unlisted");

        item.listed = false;
    }

    function relistItem(uint _itemId, uint _newPrice) public onlySeller(_itemId) {
        Item storage item = items[_itemId];
        require(!item.listed, "Item is already listed");
        item.price = _newPrice;
        item.listed = true;

        emit ItemListed(_itemId, item.seller, _newPrice);
    }

    function getItem(uint _itemId) public view returns (Item memory) {
        return items[_itemId];
    }
}