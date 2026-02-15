// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title EdenoreX Founders NFT
 * @notice ERC721 NFT collection for EdenoreX platform founders
 * @dev Secure implementation with comprehensive validation and documentation
 */
abstract contract ERC721 {
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*//////////////////////////////////////////////////////////////
                          METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name;
    string public symbol;
    
    /*//////////////////////////////////////////////////////////////
                          ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Initializes the NFT collection with name and symbol
     * @param _name The name of the NFT collection
     * @param _symbol The symbol of the NFT collection
     */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    /*//////////////////////////////////////////////////////////////
                          ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Returns the owner of a specific token
     * @dev Reverts if token doesn't exist
     * @param tokenId The ID of the token to query
     * @return owner The address of the token owner
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address owner) {
        require((owner = _ownerOf[tokenId]) != address(0), "ERC721: token does not exist");
    }
    
    /**
     * @notice Returns the balance of tokens owned by an address
     * @param owner The address to query
     * @return The number of tokens owned
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for zero address");
        return _balanceOf[owner];
    }
    
    /**
     * @notice Approves an address to transfer a specific token
     * @dev The caller must own the token or be an approved operator
     * @param spender The address to approve
     * @param tokenId The token ID to approve
     */
    function approve(address spender, uint256 tokenId) public virtual {
        address owner = _ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "ERC721: not authorized");
        
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }
    
    /**
     * @notice Sets approval for an operator to manage all tokens
     * @param operator The address to set approval for
     * @param approved Whether the operator is approved
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @notice Transfers a token from one address to another
     * @dev Caller must be owner or approved
     * @param from The current owner of the token
     * @param to The address to transfer to
     * @param tokenId The token ID to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(from == _ownerOf[tokenId], "ERC721: from is not owner");
        require(
            msg.sender == from || 
            isApprovedForAll[from][msg.sender] || 
            msg.sender == getApproved[tokenId],
            "ERC721: not authorized"
        );
        require(to != address(0), "ERC721: transfer to zero address");
        
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        
        _ownerOf[tokenId] = to;
        delete getApproved[tokenId];
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @notice Safe transfer with data
     * @param from The current owner
     * @param to The recipient address
     * @param tokenId The token ID
     * @param data Additional data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        
        require(
            to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
            ERC721TokenReceiver.onERC721Received.selector,
            "ERC721: unsafe recipient"
        );
    }
    
    /**
     * @notice Safe transfer without data
     * @param from The current owner
     * @param to The recipient address
     * @param tokenId The token ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /*//////////////////////////////////////////////////////////////
                          ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Checks if contract supports an interface
     * @param interfaceId The interface identifier
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f;   // ERC721Metadata
    }
    
    /*//////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Internal function to mint a new token
     * @param to The address to mint to
     * @param tokenId The token ID to mint
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to zero address");
        require(_ownerOf[tokenId] == address(0), "ERC721: token already minted");
        
        unchecked {
            _balanceOf[to]++;
        }
        
        _ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    
    /**
     * @dev Internal function to burn a token
     * @param tokenId The token ID to burn
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "ERC721: token does not exist");
        
        unchecked {
            _balanceOf[owner]--;
        }
        
        delete _ownerOf[tokenId];
        delete getApproved[tokenId];
        
        emit Transfer(owner, address(0), tokenId);
    }
    
    /*//////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Safe mint with receiver check
     * @param to The address to mint to
     * @param tokenId The token ID to mint
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
        
        require(
            to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, "") ==
            ERC721TokenReceiver.onERC721Received.selector,
            "ERC721: unsafe recipient"
        );
    }
    
    /**
     * @dev Safe mint with data and receiver check
     * @param to The address to mint to
     * @param tokenId The token ID to mint
     * @param data Additional data
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        
        require(
            to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, data) ==
            ERC721TokenReceiver.onERC721Received.selector,
            "ERC721: unsafe recipient"
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                        METADATA LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Returns the token URI for a given token
     * @dev Must be implemented by derived contracts
     * @param tokenId The token ID to query
     * @return The token URI string
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);
}

/**
 * @title ERC721 Token Receiver Interface
 * @notice Interface for contracts that want to support safe transfers
 */
abstract contract ERC721TokenReceiver {
    /**
     * @notice Handle the receipt of an NFT
     * @param operator The address which called `safeTransferFrom`
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier
     * @param data Additional data
     * @return The function selector to confirm receipt
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/**
 * @title EdenoreX Founders NFT
 * @notice Limited edition NFT collection for EdenoreX platform founders
 * @dev Implements ERC721 with owner-controlled minting and comprehensive security measures
 * 
 * Security Features:
 * - Zero address validation in all mint functions
 * - Proper token existence checks
 * - Event emission for all state changes
 * - Input validation on all admin functions
 * - Reentrancy protection on critical functions
 * - Gas-optimized batch minting
 * 
 * @custom:security-contact security@edenorex.io
 */
contract EdenoreXFoundersNFT is ERC721 {
    
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    
    /// @notice The current owner of the contract
    address public owner;
    
    /// @notice Base URI for token metadata
    string private _baseTokenURI;
    
    /// @notice Counter for token IDs
    uint256 private _nextTokenId;
    
    /// @notice Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 10000;
    
    /// @notice Maximum tokens per batch mint to prevent gas issues
    uint256 public constant MAX_BATCH_MINT = 100;
    
    /// @notice Reentrancy guard
    uint256 private _locked = 1;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Emitted when ownership is transferred
     * @param previousOwner The previous owner address
     * @param newOwner The new owner address
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @notice Emitted when base URI is updated
     * @param newBaseURI The new base URI
     */
    event BaseURIUpdated(string newBaseURI);
    
    /**
     * @notice Emitted when tokens are minted
     * @param to The recipient address
     * @param tokenId The minted token ID
     */
    event TokenMinted(address indexed to, uint256 indexed tokenId);
    
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Restricts function access to contract owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "EdenoreXNFT: not owner");
        _;
    }
    
    /**
     * @dev Prevents reentrancy attacks
     */
    modifier nonReentrant() {
        require(_locked == 1, "EdenoreXNFT: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initializes the EdenoreX Founders NFT collection
     * @dev Sets the deployer as initial owner and initializes base contract
     */
    constructor() ERC721("EdenoreX Founders NFT", "EDENFT") {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /*//////////////////////////////////////////////////////////////
                          OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Transfers ownership of the contract
     * @dev Emits OwnershipTransferred event
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "EdenoreXNFT: new owner is zero address");
        
        address oldOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @notice Renounces ownership of the contract
     * @dev Sets owner to zero address, making the contract ownerless
     */
    function renounceOwnership() external onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        
        emit OwnershipTransferred(oldOwner, address(0));
    }
    
    /*//////////////////////////////////////////////////////////////
                          MINTING LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Mints a single NFT to a specified address
     * @dev Only callable by owner. Validates recipient and supply limit
     * @param to The address to mint to
     */
    function mint(address to) external onlyOwner nonReentrant {
        require(to != address(0), "EdenoreXNFT: mint to zero address");
        require(_nextTokenId < MAX_SUPPLY, "EdenoreXNFT: max supply reached");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _mint(to, tokenId);
        emit TokenMinted(to, tokenId);
    }
    
    /**
     * @notice Mints multiple NFTs to a specified address in a batch
     * @dev Gas-optimized batch minting with safety limits
     * @param to The address to mint to
     * @param amount The number of tokens to mint
     */
    function mintAll(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "EdenoreXNFT: mint to zero address");
        require(amount > 0, "EdenoreXNFT: amount must be positive");
        require(amount <= MAX_BATCH_MINT, "EdenoreXNFT: exceeds batch limit");
        require(_nextTokenId + amount <= MAX_SUPPLY, "EdenoreXNFT: exceeds max supply");
        
        uint256 startId = _nextTokenId;
        uint256 endId = startId + amount;
        
        // Gas-optimized loop
        for (uint256 i = startId; i < endId;) {
            _mint(to, i);
            emit TokenMinted(to, i);
            
            unchecked {
                ++i;
            }
        }
        
        _nextTokenId = endId;
    }
    
    /*//////////////////////////////////////////////////////////////
                          METADATA LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Sets the base URI for token metadata
     * @dev Only callable by owner. Validates input is not empty
     * @param newBaseURI The new base URI string
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(bytes(newBaseURI).length > 0, "EdenoreXNFT: empty base URI");
        
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }
    
    /**
     * @notice Returns the base URI for token metadata
     * @return The base URI string
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @notice Returns the complete URI for a specific token
     * @dev Validates token existence before returning URI
     * @param tokenId The token ID to query
     * @return The complete token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Validate token exists
        require(_ownerOf[tokenId] != address(0), "EdenoreXNFT: token does not exist");
        
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        
        // Efficient string concatenation using bytes
        return string(abi.encodePacked(base, _toString(tokenId), ".json"));
    }
    
    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Returns the total number of tokens minted
     * @return The current token supply
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }
    
    /**
     * @notice Checks if a token exists
     * @param tokenId The token ID to check
     * @return True if token exists, false otherwise
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }
    
    /*//////////////////////////////////////////////////////////////
                       INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Converts a uint256 to its string representation
     * @param value The number to convert
     * @return The string representation
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}
