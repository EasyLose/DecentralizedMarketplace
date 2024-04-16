// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable private owner;

    struct Item {
        uint itemId;
        address payable seller;
        address buyer;
        uint price;
        bool listed;
    }

    uint public itemCount = 0;
    mapping(uint => Item) public items;

    event ItemListed(uint itemId, address indexed seller, uint price);
    event ItemBought(uint itemId, address indexed buyer, uint price);
    event ItemUnlisted(uint itemId);
    event ItemRelisted(uint itemId, uint newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the marketplace owner can perform this action");
        _;
    }

    modifier onlySeller(uint itemId) {
        require(msg.sender == items[itemId].seller, "Only the item's seller can perform this action");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function listItem(uint _price) external returns (uint) {
        itemCount++;
        items[itemCount] = Item(itemCount, payable(msg.sender), address(0), _price, true);

        emit ItemListed(itemCount, msg.sender, _price);

        return itemCount;
    }

    function buyItem(uint itemId) external payable {
        Item storage item = items[itemId];

        require(item.listed, "Item is not listed.");
        require(msg.value == item.price, "Incorrect value.");
        require(item.seller != msg.sender, "Seller cannot buy their own item.");

        item.seller.transfer(msg.value);
        item.buyer = msg.sender;
        item.listed = false;

        emit ItemBought(itemId, msg.sender, msg.value);
    }

    function unlistItem(uint itemId) external onlySeller(itemId) {
        Item storage item = items[itemId];
        require(item.listed, "Item is already unlisted.");

        item.listed = false;

        emit ItemUnlisted(itemId);
    }

    function relistItem(uint itemId, uint newPrice) external onlySeller(itemId) {
        Item storage item = items[itemId];
        require(!item.listed, "Item is already listed.");
        
        item.price = newPrice;
        item.listed = true;
        
        emit ItemRelisted(itemId, newPrice);
    }
}