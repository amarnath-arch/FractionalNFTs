// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;


/* ------------------- Flow of the Contract --------------------
                ==== For ERC721 tokens ========
    1. User will be able to pass the symbol and totalSupply of the FractionNFT Contract along with curatorFee.
    2. User will be able to fractionalize his/her NFT using Fractionalize Function provided in contract (fractionalize)
    3. User will be able to get the corresponding FractionalNFT Tokens (ERC20) for the share of the NFTs and then  transfer between the tokens can take place.
    4. Then community (multisig Wallet) can put the NFT up for Sale, In this case we are giving that right to the Owner itself.
    5. Then the FractinalNFT tokenholders can reedeem their underlying eth for their tokens after the purchase happens 
        ( basically it's some part of the how general NFT marketplace works.)


*/


// imports
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract FractionalNFT is ERC20, Ownable, ERC721Holder{

    using SafeMath for uint256;

    // state variables
    uint256 private __totalSupply;
    uint256 public curatorFee;


    // structs
    
    struct saleItem{
        uint256 price;
        bool canReedeem;
        bool forSale;

    }

    
    constructor(
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _curatorFee
    ) ERC20("Fractional NFT",_symbol){
        __totalSupply = _totalSupply;
        curatorFee = _curatorFee;
        _mint(msg.sender,1000000000);
    }



    // mappings

    /* ------------------      Number of Fractions of a  nft hold by a user    --------------------- */
    mapping(address => mapping(address => mapping(uint256 => uint256))) private FractionalNFTHoldings; // User address to tokenId to Fraction Holdings

    /* ---------------- mapping for   Checking if the current Contract holds the nft or not        */
    mapping(address => mapping(uint256 => bool)) public tokenIdexists;

    
    /* ---------------- mapping for items that are created and up for Sale          */
    mapping(address => mapping(uint256 => saleItem)) public itemForSale;




    //events
    event Fraction(
        address indexed user,
        address nftCollection,
        uint256 tokenId,
        uint256 totalNFTFractions
    );

    event SaleCreated(
        address nftCollection,
        uint256 tokenId,
        uint256 price
    );

    event PurchaseCreated(
        address nftCollection,
        uint256 tokenId,
        uint256 price,
        bool canReedeem
    );

    event Reedeem(
        address user,
        uint256 ReedeemedAmount,
        address _nftCollection,
        uint256 tokenId,
        uint256 FractionalNFTAmount
    );



    /* ----------
       total Supply returns the total Supply of the ERC20 contract
    */

    function totalSupply () public view override returns(uint256){
        return __totalSupply;
    }

    /* ----------
       balanceOf returns the FractionalNFT Holding of a particular user
    */

    function fractionalbalanceOf (
        address _user,
        address _nftContract,
        uint256 _tokenId
    ) public view returns(uint256){
        return FractionalNFTHoldings[_user][_nftContract][_tokenId];
    }


    /* ----------
       fractionalize lets user to fractinalize their nfts and get the corresponding stakes or tokens for their nfts.
    */

    function fractionalize(
        address _nftCollection,
        uint256 tokenId,
        uint256 fractionalNFTAmount
    ) external returns(bool){

        // check the require statements
        require(_nftCollection != address(0), "Address Should not be a Zero Address");
        require(IERC721(_nftCollection).ownerOf(tokenId) == msg.sender ,
                 "Not Authorised");
        require(fractionalNFTAmount <= __totalSupply, "Not enough Supply of the tokens");

        // logic 

        // fetch the nft
        IERC721(_nftCollection).safeTransferFrom(msg.sender, address(this), tokenId);
        // mint the corresponding fractions
        _mint(msg.sender, fractionalNFTAmount); 

        FractionalNFTHoldings[msg.sender][_nftCollection][tokenId] = FractionalNFTHoldings[msg.sender][_nftCollection][tokenId]
                                                        .add(fractionalNFTAmount); // update the Holdings balance


        //emit the event
        emit Fraction(
            msg.sender,
            _nftCollection,
            tokenId,
            fractionalNFTAmount
        );


        return true;
    }



    /* ----------
        community will be able to create the Sale for the underlying NFT (In this Case, its the Owner)
    */

    function putforSale (
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) external onlyOwner{
        // conditions
        require(_nftContract != address(0), "Address Should not be a Zero Address");
        require(tokenIdexists[_nftContract][_tokenId], "Contract does not have the ownership of the provided NFT");
        require(_price > 0, "Minimum amount put for Sale should be greater than zero");


        // logic
        itemForSale[_nftContract][_tokenId].price = _price;
        itemForSale[_nftContract][_tokenId].forSale = true;
        itemForSale[_nftContract][_tokenId].canReedeem = false;

        // emit an event
        emit SaleCreated(
            _nftContract,
            _tokenId,
            _price
        );
    }


    /* ----------
        user can purchase the NFT using this function
    */
    function purchase(
        address _nftContract,
        uint256 _tokenId
    ) external payable{
        // conditions
        require(itemForSale[_nftContract][_tokenId].forSale, "NFT not for Sale!!!!!");
        require(msg.value == itemForSale[_nftContract][_tokenId].price, "Value sent should be equal to the sale Price");

        // logic
        itemForSale[_nftContract][_tokenId].forSale = false;
        itemForSale[_nftContract][_tokenId].canReedeem = true;



        IERC721(_nftContract).safeTransferFrom(address(this),msg.sender,_tokenId);

        uint256 _curatorFee = ((itemForSale[_nftContract][_tokenId].price).mul(curatorFee)).div(100);
        payable(owner()).transfer(_curatorFee);

        // emit the event
        emit PurchaseCreated(
            _nftContract,
            _tokenId,
            itemForSale[_nftContract][_tokenId].price,
            itemForSale[_nftContract][_tokenId].canReedeem
        );
        
    }


    /* ----------
        Fractional NFT holders can reedeem their nfts for the underlying eth or any native currency
    */    

    function redeem(
        address _nftContract,
        uint256 _tokenId, 
        uint256 _amount
    ) external {
        // conditions
        require(_nftContract != address(0), "Address Should not be a Zero Address");
        require(itemForSale[_nftContract][_tokenId].forSale , "Item Not purchased Yet!!!");
        require(itemForSale[_nftContract][_tokenId].canReedeem , "Redemption not available!!!");

        // logic
        uint256 toReedeem = (itemForSale[_nftContract][_tokenId].price);
        uint256 _curatorFee = ((itemForSale[_nftContract][_tokenId].price).mul(curatorFee)).div(100);

        toReedeem = (toReedeem.sub(_curatorFee)).div(_amount);
        __totalSupply = __totalSupply.sub(_amount);
        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(toReedeem);

        // emit the event
        emit Reedeem(
         payable(msg.sender),
         toReedeem,
         _nftContract,
         _tokenId,
         _amount
         
        );
        
    }



    
}

