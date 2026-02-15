// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title OREX Token (ORX)
 * @notice Fixed-supply ERC20 token with controlled DEX launch
 * @dev Audit-optimized, CEX-friendly, no mint, no rescue, no blacklist
 */
contract OREX {

    /*//////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    string public constant name = "OREX";
    string public constant symbol = "ORX";
    uint8  public constant decimals = 18;

    uint256 private immutable _totalSupply;

    /*//////////////////////////////////////////////////////////////
                                OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "OREX: not owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /*//////////////////////////////////////////////////////////////
                        TRADING CONTROL (CRITICAL)
    //////////////////////////////////////////////////////////////*/

    bool public tradingEnabled = false;
    bool public tradingFrozen = false; // irreversible

    mapping(address => bool) public isDexPair;
    mapping(address => bool) public isExcludedFromTrading;

    event TradingEnabled();
    event TradingFrozen();
    event DexPairUpdated(address indexed pair, bool status);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address initialHolder) {
        require(initialHolder != address(0), "OREX: zero holder");

        owner = msg.sender;

        uint256 supply = 50_000_000 * 10 ** decimals;
        _totalSupply = supply;

        _balances[initialHolder] = supply;

        // Exclusions for setup
        isExcludedFromTrading[initialHolder] = true;
        isExcludedFromTrading[address(this)] = true;

        emit Transfer(address(0), initialHolder, supply);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                           ERC20 STANDARD
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view returns (uint256) {
        return _allowances[holder][spender];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "OREX: allowance exceeded");

        unchecked {
            _allowances[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "OREX: from zero");
        require(to != address(0), "OREX: to zero");

        uint256 balance = _balances[from];
        require(balance >= amount, "OREX: insufficient balance");

        // Trading gate (core protection)
        if (!tradingEnabled) {
            require(
                isExcludedFromTrading[from] || isExcludedFromTrading[to],
                "OREX: trading not enabled"
            );
        }

        unchecked {
            _balances[from] = balance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 amount) internal {
        require(holder != address(0), "OREX: approve from zero");
        require(spender != address(0), "OREX: approve to zero");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN — SAFE & LIMITED
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable trading after LP is added and locked
     * @dev Can be called only once
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "OREX: already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    /**
     * @notice Freeze trading state forever (optional, for CEX trust)
     */
    function freezeTrading() external onlyOwner {
        require(tradingEnabled, "OREX: trading not enabled");
        tradingFrozen = true;
        emit TradingFrozen();
    }

    /**
     * @notice Register PancakeSwap pair
     */
    function setDexPair(address pair, bool status) external onlyOwner {
        require(pair != address(0), "OREX: zero pair");
        isDexPair[pair] = status;
        isExcludedFromTrading[pair] = true; // LP-safe
        emit DexPairUpdated(pair, status);
    }

    /**
     * @notice Transfer ownership (multisig / renounce later)
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "OREX: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /*//////////////////////////////////////////////////////////////
                                BURN
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Permanently burn ORX tokens
     * @dev Fixed-supply model; totalSupply unchanged
     */
    function burn(uint256 amount) external {
        require(amount > 0, "OREX: burn zero");

        uint256 balance = _balances[msg.sender];
        require(balance >= amount, "OREX: insufficient");

        unchecked {
            _balances[msg.sender] = balance - amount;
            _balances[address(0)] += amount;
        }

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}
