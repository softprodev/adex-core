pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./helpers/Drainable.sol";
import "./ADXRegistryAbstraction.sol";

contract ADXAdvertiserRegistry is Ownable, Drainable, Registry {
	string public name = "AdEx Registry";

	// Structure:
	// AdUnit (advertiser) - a unit of a single advertisement
	// Property (publisher) - a particular property that can display an ad unit
	// Campaign (advertiser) - group of ad units ; not vital
	// Channel (publisher) - group of properties ; not vital
	// Each Account is linked to all the items they own through the Account struct

	mapping (address => Account) public accounts;

	// XXX: mostly unused, because solidity does not allow mapping with enum as primary type.. :( we just use uint
    enum ItemType { AdUnit, Property, Campaign, Channel }

    // uint here corresponds to the ItemType
    mapping (uint => uint) public counts;
    mapping (uint => mapping (uint => Item)) public items;

	// Publisher or Advertiser (could be both)
	struct Account {		
		address addr;
		address wallet;

		string name;
		string meta;

		// Items, by type, then in an array of numeric IDs	
		mapping (uint => uint[]) items;
	}

	struct Item {
		uint id;
		address owner;

		ItemType itemType;

		string name; // name, 
		string meta; // metadata, can be JSON, can be other format, depends on the high-level implementation
		bytes32 ipfs; // ipfs addr for additional (larger) meta		
	}

	modifier onlyRegistered() {
		var acc = accounts[msg.sender];
		require(acc.addr != 0);
		_;
	}

	// can be called over and over to update the data
	// XXX consider entrance barrier, such as locking in some ADX
	function register(string _name, address _wallet, string _meta)
		external
	{
		require(_wallet != 0);

		var isNew = accounts[msg.sender].addr == 0;

		var acc = accounts[msg.sender];
		acc.addr = msg.sender;
		acc.name = _name;
		acc.wallet = _wallet;
		acc.meta = _meta;

		if (isNew) LogAccountRegistered(acc.addr, acc.wallet, acc.name, acc.meta);
		else LogAccountModified(acc.addr, acc.wallet, acc.name, acc.meta);
	}

	// use _id = 0 to create a new item, otherwise modify existing
	function registerItem(uint _type, uint _id, string _name, string _meta, bytes32 _ipfs)
		onlyRegistered
	{
		// XXX _type sanity check?

		var item = items[_type][_id];

		if (_id == 0) {
			// XXX: what about overflow here?
			var newId = ++counts[_type];

			item = items[_type][newId];
			item.id = newId;
			item.itemType = ItemType(_type);
			item.owner = msg.sender;

			accounts[msg.sender].items[_type].push(item.id);
		}

		require(item.owner == msg.sender);

		item.name = _name;
		item.meta = _meta;
		item.ipfs = _ipfs;

		if (_id == 0) LogItemRegistered(
			uint(item.itemType), item.id, item.name, item.meta, item.ipfs
		);
		else LogItemModified(
			uint(item.itemType), item.id, item.name, item.meta, item.ipfs
		);
	}

	// NOTE
	// There's no real point of un-registering items
	// Campaigns need to be kept anyway, as well as ad units
	// END NOTE

	//
	// Constant functions
	//

	function isRegistered(address who)
		public 
		constant
		returns (bool)
	{
		var acc = accounts[who];
		return acc.addr != 0;
	}

	// Functions exposed for web3 interface
	function getAccount(address _acc)
		constant
		public
		returns (string, address, string)
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return (acc.name, acc.wallet, acc.meta);
	}

	function getAccountItems(address _acc, uint _type)
		constant
		public
		returns (uint[])
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return acc.items[_type];
	}

	function getItem(uint _type, uint _id) 
		constant
		public
		returns (string, string, bytes32)
	{
		var item = items[_type][_id];
		require(item.id != 0);
		return (item.name, item.meta, item.ipfs);
	}

	// Events
	event LogAccountRegistered(address addr, address wallet, string name, string meta);
	event LogAccountModified(address addr, address wallet, string name, string meta);
	
	event LogItemRegistered(uint itemType, uint id, string name, string meta, bytes32 ipfs);
	event LogItemModified(uint itemType, uint id, string name, string meta, bytes32 ipfs);
}
