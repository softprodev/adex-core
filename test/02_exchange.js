var ADXExchange = artifacts.require("./ADXExchange.sol");
var ADXRegistry = artifacts.require("./ADXRegistry.sol"); // we need the registry because the exchange depends on it
var ADXMock = artifacts.require("./ADXMock.sol"); // adx mock token
var Promise = require('bluebird')
var time = require('../helpers/time')

contract('ADXExchange', function(accounts) {
	var accOne = web3.eth.accounts[0]
	var accTwo = web3.eth.accounts[1]
	var advWallet = web3.eth.accounts[8]

	var ADUNIT = 0 
	var PROPERTY = 1

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

	it("can NOT place a bid without an account", function() {
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(1, 50 * 10000, 0, {
				from: accTwo,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	// WARNING: copied from registry tests; we need to make an ad unit in order to use it
	it("register as an account", function() {
		return adxRegistry.register("stremio", advWallet, 0x57, "{}", {
			from: accTwo,
			gas: 130000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAccountRegistered')
			assert.equal(ev.args.addr, accTwo)
			assert.equal(web3.toUtf8(ev.args.name), 'stremio')
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

			// TODO check all ad units for an account after
		})
	})

	it("give some tokens to accTwo so they can place a bid", function() {
		return adxToken.transfer(advWallet, 50 * 10000, { from: accOne })
	})

	it("can NOT place a bid because of allowance", function() {
		return new Promise((resolve, reject) => {
			adxExchange.placeBid(0, 50 * 10000, 0, {
				from: accTwo,
				gas: 860000 // costly :((
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	it("give allowance to transfer so we can place a bid", function() {
		return adxToken.approve(adxExchange.address, 50 * 10000, { from: advWallet })
	})

	it("can place a bid", function() {
		return adxExchange.placeBid(adunitId, 50 * 10000, 0, {
			from: accTwo,
			gas: 860000 // costly :((
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogBidOpened')

			return adxToken.balanceOf(adxExchange.address)
		}).then(function(bal) {
			assert.equal(bal.toNumber(), 50 * 10000)
		})
	})
})
