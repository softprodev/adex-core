pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./helpers/Drainable.sol";

contract ADXAdvertiserRegistry is Ownable, Drainable {
	// Structure:
	// Advertisers
	// 		Campaigns - particular advertising campaigns
	//		Ad Units - particular ad units 
	// Advertisers are linked to Campaigns
	// Advertisers are linked to Ad Units
	// Campaigns are linked to Ad units, and one ad unit can be re-used in many campaigns
	// Ad units are linked to Campaigns, and one campaign can be linked to multiple ad units

	mapping (address => Advertiser) public advertisers;
	mapping (bytes32 => Campaign) public campaigns;
	mapping (bytes32 => AdUnit) public adunits;

	struct Advertiser {		
		address advertiserAddr;
		string name;
		address walletAddr;
	
		mapping (bytes32 => Campaign) campaigns;
		mapping (bytes32 => AdUnit) adunits;
	}

	struct Campaign {
		bytes32 id;
		string name;
		mapping (bytes32 => AdUnit) adunits;
	}

	struct AdUnit {
		bytes32 id;
		
		bytes32 metaIpfsAddr; // ipfs addr of meta for this ad unit
		
		bytes32[] targeting; // any meta that may be relevant to the targeting, in an AdEx-specific format

		mapping (bytes32 => Campaign) campaigns;
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
	function registerAsAdvertiser(string _name, address _wallet) external
	{
		var adv = advertisers[msg.sender];
		adv.advertiserAddr = msg.sender;
		adv.name = _name;
		adv.walletAddr = _wallet;
	}

	function registerCampaign() onlyRegisteredAdvertiser {

	}

	function unregisterCampaign() onlyRegisteredAdvertiser {

	}

	function registerAdUnit() onlyRegisteredAdvertiser {

	}

	function unregisterAdUnit() onlyRegisteredAdvertiser {

	}


	// event LogAdvertiserRegistered();
	// event LogCampaignRegistered();
	// event LogAdUnitRegistered();
}
