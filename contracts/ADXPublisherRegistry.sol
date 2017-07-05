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



	enum ChannelType { Web, Mobile, Desktop }

	struct Channel {
		bytes32 id;
		string name;
		string description;
		ChannelType type;
		string subtype;

		mapping (bytes32 => Property) properties;

		bytes32 publisherId;
	}

	//struct PropertyType {  } // TODO

	struct Property {
		bytes32 id;
		string name;
		string description;
		//PropertyType type; // TODO

		bytes32 publisherId;
		bytes32 channelId;
	}

	modifier publisherExists
	modifier publisherNotExists

	modifier channelExists
	modifier channelNotExists

	modifier propertyExists
	modifier propertyNotExists

	function registerAsPublisher() publisherNotExists {

	}

	function updatePublisher() publisherExists {

	}

	function registerChannel() publisherExists {

	}


	function registerProperty() publisherExists {

	}

	function unregisterChannel() publisherExists {
		// MAKE SURE ALL PROPERTIES ARE UN-REGISTERED

	}

	function unregisterProperty(bytes32 id) publisherExists {
		Property prop = propertiesById[id];
		if (! prop) throw;

		delete propertiesById[id];
		delete channelsById[prop.channelId].properties[id];
		delete publishers[prop.publisherId].properties[id];
	}

	event PublisherRegistered();
	event ChannelRegistered();
	event PropertyRegistered();
}
