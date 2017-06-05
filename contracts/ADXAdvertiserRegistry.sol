pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXAdvertiserRegistry is Ownable {

	// Structure:
	// Advertisers
	// 		Campaigns - particular advertising campaigns
	//		Ad Units - particular ad units 
	// Advertisers are linked to Campaigns
	// Advertisers are linked to Ad Units
	// Campaigns are linked to Ad units, but one ad unit can be re-used in many campaigns

	mapping (address => Advertiser) advertisers;
	mapping (bytes32 => Campaign) campaigns;
	mapping (bytes32 => AdUnit) adunits;

	struct Advertiser {
		address advertiserAddr;
		string name;
		address walletAddr;

	}
}
