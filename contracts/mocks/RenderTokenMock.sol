pragma solidity ^0.4.18;

import "./RenderToken.sol";

/**
 * @title RenderTokenMock
 */
contract RenderTokenMock is RenderToken {

  constructor(address initialAccount, uint256 initialBalance) public {
    balances[initialAccount] = initialBalance;
    totalSupply = initialBalance;
  }

}
