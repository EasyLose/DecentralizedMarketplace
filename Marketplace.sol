pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable private _owner;

    struct Item {
        uint id;
        address payable seller;
        address buyer;
        uint price;
        bool isListed;
    }

    uint public totalItems = 0;
    mapping(uint => Item) public itemList;

    event ItemListed(uint itemId, address indexed seller, uint price);
    event MultipleItemsListed(uint[] itemIds);
    event ItemPurchased(uint itemId, address indexed buyer, uint price);
    event MultipleItemsPurchased(uint[] itemIds);
    event ItemDelisted(uint itemId);
    event ItemPriceUpdated(uint itemId, uint newPrice);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the marketplace owner can perform this action");
        _;
    }

    modifier onlyItemSeller(uint itemId) {
        require(msg.sender == itemList[itemId].seller, "Only the item's seller can perform this action");
        _;
    }

    constructor() {
        _owner = payable(msg.sender);
    }

    function listItem(uint price) external returns (uint) {
        totalItems++;
        itemList[totalItems] = Item(totalItems, payable(msg.sender), address(0), price, true);

        emit ItemListed(totalItems, msg.sender, price);

        return totalItems;
    }

    function listMultipleItems(uint[] calldata prices) external returns (uint[] memory) {
        uint[] memory ids = new uint[](prices.length);

        for (uint i = 0; i < prices.length; i++) {
            totalItems++;
            itemList[totalItems] = Item(totalItems, payable(msg.sender), address(0), prices[i], true);
            ids[i] = totalItems;

            emit ItemListed(totalItems, msg.sender, prices[i]);
        }

        emit MultipleItemsListed(ids);

        return ids;
    }

    function purchaseItem(uint itemId) external payable {
        Item storage item = itemList[itemId];

        require(item.isListed, "Item is not listed.");
        require(msg.value == item.price, "Incorrect value.");
        require(item.seller != msg.sender, "Seller cannot buy their own item.");

        item.seller.transfer(msg.value);
        item.buyer = msg.sender;
        item.isListed = false;

        emit ItemPurchased(itemId, msg.sender, msg.value);
    }

    function purchaseMultipleItems(uint[] calldata itemIds) external payable {
        require(itemIds.length > 0, "No items provided");
        uint totalCost = 0;

        for(uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            Item storage item = itemList[itemId];

            require(item.isListed, "Item is not listed.");
            require(item.seller != msg.sender, "Seller cannot buy their own item.");

            totalCost += item.price;
            item.buyer = msg.sender;
            item.isListed = false;

            emit ItemPurchased(itemId, msg.sender, item.price);
        }

        require(msg.value == totalCost, "Incorrect total value.");
        payable(msg.sender).transfer(msg.value - totalCost);

        emit MultipleItemsPurchased(itemIds);
    }

    function delistItem(uint itemId) external onlyItemSeller(itemId) {
        Item storage item = itemList[itemId];
        require(item.isListed, "Item is already delisted.");

        item.isListed = false;

        emit ItemDelisted(itemId);
    }

    function updateItemPrice(uint itemId, uint newPrice) external onlyItemSeller(itemId) {
        Item storage item = itemList[itemId];
        require(!item.isListed, "Item is already listed.");

        item.price = newPrice;
        item.isListed = true;

        emit ItemPriceUpdated(itemId, newPrice);
    }
}