// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import {HatcherServicePassport} from "./HatcherServicePassport.sol";

/**
 * @title hatcher service NFT
 * @author Hatcher Network
 * @notice service provider create their service NFTs
 */
contract HatcherServiceCertificate is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 private _mintPrice = 0.01 ether; // 0.01 BNB mint price for each service
    uint256 private _devTax; // dev gets _devTax/100 * revenue

    struct Service {
        uint256 serviceId;
        uint256 createTime;
        uint256 userCount;
        uint256 maxUserLimit;
        uint256 price; // user should pay this amount per month for using this service
        // service description
        string logo; // e.g. gnfd://hatcher/1.png
        string name;
        string description;
        string endpoint;
        string service_type; // chat, text-to-image, etc.
        uint256 revenue; // service income
        uint8 status; // 0: inactive, 1: active
    }

    HatcherServicePassport private _hatcherServicePassport;
    uint256 public totalSupply;

    mapping(uint256 => Service) public services; // serviceId => service
    mapping(address => uint256) public balances; // service revenue
    mapping(address => uint256[]) public userServices; // user => service IDs

    // storage gap
    uint256[25] public _Gap;

    // EVENTS
    event NewService(
        uint256 indexed serviceId, 
        address indexed owner, 
        uint256 createTime,
        uint256 maxUserLimit, 
        uint256 price,
        string logo,
        string name,
        string description,
        string endpoint,
        string service_type
    );
    event UpdateService(
        uint256 indexed serviceId, 
        address indexed owner, 
        uint256 maxUserLimit, 
        uint256 price,
        string logo,
        string name,
        string description,
        string endpoint,
        string service_type,
        uint8 status
    );
    event Withdraw(address indexed to, uint256 amount);
    event UpdateDevTax(uint256 indexed tax);

    function initialize(
        address hatcherServicePassport,
        uint256 devTax
    ) public initializer {
        _hatcherServicePassport = HatcherServicePassport(
            hatcherServicePassport
        );
        _devTax = devTax;
        __ERC721_init("Hatcher Service NFT", "HSC");
        __ERC721URIStorage_init();
        __Ownable_init();
    }

    /**
     * @dev service provider create a new service
     * @param maxUserLimit  maximum number of users using this service set by the service provider
     * @param price the amount of payment for the service set by the service provider
     * @return s  the new service info
     */
    function mint(
        uint256 maxUserLimit,
        uint256 price,
        string memory logo,
        string memory name_,
        string memory description,
        string memory endpoint,
        string memory service_type
    ) public payable returns (Service memory) {
        require(msg.value >= _mintPrice, "VALUE TOO SMALL");
        balances[owner()] += _mintPrice;
        // mint NFT to creator
        uint256 serviceId = totalSupply;
        totalSupply = totalSupply.add(1);
        _safeMint(msg.sender, serviceId);
        // service info
        Service memory s = Service({
            serviceId: serviceId,
            createTime: block.timestamp,
            userCount: 0,
            maxUserLimit: maxUserLimit,
            price: price,
            logo: logo,
            name: name_,
            description: description,
            endpoint: endpoint,
            service_type: service_type,
            revenue: 0,
            status: 1
        });
        services[serviceId] = s;
        userServices[msg.sender].push(serviceId);

        emit NewService(
            serviceId, _msgSender(), block.timestamp, maxUserLimit, 
            price, logo, name_, description, endpoint, service_type
        );
        return s;
    }

    // service owner can set token URI
    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender, "UNAUTHORIZED");
        _setTokenURI(tokenId, uri);
    }

    function setServiceInfo(
        uint256 serviceId,
        uint256 maxUserLimit,
        uint256 price,
        string memory logo,
        string memory name_,
        string memory description,
        string memory endpoint,
        string memory service_type,
        uint8 status
    ) public returns (Service memory) {
        require(_exists(serviceId), "serviceId does not exist");
        Service storage s = services[serviceId];
        s.maxUserLimit = maxUserLimit;
        s.price = price;
        s.logo = logo;
        s.name = name_;
        s.description = description;
        s.endpoint = endpoint;
        s.service_type = service_type;
        s.status = status;
        
        emit UpdateService(
            serviceId, msg.sender, maxUserLimit, price, 
            logo, name_, description, endpoint, service_type, status
        );
        return s;
    }

    // TODO: override transfer & transferFrom, update userPassport
    // function transfer() public {

    // }

    // function transferFrom() public {

    // }

    // function _updateUserServices() public {

    // }

    /** public functions */
    function getServiceUserCount(
        uint256 serviceId
    ) public view returns (uint256) {
        return _hatcherServicePassport.getServiceUserCount(serviceId);
    }

    function getServiceInfo(
        uint256 serviceId
    ) public view returns (Service memory) {
        require(_exists(serviceId), "NOT EXIST");
        return services[serviceId];
    }
    
    // only passport contract call
    function addServiceRevenue(
        uint256 serviceId,
        uint256 amount
    ) external payable {
        require(msg.value >= amount, "VALUE TOO SMALL");
        require(
            address(_hatcherServicePassport) == msg.sender,
            "UNAUTHORIZED"
        );
        Service storage s = services[serviceId];
        s.revenue += amount;
        // update dev fee & owner balance
        uint devFee = _devTax / 100 * msg.value;
        balances[owner()] += devFee;
        balances[ownerOf(serviceId)] += (amount - devFee);
    }

    function setDevTax(uint256 _tax) public onlyOwner {
        require(_tax <= 100, "INVALID");
        _devTax = _tax;

        emit UpdateDevTax(_tax);
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        _mintPrice = _price;
    }

    // withdraw balance
    function withdraw(address payable _to, uint256 _amount) external {
        require(_to != address(0x0), "INVALID TO");
        require(_amount <= balances[msg.sender], "NOT ENOUGH BALANCE");
        balances[msg.sender] -= _amount;

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "WITHDRAW FAILED");

        emit Withdraw(_to, _amount);
    }

    function exists(uint256 serviceId) public view returns (bool) {
        return _exists(serviceId);
    }
}
