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
        require(priceInWei > 0, "DecentralizedMarketplace: Price must be greater than zero");
        
        itemCount++;
        itemsForSale[itemCount] = Item(itemCount, payable(msg.sender), address(0), priceInWei, true);

        emit ItemListedEvent(itemCount, msg.sender, priceInWei);

        return itemCount;
    }

    function listMultipleItemsForSale(uint[] calldata pricesInWei) external returns (uint[] memory) {
        require(pricesInWei.length > 0, "DecentralizedMarketplace: No prices provided");
        
        uint[] memory ids = new uint[](pricesInWei.length);

        for (uint i = 0; i < pricesInWei.length; i++) {
            require(pricesInWei[i] > 0, "DecentralizedMarketplace: Price must be greater than zero");
            
            itemCount++;
            itemsForSale[itemCount] = Item(itemCount, payable(msg.sender), address(0), pricesInWei[i], true);
            ids[i] = itemCount;

            emit ItemListedEvent(itemCount, msg.sender, pricesInWei[i]);
        }

        emit MultipleItemsListedEvent(ids);

        return ids;
    }

    function purchaseItem(uint itemId) external payable {
        Item storage item = itemsForSale[itemId];

        require(item.isCurrentlyListed, "DecentralizedMarketplace: Item is not listed");
        require(msg.value == item.priceInWei, "DecentralizedMarketplace: Incorrect value");
        require(item.sellerAddress != msg.sender, "DecentralizedMarketplace: Seller cannot buy their own item");

        item.sellerAddress.transfer(msg.value);
        item.buyerAddress = msg.sender;
        item.isCurrentlyListed = false;

        emit ItemPurchasedEvent(itemId, msg.sender, msg.value);
    }

    function purchaseMultipleItems(uint[] calldata itemIds) external payable {
        require(itemIds.length > 0, "DecentralizedMarketplace: No items provided");
        
        uint totalCostInWei = 0;
        for(uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            Item storage item = itemsForSale[itemId];

            require(item.isCurrentlyListed, "DecentralizedMarketplace: Item is not listed");
            require(item.sellerAddress != msg.sender, "DecentralizedMarketplace: Seller cannot buy their own item");

            totalCostInWei += item.priceInWei;
            item.buyerAddress = msg.sender;
            item.isCurrentlyListed = false;
            emit ItemPurchasedEvent(itemId, msg.sender, item.priceInWei);
        }

        require(msg.value >= totalCostInWei, "DecentralizedMarketplace: Incorrect total value");

        if(msg.value > totalCostInWei) {
            payable(msg.sender).transfer(msg.value - totalCostInWei);
        }

        emit MultipleItemsPurchasedEvent(itemIds);
    }

    function delistItem(uint itemId) external onlySellerOfItem(itemId) {
        Item storage item = itemsForSale[itemId];
        require(item.isCurrentlyListed, "DecentralizedMarketplace: Item is already delisted");

        item.isCurrentlyListed = false;

        emit ItemDelistedEvent(itemId);
    }

    function updateItemPrice(uint itemId, uint newPriceInWei) external onlySellerOfItem(itemId) {
        require(newPriceInWei > 0, "DecentralizedMarketplace: Price must be greater than zero");
        Item storage item = itemsForSale[itemId];
        require(!item.isCurrentlyListed, "DecentralizedMarketplace: Item is listed; cannot update price");

        item.priceInWei = newPriceInWei;

        emit ItemPriceUpdatedEvent(itemId, newPriceInWei);
    }
}