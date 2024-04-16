pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable private contractOwner;

    struct Item {
        uint itemId;
        address payable seller;
        address buyer;
        uint priceWei;
        bool listedForSale;
    }

    uint public totalItems = 0;
    mapping(uint => Item) public itemsListed;

    event ItemListed(uint itemId, address indexed seller, uint priceWei);
    event ItemsListedBulk(uint[] itemIds);
    event ItemSold(uint itemId, address indexed buyer, uint priceWei);
    event ItemsSoldBulk(uint[] itemIds);
    event ItemRemoved(uint itemId);
    event ItemPriceChanged(uint itemId, uint newPriceWei);

    modifier isOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this operation");
        _;
    }

    modifier isSeller(uint itemId) {
        require(msg.sender == itemsListed[itemId].seller, "Only the item seller can perform this operation");
        _;
    }

    constructor() {
        contractOwner = payable(msg.sender);
    }

    function offerItem(uint priceWei) external returns (uint) {
        return listItem(priceWei);
    }

    function offerMultipleItems(uint[] calldata pricesWei) external returns (uint[] memory) {
        return listItemsBulk(pricesWei);
    }

    function buyItem(uint itemId) external payable {
        executePurchaseItem(itemId);
    }

    function buyMultipleItems(uint[] calldata itemIds) external payable {
        executePurchaseItemsBulk(itemIds);
    }

    function removeItemFromSale(uint itemId) external isSeller(itemId) {
        updateListingStatus(itemId, false);
        emit ItemRemoved(itemId);
    }

    function setNewItemPrice(uint itemId, uint newPriceWei) external isSeller(itemId) {
        require(newPriceWei > 0, "Item price must be greater than zero");
        Item storage item = itemsListed[itemId];
        require(!item.listedForSale, "Item currently listed, cannot change price");
        item.priceWei = newPriceWei;
        emit ItemPriceChanged(itemId, newPriceWei);
    }

    function listItem(uint priceWei) private returns (uint) {
        require(priceWei > 0, "Item price must be greater than zero");
        totalItems++;
        itemsListed[totalItems] = Item(totalItems, payable(msg.sender), address(0), priceWei, true);
        emit ItemListed(totalItems, msg.sender, priceWei);
        return totalItems;
    }

    function listItemsBulk(uint[] memory pricesWei) private returns (uint[] memory) {
        require(pricesWei.length > 0, "No item prices provided");
        uint[] memory ids = new uint[](pricesWei.length);
        for (uint i = 0; i < pricesWei.length; i++) {
            ids[i] = listItem(pricesWei[i]);
        }
        emit ItemsListedBulk(ids);
        return ids;
    }

    function executePurchaseItem(uint itemId) private {
        Item storage item = itemsListed[itemId];
        validatePurchase(item);
        item.seller.transfer(msg.value);
        finalizeItemSale(item, itemId);
    }

    function executePurchaseItemsBulk(uint[] memory itemIds) private {
        uint totalPriceWei = 0;
        for (uint i = 0; i < itemIds.length; i++) {
            Item storage item = itemsListed[itemIds[i]];
            validatePurchase(item);
            totalPriceWei += item.priceWei;
            finalizeItemSale(item, itemIds[i]);
        }
        issueRefundIfNeeded(totalPriceWei);
        emit ItemsSoldBulk(itemIds);
    }

    function validatePurchase(Item storage item) private view {
        require(item.listedForSale, "Item not for sale");
        require(msg.sender != item.seller, "Seller cannot buy their own item");
        require(msg.value >= item.priceWei, "Sent value is below the item price");
    }

    function finalizeItemSale(Item storage item, uint itemId) private {
        item.buyer = msg.sender;
        item.listedForSale = false;
        emit ItemSold(itemId, msg.sender, item.priceWei);
    }

    function issueRefundIfNeeded(uint totalPriceWei) private {
        if (msg.value > totalPriceWei) {
            payable(msg.sender).transfer(msg.value - totalPriceWei);
        }
    }

    function updateListingStatus(uint itemId, bool newListedStatus) private {
        Item storage item = itemsListed[itemId];
        require(item.listedForSale != newListedStatus, "No change in listing status");
        item.listedForSale = newListedStatus;
    }
}