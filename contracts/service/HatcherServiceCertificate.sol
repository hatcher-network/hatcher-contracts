// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {HatcherDeveloperBadge} from "./HatcherDeveloperBadge.sol";
import {HatcherServicePassport} from "./HatcherServicePassport.sol";

/**
 * @title hatcher service
 * @author Rocklabs
 * @notice service provider create their service that will be used for users
 */
contract HatcherServiceCertificate is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 public constant MAX_SERVICES_PER_USER = 10;

    uint256 private _revenueShareRate; // for developer

    struct Service {
        uint256 serviceId;
        address owner; // revenue to this address
        uint256 createdTime;
        uint256 userCount;
        uint256 maxUserLimit;
        uint256 fee; // user should pay this amount for using this service
        uint256 revenue;
    }

    // private members
    mapping(address => Service[]) private _servicesData; // creator => services
    HatcherDeveloperBadge private _hatcherDeveloperBadge;
    HatcherServicePassport private _hatcherServicePassport;
    uint256 private _totalSupply;

    // EVENTS
    event Mint(uint256 indexed serviceId, address indexed owner, uint256 maxUserLimit, uint256 fee);
    event TransferFrom(uint256 indexed serviceId, address indexed from, address indexed to);
    event SetServiceProps(uint256 indexed serviceId, address indexed owner, uint256 maxUserLimit, uint256 fee);
    event Withdraw(address indexed to, uint256 amount);
    event SetRevenueShare(uint256 indexed revenueShareRate);

    constructor(
        address hatcherDeveloperBadge,
        uint256 revenueShareRate
    ) ERC721("Hatcher Service Certificate", "HSC") {
        _hatcherDeveloperBadge = HatcherDeveloperBadge(hatcherDeveloperBadge);
        _revenueShareRate = revenueShareRate;
    }

    /**
     * @notice call this first to set service password contract address
     * @param hatcherServicePassport contract address
     */
    function init(address hatcherServicePassport) external onlyOwner {
        _hatcherServicePassport = HatcherServicePassport(
            hatcherServicePassport
        );
    }

    /**
     * @notice only badge nft owner could call this method
     * @dev service provider create a new service
     * @param maxUserLimit  maximum number of users using this service set by the service provider
     * @param fee the amount of payment for the service set by the service provider
     * @return service  the new service info
     */
    function mint(
        uint256 maxUserLimit,
        uint256 fee
    ) public payable returns (Service memory service) {
        require(
            _hatcherDeveloperBadge.balanceOf(msg.sender) > 0,
            "You need an Hatcher Developer Badge to mint this NFT"
        );
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        uint256 servicesPerUser = balanceOf(_msgSender());
        require(
            servicesPerUser < MAX_SERVICES_PER_USER,
            "Exceeded maximum number of tokens per user"
        );

        uint256 serviceId = _totalSupply;
        _totalSupply = _totalSupply.add(1);
        _safeMint(msg.sender, serviceId);
        service = _addService(msg.sender, serviceId, maxUserLimit, fee);

        emit Mint(serviceId, _msgSender(), maxUserLimit, fee);
    }

    /** public functions */
    function getServiceUserCount(
        uint256 serviceId
    ) public view returns (uint256) {
        return _hatcherServicePassport.getServiceUsersCount(serviceId);
    }

    function getOwnerServices(
        address owner
    ) public view returns (Service[] memory) {
        Service[] memory s = _servicesData[owner];
        for (uint i = 0; i < s.length; i++) {
            s[i].userCount = getServiceUserCount(s[i].serviceId);
        }
        return s;
    }

    // function getSubscribedServices(address user) public view returns(Service[] memory) {

    // }

    function getServiceInfo(
        uint256 serviceId
    ) public view returns (Service memory ret) {
        require(_exists(serviceId), "Token does not exist");
        Service[] memory s = _servicesData[ownerOf(serviceId)];
        for (uint i = 0; i < s.length; i++) {
            if (s[i].serviceId == serviceId) ret = s[i];
        }
        ret.userCount = getServiceUserCount(serviceId);
    }

    function getServiceCount(address owner) public view returns (uint256) {
        return _servicesData[owner].length;
    }

    function getServiceRevenue(
        uint256 serviceId
    ) public view returns (uint256) {
        return getServiceInfo(serviceId).revenue;
    }

    /** ************* badge owner call **********/
    function transferFrom(
        address from,
        address to,
        uint256 serviceId
    ) public override {
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        Service memory temp;
        for (uint i = 0; i < s.length; i++) {
            if (s[i].serviceId == serviceId) {
                temp = s[i];
                delete s[i];
            }
        }
        _servicesData[from] = s;

        // transfer revenue
        uint256 revenue = getServiceRevenue(serviceId);
        uint256 revenueShare = (revenue * _revenueShareRate) / 100;
        payable(owner()).transfer(revenueShare);
        payable(ownerOf(serviceId)).transfer(revenue - revenueShare);

        // update to service
        super.transferFrom(from, to, serviceId);
        Service memory ns = Service({
            serviceId: serviceId,
            owner: to,
            createdTime: temp.createdTime,
            maxUserLimit: temp.maxUserLimit,
            userCount: 0,
            fee: temp.fee,
            revenue: 0
        });
        _servicesData[to].push(ns);

        emit TransferFrom(serviceId, from, to);
    }

    function setServiceProps(
        uint256 serviceId,
        uint256 maxUserLimit,
        uint256 fee
    ) public {
        require(_exists(serviceId), "serviceId does not exist");
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        for (uint i = 0; i < s.length; i++) {
            if (s[i].serviceId == serviceId && s[i].owner == msg.sender) {
                s[i].maxUserLimit = maxUserLimit;
                s[i].fee = fee;
                _servicesData[msg.sender] = s;
            }
        }
        emit SetServiceProps(serviceId, msg.sender, maxUserLimit, fee);
    }

    /** *** only passport contract call it ***/
    function addServiceRevenue(
        uint256 serviceId,
        uint256 amount
    ) external payable {
        require(
            address(_hatcherServicePassport) == msg.sender,
            "only service passport can call it."
        );
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        for (uint i = 0; i < s.length; i++) {
            if (s[i].serviceId == serviceId)
                s[i].revenue = s[i].revenue.add(amount);
        }
        _servicesData[ownerOf(serviceId)] = s;
    }

    /************* owner call *************** */
    function setRevenueShare(uint256 revenueShareRate) public onlyOwner {
        require(revenueShareRate <= 100, "Invalid revenue share rate");
        _revenueShareRate = revenueShareRate;

        emit SetRevenueShare(revenueShareRate);
    }

    // withdraw native token function.
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0x0), " _to cannot be zero address");
        require(_amount < (MINT_PRICE * _totalSupply), " _amount cannot be larger than total mint amount");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "withdraw failed");

        emit Withdraw(_to, _amount);
    }

    /** internal functions */
    function _addService(
        address _creator,
        uint256 _serviceId,
        uint256 _maxUserLimit,
        uint256 _fee
    ) internal returns (Service memory) {
        Service[] storage s = _servicesData[_creator];
        Service memory s1 = Service({
            serviceId: _serviceId,
            owner: _creator,
            createdTime: block.timestamp,
            userCount: 0,
            maxUserLimit: _maxUserLimit,
            fee: _fee,
            revenue: 0
        });
        s.push(s1);
        _servicesData[_creator] = s;
        return s1;
    }

    function exists(uint256 serviceId) public view returns (bool) {
        return _exists(serviceId);
    }
}
