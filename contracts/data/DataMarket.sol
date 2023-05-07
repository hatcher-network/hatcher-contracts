// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../greenfield/BucketApp.sol";
import "../greenfield/ObjectApp.sol";
import "../greenfield/GroupApp.sol";
import "../greenfield/interface/IERC1155.sol";
import "../greenfield/interface/IERC721NonTransferable.sol";
import "../greenfield/interface/IERC1155NonTransferable.sol";

/**
 * @dev Hatcher data market
 * 
 * Resources like bucket,object,group are mirrored to BSC, represented in ERC721 tokens
 *
 * Workflow:
 *  On Greenfield, use disko app created by hatcher: 
 *      1. user create a bucket
 *      2. user upload data (create an object)
 *      3. user create a group, and grant the group members access right to the data object
 *      4. trigger a mirror action, mirror bucket,object,group resources to BSC
 *  On BSC:
 *      1. user publish a data item (user select object from his bucket on frontend)
 *      2. buyer pay to buy the item, trigger a crosschain call to greenfield, add the buyer to the group
 *      3. buyer can download the data from greenfield after he is added to the group
 *
 * And an DataItem should be bonding to a group (usage right for this data item)
 * Only members of the group can download the DataItem from greenfield
 */
contract DataMarket is BucketApp, ObjectApp, GroupApp {
    /*----------------- constants -----------------*/
    // error code
    // 0-3: defined in `baseApp`
    string public constant ERROR_INVALID_NAME = "4";
    string public constant ERROR_RESOURCE_EXISTED = "5";
    string public constant ERROR_INVALID_PRICE = "6";
    string public constant ERROR_GROUP_NOT_EXISTED = "7";
    string public constant ERROR_DATA_NOT_ONSHELF = "8";
    string public constant ERROR_NOT_ENOUGH_VALUE = "9";
    string public constant ERROR_INVALID_TAX = "10";

    /*----------------- storage -----------------*/
    // admins
    address public owner;
    mapping(address => bool) public operators;

    struct DataItem {
        string title;
        string description;
        address owner;
        string tags;
        string data_type; // e.g. pdf, text
        uint price; // in wei
        string gnfd_path; // gnfd://bucket_name/obj_name
        uint bucket_id;
        uint obj_id; // unique
        uint group_id; // the group representing usage right for this data item on greenfield
        string group_name; // the group name
        uint status; // item status, 0: delisted, 1: selling
        uint sale_count; // count of sales
        uint income; // total income
        uint timestamp; // publish timestamp
    }

    // ERC1155 token for onshelf data items
    address public dataToken;

    // system contract
    address public bucketToken;
    address public objectToken;
    address public groupToken;
    address public memberToken;

    // data object id => DataItem
    mapping(uint256 => DataItem) dataItem;

    // dev fee = tax/100
    uint256 public tax;
    mapping(address => uint256) public income;

    // PlaceHolder reserve for future use
    uint256[25] public _Gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner || _isOperator(msg.sender), "caller is not the owner or operator");
        _;
    }

    function initialize(
        address _crossChain,
        address _bucketHub,
        address _objectHub,
        address _groupHub,
        address _paymentAddress,
        uint256 _callbackGasLimit,
        address _refundAddress,
        uint8 _failureHandleStrategy,
        address _owner,
        address _dataToken,
        uint256 _tax
    ) public initializer {
        require(_owner != address(0), string.concat("DataMarket: ", ERROR_INVALID_CALLER));
        _transferOwnership(_owner);

        tax = _tax;
        dataToken = _dataToken;
        bucketToken = IBucketHub(_bucketHub).ERC721Token();
        objectToken = IObjectHub(_objectHub).ERC721Token();
        groupToken = IGroupHub(_groupHub).ERC721Token();
        memberToken = IGroupHub(_groupHub).ERC1155Token();

        __base_app_init_unchained(_crossChain, _callbackGasLimit, _refundAddress, _failureHandleStrategy);
        __bucket_app_init_unchained(_bucketHub, _paymentAddress);
        __group_app_init_unchained(_groupHub);
        __object_app_init_unchained(_objectHub);
    }

    /*----------------- external functions -----------------*/
    // unused
    function greenfieldCall(
        uint32 status,
        uint8 resoureceType,
        uint8 operationType,
        uint256 resourceId,
        bytes calldata callbackData
    ) external override(BucketApp, ObjectApp, GroupApp) {
        require(msg.sender == crossChain, string.concat("DataMarket: ", ERROR_INVALID_CALLER));

        if (resoureceType == RESOURCE_BUCKET) {
            _bucketGreenfieldCall(status, operationType, resourceId, callbackData);
        } else if (resoureceType == RESOURCE_OBJECT) {
            _objectGreenfieldCall(status, operationType, resourceId, callbackData);
        } else if (resoureceType == RESOURCE_GROUP) {
            _groupGreenfieldCall(status, operationType, resourceId, callbackData);
        } else {
            revert(string.concat("DataMarket: ", ERROR_INVALID_RESOURCE));
        }
    }

    /**
     * @dev Provide an ebook's ID to publish it.
     *
     * An ERC1155 token will be minted to the owner.
     * Other users can buy the ebook by calling `buyEbook` function with given price.
     */
    function publishDataItem(
        string memory title,
        string memory description,
        string memory tags,
        string memory data_type,
        uint price,
        string memory gnfd_path,
        uint bucket_id,
        uint obj_id,
        uint group_id,
        string memory group_name
    ) external {
        DataItem memory _item = DataItem({
            title: title,
            description: description,
            owner: msg.sender,
            tags: tags,
            data_type: data_type,
            price: price,
            gnfd_path: gnfd_path,
            bucket_id: bucket_id,
            obj_id: obj_id,
            group_id: group_id,
            group_name: group_name,
            status: 1,
            sale_count: 0,
            income: 0,
            timestamp: block.timestamp
        });
        // ensure the seller is the owner of selected data
        require(
            IERC721NonTransferable(bucketToken).ownerOf(_item.bucket_id) == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        require(
            IERC721NonTransferable(objectToken).ownerOf(_item.obj_id) == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        require(
            IERC721NonTransferable(groupToken).ownerOf(_item.group_id) == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        // not published before
        require(dataItem[_item.obj_id].timestamp == 0, string.concat("DataMarket: ", ERROR_RESOURCE_EXISTED));
        require(price >= 0, string.concat("DataMarket: ", ERROR_INVALID_PRICE));

        dataItem[_item.obj_id] = _item;
        IERC1155(dataToken).mint(msg.sender, _item.obj_id, 1, "");
    }

    /**
     * @dev Provide an data item's ID to buy it.
     *
     * Buyer will be added to the group of the data item.
     * An ERC1155 token will be minted to the buyer.
     */
    function buyDataItem(uint256 _id) external payable {
        require(dataItem[_id].status == 1, string.concat("DataMarket: ", ERROR_DATA_NOT_ONSHELF));

        uint256 price = dataItem[_id].price;
        require(msg.value >= price, string.concat("DataItem: ", ERROR_NOT_ENOUGH_VALUE));

        IERC1155(dataToken).mint(msg.sender, _id, 1, "");

        // send crosschain msg to greenfield to update group info
        uint256 _groupId = dataItem[_id].group_id;
        address _owner = IERC721NonTransferable(groupToken).ownerOf(_groupId);
        address[] memory _member = new address[](1);
        _member[0] = msg.sender;
        _updateGroup(_owner, _groupId, UPDATE_ADD, _member);

        // update stats
        uint256 _income = price * (100 - tax) / 100;
        DataItem storage item = dataItem[_id];
        item.income += _income;
        item.sale_count += 1;
        income[_owner] += _income;

        // dev fee
        income[owner] = msg.value - _income;
    }

    /**
     * @dev Provide an data item's ID to update its price.
     *
     */
    function updatePrice(uint256 _id, uint256 _price) external {
        require(
            dataItem[_id].owner == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        DataItem storage item = dataItem[_id];
        item.price = _price;
    }

    function delistItem(uint256 _id) external {
        require(
            dataItem[_id].owner == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        DataItem storage item = dataItem[_id];
        item.status = 0;
    }

    function listItem(uint256 _id) external {
        require(
            dataItem[_id].owner == msg.sender,
            string.concat("DataMarket: ", ERROR_INVALID_CALLER)
        );
        DataItem storage item = dataItem[_id];
        item.status = 1;
    }

    function withdrawIncome() external {
        uint256 _income = income[msg.sender];
        income[msg.sender] = 0;
        msg.sender.call{value: _income}("");
    }

    /*----------------- admin functions -----------------*/
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), string.concat("EbookShop: ", ERROR_INVALID_CALLER));
        _transferOwnership(newOwner);
    }

    function addOperator(address newOperator) public onlyOwner {
        operators[newOperator] = true;
    }

    function removeOperator(address operator) public onlyOwner {
        delete operators[operator];
    }

    function setTax(uint256 _tax) external onlyOwner {
        require(_tax < 100, string.concat("DataMarket: ", ERROR_INVALID_TAX));
        tax = _tax;
    }

    /*----------------- internal functions -----------------*/
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _isOperator(address account) internal view returns (bool) {
        return operators[account];
    }
}