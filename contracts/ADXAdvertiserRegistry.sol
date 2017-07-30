pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./helpers/Drainable.sol";
import "./ADXRegistryAbstraction.sol";

contract ADXAdvertiserRegistry is Ownable, Drainable, Registry {
	// Structure:
	// Advertisers
	// 		Campaigns - particular advertising campaigns
	//		Ad Units - particular ad units 
	// Advertisers are linked to Campaigns
	// Advertisers are linked to Ad Units
	// Ad units are linked to Campaigns, and one ad unit can be linked to multiple campaigns

	string public name = "AdEx Advertiser Registry";

	uint public campaignsCount;
	uint public adUnitsCount;

	mapping (address => Advertiser) public advertisers;
	mapping (uint => Campaign) public campaigns;
	mapping (uint => AdUnit) public adunits;

	struct Advertiser {		
		address advertiserAddr;
		string name;
		address walletAddr;
		string meta;
	
		mapping (uint => Campaign) campaigns;
		mapping (uint => AdUnit) adunits;
	}

	struct Campaign {
		uint id;
		address owner; // the advertiser who owns the campaign

		string name;
		string meta;
	}

	struct AdUnit {
		uint id;
		address owner;  // the advertiser who owns the ad unit

		bytes32 metaIpfsAddr; // ipfs addr of meta for this ad unit
		
		bytes32[] targeting; // any meta that may be relevant to the targeting, in an AdEx-specific format

		uint[] campaignIds;
	}

	modifier onlyRegisteredAdvertiser() {
		var adv = advertisers[msg.sender];
		require(adv.advertiserAddr != 0);
		_;
	}

	function isRegistered(address who)
		external 
		constant
		returns (bool)
	{
		var adv = advertisers[who];
		return adv.advertiserAddr != 0;
	}

	// can be called over and over to update the data
	// XXX consider entrance barrier, such as locking in some ADX
	function registerAsAdvertiser(string _name, address _wallet, string _meta)
		external
	{
		require(_wallet != 0);

		var isNew = advertisers[msg.sender].advertiserAddr == 0;

		var adv = advertisers[msg.sender];
		adv.advertiserAddr = msg.sender;
		adv.name = _name;
		adv.walletAddr = _wallet;
		adv.meta = _meta;

		if (isNew) LogAdvertiserRegistered(adv.advertiserAddr, adv.walletAddr, adv.name, adv.meta);
		else LogAdvertiserModified(adv.advertiserAddr, adv.walletAddr, adv.name, adv.meta);
	}

	// use _id = 0 to create a new campaign, otherwise modify existing
	function registerCampaign(uint _id, string _name, string _meta)
		onlyRegisteredAdvertiser
	{
		Campaign campaign;

		if (_id == 0) {
			campaignsCount++;
			campaign = campaigns[campaignsCount];
			campaign.id = campaignsCount;
			campaign.owner = msg.sender;
		}

		require(campaign.owner == msg.sender);

		campaign.name = _name;
		campaign.meta = _meta;

		advertisers[msg.sender].campaigns[campaign.id] = campaign;

		if (_id == 0) LogCampaignRegistered(campaign.id, campaign.name, campaign.meta);
		else LogCampaignModified(campaign.id, campaign.name, campaign.meta);
	}

	// use _id = 0 to create a new ad unit, otherwise modify existing
	function registerAdUnit(uint _id, bytes32 _metaIpfsAddr, bytes32[] _targeting, uint[] _campaignIds)
		onlyRegisteredAdvertiser 
	{
		AdUnit unit;

		if (_id == 0) {
			adUnitsCount++;
			unit = adunits[adUnitsCount];
			unit.id = adUnitsCount;
			unit.owner = msg.sender;
		}

		require(unit.owner == msg.sender);

		unit.metaIpfsAddr = _metaIpfsAddr;
		unit.targeting = _targeting;
		unit.campaignIds = _campaignIds;

		advertisers[msg.sender].adunits[unit.id] = unit;

		if (_id == 0) LogAdUnitRegistered(unit.id, unit.metaIpfsAddr, unit.targeting);
		else LogAdUnitModified(unit.id, unit.metaIpfsAddr, unit.targeting);
	}

	// NOTE
	// There's no real point of un-registering campaigns and ad units 
	// Campaigns need to be kept anyway, as well as ad units
	// END NOTE

	// Constant functions
	function getMyCampaigns()
		onlyRegisteredAdvertiser
		constant
	{

	}

	function getMyAdUnits()
		onlyRegisteredAdvertiser
		constant
	{

	}

	function getMyAdUnitsForCampaign()
		onlyRegisteredAdvertiser
		constant
	{

	}

	// Events
	event LogAdvertiserRegistered(address addr, address wallet, string name, string meta);
	event LogAdvertiserModified(address addr, address wallet, string name, string meta);
	
	event LogCampaignRegistered(uint id, string name, string meta);
	event LogCampaignModified(uint id, string name, string meta);

	event LogAdUnitRegistered(uint id, bytes32 metaIpfsAddr, bytes32[] targeting);
	event LogAdUnitModified(uint id, bytes32 metaIpfsAddr, bytes32[] targeting);
	// ... modified event for everything
}
