pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIServiceCertificate is ERC721, Ownable {
    uint256 public constant REVENUE_SHARE_RATE = 20; // 20% revenue share uint256 public constant TOTAL_SUPPLY = 1000; AlDeveloperBadge private _alDeveloperBadge;
    struct Service {
        uint256 serviceId;
        address owner;
        uint256 createdTime;
        uint256 revenue;
    }

    Service[] private _services;

    constructor(
        address hatcherDeveloperBadge
    ) ERC721("Hatcher Service Certificate", "AISC") {
        _hatcherDeveloperBadge = HatcherDeveloperBadge(hatcherDeveloperBadge);
    }

    function mint() public {
        require(
            _hatcherDeveloperBadge.balanceOf(msg.sender) > 0,
            "You need an Hatcher Developer Badge to mint this NFT"
        );
        require(
            totalSupply() < TOTAL_SUPPLY,
            "Total supply of NFTs already minted"
        );
        _safeMint(msg.sender, totalSupply() + 1);
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
