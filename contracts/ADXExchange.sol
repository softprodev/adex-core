pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXExchange {
	// XXX: use typedef for id's

	
	address token;
	address pubRegistry;
	address advRegistry;

	mapping (address => Bid) bidsById;
	mapping (address => Bid) bidsByAdvertiser; // bids set out by advertisers
	mapping (address => Bid) bidsByPublisher; // accepted by publisher

	enum BidState { 
		Open, 
		Accepted, // in progress

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
		address advertiserWallet;

		// Links on publisher side
		address publisher;
		bytes32 channel;
		bytes32 adProperty;
		address publisherWallet;

		uint acceptedDate; // when was it accepted by a publisher

		// Requirements
		uint requiredGoals;
		uint requiredAcceptTime; // XXX: do we need this? advertisers can give up the bids themslevs is state is Open
		uint requiredExecTime;

		// margin of error against the state channel (append-only stats DB)
		// a min threshold for that is good, but better protect the users from themselves in the dapp rather than the SC
		uint acceptableMarginOfError;

		// Results
		uint achievedGoals;
	}

	modifier onlyRegisteredAdvertiser
	modifier onlyRegisteredPublisher

	function setAddresses(address _token, address _pubRegistry, address _advRegistry) onlyOwner {
		token = _token;
		pubRegistry = _pubRegistry;
		advRegistry = _advRegistry;
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

	function revokeAndRefundBid(Bid bid, BidState newState) internal {
		// evaluate if existing state is sane (possible to refund)

		// set bid state
		// evaluate if newState is Canceled or Expired

		// allow newState to be Canceled only if current state is Open
		// allow newState to be Expired only if current state is Accepted

		bid.state = newState;
		token.transfer(bid.advertiserWallet, bid.amount);
	}
}

