// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title ERC20 Token
 * @dev Implementation of the ERC20 Token Standard
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20 Token Implementation
 * @dev Implementation of the ERC20 Token Standard
 */
contract ERC20Token is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    bool private _mintable;
    bool private _burnable;
    
    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "ERC20: caller is not the owner");
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol}, {decimals}, and {initialSupply}.
     *
     * All of these values are immutable: they can only be set once during construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialOwner_,
        bool mintable_,
        bool burnable_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mintable = mintable_;
        _burnable = burnable_;
        _owner = initialOwner_;

        // Mint initial supply to the token creator
        _mint(initialOwner_, initialSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used for the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns if the token is mintable.
     */
    function mintable() public view returns (bool) {
        return _mintable;
    }

    /**
     * @dev Returns if the token is burnable.
     */
    function burnable() public view returns (bool) {
        return _burnable;
    }

    /**
     * @dev Returns the owner of the token.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "ERC20: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(_mintable, "ERC20: token is not mintable");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(uint256 amount) public {
        require(_burnable, "ERC20: token is not burnable");
        _burn(msg.sender, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        emit Mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner_, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner_, spender, currentAllowance - amount);
            }
        }
    }
}

/**
 * @title TokenFactory
 * @dev Factory contract to create new ERC20 tokens with different configurations
 */
contract TokenFactory {
    address public feeRecipient;
    uint256 public fee;

    mapping(address => address[]) private _creatorTokens;

    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol
    );

    /**
     * @dev Constructor sets the fee recipient and fee amount
     * @param _feeRecipient Address that will receive the fees
     * @param _fee Fee amount in wei
     */
    constructor(address _feeRecipient, uint256 _fee) {
        feeRecipient = _feeRecipient;
        fee = _fee;
    }

    /**
     * @dev Creates a new ERC20 token with the specified parameters
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _decimals Token decimals
     * @param _initialSupply Initial token supply
     * @param _mintable Whether the token can be minted
     * @param _burnable Whether the token can be burned
     * @return Address of the newly created token
     */
    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        bool _mintable,
        bool _burnable
    ) external payable returns (address) {
        require(msg.value >= fee, "TokenFactory: Insufficient fee");

        // Transfer fee to recipient
        (bool success, ) = feeRecipient.call{value: fee}("");
        require(success, "TokenFactory: Fee transfer failed");

        // Refund excess fee if any
        if (msg.value > fee) {
            (success, ) = msg.sender.call{value: msg.value - fee}("");
            require(success, "TokenFactory: Refund failed");
        }

        // Deploy new token
        ERC20Token newToken = new ERC20Token(
            _name,
            _symbol,
            _decimals,
            _initialSupply,
            msg.sender,
            _mintable,
            _burnable
        );

        // Store token address for the creator
        _creatorTokens[msg.sender].push(address(newToken));

        emit TokenCreated(address(newToken), msg.sender, _name, _symbol);

        return address(newToken);
    }

    /**
     * @dev Returns all tokens created by an address
     * @param _creator Address of the creator
     * @return Array of token addresses
     */
    function getTokensByCreator(address _creator) external view returns (address[] memory) {
        return _creatorTokens[_creator];
    }

    /**
     * @dev Updates the fee recipient address
     * @param _feeRecipient New fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external {
        require(msg.sender == feeRecipient, "TokenFactory: Not authorized");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Updates the fee amount
     * @param _fee New fee amount
     */
    function setFee(uint256 _fee) external {
        require(msg.sender == feeRecipient, "TokenFactory: Not authorized");
        fee = _fee;
    }
}