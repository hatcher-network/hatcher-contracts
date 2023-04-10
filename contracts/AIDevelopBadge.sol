pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIDeveloperBadge is ERC721, Ownable {
    uint256 public constant MAX_TOKENS = 100;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_TOKENS_PER_USER = 10;
    uint256 public constant RENEWAL_PRICE = 0.05 ether;
    mapping(address => uint256) private _tokenCounts;
    mapping(address => uint256) private _expiryDates;

    constructor() ERC721("Hatcher Developer Badge", "AIDEV") {}

    function mint() public payable {
        require(totalSupply() < MAX_TOKENS, "Maximum number of tokens minted");
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        uint256 tokensPerUser = balanceOf(_msgSender());
        require(
            tokensPerUser < getMaxTokensPerUser(_msgSender()),
            "Exceeded maximum number of tokens per user"
        );

        _safeMint(_msgSender(), totalSupply() + 1);

        _tokenCounts[_msgSender()]++;
        if (_expiryDates[_msgSender()] < block.timestamp) {
            _expiryDates[_msgSender()] = block.timestamp + 30 days;
        }
    }

    function renew() public payable {
        require(msg.value >= RENEWAL_PRICE, "Insufficient payment");

        _tokenCounts[_msgSender()] = 0;
        _expiryDates[_msgSender()] = block.timestamp + 30 days;
    }

    function getMaxTokensPerUser(address user) public view returns (uint256) {
        if (_expiryDates[user] < block.timestamp) {
            return MAX_TOKENS_PER_USER;
        }

        uint256 remainingTokens = MAX_TOKENS_PER_USER - _tokenCounts[user];
        return remainingTokens > 0 ? remainingTokens : 0;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
