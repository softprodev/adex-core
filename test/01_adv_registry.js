var ADXAdvertiserRegistry = artifacts.require("./ADXAdvertiserRegistry.sol");
var Promise = require('bluebird')
var time = require('../helpers/time')

contract('ADXAdvertiserRegistry', function(accounts) {

	var advRegistry 

	it("initialize contract", function() {
		return ADXAdvertiserRegistry.new().then(function(_advRegistry) {
			advRegistry = _advRegistry
		})
	});

	it("can't register a campaign w/o being an advertiser", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerCampaign(0, "test campaign", "{}", {
				from: web3.eth.accounts[0],
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	});

	it("can't register an ad unit w/o being an advertiser", function() {
		return new Promise((resolve, reject) => {
			advRegistry.registerAdUnit(0, 0, [], [], {
				from: web3.eth.accounts[0],
				gas: 130000
			}).catch((err) => {
				assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
				resolve()
			})
		})
	})

	// can register a new campaign
	// update existing campaign
	// can't update another advertiser's campaign

	// can register an ad unit
	// can update an existing ad unit
	// can't update another advertiser's ad unit
})