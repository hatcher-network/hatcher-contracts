pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HatcherServicePassport is ERC721, Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 serviceId;
        uint256 userId;
        uint256 createdTime;
        uint256 expiredTime;
    }

    HatcherServiceCertificate private _certificateContract;
    mapping(uint256 => UserInfo[]) private _serviceUsers;
    mapping(address => uint256[]) private _users; // user => services
    mapping(uint256 => uint256) private _revenue; // serviceId => revenue
    uint256 private _totalSupply;

    constructor(
        address certificateContract
    ) ERC721("Hatcher Service Passport", "HSP") {
        _certificateContract = HatcherServiceCertificate(certificateContract);
    }

    function mint(uint256 serviceId) public payable {
        require(_certificateContract._exists(serviceId), "Token id does not exist");
        HatcherServiceCertificate.Service memory s = _certificateContract.getServiceInfo(serviceId);

        require(!checkUserSubscription(serviceId, msg.sender), "User already has an active subscription");

        require(
            _serviceUsers[serviceId].length < s.maxUserLimit,
            "exceeded max user limit"
        );
        require(msg.value >= s.fee, "Insufficient payment");

        _safeMint(msg.sender, _totalSupply);

        uint256 createdTime = block.timestamp;
        uint256 expiredTime = block.timestamp + s.expiredTime;

        _updateRevenue(serviceId, s.fee);

        _serviceUsers[serviceId].push(UserInfo({
            serviceId: serviceId,
            userId: _totalSupply,
            createdTime: createdTime,
            expiredTime: expiredTime
        }));
        _users[msg.sender].push(serviceId);
        _totalSupply++;
    }

    function renew(uint256 serviceId, address user) public payable {
        require(_certificateContract._exists(serviceId), "Token id does not exist");
        HatcherServiceCertificate.Service memory s = _certificateContract.getServiceInfo(serviceId);
        require(checkUserSubscription(serviceId, msg.sender), "User does not has an active subscription, mint frist!");
        require(msg.value >= s.fee, "Insufficient payment");

        UserInfo[] storage users = _serviceUsers[serviceId];

        _updateRevenue(serviceId, s.fee);

        uint256 createdTime = block.timestamp;
        uint256 expiredTime = block.timestamp + s.expiredTime;
        for(uint i = 0; i < users.length; i++)
        {
            if(ownerOf(users[i].userId == user)) {
                users[i].createdTime = createdTime;
                users[i].expiredTime = expiredTime;
                _serviceUsers[serviceId] = users;
            }
        }
    }   

    function _updateRevenue(uint256 serviceId, uint256 amount) internal payable {
        require(msg.value > amount, "Insufficient payment");
        _certificateContract.call{value: msg.value}(
            "addServiceRevenue(uint256,uint256)",
            user.userId,
            amount
        );

    }

    /** ********** public call **************** */
    function checkUserSubscription(uint256 serviceId, address user) public view returns (bool) {
        uint256[] memory s = _users[user];
        for(uint i = 0; i < s.length; i++)
        {
            if(s[i] == serviceId) return true;
        }
        return false;
    }

    function getUserInfo(uint256 serviceId, address user) public view returns (UserInfo memory) {
        UserInfo[] memory users = _serviceUsers[serviceId];
        for(uint i = 0; i < users.length; i++)
        {
            if(ownerOf(users[i].userId == user)) return users[i];
        }
    }

    function getUserServicesCount(uint256 serviceId) public view returns (uint256) {
        return _serviceUsers[serviceId].length;
    }

    function getUserServices(address user) public view returns (uint256[] memory) {
        return _users[user];
    }

    function getUserServicesCount(address user) public view returns (uint256) {
        return _users[user].length;
    }

}
