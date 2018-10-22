# Airdrop contract

---

## Contract workflow:

  0. Prepare a CSV bonus list with `users address`, `bonus amount`
  1. Deploy Airdrop contract (pointing to RNDR token ERC20 contract address in a constuctor)
  2. Call `addManyUsers(userAddresses[], bonusAmounts[])` with corresponding arrays. Can be done several batches (adding each user costs around 80k gas)
  3. Call `finalizeList()` to lock the modification of user bonus list
  4. Perform safety checks on the blockchain list:
      * Check that `bonusAddresses[]` array contain only allowed users
      * Check that corresponding `bonusAmounts` mappings have relevant amount of bonus
      * Check `totalBonus`
      * Check `userCount`
  5. If all checks correspond to your local bonus list - load Airdrop contract with enough RNDR tokens (`totalBonus`)
  6. Call `payManyUsers(batchSize)` with a chosen `batchSize` several times (paying each user costs around 40-50k gas)
  7. If any excess tokens are left on the contract - it can be withdrawn by calling `returnTokens()`


## Testing:

  There are a couple of truffle tests which run through the above basic workflow and some safety-checks.

  To run, do the following:
  1. `npm install`
  2. Get latest ganache or any other blockchain that supports require messages running on port 8545
  3. `truffle compile`
  4. `truffle test` (global fresh truffle v5 installation required)
