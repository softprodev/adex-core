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
		string channelType; // format: "primaryType:secondaryType" or "primaryType"; primaryType can be "web", "mobile", "desktop"

		mapping (bytes32 => Property) properties;

		address publisherAddr;
	}

	//struct PropertyType {  } // XXX consider this for future versions

	struct Property {
		bytes32 id;
		string name;
		string meta;

		bool active;

		address publisherAddr;
		bytes32 channelId;
	}

	modifier onlyRegisteredPublisher() { 
		var pub = publishers[msg.sender];
		require(pub.publisherAddr != 0); 
		_; 
	}

	function registerAsPublisher()
	{

	}

	function registerChannel()
		onlyRegisteredPublisher
	{

	}


	function registerProperty()
		onlyRegisteredPublisher
	{

	}

	//
	// Constant functions
	//

	function isRegistered(address _who)
		public
		constant 
		returns (bool)
	{
		return publishers[_who].publisherAddr != 0;
	}
	// event LogPublisherRegistered();
	// event LogChannelRegistered();
	// event LogPropertyRegistered();

	// TODO modified events

	// TODO: property activated / property de-activated
}
