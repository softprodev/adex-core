pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXPublisherRegistry is Ownable {

	// Structure:
	// Publishers
	// 		Channels (e.g. website/app)
	//			Properties (particular advertising spaces)
	// Publishers are linked to Channels 
	// Publishers are linked to Properties
	// Channels are linked to Properties 
	// everything is saved at the top-level and accessible by ID

	mapping (address => Publisher) publishers;
	mapping (bytes32 => Channel) channelsById;
	mapping (bytes32 => Property) propertiesById;

	struct Publisher {
		address publisherAddr;
		string name;
		string website;
		string email;
		address walletAddr;

		mapping (bytes32 => Channel) channels;
		mapping (bytes32 => Property) properties;
	}


	struct Channel {
		bytes32 id;
		string name;
		string type; // XXX: could be enum, but this is more flexible

		mapping (bytes32 => Property) properties;

	}

	struct Property {
		bytes32 id;
		string name;
		string type; // XXX: could be enum, but this is more flexible


	}

	modifier publisher_exists
	modifier publisher_not_exists

	modifier channel_exists
	modifier channel_not_exists

	modifier property_exists
	modifier property_not_exists

	function registerPublisher

	function updatePublisher

	function registerChannel

	function registerProperty

	function unregisterChannel

	function unregisterProperty
}
