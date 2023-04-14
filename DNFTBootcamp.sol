// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.2/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Una vez el contrato se despliega tenemos que
// ejecutar la funcion safeMint con tu address
contract DNFTBootcamp is AutomationCompatibleInterface, ERC721, ERC721URIStorage  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint interval;
    uint lastTimeStamp;

    enum Status{
        First,  // 0
        Second, // 1
        Third   // 2
    }

    mapping (uint256 => Status) nftStatus;

    //Estos valores sonn estaticos pero el NFT ira apuntando
    // a cualquier de estos valores a medida que va evolucionando
    string[] IpfsUri = [
        "https://ipfs.io/ipfs/QmNgAqH1jc333gMWofPXBembVH38jKPxJrUoR7DaL27Wai/state_0.json",
        "https://ipfs.io/ipfs/QmNgAqH1jc333gMWofPXBembVH38jKPxJrUoR7DaL27Wai/state_1.json",
        "https://ipfs.io/ipfs/QmNgAqH1jc333gMWofPXBembVH38jKPxJrUoR7DaL27Wai/state_2.json"
    ];

    constructor(uint _interval) ERC721("dNFTBootcamp", "DBTC") {
        interval = _interval;
        lastTimeStamp = block.timestamp;
    }

    // Automation - BEGIN
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;        
    }

    function performUpkeep(bytes calldata /* performData */) external override  {        
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;    
            updateAllNFTs();            
        }        
    }
    // Automation - END

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);      
        nftStatus[tokenId] = Status.First;  
    }

    function updateAllNFTs() public {
        uint counter = _tokenIdCounter.current();
        for(uint i = 0; i < counter; i++){
            updateStatus(i);
        }
    }

    function updateStatus(uint256 _tokenId) public {
        uint256 currentStatus = getNFTLevel(_tokenId);

        if(currentStatus == 0){
             nftStatus[_tokenId] = Status.Second; 
        }
        else if(currentStatus == 1){
             nftStatus[_tokenId] = Status.Third; 
        }
        else if(currentStatus == 2){
            nftStatus[_tokenId] = Status.First;
        }
    }

    // helper functions
    function getNFTStatus(uint256 _tokenId) public view returns(Status){
        Status status = nftStatus[_tokenId];
        return status;
    }

    function getNFTLevel(uint256 _tokenId) public view returns(uint256){
        Status statusIndex = nftStatus[_tokenId];
        return uint(statusIndex);
    }

    function getUriByLevel(uint256 _tokenId) public view returns(string memory){
        Status statusIndex = nftStatus[_tokenId];
        return IpfsUri[uint(statusIndex)];
    }

    // The following functions are overrides required by Solidity.
    //
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return getUriByLevel(tokenId);
    }
}