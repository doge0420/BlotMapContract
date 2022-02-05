// SPDX-License-Identifier: MIT

/// @author Doge0420 and inspired by HashlipsLowerGasFee contract - MIT licence

// Do not use this contract even i don't know if it's safe lol

pragma solidity >=0.8.0 < 0.9.0;

// cool stuff
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title The BlotMap contract
contract BlotMap is Ownable, ERC721{

    using Strings for uint256;
    using Counters for Counters.Counter;

    // counter of the nfts
    Counters.Counter private supply;

    // contract status tings
    bool public statusPause = true;
    bool public statusWhitelist = true;
    bool public statusReveal = false;

    // metadata stuff
    string public hiddenURI;
    string public uriPrefix;
    string public uriSuffix = ".json";

    // !! must change before deploying !! or you can do it after lol
    uint256 public cost = 1000000000000000000 wei;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmmount = 10;
    
    // me and my friend
    address public contractOwner1 = 0x1f7D475723543Ba5715D7AD33F5FD2304e006847;
    address public contractOwner2 = 0x125f2788fa587DF002150f0E773Bb108eA276059;

    /// @dev whitelist and blacklist
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    // !! don't forget to change !! hehe
    constructor() ERC721("BlotMapCabinet", "BMC") {
        setHiddenURI("ipfs://QmPpWsJh4XVUATTuXNpyqjrJDpBtJijyQ9ohNifzScMUFJ/1.json");
        whitelistAddAddress(0x1f7D475723543Ba5715D7AD33F5FD2304e006847);
        whitelistAddAddress(0x125f2788fa587DF002150f0E773Bb108eA276059);
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

    /// @dev MODIFIER requires the msg.sender to be in the whitelist
    modifier whitelisted(address _sender) {
        if(statusWhitelist == true) {require(whitelist[_sender], "You are not whitelisted.");
        _;
        }
        else {
        _;
        }
    }

    /// @dev MODIFIER requires the msg.sender to not be blacklisted
    modifier blacklisted(address _sender) {
        require(!blacklist[_sender], "You are blacklisted.");
        _;
    }

    /// @dev mints (x) nfts to msg.sender
    /// @notice A function to mint nfts. Current cost is `cost` ether
    /// @param _ammount The number of ntfs you want to mint
    function mint(uint256 _ammount) public payable mintable(_ammount) isPaused whitelisted(msg.sender) blacklisted(msg.sender) {
        require(msg.value >= cost * _ammount, "Not enough fund");
        _mintAll(msg.sender, _ammount);
    }

    /// @notice Function to get the current minted ammount of nfts
    /// @return total minted supply
    function getTotalSupply() public view returns(uint256) {
        return supply.current();
    }

    /// @notice ONLY OWNER chnages max mint ammount per address
    function changeMaxMintAmmount(uint256 _maxMintAmmount) public onlyOwner {
        maxMintAmmount = _maxMintAmmount;
    }

    /// @notice ONLY OWNER changes the max supply ammount
    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    /// @notice ONLY OWNER changes the price (!! IN WEI !!) to mint an nft
    function changePriceInWei(uint256 _price) public onlyOwner {
        cost = _price;
    }

    /// @notice ONLY OWNER add address to the blacklist
    function blacklistAddAddress(address _address) public onlyOwner {
        require(!blacklist[_address], "This address has already been blacklisted.");
        blacklist[_address] = true;
    }

    /// @notice ONLY OWNER remove addresse from the blacklist
    function blacklistRemoveAddress(address _address) public onlyOwner {
        require(blacklist[_address], "This address is already out of the blacklist.");
        blacklist[_address] = false;
    }

    /// @notice ONLY OWNER add addresse to the whitelist
    function whitelistAddAddress(address _address) public onlyOwner {
        require(!whitelist[_address], "This address has already been whitelisted.");
        whitelist[_address] = true;
    }

    /// @notice ONLY OWNER remove addresse from the whitelist
    function whitelisteRemoveAddress(address _address) public onlyOwner {
        require(whitelist[_address], "This address is already out of the whitelist.");
        whitelist[_address] = false;
    }

    /// @notice ONLY OWNER toggles whitelistmode on or off
    function whitelistToggle() public onlyOwner {
        statusWhitelist = !statusWhitelist;
    }

    /// @notice ONLY OWNER pauses the contract
    function pause() public onlyOwner {
        statusPause = !statusPause;
    }

    /// @notice ONLY OWNER sets the real uri of all nfts
    function setRealURI(string memory _realURI) public onlyOwner {
        require(keccak256(abi.encodePacked(_realURI)) != keccak256(abi.encodePacked("")) , "invalid uriPrefix");
        uriPrefix = _realURI;
    }

    /// @notice ONLY OWNER sets the uri in hidden state of the nfts
    function setHiddenURI(string memory _hiddenURI) public onlyOwner {
        require(keccak256(abi.encodePacked(_hiddenURI)) != keccak256(abi.encodePacked("")) , "invalid hiddenUri");
       hiddenURI = _hiddenURI;
    }

    /// @notice ONLY OWNER reveals or hide the nft collection
    function revealOrHide() public onlyOwner {
        require(keccak256(abi.encodePacked(uriPrefix)) != keccak256(abi.encodePacked("")) , "uriPrefix is not set");
        statusReveal = !statusReveal;
    }

    /// @notice ONLY OWNER mints nfts to an address
    function mintToAddress(address _to, uint256 _ammount) public mintable(_ammount) onlyOwner {
        _mintAll(_to, _ammount);
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
    function withdraw() public onlyOwner {
        (bool transaction1, ) = payable(contractOwner1).call{value: ((address(this).balance) * 50 / 100)}("");
        (bool transaction2, ) = payable(contractOwner2).call{value: (address(this).balance)}("");
        require(transaction1 && transaction2);
    }
}