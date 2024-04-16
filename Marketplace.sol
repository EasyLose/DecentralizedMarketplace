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
    event ItemsListed(uint[] itemIds);
    event ItemBought(uint itemId, address indexed buyer, uint price);
    event ItemsBought(uint[] itemIds);
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

    // Batch list items
    function listItems(uint[] calldata _prices) external returns (uint[] memory) {
        uint[] memory ids = new uint[](_prices.length);

        for (uint i = 0; i < _prices.length; i++) {
            itemCount++;
            items[itemCount] = Item(itemCount, payable(msg.sender), address(0), _prices[i], true);
            ids[i] = itemCount;

            emit ItemListed(itemCount, msg.sender, _prices[i]);
        }

        emit ItemsListed(ids);

        return ids;
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

    // Batch buy items
    function buyItems(uint[] calldata itemIds) external payable {
        require(itemIds.length > 0, "No items provided");
        uint totalPrice = 0;

        for(uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            Item storage item = items[itemId];

            require(item.listed, "Item is not listed.");
            require(item.seller != msg.sender, "Seller cannot buy their own item.");

            totalPrice += item.price;
            item.buyer = msg.sender;
            item.listed = false;

            emit ItemBought(itemId, msg.sender, item.price);
        }

        require(msg.value == totalPrice, "Incorrect total value.");
        payable(msg.sender).transfer(msg.value - totalPrice);

        emit ItemsBought(itemIds);
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