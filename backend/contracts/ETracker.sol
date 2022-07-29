//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title Expense Tracker
/// @author Yanuka Deneth
/// @notice A Contract to track expenses for individual accounts/address. Can be used for Smart Contracts and EOA
contract ETracker is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /// @notice Account to hold all values of a user
    /// @dev Contains a name, amount of Categories, the categories itself, The Category to the Amount of Entries, and the entry itself (positive or negative number)
    struct Account {
        bytes32 name;
        uint256 amountOfCategories;
        mapping(uint256 => bytes32) categories;
        mapping(uint256 => uint256) catToAmountofEntries;
        mapping(uint256 => mapping(uint256 => int256)) entries; //CatID, EntryID, Amount
    }

    /// @notice Contains all Transaction object, which contains a name, all categories and total values
    struct AllTransactions {
        bytes32 name;
        bytes32[] categories;
        int256[] amounts;
    }

    /// @notice Contains all the mapping from address to Account
    /// @dev One address can have only one account
    mapping(address => Account) private _accounts;

    /// @notice Assumes the user has an account
    modifier alreadySigned() {
        require(
            _accounts[msg.sender].name != bytes32(0),
            "Account does not exist!"
        );
        _;
    }

    /// @notice Create an account if it does not exist
    function createAccount(bytes32 _name) external whenNotPaused {
        require(
            _accounts[msg.sender].name == bytes32(0),
            "Account already exists"
        );
        _accounts[msg.sender].name = _name;
    }

    // =============================================================
    //                           GETTERS
    // =============================================================

    /// @notice How many Categories does the caller account have
    function getAmountOfCategories()
        external
        view
        alreadySigned
        whenNotPaused
        returns (uint256)
    {
        return _accounts[msg.sender].amountOfCategories;
    }

    /// @dev Returns a byte32 array of all the categories the user has
    function getAllCategories()
        public
        view
        whenNotPaused
        alreadySigned
        returns (bytes32[] memory)
    {
        Account storage _ac = _accounts[msg.sender];
        uint256 amount = _ac.amountOfCategories;
        bytes32[] memory _categories = new bytes32[](amount);
        for (uint256 i; i < amount; i++) {
            _categories[i] = _ac.categories[i];
        }

        return _categories;
    }

    /// @notice Get the Category Name from ID
    function getCategoryName(uint256 _id)
        external
        view
        alreadySigned
        whenNotPaused
        returns (bytes32)
    {
        return _accounts[msg.sender].categories[_id];
    }

    /// @notice Gets the Category ID from the name
    function getCategoryID(bytes32 _name)
        external
        view
        alreadySigned
        whenNotPaused
        returns (uint256 id)
    {
        for (uint256 i; i < _accounts[msg.sender].amountOfCategories; i++) {
            if (_accounts[msg.sender].categories[i] == _name) {
                return i;
            }
        }
    }

    /// @notice Gets the Amount of Entries of the sent Category
    function getAmountOfEntriesPerCat(uint256 _catId)
        external
        view
        whenNotPaused
        alreadySigned
        returns (uint256 amount)
    {
        return _accounts[msg.sender].catToAmountofEntries[_catId];
    }

    /// @notice Returns the name of the Account
    function getName()
        external
        view
        whenNotPaused
        alreadySigned
        returns (bytes32)
    {
        return _accounts[msg.sender].name;
    }

    /// @notice Gets all Transactions and returns a Transaction Object
    function getAllTransactions()
        external
        view
        alreadySigned
        whenNotPaused
        returns (AllTransactions memory)
    {
        // Create Trans Object
        AllTransactions memory alltrans;
        Account storage _ac = _accounts[msg.sender];
        alltrans.name = _ac.name; // Name
        uint256 _catAmount = _ac.amountOfCategories;
        bytes32[] memory _categories = new bytes32[](_catAmount);
        int256[] memory _trans = new int256[](_catAmount);

        // Looping over the amount of categories
        for (uint256 i; i < _catAmount; i++) {
            _categories[i] = _ac.categories[i]; // Pass that category name of that index
            uint256 _entAmount = _ac.catToAmountofEntries[i]; // Get the amount of Entries of the category at index
            int256 tot = 0; // Create a new variable that will add/sub
            // Looping over the number of entries per that category
            for (uint256 j; j < _entAmount; j++) {
                tot += _ac.entries[i][j]; // Add/Sub the number to the total
            }
            _trans[i] = tot; // Return the total into the amount array of that category's index
        }

        alltrans.categories = _categories; // Categories
        alltrans.amounts = _trans; // Amounts

        return alltrans;
    }

    /// @notice Gets the entry at that Category and Entry ID
    function getEntry(uint256 _catId, uint256 _entryId)
        external
        view
        whenNotPaused
        alreadySigned
        returns (int256)
    {
        return _accounts[msg.sender].entries[_catId][_entryId];
    }

    /// @notice Main Initialize function
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
    }

    /// @notice Pause the Contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resume the pause contract
    function resume() external onlyOwner {
        _unpause();
    }

    //TODO : use `modifier whenNotPaused()` and `modifier whenPaused()` in the project

    ///@notice Authorize Upgrade Version
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
