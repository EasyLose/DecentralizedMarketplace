pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    address payable public owner;
    uint public itemCount = 0;

    mapping(uint => Item) public items;
    mapping(uint => address) public itemOwners;

    struct Item {
        uint id;
        address payable seller;
        string name;
        uint price;
        bool sold;
    }

    event ItemListed(
        uint id,
        address indexed seller,
        string name,
        uint price
    );

    event ItemBought(
        uint id,
        address indexed buyer,
        string name,
        uint price
    );

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this operation");
        _;
    }

    function listItem(string memory _name, uint _price) public {
        require(_price > 0, "Price must be greater than zero");
        itemCount++;
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: _name,
            price: _price,
            sold: false
        });
        emit ItemListed(itemCount, msg.sender, _name, _price);
    }

    function buyItem(uint _itemId) public payable {
        Item storage item = items[_itemId];
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        require(msg.value >= item.price, "Insufficient funds sent");
        require(!item.sold, "Item is already sold");

        item.seller.transfer(msg.value);
        item.sold = true;
        itemOwners[_itemId] = msg.sender;
        
        emit ItemBought(_itemId, msg.sender, item.name, item.price);
    }

    function getOwnership(uint _itemId) public view returns (address) {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        require(itemOwners[_itemId] != address(0), "This item has not been sold yet");

        return itemOwners[_itemId];
    }
}