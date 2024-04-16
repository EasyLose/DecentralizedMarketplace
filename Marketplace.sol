pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable private ownerAddress;

    struct Item {
        uint id;
        address payable sellerAddress;
        address buyerAddress;
        uint priceInWei;
        bool isCurrentlyListed;
    }

    uint public itemCount = 0;
    mapping(uint => Item) public itemsForSale;

    event ItemListedEvent(uint itemId, address indexed sellerAddress, uint priceInWei);
    event MultipleItemsListedEvent(uint[] itemIds);
    event ItemPurchasedEvent(uint itemId, address indexed buyerAddress, uint priceInWei);
    event MultipleItemsPurchasedEvent(uint[] itemIds);
    event ItemDelistedEvent(uint itemId);
    event ItemPriceUpdatedEvent(uint itemId, uint newPriceInWei);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "DecentralizedMarketplace: Caller is not the owner");
        _;
    }

    modifier onlySellerOfItem(uint itemId) {
        require(msg.sender == itemsForSale[itemId].sellerAddress, "DecentralizedMarketplace: Caller is not the seller of this item");
        _;
    }

    constructor() {
        ownerAddress = payable(msg.sender);
    }

    function listItemForSale(uint priceInWei) external returns (uint) {
        addItemToList(priceInWei);
    }

    function listMultipleItemsForSale(uint[] calldata pricesInWei) external returns (uint[] memory) {
        return addMultipleItemsToList(pricesInWei);
    }

    function purchaseItem(uint itemId) external payable {
        processSingleItemPurchase(itemId);
    }

    function purchaseMultipleItems(uint[] calldata itemIds) external payable {
        processMultipleItemPurchase(itemIds);
    }

    function delistItem(uint itemId) external onlySellerOfItem(itemId) {
        updateItemListingStatus(itemId, false);
        emit ItemDelistedEvent(itemId);
    }

    function updateItemPrice(uint itemId, uint newPriceInWei) external onlySellerOfItem(itemId) {
        require(newPriceInWei > 0, "DecentralizedMarketplace: Price must be greater than zero");
        Item storage item = itemsForSale[itemId];
        require(item.isCurrentlyListed == false, "DecentralizedMarketplace: Item is listed; cannot update price");
        item.priceInWei = newPriceInWei;
        emit ItemPriceUpdatedEvent(itemId, newPriceInWei);
    }

    // Helper functions
    function addItemToList(uint priceInWei) private returns (uint) {
        require(priceInWei > 0, "DecentralizedMarketplace: Price must be greater than zero");
        itemCount++;
        itemsForSale[itemCount] = Item(itemCount, payable(msg.sender), address(0), priceInWei, true);
        emit ItemListedEvent(itemCount, msg.sender, priceInWei);
        return itemCount;
    }

    function addMultipleItemsToList(uint[] memory pricesInWei) private returns (uint[] memory) {
        require(pricesInWei.length > 0, "DecentralizedMarketplace: No prices provided");
        uint[] memory ids = new uint[](pricesInWei.length);
        for (uint i = 0; i < pricesInWei.length; i++) {
            ids[i] = addItemToList(pricesInWei[i]);
        }
        emit MultipleItemsListedEvent(ids);
        return ids;
    }

    function processSingleItemPurchase(uint itemId) private {
        Item storage item = itemsForSale[itemId];
        validateItemPurchase(item);
        item.sellerAddress.transfer(msg.value);
        finalizePurchase(item, itemId);
    }

    function processMultipleItemPurchase(uint[] memory itemIds) private {
        uint totalCostInWei = 0;
        for (uint i = 0; i < itemIds.length; i++) {
            Item storage item = itemsForSale[itemIds[i]];
            validateItemPurchase(item);
            totalCostInWei += item.priceInWei;
            finalizePurchase(item, itemIds[i]);
        }
        returnChangeIfNecessary(totalCostInWei);
        emit MultipleItemsPurchasedEvent(itemIds);
    }

    function validateItemPurchase(Item storage item) private view {
        require(item.isCurrentlyListed, "DecentralizedMarketplace: Item is not listed");
        require(msg.sender != item.sellerAddress, "DecentralizedMarketplace: Seller cannot buy their own item");
        require(msg.value >= item.priceInWei, "DecentralizedMarketplace: Incorrect value");
    }

    function finalizePurchase(Item storage item, uint itemId) private {
        item.buyerAddress = msg.sender;
        item.isCurrentlyListed = false;
        emit ItemPurchasedEvent(itemId, msg.sender, item.priceInWei);
    }

    function returnChangeIfNecessary(uint totalCostInWei) private {
        if (msg.value > totalCostInWei) {
            payable(msg.sender).transfer(msg.value - totalCostInWei);
        }
    }

    function updateItemListingStatus(uint itemId, bool isListed) private {
        Item storage item = itemsForSale[itemId];
        require(item.isCurrentlyListed != isListed, "DecentralizedMarketplace: Incorrect listing status");
        item.isCurrentlyListed = isListed;
    }
}