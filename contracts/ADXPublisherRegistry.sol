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
	mapping (uint => Channel) public channels;
	mapping (uint => Property) public properties;

	struct Publisher {
		address publisherAddr;
		string name;
		string meta;
		address walletAddr;

		// by id
		uint[] channels;
		uint[] properties;
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

	//
	// Modifiers
	//
	modifier onlyRegisteredPublisher() { 
		var pub = publishers[msg.sender];
		require(pub.publisherAddr != 0); 
		_; 
	}

	// 
	// Functions that modify state
	//

	// can be called over and over to update the data
	function registerAsPublisher(string _name, address _wallet, string _meta)
		external
	{
		require(_wallet != 0);

		var isNew = publishers[msg.sender].publisherAddr == 0;

		var pub = publishers[msg.sender];
		pub.publisherAddr = msg.sender;
		pub.name = _name;
		pub.walletAddr = _wallet;
		pub.meta = _meta;

		// if (isNew) LogAdvertiserRegistered(adv.advertiserAddr, adv.walletAddr, adv.name, adv.meta);
		// else LogAdvertiserModified(adv.advertiserAddr, adv.walletAddr, adv.name, adv.meta);
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
