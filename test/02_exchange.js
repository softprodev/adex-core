var ADXExchange = artifacts.require("./ADXExchange.sol");
var ADXRegistry = artifacts.require("./ADXRegistry.sol"); // we need the registry because the exchange depends on it
var ADXMock = artifacts.require("./ADXMock.sol"); // adx mock token
var Promise = require('bluebird')
var time = require('../helpers/time')

contract('ADXExchange', function(accounts) {
	var accOne = web3.eth.accounts[0]
	var accTwo = web3.eth.accounts[1] // advertiser
	var accThree = web3.eth.accounts[2] // publisher
	var advWallet = web3.eth.accounts[8]
	var pubWallet = web3.eth.accounts[7]

	var SIG = 0x420000000000000002300023400022000000000000000000000000000000000

	var ADUNIT = 0 
	var ADSLOT = 1

	var adxToken;
	it("create adx mock token", function() {
		return ADXMock.new({ from: accOne }).then(function(_adxToken) {
			adxToken = _adxToken
		})
	})

	var adxRegistry
	it("create adx registry", function() {
		return ADXRegistry.new().then(function(_adxRegistry) {
			adxRegistry = _adxRegistry
		})
	})

	var adxExchange 
	it("create adx exchange", function() {
		return ADXExchange.new(adxToken.address, adxRegistry.address, { from: accOne })
		.then(function(_adxExchange) {
			adxExchange = _adxExchange
		})
	})

	var adunitId
	var adslotId

	it("can NOT place a bid without an account", function() {
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(1, 50 * 10000, 0, {
				from: accTwo,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	// WARNING: copied from registry tests; we need to make an ad unit in order to use it
	it("register as an account", function() {
		return adxRegistry.register("vyperCola", advWallet, 0x57, SIG, "{}", {
			from: accTwo,
			gas: 170000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAccountRegistered')
			assert.equal(ev.args.addr, accTwo)
			assert.equal(web3.toUtf8(ev.args.name), 'vyperCola')
			assert.equal(ev.args.ipfs, '0x5700000000000000000000000000000000000000000000000000000000000000');
			assert.equal(ev.args.wallet, advWallet)
			assert.equal(ev.args.meta, '{}')
		})
	})


	it("can NOT place a bid without an ad unit", function() {
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(0, 50 * 10000, 0, {
				from: accTwo,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can register a new ad unit", function() {
		return adxRegistry.registerItem(ADUNIT, 0, 0x482, "foobar ad unit", "{}", {
			from: accTwo,
			gas: 230000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogItemRegistered')
			assert.equal(ev.args.itemType, ADUNIT);
			assert.equal(ev.args.id, 1)
			assert.equal(web3.toUtf8(ev.args.name), 'foobar ad unit')
			assert.equal(ev.args.meta, '{}')
			assert.equal(ev.args.ipfs, '0x4820000000000000000000000000000000000000000000000000000000000000');
			assert.equal(ev.args.owner, accTwo)

			adunitId = ev.args.id.toNumber()
		})
	})

	it("can register a new publisher account and ad slot", function() {
		// WARNING: copied from registry tests; we need to make an ad slot in order to use the exchange
		return adxRegistry.register("stremio", pubWallet, 0x57, 0x421, "{}", {
			from: accThree,
			gas: 170000
		}).then(function() {
			return adxRegistry.registerItem(ADSLOT, 0, 0x4821, "foobar ad slot", "{}", {
				from: accThree,
				gas: 230000
			})
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogItemRegistered')
			assert.equal(ev.args.itemType, ADSLOT);
			assert.equal(ev.args.id, 1)
			assert.equal(web3.toUtf8(ev.args.name), 'foobar ad slot')
			assert.equal(ev.args.meta, '{}')
			assert.equal(ev.args.ipfs, '0x4821000000000000000000000000000000000000000000000000000000000000');
			assert.equal(ev.args.owner, accThree)

			adslotId = ev.args.id.toNumber()
		})
	})

	// we give more so we can
	// 1) test whether publisher can double-claim reward
	// 2) open another bid for 40k

	it("give some tokens to accTwo so they can place a bid", function() {
		return adxToken.transfer(advWallet, 110 * 10000, { from: accOne })
	})

	it("can NOT place a bid because of allowance", function() {
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(adunitId, 50 * 10000, 0, {
				from: accTwo,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("give allowance to transfer so we can place a bid", function() {
		return adxToken.approve(adxExchange.address, 50 * 10000, { from: advWallet })
	})


	it("can NOT place a bid because we don't own the ad unit (not the advertiser)", function() {
		// if this was allowed, it would still send the adx to accTwo (the rightful owner), because 'advertiser' is taken from the ad unit object
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(adunitId, 50 * 10000, 0, {
				from: accOne,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can place a bid", function() {
		return adxExchange.placeBid(adunitId, 50 * 10000, 0, {
			from: accTwo,
			gas: 860000 // costly :((
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidOpened')
			assert.equal(ev.args.bidId, 1)
			assert.equal(ev.args.advertiser, accTwo)
			assert.equal(ev.args.adunitId, adunitId)
			assert.equal(ev.args.rewardAmount, 50 * 10000)
			assert.equal(ev.args.timeout, 0);

			return adxToken.balanceOf(adxExchange.address)
		}).then(function(bal) {
			// exchange has 50k
			assert.equal(bal.toNumber(), 50 * 10000)

			return adxToken.balanceOf(advWallet)
		}).then(function(advBal) {
			// advertiser still has 60k
			assert.equal(advBal.toNumber(), 60 * 10000)
		})
	})

	it("can NOT cancel a bid that's not ours", function() {
		return new Promise((resolve, reject) => {
			adxExchange.cancelBid(1, { from: accOne, gas: 300000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can NOT cancel a bid that does not exist", function() {
		return new Promise((resolve, reject) => {
			adxExchange.cancelBid(111, { from: accTwo, gas: 300000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can cancel a bid and will be refunded", function() {
		return adxExchange.cancelBid(1, { from: accTwo, gas: 300000 })
		.then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidCanceled')
			assert.equal(ev.args.bidId, 1)

			return adxToken.balanceOf(advWallet)
		})
		.then(function(bal) {
			assert.equal(bal, 110 * 10000)
		})
	})

	it("give allowance to transfer so we can place a bid", function() {
		return adxToken.approve(adxExchange.address, 50 * 10000, { from: advWallet })
	})

	it("can place a second bid", function() {
		return adxExchange.placeBid(adunitId, 50 * 10000, 0, {
			from: accTwo,
			gas: 860000 // costly :((
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidOpened')
			assert.equal(ev.args.bidId, 2)
			assert.equal(ev.args.advertiser, accTwo)
			assert.equal(ev.args.adunitId, adunitId)
			assert.equal(ev.args.adunitIpfs, '0x4820000000000000000000000000000000000000000000000000000000000000')
			assert.equal(ev.args.rewardAmount, 50 * 10000)
			assert.equal(ev.args.timeout, 0)

			return adxToken.balanceOf(adxExchange.address)
		}).then(function(bal) {
			assert.equal(bal.toNumber(), 50 * 10000)
		})
	})

	it("advertiser can NOT confirm the bid before it's accepted", function() {
		return new Promise((resolve, reject) => {
			adxExchange.verifyBid(2, { from: accTwo, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can NOT accept a bid if you're not the publisher", function() {
		return new Promise((resolve, reject) => {
			adxExchange.acceptBid(2, adslotId, { from: accTwo, gas: 860000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("can accept a bid", function() {
	 	return adxExchange.acceptBid(2, adslotId, {
	 		from: accThree,
	 		gas: 860000
	 	}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidAccepted')
			assert.equal(ev.args.bidId, 2)
			assert.equal(ev.args.publisher, accThree)
			assert.equal(ev.args.adslotId, adslotId)
			assert.equal(ev.args.adslotIpfs, '0x4821000000000000000000000000000000000000000000000000000000000000')

			return adxToken.balanceOf(adxExchange.address)
		})
	})

	it("can NOT cancel a bid once it's accepted", function() {
		return new Promise((resolve, reject) => {
			adxExchange.cancelBid(2, { from: accTwo, gas: 300000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})
	
	it("can NOT claim bid reward before it's confirmed", function() {
		return new Promise((resolve, reject) => {
			adxExchange.claimBidReward(2, { from: accThree, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})


	it("can NOT refund the bid even considering it's Open", function() {
		return new Promise((resolve, reject) => {
			adxExchange.refundBid(2, { from: accTwo, gas: 300000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	// Bid can be completed

	it("non-publisher/advertiser can NOT confirm the bid", function() {
		return new Promise((resolve, reject) => {
			adxExchange.verifyBid(2, { from: accOne, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("publisher can confirm the bid", function() {
		return adxExchange.verifyBid(2, { from: accThree, gas: 400000 })
	})

	it("can NOT claim bid reward before it's FULLY confirmed (advertiser + publisher)", function() {
		return new Promise((resolve, reject) => {
			adxExchange.claimBidReward(2, { from: accThree, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("advertiser can confirm the bid", function() {
		return adxExchange.verifyBid(2, { from: accTwo, gas: 400000 })
		.then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidCompleted')
		})
	})

	// TODO: repeat that test, but in the other order

	it("non-publisher can NOT claim bid reward", function() {
		return new Promise((resolve, reject) => {
			adxExchange.claimBidReward(2, { from: accTwo, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("publisher can claim bid reward", function() {
		return adxExchange.claimBidReward(2, { from: accThree, gas: 400000 })
		.then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidRewardClaimed')

			return adxToken.balanceOf(pubWallet)
		})
		.then(function(balance) {
			assert.equal(balance.toNumber(), 50 * 10000)
		})
	})


	it("publisher can NOT claim bid reward TWICE", function() {
		return new Promise((resolve, reject) => {
			adxExchange.claimBidReward(2, { from: accThree, gas: 400000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	// Bid can be refunded, but only if required (it is expired)
	it("give allowance to transfer so we can place a bid", function() {
		return adxToken.approve(adxExchange.address, 40 * 10000, { from: advWallet })
	})
	
	it("can place a third bid with 300s timeout (and accept it)", function() {
		return adxExchange.placeBid(adunitId, 40 * 10000, 300, {
			from: accTwo,
			gas: 860000 // costly :((
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidOpened')
			assert.equal(ev.args.bidId, 3)
			assert.equal(ev.args.advertiser, accTwo)
			assert.equal(ev.args.adunitId, adunitId)
			assert.equal(ev.args.adunitIpfs, '0x4820000000000000000000000000000000000000000000000000000000000000')
			assert.equal(ev.args.rewardAmount, 40 * 10000)
			assert.equal(ev.args.timeout.toNumber(), 300)

			return adxToken.balanceOf(adxExchange.address)
		}).then(function(bal) {
			assert.equal(bal.toNumber(), 40 * 10000)

			return adxExchange.acceptBid(3, adslotId, {
		 		from: accThree,
		 		gas: 860000
		 	})
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidAccepted')
			assert.equal(ev.args.bidId, 3)
			assert.equal(ev.args.publisher, accThree)
			assert.equal(ev.args.adslotId, adslotId)
			assert.equal(ev.args.adslotIpfs, '0x4821000000000000000000000000000000000000000000000000000000000000')
		
			return adxToken.balanceOf(advWallet)
		})
		.then(function(bal) {
			// has 20k left, after we spent 50k for a bid and locked another 40k
			assert.equal(bal.toNumber(), 20 * 10000)
		})
	})

	it("can NOT refund the bid", function() {
		return new Promise((resolve, reject) => {
			adxExchange.refundBid(3, { from: accTwo, gas: 300000 })
			.catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
			.then(function() { reject('cant be here - unexpected success') })
		})
	})

	it("move time 300s", function() {
		return time.move(web3, 310)
	})

	it("bid should be timed out, can now refund the bid", function() {
		return adxExchange.refundBid(3, { from: accTwo, gas: 300000 })
		.then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidExpired')

			return adxToken.balanceOf(advWallet)
		})
		.then(function(bal) {
			assert.equal(bal.toNumber(), 60 * 10000)
		})
	})

})
