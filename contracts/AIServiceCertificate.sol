pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

from "./AIDeveloperBadge.sol" import AIDeveloperBadge

contract AIServiceCertificate is ERC721, Ownable {
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_SERVICES_PER_USER = 10;

    uint256 public constant REVENUE_SHARE_RATE = 20; // 20% revenue share Developer 
    struct Service {
        uint256 serviceId;
        address owner;
        uint256 createdTime;
        uint256 revenue;
    }

    // private members
    mapping(address => Service[]) private _servicesData;
    AIDeveloperBadge private _aiDeveloperBadge;
    uint256 private _tokenSupply;

    constructor(
        address hatcherDeveloperBadge
    ) ERC721("Hatcher Service Certificate", "AISC") {
        _hatcherDeveloperBadge = HatcherDeveloperBadge(hatcherDeveloperBadge);
    }

    function mint(uint256 revenue) public {
        require(
            _hatcherDeveloperBadge.balanceOf(msg.sender) > 0,
            "You need an Hatcher Developer Badge to mint this NFT"
        );
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        uint256 tokensPerUser = balanceOf(_msgSender());
        require(
            tokensPerUser < MAX_TOKENS_PER_USER,
            "Exceeded maximum number of tokens per user"
        );
        _safeMint(msg.sender, _tokenSupply + 1); // start from 1


        
    }

    function _createService(address creator, serviceId, uint256 revenue) internal {{
        Service[] storage s = _servicesData[]
    }

    function getServiceInfo(
        uint256 tokenId
    ) public view returns (Service memory) {
        require(_exists(tokenId), "Token does not exist");
        return
            Service({
                serviceId: tokenId,
                owner: ownerOf(tokenId),
                createdTime: tokenTimestamp(tokenId),
                revenue: tokenRevenue(tokenId)
            });
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        uint256 revenue = getServiceRevenue(tokenId);
        uint256 revenueShare = (revenue * REVENUE_SHARE_RATE) / 100;
        payable(owner()).transfer(revenueShare);
        payable(ownerOf(tokenId)).transfer(revenue - revenueShare);
    }

    function tokenTimestamp(uint256 tokenId) public view returns (uint256) {
        return _services[tokenId - 1].createdTime;
    }

    function tokenRevenue(uint256 tokenId) public view returns (uint256) {
        return _services[tokenId - 1].revenue;
    }

    function getServiceRevenue(uint256 tokenId) public view returns (uint256) {
        return
            _services[tokenId - 1].revenue -
            ((_services[tokenId - 1].revenue * REVENUE_SHARE_RATE) / 100);
    }

    function addServiceRevenue(
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _services[tokenId - 1].revenue += amount;
    }
}
