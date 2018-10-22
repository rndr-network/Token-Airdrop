const AirDrop = artifacts.require("AirDrop")
const RenderTokenMock = artifacts.require("RenderTokenMock")

contract("AirDrop", async ([owner, ...users]) => {
  const bonuses = [300, 200, 100]
  const totalBonus = bonuses.reduce((acc, val) => acc + val, 0)
  const userCount = bonuses.length
  users = users.slice(0, userCount)

  before(async () => {
    airdrop = await AirDrop.deployed();
    rndr = await RenderTokenMock.deployed();
  })

  it("sets an owner", async () => {
    assert.equal(await airdrop.owner(), owner)
  })

  it("has balance", async () => {
    let balance = await rndr.balanceOf(owner)
    assert(balance > 0, `Owner has ${balance} RNDR`)
  })
  
  it("can add multiple users (userCount check)", async () => {
    await airdrop.addManyUsers(users, bonuses)
    assert.equal(await airdrop.getUserCount(), userCount)
  })

  it("check bonus addresses list", async () => {
    for (let i = 0; i<userCount; i++) {
      assert.equal(await airdrop.bonusAddresses(i), users[i])
    }
  })

  it("check bonuses amounts list", async () => {
    for (let i = 0; i<userCount; i++) {
      assert.equal(await airdrop.bonusAmounts(await airdrop.bonusAddresses(i)), bonuses[i])
    }
  })

  it("can't pay until list is finalized", async () => {
    try {
      await airdrop.payManyUsers(2)
      assert.fail()
    } catch (err) {
      assert(err.reason === 'Payment can be called only after list is finalized', err.reason)
    }
  })

  it("can finalize list", async () => {
    assert.equal(await airdrop.listFinalized(), false)
    await airdrop.finalizeList()
    assert.equal(await airdrop.listFinalized(), true)
  })

  it("can't add more users after list is finalized", async () => {
    try {
      await airdrop.addManyUsers([owner], [50])
      assert.fail()
    } catch (err) {
      assert(err.reason === "Adding users allowed only when list isn't finalized", err.reason)
    }
  })

  it("total bonus matches", async () => {
    assert.equal(await airdrop.totalBonus(), totalBonus)
  })

  it("adding enough funds", async () => {
    await rndr.transfer(airdrop.address, totalBonus)
    assert.equal(await rndr.balanceOf(airdrop.address), totalBonus)
  })

  it("can pay bonuses", async () => {
    await airdrop.payManyUsers(10)
    assert.equal(await rndr.balanceOf(airdrop.address), 0)

    for (let i = 0; i<userCount; i++) {
      assert.equal(await rndr.balanceOf(users[i]), bonuses[i])
    }
  })

  it("can withdraw excess tokens", async () => {
    let initialBalance = await rndr.balanceOf(airdrop.address)

    await rndr.transfer(airdrop.address, 100)
    assert.equal(await rndr.balanceOf(airdrop.address), 100 + initialBalance*1, `AirDrop balance before is ${(await rndr.balanceOf(airdrop.address)).toNumber()} instead of ${100 + initialBalance*1}`)

    let ownerBalance = await rndr.balanceOf(owner)
    await airdrop.returnTokens()
    assert.equal(await rndr.balanceOf(airdrop.address), 0, `AirDrop balance after is ${(await rndr.balanceOf(airdrop.address)).toNumber()} instead of 0`)
    assert.equal(await rndr.balanceOf(owner), 100 + ownerBalance*1, `Owner balance after is ${await rndr.balanceOf(owner)} instead of ${100 + ownerBalance*1}`)
  })
})
