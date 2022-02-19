// SPDX-License-Identifier: MIT

/// @author Doge0420 
// inspired by HashlipsLowerGasFee contract - MIT licence

// !!! I, for now, do not recommend you to use my contract !!!

pragma solidity >=0.8.0 < 0.9.0;

// cool stuff
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title The BlotMap contract
contract BlotMap is Ownable, ERC721{

    using Strings for uint256;
    using Counters for Counters.Counter;

    // counter of the nfts
    Counters.Counter private supply;
    
    // me and my friend
    address public contractOwner1 = 0x1f7D475723543Ba5715D7AD33F5FD2304e006847;
    address public contractOwner2 = 0x125f2788fa587DF002150f0E773Bb108eA276059;

    // It is better to change those values before deploying the contract but you can change them after
    uint32 public maxSupply = 1000;
    uint32 public maxMintAmmount = 10;
    uint128 public cost = 1000000000000000000 wei;
    bytes32 public root = 0x64c833bf8606dd3bfd7247cb68c286309781faf9962601355e5f13e6034de7b6;
    
    // contract status tings
    bool public statusPause = true;
    bool public statusWhitelist = true;
    bool public statusReveal = false;

    // metadata stuff
    string public hiddenURI;
    string public uriPrefix;
    string public uriSuffix = ".json";

    // !! don't forget to change !!
    constructor() ERC721("BlotMap", "BMC") {
        setHiddenURI("ipfs://___CID___");
    }

    /// @dev MODIFIER requires the contract to be not paused
    modifier isPaused() {
        require(!statusPause, "Contract has been paused");
        _;
    }

    /// @dev MODIFIER limits, filters mint ammount and checks if max supply has been hit
    modifier mintable(uint256 _ammount) {
        require(supply.current() + _ammount <= maxSupply, "Max supply has been hit");
        require(_ammount <= maxMintAmmount, "Cannot mint more than 'maxMintAmmount'");
        require(_ammount > 0, "Invalid mint ammount");
        _;
    }

    /// @dev MODIFIER requires the whitelist to be set to false
    modifier whitelistOff() {
        require(!statusWhitelist, "Whitelist is activated. If you are whitelisted please go to the 'mintWhitelisted' function.");
        _;
    }

    /// @dev MODIFIER requires the whitelist to be set to true
    modifier whitelistOn() {
        require(statusWhitelist, "Whitelist is not acvtivated. If you want to mint your nfts please go to the mint function.");
        _;
    }

    /// @dev mints (x) nfts to msg.sender
    /// @notice A function to mint nfts. Current cost is `cost` ether
    /// @param _ammount The number of ntfs you want to mint
    function mint(uint256 _ammount) public payable mintable(_ammount) isPaused whitelistOff {
        require(msg.value == cost * _ammount, "Not enough fund");
        _mintAll(msg.sender, _ammount);
    }

    /// @dev mint function for whitelisted addresses
    /// @notice A function to mint nfts only if you are whitelisted
    /// @param _ammount The number of ntfs you want to mint
    /// @param _proof Array 
    function mintWhitelisted(uint128 _ammount, bytes32[] memory _proof) public payable mintable(_ammount) isPaused whitelistOn {
        require(proof(_proof, msg.sender), "You are not whitelisted.");
        require(msg.value == cost * _ammount, "Not enough fund");
        _mintAll(msg.sender, _ammount);
    }

    /// @notice Function to get the current minted ammount of nfts
    /// @return total minted supply
    function getMintedSupply() public view returns(uint256) {
        return supply.current();
    }

    /// @notice ONLY OWNER chnages max mint ammount per address
    function changeMaxMintAmmount(uint32 _maxMintAmmount) public onlyOwner isPaused {
        maxMintAmmount = _maxMintAmmount;
    }

    /// @notice ONLY OWNER changes the max supply ammount
    function changeMaxSupply(uint32 _maxSupply) public onlyOwner isPaused {
        maxSupply = _maxSupply;
    }

    /// @notice ONLY OWNER changes the root hash of the merkle tree !! do not forget to add "0x" before the hash !!
    function changeRoot(bytes32 _root) public onlyOwner isPaused {
        root = _root;
    }

    /// @notice ONLY OWNER changes the price (!! IN WEI !!) to mint an nft
    function changePriceInWei(uint128 _cost) public onlyOwner isPaused {
        cost = _cost;
    }

    /// @notice ONLY OWNER toggles whitelistmode on or off
    function whitelistToggle() public onlyOwner isPaused {
        statusWhitelist = !statusWhitelist;
    }

    /// @notice ONLY OWNER pauses the contract
    function pause() public onlyOwner {
        statusPause = !statusPause;
    }

    /// @notice ONLY OWNER sets the real uri of all nfts !! do not forget to add 'ipfs://__CID__/' (replace '__CID__' with your cid) !!
    function setRealURI(string memory _realURI) public onlyOwner isPaused {
        require(keccak256(abi.encodePacked(_realURI)) != keccak256(abi.encodePacked("")) , "invalid uriPrefix");
        uriPrefix = _realURI;
    }

    /// @notice ONLY OWNER sets the uri in hidden state of the nfts !! do not forget to add 'ipfs://__CID__' (replace '__CID__' with your cid) !!
    function setHiddenURI(string memory _hiddenURI) public onlyOwner {
        require(keccak256(abi.encodePacked(_hiddenURI)) != keccak256(abi.encodePacked("")) , "invalid hiddenUri");
       hiddenURI = _hiddenURI;
    }

    /// @notice ONLY OWNER reveals or hide the nft collection
    function revealOrHide() public onlyOwner isPaused {
        require(keccak256(abi.encodePacked(uriPrefix)) != keccak256(abi.encodePacked("")) , "uriPrefix is not set");
        statusReveal = !statusReveal;
    }

    /// @notice ONLY OWNER mints nfts to an address
    function mintToAddress(address _to, uint256 _ammount) public mintable(_ammount) onlyOwner {
        _mintAll(_to, _ammount);
    }

    /// @dev an internal function to verify whitelisted addresses using a merkle proof
    function proof(bytes32[] memory _proof, address _sender) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(_proof, root, leaf);
    }

    /// @notice an internal function to handle the ammount variable in the mint function and to actually mint the nfts
    function _mintAll(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
            }
    }

    /// @notice returns the token uri depending if the metadatas has been revealed or not
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (statusReveal == false) {
        return hiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    /// @notice internal function to set the base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /// @notice ONLY OWNER allows the owner to split the contract's balance and withdraw it
    function withdraw() public onlyOwner isPaused {
        (bool transaction1, ) = payable(contractOwner1).call{value: ((address(this).balance) * 50 / 100)}("");
        (bool transaction2, ) = payable(contractOwner2).call{value: (address(this).balance)}("");
        require(transaction1 && transaction2);
    }
}