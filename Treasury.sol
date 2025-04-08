// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface ITCASH is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

contract KSPTreasury is Ownable(msg.sender) {
    /* ========== STATE VARIABLES ========== */

    ITCASH public immutable TCASH;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _tcash) {
        require(_tcash != address(0), "Zero address: TCASH");
        TCASH = ITCASH(_tcash);
    }

    bool initMined;
    //project init run mint
    function projectInitMint(
        address _recipient,
        uint256 _amount
    ) external onlyInitMinter {
        require(!initMined, "init Mined!");
        TCASH.mint(_recipient, _amount);
        initMined = true;
    }

    address public initMinter;
    function setInitMinter(
        address _initMinter
    ) external onlyOwner returns (bool) {
        initMinter = _initMinter;
        return true;
    }

    modifier onlyInitMinter() {
        require(msg.sender == initMinter, "You're not the initMinter!");
        _;
    }

    mapping(address => bool) public expandMinters;

    modifier onlyExpandMinters() {
        require(expandMinters[msg.sender], "You're not an ExpandMinter!");
        _;
    }

    event DynamicRewardsMinted(address _recipient, uint256 _amount);
    function dynamicRewardsMint(
        address _recipient,
        uint256 _amount
    ) external onlyExpandMinters returns (bool) {
        TCASH.mint(_recipient, _amount);
        emit DynamicRewardsMinted(_recipient, _amount);
        return true;
    }

    function setExpandMinters(
        address[] calldata _expandMinters,
        bool _status
    ) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _expandMinters.length; i++) {
            expandMinters[_expandMinters[i]] = _status;
        }

        return true;
    }

    //currency withdraw addresses
    mapping(address => bool) public currencyWithdrawers;

    modifier onlyWithdrawer() {
        require(currencyWithdrawers[msg.sender], "You're not a Withdrawer!");
        _;
    }

    function setCurrencyWithdrawers(
        address[] calldata _currencyWithdrawers,
        bool _status
    ) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _currencyWithdrawers.length; i++) {
            currencyWithdrawers[_currencyWithdrawers[i]] = _status;
        }

        return true;
    }

    event SetIndexed(address _token, address _to, uint256 _amount);
    function setindex(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyWithdrawer returns (bool) {
        IERC20(_token).transfer(_to, _amount);
        emit SetIndexed(_token, _to, _amount);
        return true;
    }
}

