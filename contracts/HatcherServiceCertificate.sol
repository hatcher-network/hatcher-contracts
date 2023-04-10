pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {HatcherDeveloperBadge} from "./HatcherDevelopBadge.sol";
import {HatcherServicePassport} from "./HatcherServicePasspord.sol";

contract HatcherServiceCertificate is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_SERVICES_PER_USER = 10;

    uint256 private _revenueShareRate;

    struct Service {
        uint256 serviceId;
        address owner;
        uint256 createdTime;
        uint256 maxUserLimit;
        uint256 fee; // use native token now
        uint256 expiredTime;
        uint256 revenue;
    }

    // private members
    mapping(address => Service[]) private _servicesData; // creator => services
    HatcherDeveloperBadge private _hatcherDeveloperBadge;
    HatcherServicePasspord private _hatcherServicePasspord;
    uint256 private _totalSupply;

    constructor(
        address hatcherDeveloperBadge,
        uint256 revenueShareRate
    ) ERC721("Hatcher Service Certificate", "HSC") {
        _hatcherDeveloperBadge = HatcherDeveloperBadge(hatcherDeveloperBadge);
        _revenueShareRate = revenueShareRate;
    }

    // call this first to set service password contract address
    function init(address hatcherServicePasspord) external onlyOwner {
        _hatcherServicePasspord = HatcherServicePasspord(hatcherServicePasspord);
    }

    function mint(uint256 maxUserLimit, uint256 fee, uint256 expiredTime) public payable {
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
        _safeMint(msg.sender, _totalSupply);
        _addService(msg.sender, _totalSupply, maxUserLimit, fee, expiredTime)
        _totalSupply = _totalSupply.add(1);
        
    }

    /** public functions */
    function addServiceRevenue(uint256 serviceId, uint256 amount) external payable {
        require(address(_hatcherServicePasspord) == msg.sender, "only service passpord can call it.");
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i].serviceId == serviceId) s[i].revenue = s[i].revenue.add(amount);
        }
        _servicesData[from] = s;

    }
    
    function getOwnerServices(address owner) public view returns (Service[] memory) {
        return _servicesData[creator];
    }

    function getServiceInfo(
        uint256 serviceId
    ) public view returns (Service memory) {
        require(_exists(serviceId), "Token does not exist");
        Service[] memory s = _servicesData[ownerOf(serviceId)];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i].serviceId == serviceId) return s[i];
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 serviceId
    ) public virtual override {
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i].serviceId == serviceId) delete s[i];
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
            createdTime: block.timestamp(),
            maxUserLimit: type(uint256).max,
            fee: 0,
            expiredTime: type(uint256).max,
            revenue: 0
        });
        _servicesData[to].push(ns);

    }

    function getServiceCount(address owner) public view returns(uint256){
        return  _servicesData[owner].length;
    }

    function getServiceRevenue(uint256 serviceId) public view returns (uint256) {
        return getServiceInfo(serviceId).revenue;
    }

    function setServiceParams(uint256 serviceId, uint256 maxUserLimit, uint256 fee, uint256 expiredTime
    ) public {
        require(_exists(serviceId), "serviceId does not exist");
        Service[] storage s = _servicesData[ownerOf(serviceId)];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i].serviceId == serviceId && s[i].owner == msg.sender) {
                s[i].maxUserLimit = maxUserLimit;
                s[i].fee = fee;
                s[i].expiredTime = expiredTime;
                _servicesData[msg.sender] = s;
            }
        }
    }

    /************* owner call *************** */
    function setRevenueShare(uint256 revenueShareRate) public onlyOwner {
        require(revenueShareRate <= 100, "Invalid revenue share rate");
        _revenueShareRate = revenueShareRate;
    }
    // withdraw native token function.
    function withdraw(address payable _to, uint256 _amount)
        external
        onlyOwner
    {
        require(_to != address(0x0), " _to cannot be zero address");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "withdraw failed");
    }

    /** internal functions */
    function _addService(address _creator, uint256 _serviceId, uint256 _maxUserLimit, uint256 _fee, uint256 _expiredTime) internal {
        Service[] storage s = _servicesData[creator];
        s.push(Service({
            serviceId: _serviceId,
            owner: _creator, 
            createdTime: block.timestamp(), 
            maxUserLimit: _maxUserLimit,
            fee: _fee,
            expiredTime: _expiredTime,
            revenue: 0}));
        _servicesData[creator] = s;
    }
}
