// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title hatcher badge for service provider
 * @author Rocklabs
 * @notice who with hatcher badge could create service
 */
contract HatcherDeveloperBadge is ERC721, Ownable {
    using SafeMath for uint256;

    string private _URI = "";
    //total supply
    uint256 private _totalSupply;

    constructor() ERC721("Hatcher Developer Badge", "HDB") {}

    function mint() public {
        require(balanceOf(_msgSender()) == 0, "Hatcher Developer Badge has already minted");
        _safeMint(_msgSender(), _totalSupply);
        _totalSupply = _totalSupply.add(1);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /** internal function */

    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }

    function _setBaseURI(string memory baseURI) internal {
        _URI = baseURI;
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
}
