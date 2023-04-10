pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIServicePassport is ERC721, Ownable {
    uint256 public constant MAX_USERS = 1000;
    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 private _mintedCount;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant MAX_SERVICES_PER_USER = 10;

    address private _certificateContract;
    uint256 private _revenueShareRate;

    struct UserInfo {
        uint256 userId;
        uint256 createdTime;
        uint256 expiredTime;
        uint256 revenue;
        uint256 servicesCount;
    }

    mapping(address => UserInfo) private _users;

    constructor(
        address certificateContract,
        uint256 revenueShareRate
    ) ERC721("AI Service Passport", "AISP") {
        _certificateContract = certificateContract;
        _revenueShareRate = revenueShareRate;
    }

    function mint() public payable {
        require(
            _mintedCount < TOTAL_SUPPLY,
            "Total supply of NFTs already minted"
        );
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        UserInfo storage user = _users[msg.sender];
        bool userExists = user.createdTime > 0;

        if (userExists) {
            require(
                block.timestamp > user.expiredTime,
                "User already has an active subscription"
            );
        } else {
            require(
                totalSupply() < MAX_USERS,
                "Maximum number of users already minted"
            );
        }

        _safeMint(msg.sender, _mintedCount + 1);

        uint256 createdTime = block.timestamp;
        uint256 expiredTime = block.timestamp + 30 days;
        _users[msg.sender] = UserInfo({
            userId: _mintedCount + 1,
            createdTime: createdTime,
            expiredTime: expiredTime,
            revenue: 0,
            servicesCount: 0
        });

        if (userExists) {
            delete user.servicesCount;
        }
        _mintedCount++;
    }

    function addService() public payable {
        require(_exists(_msgSender()), "User does not exist");
        require(
            totalServices(_msgSender()) < MAX_SERVICES_PER_USER,
            "Maximum number of services per user already added"
        );
        require(msg.value > 0, "Insufficient payment");

        UserInfo storage user = _users[_msgSender()];
        uint256 revenueShare = (msg.value * _revenueShareRate) / 100;
        payable(owner()).transfer(revenueShare);
        _certificateContract.call{value: msg.value - revenueShare}(
            "addServiceRevenue(uint256,uint256)",
            user.userId,
            msg.value - revenueShare
        );
        user.revenue += msg.value;
        user.servicesCount++;
    }

    function getUserInfo(address user) public view returns (UserInfo memory) {
        require(_exists(user), "User does not exist");
        return _users[user];
    }

    function totalServices(address user) public view returns (uint256) {
        return _users[user].servicesCount;
    }

    function setRevenueShare(uint256 revenueShareRate) public onlyOwner {
        require(revenueShareRate <= 100, "Invalid revenue share rate");
        _revenueShareRate = revenueShareRate;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
