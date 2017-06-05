pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXExchange {
	address tokenAddr = hex"";

	mapping (address => Bid) bidsById;
	mapping (address => Bid) bidsByAdvertiser; // bids set out by advertisers
	mapping (address => Bid) bidsByPublisher; // accepted by publisher

	enum BidState { 
		Open, 
		Accepted, 
		Executing, // in progress states
		Expired, Canceled, // fail states
		Completed // success states
	}

	struct Bid {
		bytes32 id;
		BidState state;

		// ADX amount
		uint amount;

		// Links on advertiser side
		address advertiser;
		bytes32 campaign;

		// Links on publisher side
		address publisher;
		bytes32 channel;
		bytes32 adProperty;
	}

	function changeTokenAddr() onlyOwner {

	}


	function changePubRegistryAddr() onlyOwner {
		// TODO
	}

	function changeAdvRegistryAddr() onlyOwner {
		// TODO
	}
}

