var ADXAdvertiserRegistry = artifacts.require("./ADXAdvertiserRegistry.sol");
var Promise = require('bluebird')
var time = require('../helpers/time')

contract('ADXAdvertiserRegistry', function(accounts) {
	var accOne = web3.eth.accounts[0]
	var wallet = web3.eth.accounts[8]


	var advRegistry 

	it("initialize contract", function() {
		return ADXAdvertiserRegistry.new().then(function(_advRegistry) {
			advRegistry = _advRegistry
		})
	});

	it("can't register a campaign w/o being an advertiser", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerCampaign(0, "test campaign", "{}", {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	});

	it("can't register an ad unit w/o being an advertiser", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerAdUnit(0, 0, [], {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})


	it("can't register as an advertiser w/o a wallet", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerAsAdvertiser("stremio", 0, "{}", {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	it("advertiser not registered", function() {
		return advRegistry.isRegistered(accOne)
		.then(function(isReg) {
			assert.equal(isReg, false)
		})
	})

	it("can register as an advertiser", function() {
		return advRegistry.registerAsAdvertiser("stremio", wallet, "{}", {
			from: accOne,
			gas: 130000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAdvertiserRegistered')
			assert.equal(ev.args.addr, accOne)
			assert.equal(ev.args.wallet, wallet)
			assert.equal(ev.args.meta, '{}')
		})
	})

	it("advertiser is registered", function() {
		return advRegistry.isRegistered(accOne)
		.then(function(isReg) { 
			assert.equal(isReg, true)
		})
	})

	it("can update advertiser info", function() {
		return advRegistry.registerAsAdvertiser("stremio", wallet, '{ "email": "office@strem.io" }', {
			from: accOne,
			gas: 130000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAdvertiserModified')
			assert.equal(ev.args.addr, accOne)
			assert.equal(ev.args.wallet, wallet)
			assert.equal(ev.args.meta, '{ "email": "office@strem.io" }')
		})
	})

	it("can register a new campaign", function() {
		return advRegistry.registerCampaign(0, "foobar campaign", "{}", {
			from: accOne,
			gas: 230000
		})
	})
	// TODO: update existing campaign
	// TODO: can't update another advertiser's campaign

	// TODO: can register an ad unit
	// TODO: can update an existing ad unit
	// TODO: can't update another advertiser's ad unit

	// can drain ether: can't test that, because we can't send ether in the first place...
	// maybe figure out a way to test it?

	// TODO: can drain tokens if accidently sent

	// TODO: all the *get methods 
	// also test if they are callable for non-registered advertisers

	it("can't send ether accidently", function() {
		return new Promise((resolve, reject) => {
			web3.eth.sendTransaction({
				from: accOne,
				to: advRegistry.address,
				value: 1*10**18,
				gas: 130000
			}, (err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	it("can get an advertiser", function() {
		return advRegistry.getAdvertiser(accOne)
		.then(function(res) {
			console.log(res)
		})
	})
})
