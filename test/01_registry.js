var ADXRegistry = artifacts.require("./ADXRegistry.sol");
var Promise = require('bluebird')
var time = require('../helpers/time')

contract('ADXRegistry', function(accounts) {
	var accOne = web3.eth.accounts[0]
	var wallet = web3.eth.accounts[8]

	var ADUNIT = 0 
	var PROPERTY = 1

	var advRegistry 

	it("initialize contract", function() {
		return ADXRegistry.new().then(function(_advRegistry) {
			advRegistry = _advRegistry
		})
	});

	it("can't register a property w/o being an account", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerItem(PROPERTY, 0, "test campaign", "{}", 0, {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	});

	it("can't register an ad unit w/o being an account", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerItem(ADUNIT, 0, "blank name", "blank meta", 0, {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})


	it("can't register as a publisher w/o a wallet", function() {
		return new Promise((resolve, reject) => {
			advRegistry.register("stremio", 0, "{}", {
				from: accOne,
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	it("account not registered", function() {
		return advRegistry.isRegistered(accOne)
		.then(function(isReg) {
			assert.equal(isReg, false)
		})
	})

	it("can register as an account", function() {
		return advRegistry.register("stremio", wallet, "{}", {
			from: accOne,
			gas: 130000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAccountRegistered')
			assert.equal(ev.args.addr, accOne)
			assert.equal(ev.args.wallet, wallet)
			assert.equal(ev.args.meta, '{}')
		})
	})

	it("account is registered", function() {
		return advRegistry.isRegistered(accOne)
		.then(function(isReg) { 
			assert.equal(isReg, true)
		})
	})

	it("can update account info", function() {
		return advRegistry.register("stremio", wallet, '{ "email": "office@strem.io" }', {
			from: accOne,
			gas: 130000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogAccountModified')
			assert.equal(ev.args.addr, accOne)
			assert.equal(ev.args.wallet, wallet)
			assert.equal(ev.args.meta, '{ "email": "office@strem.io" }')
		})
	})

	var adunitId;
	it("can register a new ad unit", function() {
		return advRegistry.registerItem(ADUNIT, 0, "foobar ad unit", "{}", 0x42, {
			from: accOne,
			gas: 230000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogItemRegistered')
			assert.equal(ev.args.itemType, ADUNIT);
			assert.equal(ev.args.id, 1)
			assert.equal(ev.args.name, 'foobar ad unit')
			assert.equal(ev.args.meta, '{}')
			assert.equal(ev.args.ipfs, '0x4200000000000000000000000000000000000000000000000000000000000000');
			assert.equal(ev.args.owner, accOne)

			adunitId = ev.args.id.toNumber()

			// TODO check all ad units for an account after
		})
	})
	it("can update an ad unit", function() {
		return advRegistry.registerItem(ADUNIT, adunitId, "foobar campaign", "{ someMeta: 's' }", 0x45, {
			from: accOne,
			gas: 230000
		}).then(function(res) {
			var ev = res.logs[0]
			if (! ev) throw 'no event'
			assert.equal(ev.event, 'LogItemModified')
			assert.equal(ev.args.itemType, ADUNIT);
			assert.equal(ev.args.name, 'foobar campaign')
			assert.equal(ev.args.meta, "{ someMeta: 's' }")
			assert.equal(ev.args.ipfs, '0x4500000000000000000000000000000000000000000000000000000000000000');
			assert.equal(ev.args.id.toNumber(), adunitId)
			assert.equal(ev.args.owner, accOne)
		})
	})
	it("can't update another accounts' ad unit", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerItem(ADUNIT, adunitId, "foobar campaign", "{ someMeta: 'sx' }", 0x45, {
				from: web3.eth.accounts[3],
				gas: 230000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})			
		})
	})

	// TODO: also do some testing with properties

	// can drain ether: can't test that, because we can't send ether in the first place...
	// maybe figure out a way to test it?

	// TODO: can drain tokens if accidently sent

	// TODO: all the *get methods 
	// also test if they are callable for non-registered accounts

	it("can't send ether accidently", function() {
		return new Promise((resolve, reject) => {
			web3.eth.sendTransaction({
				from: accOne,
				to: advRegistry.address,
				value: 1*Math.pow(10,18),
				gas: 130000
			}, (err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	it("can get an account, account meta correct", function() {
		return advRegistry.getAccount(accOne)
		.then(function(res) {
			assert.equal(res[0], 'stremio')
			assert.equal(res[1], wallet)
			assert.equal(res[2], '{ "email": "office@strem.io" }')
		})
	})

	it("can get items for an acc", function() {
		return advRegistry.getAccountItems(accOne, ADUNIT)
		.then(function(res) {
			assert.equal(res.length, 1)
			assert.equal(res[0].toNumber(), adunitId)
		})
	})


	it("can get a single item", function() {
		return advRegistry.getItem(ADUNIT, adunitId)
		.then(function(res) {
			assert.equal(res[0], 'foobar campaign')
			assert.equal(res[1], "{ someMeta: 's' }")
			assert.equal(res[2], '0x4500000000000000000000000000000000000000000000000000000000000000')
			assert.equal(res[3], accOne)
		})
	})


	it("hasItem - item exists", function() {
		return advRegistry.hasItem(ADUNIT, adunitId)
		.then(function(res) {
			assert.equal(res, true)
		})
	})

	it("hasItem - item does not exist", function() {
		return advRegistry.hasItem(ADUNIT, 24135)
		.then(function(res) {
			assert.equal(res, false)
		})
	})
})
