//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title Expense Tracker
/// @author Yanuka Deneth
/// @notice An Upgradable Contract to track expenses for individual accounts/address. Can be used for Smart Contracts and EOA
contract ETracker is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /// @notice Account to hold all values of a user
    /// @dev Contains a name, amount of Categories, the category name, The Category to the Amount of Entries, and an entry object with amount and timestamps
    struct Account {
        bytes32 name;
        uint256 amountOfCategories;
        mapping(uint256 => bytes32) categories; // ID => Category Name
        mapping(uint256 => uint256) catToAmountofEntries; // CatID => How many Entries
        mapping(uint256 => mapping(uint256 => Entry)) entries; // CatID => (EntryID => Entry[amount,created_At,updated_At])
    }

    /// @notice Entry Object to track amount and timestamps
    /// @dev Every entry (transaction), has a positive or negative amount and the time it was created.
    struct Entry {
        int256 amount;
        uint256 created_At;
        uint256 update_At;
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

    /// @notice Assumes the category Exists
    /// @param _catId Category ID
    modifier categoryExists(uint256 _catId) {
        require(
            _accounts[msg.sender].categories[_catId] != bytes32(0),
            "Category does not exist!"
        );
        _;
    }

    // =============================================================
    //                           CREATORS
    // =============================================================

    /// @notice Create an account if it does not exist and the name is not null
    /// @param _name Pass a 32 character name to be assigned to the account.
    function createAccount(bytes32 _name) external whenNotPaused {
        require(
            _accounts[msg.sender].name == bytes32(0),
            "Account already exists"
        );
        require(_name != bytes32(0), "Null Name!");
        _accounts[msg.sender].name = _name;
    }

    /// @notice Creates a Category by name and update the amount of Categories, if it does not exist already, name cannot be null.
    /// @param _name Pass a 32 character category name to be created
    function createCategory(bytes32 _name)
        external
        whenNotPaused
        alreadySigned
    {
        require(_name != bytes32(0), "Null Name!");
        uint256 _amountCat = _accounts[msg.sender].amountOfCategories;
        if (_amountCat > 0) {
            for (uint256 i; i < _amountCat; i++) {
                require(
                    _accounts[msg.sender].categories[i] != _name,
                    "Category already exists!"
                );
            }
        }
        uint256 newAmount = _amountCat + 1;
        _accounts[msg.sender].categories[newAmount] = _name;
        _accounts[msg.sender].amountOfCategories = newAmount;
    }

    /// @notice Create a Entry to a Category, if the category exists
    /// @param _catId Category ID
    /// @param _amount The amount of the transaction
    function createEntry(uint256 _catId, int256 _amount)
        external
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
    {
        uint256 _newEntryId = _accounts[msg.sender].catToAmountofEntries[
            _catId
        ] + 1;
        uint256 _nowTime = block.timestamp;
        _accounts[msg.sender].entries[_catId][_newEntryId].amount = _amount;
        _accounts[msg.sender]
        .entries[_catId][_newEntryId].created_At = _nowTime;
        _accounts[msg.sender].entries[_catId][_newEntryId].update_At = _nowTime;
    }

    // =============================================================
    //                           UPDATORS
    // =============================================================

    /// @notice Change the name of the Category, if the Category exists, and the name is not the same, name not null
    /// @param _catId Category ID
    /// @param _newName New Category 32 character name
    /// @dev use `getCategoryID()` to get the ID
    function updateCategoryName(uint256 _catId, bytes32 _newName)
        external
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
    {
        require(_newName != bytes32(0), "Null Name");
        require(
            _accounts[msg.sender].categories[_catId] != _newName,
            "You have passed the same name"
        );
        _accounts[msg.sender].categories[_catId] = _newName;
    }

    /// @notice Update the Entry if Category and entry exists
    /// @param _catId Category ID
    /// @param _entryId Entry ID
    /// @dev use `getAmountOfEntriesPerCat()` to get the Amount of Categories
    function updateEntry(
        uint256 _catId,
        uint256 _entryId,
        int256 _newAmount
    ) external alreadySigned whenNotPaused categoryExists(_catId) {
        require(
            _accounts[msg.sender].entries[_catId][_entryId].created_At !=
                uint256(0),
            "This entry is not created yet!"
        );
        Entry storage _entry = _accounts[msg.sender].entries[_catId][_entryId];
        _entry.amount = _newAmount;
        _entry.update_At = block.timestamp;
        assert(
            _accounts[msg.sender].entries[_catId][_entryId].amount == _newAmount
        );
    }

    /// @notice Change the name to the new name, if it's not the same name, and not null
    /// @param _newName New 32 character name
    function updateName(bytes32 _newName) external whenNotPaused alreadySigned {
        require(
            _accounts[msg.sender].name != _newName,
            "Setting name is the same!"
        );
        require(_newName != bytes32(0), "Null Name");
        _accounts[msg.sender].name = _newName;
    }

    // =============================================================
    //                           GETTERS
    // =============================================================

    /// @notice Get how many Categories does the caller account have
    /// @return A Big Number with the amount of categories
    function getAmountOfCategories()
        external
        view
        alreadySigned
        whenNotPaused
        returns (uint256)
    {
        return _accounts[msg.sender].amountOfCategories;
    }

    /// @notice Get all Categories the account has
    /// @return An array of 32 characters which contain the category names
    /// @return _amount The amount of categories
    function getAllCategories()
        external
        view
        whenNotPaused
        alreadySigned
        returns (bytes32[] memory, uint256 _amount)
    {
        Account storage _ac = _accounts[msg.sender];
        uint256 _amountCat = _ac.amountOfCategories; // Get the amount of categories
        if (_amountCat > 0) {
            bytes32[] memory _categories = new bytes32[](_amount);
            for (uint256 i; i < _amountCat; i++) {
                _categories[i] = _ac.categories[i]; // Get each Category and add to new array created before
            }
            return (_categories, _accounts[msg.sender].amountOfCategories);
        }
        return (new bytes32[](0), 0);
    }

    /// @notice Gets the Category Name from ID, if the category ID is valid
    /// @param _id Category ID
    /// @return _name 32 Character name of the Category
    function getCategoryName(uint256 _id)
        external
        view
        alreadySigned
        whenNotPaused
        returns (bytes32)
    {
        require(
            _accounts[msg.sender].categories[_id] != bytes32(0),
            "Category does not exist!"
        );
        return _accounts[msg.sender].categories[_id];
    }

    /// @notice Gets the Category ID from the name, if its not null
    /// @param _name 32 Character Name
    /// @return id Big Number ID the passed Category name
    function getCategoryID(bytes32 _name)
        external
        view
        alreadySigned
        whenNotPaused
        returns (uint256 id)
    {
        require(_name != bytes32(0), "Null Name!");
        for (uint256 i; i < _accounts[msg.sender].amountOfCategories; i++) {
            if (_accounts[msg.sender].categories[i] == _name) {
                return i;
            } else {
                require(true, "Category does not exist!");
            }
        }
    }

    /// @notice Gets how many entries are there in the category, if the category exists
    /// @param _catId Category ID
    /// @return amount The number of entries
    function getAmountOfEntriesPerCat(uint256 _catId)
        external
        view
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
        returns (uint256 amount)
    {
        return _accounts[msg.sender].catToAmountofEntries[_catId];
    }

    /// @notice Returns the name of the Account
    /// @return 32 Character name of the Account
    function getName()
        external
        view
        whenNotPaused
        alreadySigned
        returns (bytes32)
    {
        return _accounts[msg.sender].name;
    }

    /// @notice Gets all Transactions per sent Category ID, if category exists
    /// @param _catId Category ID
    /// @return 32 character name of the Category
    /// @return Entry object containing each entry and their timestamps
    function getAllTransactionsPerCat(uint256 _catId)
        external
        view
        alreadySigned
        whenNotPaused
        categoryExists(_catId)
        returns (bytes32, Entry[] memory)
    {
        Account storage _ac = _accounts[msg.sender];
        bytes32 _catName = _ac.categories[_catId];
        uint256 _entryAmount = _ac.catToAmountofEntries[_catId];

        Entry[] memory allEntries = new Entry[](_entryAmount);
        for (uint256 i; i < _entryAmount; i++) {
            allEntries[i] = _ac.entries[_catId][i];
        }

        return (_catName, allEntries);
    }

    /// @notice Gets the entry of a category, if the category exists and have entries
    /// @param _catId Category ID
    /// @param _entryId Entry ID
    /// @return Entry Object with entry amount and timestamps
    function getEntry(uint256 _catId, uint256 _entryId)
        external
        view
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
        returns (Entry memory)
    {
        require(
            _accounts[msg.sender].catToAmountofEntries[_entryId] > 0,
            "Dont have entries!"
        );
        return _accounts[msg.sender].entries[_catId][_entryId];
    }

    /// @notice Gets whether a user has an account
    /// @return Does user have an account?
    function getAccount() external view returns (bool) {
        if (_accounts[msg.sender].name != bytes32(0)) {
            return true;
        }
        return false;
    }

    // =============================================================
    //                           DELETORS
    // =============================================================

    /// @notice Delete an Entry if category exists, and the category has an entry
    /// @param _catId Category ID
    /// @param _entryId Entry ID
    function deleteEntry(uint256 _catId, uint256 _entryId)
        external
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
    {
        require(
            _accounts[msg.sender].catToAmountofEntries[_catId] > 0,
            "Doesnt have entries"
        );
        Account storage _ac = _accounts[msg.sender];
        require(
            _ac.entries[_catId][_entryId].created_At != uint256(0),
            "This entry does not exist!"
        );
        _ac.catToAmountofEntries[_catId]--;
        delete _ac.entries[_catId][_entryId];
        assert(
            _accounts[msg.sender].entries[_catId][_entryId].created_At ==
                uint256(0)
        );
    }

    /// @notice Delete Category if category exists
    /// @param _catId Category ID
    function deleteCategory(uint256 _catId)
        external
        whenNotPaused
        alreadySigned
        categoryExists(_catId)
    {
        Account storage _ac = _accounts[msg.sender];
        uint256 _entryAmount = _ac.catToAmountofEntries[_catId];
        if (_entryAmount > 0) {
            for (uint256 i; i < _entryAmount; i++) {
                delete _ac.entries[_catId][i]; // Delete each entry
            }
        }
        delete _ac.categories[_catId]; // Delete the Category Name
        _ac.amountOfCategories--; // Reduce the amount of categories
        delete _ac.catToAmountofEntries[_catId]; // Delete the Amount of Entries in that category
    }

    /// @notice Delete Account
    function deleteAccount() external whenNotPaused alreadySigned {
        delete _accounts[msg.sender];
    }

    // =============================================================
    //                           MAIN
    // =============================================================

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

    ///@notice Authorize Upgrade Version
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
