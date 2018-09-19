pragma solidity ^0.4.0;
pragma experimental "v0.5.0";

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract AirDrop is Ownable {
    address public renderTokenAddress;
    bool public listFinalized = false;
    uint256 public totalBonus;
    uint256 public nextUserToBePaid = 0;

    mapping (address => uint256) public bonusAmounts;
    address[] public bonusAddresses;

    event AddedUser(address userAddress, uint256 userIndex, uint256 bonusAmount);
    event PaidUser(address userAddress, uint256 userIndex, uint256 amountPaid);

    constructor(address _renderTokenAddress) public {
        renderTokenAddress = _renderTokenAddress;
    }
    
    function getUserCount() public view returns (uint256) {
        return bonusAddresses.length;
    }
    
    function addUser(address _userAddress, uint256 _amount) internal {
        require (bonusAmounts[_userAddress] == 0, "User bonus shouldn't exist before adding");
        bonusAmounts[_userAddress] = _amount;
        totalBonus += _amount;
        emit AddedUser(_userAddress, bonusAddresses.push(_userAddress) - 1, _amount);
    }

    function payUser(uint256 _id) internal returns(uint256 amount) {
        amount = bonusAmounts[bonusAddresses[_id]];

        if (amount > 0) { // If bonus hasn't been paid yet
            bonusAmounts[bonusAddresses[_id]] = 0;
            totalBonus -= amount;
            ERC20(renderTokenAddress).transfer(bonusAddresses[_id], amount);
            emit PaidUser(bonusAddresses[_id], _id, amount);
        }
    }

    function addManyUsers(address[] _recipients, uint256[] _amounts) public onlyOwner {
        require(!listFinalized, "Adding users allowed only when list isn't finalized");
        for (uint i = 0; i < _recipients.length; i++) {
            addUser(_recipients[i], _amounts[i]);
        }
    }
    
    function payUserRange(uint256 _idFrom, uint256 _idTo) internal returns(uint256 totalPaid) {
        require(_idTo < bonusAddresses.length, "idTo should be less than user count");
        require(_idFrom <= _idTo, "idFrom shouldn't be greater than idTo");
        for (uint i = _idFrom; i <= _idTo; i++) { // idTo included
            totalPaid += payUser(i);
        }
        nextUserToBePaid = _idTo + 1;
    }
    
    function payManyUsers(uint256 batchSize) public onlyOwner returns(uint256 totalPaid) {
        require(listFinalized, "Payment can be called only after list is finalized");
        uint256 idFrom = nextUserToBePaid;
        uint256 idTo = idFrom + batchSize - 1;
        if (idTo >= bonusAddresses.length) idTo = bonusAddresses.length - 1;
        return payUserRange(idFrom, idTo);
    }

    function finalizeList() public onlyOwner {
        require(!listFinalized, "Can be called only if list isn't finalized");
        listFinalized = true;
    }
    
    function returnTokens() public onlyOwner {
        uint256 amount = ERC20(renderTokenAddress).balanceOf(address(this));
        ERC20(renderTokenAddress).transfer(owner, amount);
    }
}