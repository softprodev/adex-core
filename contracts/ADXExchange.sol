pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../zeppelin-solidity/contracts/math/SafeMath.sol";
import "./helpers/Drainable.sol";
import "../zeppelin-solidity/contracts/token/ERC20.sol";
import "./ADXRegistryAbstraction.sol";

contract ADXExchange is Ownable, Drainable {

	ERC20 token;
	Registry pubRegistry;
	Registry advRegistry;

	mapping (bytes32 => Bid) bidsById;
	mapping (address => mapping (bytes32 => Bid)) bidsByAdvertiser; // bids set out by advertisers
	mapping (address => mapping (bytes32 => Bid)) bidsByPublisher; // accepted by publisher

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

		// ADX reward amount
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
		//RequirementType type;
		uint requiredPoints; // how many impressions/clicks/conversions have to be done
		uint requiredExecTime;

		// margin of error against the state channel (append-only stats DB)
		// a min threshold for that is good, but better protect the users from themselves in the dapp rather than the SC
		uint acceptableMarginOfError;

		// Results
		uint achievedPoints;

		// Additional payload
		bytes32[] payload;

		// State channel peers
		bytes32[] peers;
	}

	modifier onlyRegisteredAdvertiser() { require(advRegistry.isRegistered(msg.sender)); _; }
	modifier onlyRegisteredPublisher() { require(pubRegistry.isRegistered(msg.sender)); _;  }

	modifier onlyBidOwner(bytes32 bidId) { require(msg.sender == bidsById[bidId].advertiser); _; }
	modifier existingBid(bytes32 bidId) { require(bidsById[bidId].id != 0); _; }

	// Functions

	function setAddresses(address _token, address _pubRegistry, address _advRegistry) onlyOwner {
		token = ERC20(_token);
		pubRegistry = Registry(_pubRegistry);
		advRegistry = Registry(_advRegistry);
	}

	//
	// Bid actions
	// 

	function placeBid() onlyRegisteredAdvertiser  {

		// ADXToken.transferFrom(advertiserWallet, ourAddr)
		// if that succeeds, we passed that THIS amount of ADX has been locked in the bid
	}

	function cancelBid(bytes32 _bidId) 
		onlyRegisteredAdvertiser
		onlyBidOwner(_bidId)
		existingBid(_bidId) 
	{
		
	}

	function acceptBid(bytes32 _bidId) 
		onlyRegisteredPublisher 
		existingBid(_bidId) 
		//openBid(bidId) 
	{

	}

	// both publisher and advertiser have to call this for a bid to be considered verified; it has to be within margin of error
	function verifyBid(bytes32 _bidId) 
		existingBid(_bidId)
	{

	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(bytes32 _bidId)
		onlyRegisteredAdvertiser
		onlyBidOwner(_bidId)
	{

	}

	function revokeAndRefundBid(Bid bid, BidState newState)
		internal
	{
		// evaluate if existing state is sane (possible to refund)

		// set bid state
		// evaluate if newState is Canceled or Expired

		// allow newState to be Canceled only if current state is Open
		// allow newState to be Expired only if current state is Accepted

		bid.state = newState;
		//token.transfer(bid.advertiserWallet, bid.amount);
	}

	//
	// Public constant functions
	//

	function getBids()
		constant
		external
	{

	}

	//
	// Events
	//
	event LogBidOpened(bytes32 _bidId);
	event LogBidAccepted(bytes32 _bidId);
	event LogBidCanceled(bytes32 _bidId);
	event LogBidExpired(bytes32 _bidId);
	event LogBidCompleted(bytes32 _bidId);
}

