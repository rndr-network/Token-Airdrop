# Airdrop contract

---

## Contract workflow:

  0. Prepare a list of users addresses + bonus amounts
  1. Deploy Airdrop contract pointing to RNDR token ERC20 contract address in constuctor
  2. Call `addManyUsers(userAddresses[], bonusAmounts[])` with corresponding arrays. Can be done several batches (each user costs around 80k gas)
  3. Call `finalizeList()` to lock user bonus list modification
  4. Perform list safety checks:
      * Check that `bonusAddresses[]` array contains only allowed users
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
  3. `truffle test` (global fresh truffle v5 installation required)