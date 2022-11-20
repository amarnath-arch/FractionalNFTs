const { ethers } = require("hardhat");

const main = async()=>{
    const [deployer] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("CryptoPunkz");
    const token = await Token.deploy();

    await token.deployed();

    console.log(`ERC721 Token deployed to ${token.address}`);

    const FractionalNFT  = await ethers.getContractFactory("FractionalNFT");
    const fractionalNFT = await FractionalNFT.deploy('FNFT','1000000000',5);
    await fractionalNFT.deployed();

    console.log(`Fractional NFT Contract Deployed to ${fractionalNFT.address}`);

    const balance = await fractionalNFT.balanceOf(deployer.address);
    console.log(balance.toString());
}


main()
    .then(()=> {process.exit(0)})
    .catch(error=>{
        console.error(error);
        process.exit(1);
    })