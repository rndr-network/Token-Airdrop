pragma solidity ^0.4.24;

import { ERC20, SafeERC20 } from "../node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import { Ownable } from "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import { SafeMath } from "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title AirDrop
 *
 * @dev RNDRToken GenesisBonus AirDrop contract
 * For workflow see:
 * https://github.com/jeualvarez/Token-Airdrop
 */

contract AirDrop is Ownable {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  address public renderTokenAddress;
  bool public listFinalized = false;
  uint256 public totalBonus = 0; // Before finalizing - check if totalBonus matches the total bonus amount to distribute
  uint256 public nextUserToBePaid = 0;

  mapping (address => uint256) public bonusAmounts;
  address[] public bonusAddresses;

  event AddedUser(address indexed userAddress, uint256 userIndex, uint256 bonusAmount);
  event PaidUser(address indexed userAddress, uint256 userIndex, uint256 amountPaid);
  event DoublePayAttempt(address indexed userAddress, uint256 userIndex, uint256 amountPaid);

  /**
  * @notice Create Airdrop contract
  * @param _renderTokenAddress Address of current RNDR token ERC20 contract
  */
  constructor(address _renderTokenAddress) public {
    renderTokenAddress = _renderTokenAddress;
  }

  //
  // Internal functions
  //

  /**
  * @dev Adds a user to bonus-list.
  * @param _userAddress The address of a user
  * @param _amount The amount of bonus to send to the specified user
  */
  function _addUser(address _userAddress, uint256 _amount) internal {
    require (bonusAmounts[_userAddress] == 0, "User bonus shouldn't exist before adding");
    bonusAmounts[_userAddress] = _amount;
    totalBonus = totalBonus.add(_amount);
    uint256 userIndex = bonusAddresses.push(_userAddress) - 1;
    emit AddedUser(_userAddress, userIndex, _amount);
  }

  /**
  * @dev Pays a user based on his ID in bonus-list
  * @param _id User ID from bonus-list
  * @return Amount of bonus tokens paid to this user
  */
  function _payUser(uint256 _id) internal returns(uint256 amount) {
    amount = bonusAmounts[bonusAddresses[_id]];

    if (amount > 0) { // If bonus hasn't been paid yet
      bonusAmounts[bonusAddresses[_id]] = 0;
      totalBonus = totalBonus.sub(amount);
      ERC20(renderTokenAddress).safeTransfer(bonusAddresses[_id], amount);
      emit PaidUser(bonusAddresses[_id], _id, amount);
    } else {
      emit DoublePayAttempt(bonusAddresses[_id], _id, amount); // This basically can't happen. Check why there was an attempt to double-pay?
    }
  }

  /**
  * @dev Pays many users based on their IDs in bonus-list (from-to)
  * @param _idFrom User ID to start paying from
  * @param _idTo User ID to finish paying (included)
  * @return Amount of total bonus paid
  */
  function _payUserRange(uint256 _idFrom, uint256 _idTo) internal returns(uint256 totalPaid) {
    require(_idTo < bonusAddresses.length, "idTo should be less than user count");
    require(_idFrom <= _idTo, "idFrom shouldn't be greater than idTo");
    for (uint256 i = _idFrom; i <= _idTo; i++) { // idTo included
      totalPaid = totalPaid.add(_payUser(i));
    }
    nextUserToBePaid = _idTo.add(1);
  }

  //
  // External functions
  //

  /**
  * @notice Gets total users count
  * @dev Use this to determine if bonus-list has the correct number of users before finalizing
  * @return Count of all users in bonus-list
  */
  function getUserCount() external view returns (uint256) {
    return bonusAddresses.length;
  }

  /**
  * @notice Adds many users from arrays of addresses and correspoding amounts
  * @param _recipients Array containing addresses of users
  * @param _amounts Array containing amounts of bonus to send to users from _recepients array
  */
  function addManyUsers(address[] _recipients, uint256[] _amounts) external onlyOwner {
    require(!listFinalized, "Adding users allowed only when list isn't finalized");
    require(_recipients.length == _amounts.length, "_recipients and _amounts arrays have different number of elements");
    for (uint i = 0; i < _recipients.length; i++) {
      _addUser(_recipients[i], _amounts[i]);
    }
  }

  /**
  * @notice Pays next batch of users
  * @param batchSize How many users to pay
  * @return Amount of total bonus paid
  */
  function payManyUsers(uint256 batchSize) external onlyOwner returns(uint256 totalPaid) {
    require(listFinalized, "Payment can be called only after list is finalized");
    require(batchSize > 0, "Batch size should not be 0");
    uint256 idFrom = nextUserToBePaid;
    uint256 idTo = idFrom.add(batchSize).sub(1);
    if (idTo >= bonusAddresses.length) {
      idTo = bonusAddresses.length.sub(1);
    }
    return _payUserRange(idFrom, idTo);
  }

  /**
  * @notice Finalize bonus-list. Can't add more users after the list is finalized
  * @dev Verify user count, totalBonus, and all individual user addresses & amounts after finalizing and before sending any tokens to the contract
  */
  function finalizeList() external onlyOwner {
    require(!listFinalized, "Can be called only if list isn't finalized");
    listFinalized = true;
  }

  /**
  * @notice Return the unpaid excess of tokens to owner
  */
  function returnTokens() external onlyOwner {
    uint256 amount = ERC20(renderTokenAddress).balanceOf(address(this));
    ERC20(renderTokenAddress).transfer(owner, amount);
  }
}
