pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIDeveloperBadge is ERC721, Ownable {
    uint256 public constant MINT_PRICE = 0.1 ether;

    //total supply
    string memory _base_uri = "";
    uint256 private _totalSupply;

    constructor() ERC721("AI Developer Badge", "AIDB") {}

    function mint() public payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        _safeMint(_msgSender(), _totalSupply + 1);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /** internal function */

    function _baseURI() internal view override returns (string memory) {
        return _base_uri;
    }

    function _setBaseURI(string memory baseURI) internal {
        _base_uri = baseURI;
    }

    /** prohibit transfering badge to avoid sharing just one badge to create ai service*/
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // do nothing
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // do nothing
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // do nothing
    }

    /************* owner call *************** */
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
