pragma solidity ^0.4.11;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";

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

	//enum ChannelType { Web, Mobile, Desktop }

	struct Channel {
		bytes32 id;
		string name;
		string description;
		//ChannelType type;
		string subtype;

		mapping (bytes32 => Property) properties;

		address publisherAddr;
	}

	//struct PropertyType {  } // TODO

	struct Property {
		bytes32 id;
		string name;
		string description;
		//PropertyType type; // TODO

		address publisherAddr;
		bytes32 channelId;
	}

	modifier publisherExists() { if (publishers[msg.sender].publisherAddr == 0) throw; _; }
	modifier publisherNotExists() { if (publishers[msg.sender].publisherAddr != 0) throw; _; }

	// modifier channelExists() { if (! channelsById[which].id) throw; _; }
	// modifier channelNotExists() { if (channelsById[which].id) throw; _; }

	// modifier propertyExists() { if (! propertiesById[which].id) throw; _; }
	// modifier propertyNotExists() { if (propertiesById[which].id) throw; _; }

	function isRegistered(address who) external returns (bool) {
		return publishers[who].publisherAddr != 0;
	}

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
		if (prop.id == 0) throw;

		delete propertiesById[id];
		delete channelsById[prop.channelId].properties[id];
		delete publishers[prop.publisherAddr].properties[id];
	}

	// event PublisherRegistered();
	// event ChannelRegistered();
	// event PropertyRegistered();
}
