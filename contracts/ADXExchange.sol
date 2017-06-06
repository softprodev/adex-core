pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXExchange {
	// XXX: use typedef for id's

	address tokenAddr = hex"";

	mapping (address => Bid) bidsById;
	mapping (address => Bid) bidsByAdvertiser; // bids set out by advertisers
	mapping (address => Bid) bidsByPublisher; // accepted by publisher

	enum BidState { 
		Open, 
		Accepted, 
		Executing, // in progress states

		// the following states MUST unlock the ADX amount (return to advertiser)
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
		address publisherWallet;

		uint acceptedDate; // whne it's accepted by a publisher

		// Requirements
		uint requiredGoals;
		uint requiredAcceptTime; // XXX: do we need this? advertisers can give up the bids themslevs is state is Open
		uint requiredExecTime;

		// margin of error against the state channel (append-only stats DB)
		// a min threshold for that is good, but better protect the users from themselves in the dapp rather than the SC
		uint requiredMarginOfError;

		// Results
		uint achievedGoals;
	}

	modifier onlyRegisteredAdvertiser
	modifier onlyRegisteredPublisher

	function changeTokenAddr() onlyOwner {

	}


	function changePubRegistryAddr() onlyOwner {
		// TODO
	}

	function changeAdvRegistryAddr() onlyOwner {
		// TODO
	}

	//
	// Bid actions
	// 

	function placeBid() onlyRegisteredAdvertiser  {

		// ADXToken.transferFrom(advertiserWallet, ourAddr)
		// if that succeeds, we passed that THIS amount of ADX has been locked in the bid
	}

	function cancelBid(bytes32 bidId) onlyRegisteredAdvertiser onlyBidOwner(bidId) existingBid {
		
	}

	function acceptBid() onlyRegisteredPublisher existingBid openBid {

	}

	// both publisher and advertiser have to call this for a bid to be considered verified; it has to be within margin of error
	function verifyBid() existingBid {

	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid() onlyRegisteredAdvertiser onlyBidOwner {

	}

}

