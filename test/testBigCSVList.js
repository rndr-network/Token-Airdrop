const BN = require('bn.js');
const fs = require('fs')

function loadBonusList() {
  let file = fs.readFileSync('./test/testBonusList.csv').toString().split('\r\n')
  let bonusList = file.map((e) => {return e.split(',')})
  return bonusList
}

const Airdrop = artifacts.require("Airdrop")
const RenderTokenMock = artifacts.require("RenderTokenMock")

contract("Big CSV List Airdrop Simulation", async ([owner]) => {
  var bonuses
  var users
  var totalBonus
  var userCount

  before(async () => {
    airdrop = await Airdrop.deployed();
    rndr = await RenderTokenMock.deployed();
    let bonusList = loadBonusList()
    users = bonusList.map((e) => {return e[0]})
    bonuses = bonusList.map((e) => {return new BN(e[1])})
    totalBonus = bonuses.reduce((acc, val) => acc.add(val), new BN(0))
    userCount = bonuses.length
  })

  it("sets an owner", async () => {
    assert.equal(await airdrop.owner(), owner)
  })

  it("has balance", async () => {
    let balance = await rndr.balanceOf(owner)
    assert(balance.gt(0), `Owner has ${balance.toString()} RNDR`)
  })
  
  it("add multiple users (userCount check)", async () => {
    const batchSize = 10
    for (let i = 0; i < userCount; i += batchSize) {
      idFrom = i;
      idTo = i + batchSize
      if (idTo > userCount) idTo = userCount;
      await airdrop.addManyUsers(users.slice(idFrom, idTo), bonuses.slice(idFrom, idTo))
      console.log(`Adding users ${idFrom} to ${idTo} to Airdrop Contract...`)
    }
    assert.equal(await airdrop.getUserCount(), userCount)
  })

  it("finalize list", async () => {
    assert.equal(await airdrop.listFinalized(), false)
    await airdrop.finalizeList()
    assert.equal(await airdrop.listFinalized(), true)
  })

  it("check bonus addresses list", async () => {
    for (let i = 0; i < userCount; i++) {
      assert.equal(await airdrop.bonusAddresses(i), users[i])
    }
  })

  it("check bonuses amounts list", async () => {
    for (let i = 0; i < userCount; i++) {
      assert(bonuses[i].eq(await airdrop.bonusAmounts(await airdrop.bonusAddresses(i))))
    }
  })

  it("check totalBonus amount", async () => {
    assert(totalBonus.eq(await airdrop.totalBonus()))
  })

  it("can't add more users after list is finalized", async () => {
    try {
      await airdrop.addManyUsers([owner], [50])
      assert.fail()
    } catch (err) {
      assert(err.reason === "Adding users allowed only when list isn't finalized", err.reason)
    }
  })

  it("adding enough funds", async () => {
    await rndr.transfer(airdrop.address, totalBonus)
    assert(totalBonus.eq(await rndr.balanceOf(airdrop.address)))
  })

  it("pay bonuses", async () => {
    const batchSize = 19
    for (let i = 0; i < userCount; i += batchSize) {
      await airdrop.payManyUsers(batchSize)
      console.log(`Paying ${batchSize} users starting with id ${i}...`)
    }
  })

  it("check if all tokens were spent", async () => {
    assert.equal(await rndr.balanceOf(airdrop.address), 0)
  })

  it("check user balances for bonus received", async () => {
    for (let i = 0; i<userCount; i++) {
      let userBonus = await rndr.balanceOf(users[i])
      assert(userBonus.eq(bonuses[i]))
      console.log(`User ${i} got ${userBonus.toString()} of ${bonuses[i].toString()} bonus`)
    }
  })
})
