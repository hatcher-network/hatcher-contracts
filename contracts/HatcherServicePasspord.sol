pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title hatcher service for user
 * @author Rocklabs
 * @notice this contact is for users who could pay for the service
 */
contract HatcherServicePassport is ERC721, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // support erc20 token as patment in future 

    struct UserInfo {
        uint256 serviceId; // service id which is certificated in `HatcherServiceCertificate` contract
        uint256 passpordId; // user password minted from this contact that is able to use the service
        uint256 createdTime;
        uint256 expiredTime;
    }

    // private members
    HatcherServiceCertificate private _certificateContract; // service info
    mapping(uint256 => UserInfo[]) private _serviceUsers; // service => users[]
    mapping(address => uint256[]) private _userServices; // user => services

    uint256 private _totalSupply; // 

    // EVENTS
    event NewSubscription(address indexed user, uint256 indexed serviceId, uint256 indexed passpordId);
    event RenewSubscription(address indexed user, uint256 indexed serviceId);
    event CancelSubscription(address indexed user, uint256 indexed serviceId);

    constructor(
        address certificateContract
    ) ERC721("Hatcher Service Passport", "HSP") {
        _certificateContract = HatcherServiceCertificate(certificateContract);
    }

    /**
     * @notice only supports native token as payment, erc20 is going to be supported asap
     * @dev user subscriptes a service
     * @param serviceId 
     */
    function mint(uint256 serviceId) public payable {
        require(_certificateContract._exists(serviceId), "ServiceId does not exist");
        HatcherServiceCertificate.Service memory s = _certificateContract.getServiceInfo(serviceId);

        require(!checkUserSubscription(serviceId, msg.sender), "User already has an active subscription");

        require(
            _serviceUsers[serviceId].length < s.maxUserLimit,
            "exceeded max user subscription limit"
        );
        require(msg.value >= s.fee, "Insufficient payment"); // pay for the service

        _safeMint(msg.sender, _totalSupply);

        uint256 createdTime = block.timestamp;
        uint256 expiredTime = block.timestamp + s.expiredTime;

        _updateRevenue(serviceId, s.fee); // update revenue for senvice

        _serviceUsers[serviceId].push(UserInfo({
            serviceId: serviceId,
            passpordId: _totalSupply,
            createdTime: createdTime,
            expiredTime: expiredTime
        }));
        _userServices[msg.sender].push(serviceId);
        _totalSupply++;

        emit NewSubscription(msg.sender, serviceId, _totalSupply - 1);
    }

    /**
     * @dev renew the service if the service has been expired
     * @param serviceId 
     * @param user who wants to renew the service
     */
    function renew(uint256 serviceId, address user) public payable {
        require(_certificateContract._exists(serviceId), "ServiceId does not exist");
        HatcherServiceCertificate.Service memory s = _certificateContract.getServiceInfo(serviceId);
        require(checkUserSubscription(serviceId, msg.sender), "User does not has an active subscription, mint frist!");
        require(!checkValidSubscription(serviceId, msg.sender), "User has an active subscription, no need to renew");
    
        require(msg.value >= s.fee, "Insufficient payment");
        _updateRevenue(serviceId, s.fee);

        UserInfo[] storage users = _serviceUsers[serviceId];

        uint256 createdTime = block.timestamp;
        uint256 expiredTime = block.timestamp + s.expiredTime;
        for(uint i = 0; i < users.length; i++)
        {
            if(ownerOf(users[i].passpordId) == user) {
                users[i].createdTime = createdTime;
                users[i].expiredTime = expiredTime;
                _serviceUsers[serviceId] = users;
            }
        }

        emit RenewSubscription(msg.sender, serviceId);
    }

    /**
     * @dev cancel subscription
     * @param serviceId
     */
    function cancel(uint256 serviceId, address user) external {
        require(_certificateContract._exists(serviceId), "Token id does not exist");

        require(checkUserSubscription(serviceId, msg.sender), "User does not has an active subscription");
        require(checkValidSubscription(serviceId, msg.sender), "User has an disactive subscription, fail to cancel subscription");


        UserInfo[] storage users = _serviceUsers[serviceId];
        for(uint i = 0; i < users.length; i++)
        {
            UserInfo storage u = users[i];
            if(ownerOf(u.passpordId) == user) {
                delete users[i]
                _serviceUsers[serviceId] = users;
                break;
            }
        }

        // delete service from user's subscriptions
        uint256[] storage services = _userServices[msg.sender];
        for(uint i = 0; i < services.length; i++)
        {
            if(services[i] == serviceId) {
                delete services[i];
                _userServices[msg.sender] = services;
                break;
            }
        }

        emit CancelSubscription(msg.sender, serviceId);
    } 

    function _updateRevenue(uint256 serviceId, uint256 amount) internal payable {
        require(msg.value > amount, "Insufficient payment");
        _certificateContract.call{value: msg.value}(
            "addServiceRevenue(uint256,uint256)",
            user.passpordId,
            amount
        );

    }

    /** ********** public call **************** */
    /**
     * @dev check if user already subscribed in service
     */
    function checkUserSubscription(uint256 serviceId, address user) public view returns (bool) {
        uint256[] memory s = _userServices[user];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i] == serviceId) return true;
        }
        return false;
    }

    /**
     * @dev check if user's subscription is still valid.
     */
    function checkValidSubscription(uint256 serviceId address user) public view returns (bool) {
        uint256 now_ = block.timestamp;

        UserInfo[] memory users = _serviceUsers[serviceId];

        for(uint i = 0; i < users.length; i++)
        {
            if(ownerOf(users[i].passpordId) == user) {
                return (users[i].createdTime <= now_) && (now_ <= users[i].expiredTime);
            }
        }
        return false;
    }

    function getUserInfo(uint256 serviceId, address user) public view returns (UserInfo memory) {
        UserInfo[] memory users = _serviceUsers[serviceId];
        for(uint i = 0; i < users.length; i++)
        {
            if(ownerOf(users[i].passpordId == user)) return users[i];
        }
    }

    function getServiceUsersCount(uint256 serviceId) public view returns (uint256) {
        return _serviceUsers[serviceId].length;
    }

    function getUserServices(address user) public view returns (uint256[] memory) {
        return _userServices[user];
    }

    function getUserServicesCount(address user) public view returns (uint256) {
        return _userServices[user].length;
    }

}
