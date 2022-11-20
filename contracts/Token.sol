// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;


// imports 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract CryptoPunkz is ERC721, Ownable{

    constructor() ERC721("CryptoPunkz","CPz" ){

    }

    function safeMint(
        address _to,
        uint256 _tokenId
    ) public onlyOwner{
        _safeMint(_to, _tokenId);
    }
    
}
