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

	// TODO: active bids?
	// TODO: the bid having a adunitType so that this can be filtered out

	// corresponds to enum types in ADXRegistry
	uint constant ADUNIT = 0;
	uint constant ADSLOT = 1;

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

		// whether the reward has been claimed
		bool claimed;

		// Links on advertiser side
		address advertiser;
		address advertiserWallet;
		uint adUnit;
		bytes32 adUnitIpfs;

		// Links on publisher side
		address publisher;
		address publisherWallet;
		uint adSlot;
		bytes32 adSlotIpfs;

		uint acceptedDate; // when was it accepted by a publisher

		// Requirements
		//RequirementType type;
		uint requiredPoints; // how many impressions/clicks/conversions have to be done
		uint requiredExecTime;

		// Results
		uint achievedPoints;
		bool confirmedByPublisher;
		bool confirmedByAdvertiser;

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

	function placeBid(uint _adunitId, uint _rewardAmount)
		onlyRegisteredAcc
	{
		bytes32 adIpfs;
		address advertiser;
		address advertiserWallet;

		// NOTE: those will throw if the ad or respectively the account do not exist
		(advertiser,adIpfs,,) = registry.getItem(ADUNIT, _adunitId);
		(advertiserWallet,,,) = registry.getAccount(advertiser);

		// XXX: maybe it could be a feature to allow advertisers bidding on other advertisers' ad units, but it will complicate things...
		require(advertiser == msg.sender);

		Bid bid;

		bid.id = ++bidsCount; // start from 1, so that 0 is not a valid ID
		bid.state = BidState.Open; // XXX redundant, but done for code clarity

		bid.amount = _rewardAmount;

		bid.advertiser = advertiser;
		bid.advertiserWallet = advertiserWallet;

		bid.adUnit = _adunitId;
		bid.adUnitIpfs = adIpfs;

		bidsById[bid.id] = bid;
		bidsByAdvertiser[advertiser][bid.id] = bid;

		token.transferFrom(advertiserWallet, address(this), _rewardAmount);

		LogBidOpened(bid.id);
	}

	function cancelBid(uint _bidId)
		onlyRegisteredAcc
		onlyBidOwner(_bidId)
		existingBid(_bidId)
		onlyBidState(_bidId, BidState.Open)
	{
		var bid = bidsById[_bidId];
		bid.state = BidState.Canceled;
		token.transfer(bid.advertiserWallet, bid.amount);

		LogBidCanceled(bid.id);
	}

	function acceptBid(uint _bidId, uint _slotId) 
		onlyRegisteredAcc 
		existingBid(_bidId) 
		onlyBidState(_bidId, BidState.Open)
	{
		address publisher;
		address publisherWallet;
		bytes32 adSlotIpfs;

		// NOTE: those will throw if the ad slot or respectively the account do not exist
		(publisher,adSlotIpfs,,) = registry.getItem(ADSLOT, _slotId);
		(publisherWallet,,,) = registry.getAccount(publisher);

		require(publisher == msg.sender);

		var bid = bidsById[_bidId];

		// should not happen when bid.state is BidState.Open, but just in case
		require(bid.publisher == 0);

		bid.state = BidState.Accepted;
		
		bid.publisher = publisher;
		bid.publisherWallet = publisherWallet;

		bid.adSlot = _slotId;
		bid.adSlotIpfs = adSlotIpfs;

		bid.acceptedDate = now;

		bidsByPublisher[publisher][bid.id] = bid;

		LogBidAccepted(bid.id);
	}

	// both publisher and advertiser have to call this for a bid to be considered verified; it has to be within margin of error
	function verifyBid(uint _bidId)
		onlyRegisteredAcc
		existingBid(_bidId)
	{
		var bid = bidsById[_bidId];

		require(bid.publisher == msg.sender || bid.advertiser == msg.sender);

		if (bid.publisher == msg.sender) bid.confirmedByPublisher = true;
		if (bid.advertiser == msg.sender) bid.confirmedByAdvertiser = true;
		if (bid.confirmedByAdvertiser && bid.confirmedByPublisher) {
			bid.state = BidState.Completed;
			LogBidCompleted(bid.id);
		}
	}

	// now, claim the reward; callable by the publisher; 
	function claimBidReward(uint _bidId)
		onlyRegisteredAcc
		existingBid(_bidId)
		onlyBidAceptee(_bidId)
		onlyBidState(_bidId, BidState.Completed)
	{
		var bid = bidsById[_bidId];
		
		require(!bid.claimed);
		bid.claimed = true;

		token.transfer(bid.publisherWallet, bid.amount);
	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(uint _bidId)
		onlyRegisteredAcc
		onlyBidOwner(_bidId)
	{

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
	event LogBidOpened(uint _bidId);
	event LogBidAccepted(uint _bidId);
	event LogBidCanceled(uint _bidId);
	event LogBidExpired(uint _bidId);
	event LogBidCompleted(uint _bidId);
}

