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
        mapping(uint256 => bytes32) categories; // ID => Category Name
        mapping(uint256 => uint256) catToAmountofEntries; // CatID => How many Entries
        mapping(uint256 => mapping(uint256 => Entry)) entries; // CatID => (EntryID => Entry[amount,created_At,updated_At])
    }

    /// @notice Every entry (transaction), has a positive or negative amount and the time it was created.
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

    // =============================================================
    //                           CREATION
    // =============================================================

    /// @notice Create an account if it does not exist
    function createAccount(bytes32 _name) external whenNotPaused {
        require(
            _accounts[msg.sender].name == bytes32(0),
            "Account already exists"
        );
        _accounts[msg.sender].name = _name;
    }

    /// @notice Create a Category by name and update the amount of Categories
    function createCategory(bytes32 _name)
        external
        whenNotPaused
        alreadySigned
    {
        uint256 newAmount = _accounts[msg.sender].amountOfCategories + 1;
        _accounts[msg.sender].categories[newAmount] = _name;
        _accounts[msg.sender].amountOfCategories = newAmount;
    }

    /// @notice Create a Entry to a Category
    function createEntry(uint256 _catId, int256 _amount)
        external
        whenNotPaused
        alreadySigned
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

    /// @notice Change the name to the new name
    function changeName(bytes32 _newName) external whenNotPaused alreadySigned {
        require(
            _accounts[msg.sender].name != _newName,
            "Setting name is the same!"
        );
        _accounts[msg.sender].name = _newName;
    }

    // =============================================================
    //                           UPDATION
    // =============================================================

    /// @notice Change the name of the Category per the ID
    function updateCategoryName(uint256 _catId, bytes32 _newName)
        external
        whenNotPaused
        alreadySigned
    {
        require(
            _accounts[msg.sender].categories[_catId] != _newName,
            "You have passed the same name"
        );
        _accounts[msg.sender].categories[_catId] = _newName;
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
        external
        view
        whenNotPaused
        alreadySigned
        returns (bytes32[] memory, uint256 amount)
    {
        Account storage _ac = _accounts[msg.sender];
        uint256 amount = _ac.amountOfCategories;
        bytes32[] memory _categories = new bytes32[](amount);
        for (uint256 i; i < amount; i++) {
            _categories[i] = _ac.categories[i];
        }

        return (_categories, _accounts[msg.sender].amountOfCategories);
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

    /// @notice Gets all Transactions per sent Category ID as an Entry array
    function getAllTransactionsPerCat(uint256 _catId)
        external
        view
        alreadySigned
        whenNotPaused
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

    /// @notice Gets the entry at that Category an Entry Object with amount and timestamps
    function getEntry(uint256 _catId, uint256 _entryId)
        external
        view
        whenNotPaused
        alreadySigned
        returns (Entry memory)
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

    ///@notice Authorize Upgrade Version
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
