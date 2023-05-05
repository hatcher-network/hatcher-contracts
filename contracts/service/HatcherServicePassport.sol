// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {HatcherServiceCertificate} from "./HatcherServiceCertificate.sol";

/**
 * @title hatcher service passport
 * @author Hatcher Network
 */
contract HatcherServicePassport is ERC721, Ownable, Initializable {
    using SafeMath for uint256;

    struct Passport {
        uint256 passportId; // passport to access service
        uint256 serviceId; // service id which is certificated in `HatcherServiceCertificate` contract
        uint256 createTime;
        uint256 expireTime;
    }

    HatcherServiceCertificate private _certificateContract; // service info
    mapping(uint256 => Passport) public passports;
    string private name_;
    string private symbol_;
    uint256 public totalSupply;

    // user => passport IDs
    mapping(address => uint256[]) public userPassports;
    mapping(uint256 => uint256[]) public servicePassports; // service => passport IDs

    // EVENTS
    event NewSubscription(
        address indexed user,
        uint256 indexed serviceId,
        uint256 indexed passportId,
        uint256 createTime,
        uint256 expireTime
    );
    event RenewSubscription(
        address indexed user, 
        uint256 indexed passId, 
        uint256 serviceId, 
        uint256 expireTime
    );

    constructor() ERC721("", "") {}

    function initialize(
        address certificateContract
    ) public initializer {
        _certificateContract = HatcherServiceCertificate(certificateContract);
        name_ = "Hatcher Service Passport";
        symbol_ = "HSP";
    }

    function name() public view override returns (string memory) {
        return name_;
    }

    function symbol() public view override returns (string memory) {
        return symbol_;
    }

    function _baseURI() internal override pure returns (string memory) {
        return "gnfd://hatcher/";
    }

    /**
     * @notice only supports native token as payment, erc20 is going to be supported asap
     * @dev user subscriptes a service
     * @param serviceId service id
     * @param period in month
     */
    function subscribe(uint256 serviceId, uint256 period) public payable {
        require(
            _certificateContract.exists(serviceId),
            "NOT EXIST"
        );
        require(
            !subscribed(msg.sender, serviceId),
            "SUBSCRIBED"
        );
        HatcherServiceCertificate.Service memory s = _certificateContract
            .getServiceInfo(serviceId);

        require(
            servicePassports[serviceId].length < s.maxUserLimit,
            "LIMIT REACHED"
        );
        require(msg.value >= s.price * period, "VALUE TOO SMALL"); // pay for the service

        _safeMint(msg.sender, totalSupply);
        totalSupply = totalSupply.add(1);

        uint256 createTime = block.timestamp;
        uint256 expireTime = block.timestamp + 30 * 3600 * 24 * period;

        _updateRevenue(serviceId, msg.value); // update revenue for service

        passports[totalSupply - 1] = Passport({
            serviceId: serviceId,
            passportId: totalSupply - 1,
            createTime: createTime,
            expireTime: expireTime
        });
        userPassports[msg.sender].push(totalSupply - 1);
        servicePassports[serviceId].push(totalSupply - 1);

        emit NewSubscription(msg.sender, serviceId, totalSupply - 1, createTime, expireTime);
    }

    /**
     * @dev renew subscription
     * @param passId passport ID
     */
    function renew(uint256 passId, uint256 period) public payable {
        require(
            passId < totalSupply,
            "NO SUBSCRIPTION FOUND"
        );
        require(ownerOf(passId) == msg.sender, "UNAUTHORIZED");

        Passport storage pass = passports[passId];
        HatcherServiceCertificate.Service memory s = _certificateContract
            .getServiceInfo(pass.serviceId);

        require(msg.value >= s.price * period, "VALUE TOO SMALL");
        _updateRevenue(pass.serviceId, msg.value);

        pass.expireTime += 30 * 3600 * 24 * period;

        emit RenewSubscription(msg.sender, passId, pass.serviceId, pass.expireTime);
    }

    // TODO: override transfer & transferFrom, update userPassport
    // function transfer() public {

    // }

    // function transferFrom() public {

    // }

    // function _updateUserPassports() public {

    // }

    function _updateRevenue(uint256 serviceId, uint256 amount) internal {
        require(msg.value >= amount, "VALUE TOO SMALL");
        (bool success, ) = address(_certificateContract).call{value: msg.value}(
            abi.encodeWithSignature(
                "addServiceRevenue(uint256,uint256)",
                serviceId,
                amount
            )
        );
        require(success, "UPDATE REVENUE FAILED");
    }

    /** ********** public call **************** */
    /**
     * @dev check if user already subscribed in service
     */
    function subscribed(
        address user,
        uint256 serviceId
    ) public view returns (bool) {
        uint256[] memory s = userPassports[user];
        for (uint i = 0; i < s.length; i++) {
            if (passports[s[i]].serviceId == serviceId) return true;
        }
        return false;
    }

    function subscriptionValid(uint256 passId) public view returns (bool) {
        return block.timestamp <= passports[passId].expireTime;
    }

    function getServiceUserCount(
        uint256 serviceId
    ) public view returns (uint256) {
        return servicePassports[serviceId].length;
    }
}
