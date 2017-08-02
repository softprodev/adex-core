pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../zeppelin-solidity/contracts/math/SafeMath.sol";
import "./helpers/Drainable.sol";
import "../zeppelin-solidity/contracts/token/ERC20.sol";
import "./ADXRegistry.sol";

contract ADXExchange is Ownable, Drainable {

	ERC20 token;
	ADXRegistry registry;

	uint bidsCount;

	mapping (uint => Bid) bidsById;
	mapping (address => mapping (uint => Bid)) bidsByAdvertiser; // bids set out by advertisers
	mapping (address => mapping (uint => Bid)) bidsByPublisher; // accepted by publisher

	// corresponds to enum types in ADXRegistry
	uint constant ADUNIT = 0;
	uint constant PROPERTY = 1;

	enum BidState { 
		Open, 
		Accepted, // in progress

		// the following states MUST unlock the ADX amount (return to advertiser)
		Expired, Canceled, // fail states
		Completed // success states
	}

	struct Bid {
		uint id;
		BidState state;

		// ADX reward amount
		uint amount;

		// whether it has been claimed
		bool blaimed;

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

	modifier onlyRegisteredAcc() {
		require(registry.isRegistered(msg.sender));
		_;
	}

	modifier onlyBidOwner(uint _bidId) {
		require(msg.sender == bidsById[_bidId].advertiser);
		_;
	}

	modifier onlyBidAceptee(uint _bidId) {
		require(msg.sender == bidsById[_bidId].publisher);
		_;
	}

	modifier onlyBidState(uint _bidId, BidState _state) {
		require(bidsById[_bidId].id != 0);
		require(bidsById[_bidId].state == _state);
		_;
	}

	modifier existingBid(uint _bidId) {
		require(bidsById[_bidId].id != 0);
		_;
	}

	modifier unexistingBid(uint _bidId) {
		require(bidsById[_bidId].id == 0);
		_;
	}

	// Functions

	function setAddresses(address _token, address _registry)
		onlyOwner 
	{
		token = ERC20(_token);
		registry = ADXRegistry(_registry);
	}

	//
	// Bid actions
	// 

	function placeBid(uint _adunitId)
		onlyRegisteredAcc
	{
		bytes32 adIpfs;

		// XXX: should we check ownership of the advertisement? there may be no point; why not allow advertisers place bids for other ad units; sounds like a feature
		address advertiser;
		// downside is, that will complicate msg.sender vs advertiser

		// NOTE: this will throw if the ad does not exist
		(,,adIpfs,advertiser) = registry.getItem(ADUNIT, _adunitId);

		// ADXToken.transferFrom(advertiserWallet, ourAddr)
		// if that succeeds, we passed that THIS amount of ADX has been locked in the bid
	}

	function cancelBid(uint _bidId) 
		onlyRegisteredAcc
		onlyBidOwner(_bidId)
		existingBid(_bidId)
		onlyBidState(_bidId, BidState.Open)
	{
		
	}

	function acceptBid(uint _bidId, uint _propId) 
		onlyRegisteredAcc 
		existingBid(_bidId) 
		onlyBidState(_bidId, BidState.Open)
	{
		//uint propertyId 
	}

	// both publisher and advertiser have to call this for a bid to be considered verified; it has to be within margin of error
	function verifyBid(uint _bidId)
		onlyRegisteredAcc
		existingBid(_bidId)
	{

	}

	// now, claim the reward; callable by the publisher; 
	function claimBidReward(uint _bidId)
		onlyRegisteredAcc
		existingBid(_bidId)
	{
		var bid = bidsById[_bidId];
		require(bid.publisher == msg.sender);
	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(uint _bidId)
		onlyRegisteredAcc
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

