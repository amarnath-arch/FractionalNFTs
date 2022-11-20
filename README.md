--- Use (npx hardhat compile to compile the contracts)


// how to deploy the contracts

use ( npx hardhat run --network ${your network name} scripts/deploy.js)
add your own env file or use your own private key and RPC_URL in the hardhat config.js file.

// how to test the contracts

use (npx hardhat test)

// Flow of the contract is written in the Fractional NFT Contract.



// For the Integration of the contract with the marketplace

--------       Import the FractionalNFT Token using its Address in the metamask (For more Information refer to metamask doc)
                You can now transfer Fractional NFTs to your friends.