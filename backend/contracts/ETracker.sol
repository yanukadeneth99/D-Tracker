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
        mapping(uint256 => mapping(uint256 => int256)) entries;
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
    function createAccount(bytes32 _name) public whenNotPaused {
        require(
            _accounts[msg.sender].name == bytes32(0),
            "Account already exists"
        );
        _accounts[msg.sender].name = _name;
    }

    /// @notice How many Categories does the caller account have
    function getAmountOfCategories()
        public
        view
        alreadySigned
        whenNotPaused
        returns (uint256)
    {
        return _accounts[msg.sender].amountOfCategories;
    }

    function getAllCategories()
        public
        whenNotPaused
        alreadySigned
        returns (bytes32[] memory)
    {}

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
