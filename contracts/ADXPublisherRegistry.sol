pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./helpers/Drainable.sol";
import "./ADXRegistryAbstraction.sol";

contract ADXPublisherRegistry is Ownable, Drainable, Registry {
	// Structure:
	// Publishers
	// 		Channels (e.g. website/app)
	//			Properties (particular advertising spaces)
	// Publishers are linked to Channels 
	// Publishers are linked to Properties
	// Channels are linked to Properties
	// everything is saved at the top-level and accessible by ID
	
	string public name = "AdEx Publisher Registry";

	mapping (address => Publisher) public publishers;
	mapping (bytes32 => Channel) public channelsById;
	mapping (bytes32 => Property) public propertiesById;

	struct Publisher {
		address publisherAddr;
		string name;
		string meta;
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

	modifier publisherExists() { require(publishers[msg.sender].publisherAddr != 0); _; }
	modifier publisherNotExists() { require(publishers[msg.sender].publisherAddr == 0); _; }

	// modifier channelExists() { require(channelsById[which].id); _; }
	// modifier channelNotExists() { require(!channelsById[which].id); _; }

	// modifier propertyExists() { require(propertiesById[which].id); _; }
	// modifier propertyNotExists() { require(!propertiesById[which].id); _; }

	function isRegistered(address _who)
		external
		constant 
		returns (bool)
	{
		return publishers[_who].publisherAddr != 0;
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

	function unregisterProperty(bytes32 id) 
		publisherExists 
		external
	{
		Property prop = propertiesById[id];
		require(prop.id != 0);

		delete propertiesById[id];
		delete channelsById[prop.channelId].properties[id];
		delete publishers[prop.publisherAddr].properties[id];
	}

	// event LogPublisherRegistered();
	// event LogChannelRegistered();
	// event LogPropertyRegistered();
}
