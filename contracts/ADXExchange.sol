pragma solidity ^0.4.13;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../zeppelin-solidity/contracts/math/SafeMath.sol";
import "./helpers/Drainable.sol";
import "../zeppelin-solidity/contracts/token/ERC20.sol";
import "./ADXRegistry.sol";

contract ADXExchange is Ownable, Drainable {
	string public name = "AdEx Exchange";

	ERC20 token;
	ADXRegistry registry;

	uint bidsCount;

	mapping (uint => Bid) bidsById;
	mapping (uint => uint[]) bidsByAdunit; // bids set out by ad unit
	mapping (uint => uint[]) bidsByAdslot; // accepted by publisher, by ad slot

	// TODO: some properties in the bid structure - requiredPoints/achievedPoints/peers for example - are not used atm
	
	// CONSIDER: the bid having a adunitType so that this can be filtered out
	// WHY IT'S NOT IMPORTANT: you can get bids by ad units / ad slots, which is filter enough already considering we know their types

	// CONSIDER: the possibility of advertiser/publisher canceling a bid after it's been accepted on mutual concent; e.g. they don't agree on the blacklisting conditions 
	// WHY IT'S NOT IMPORTANT: you can just wait it out... 

	// CONSIDER: locking ad units / ad slots or certain properties from them so that bids cannot be ruined by editing them
	// WHY IT'S NOT IMPORTANT: from a game theoretical point of view there's no incentive to do that

	// corresponds to enum types in ADXRegistry
	uint constant ADUNIT = 0;
	uint constant ADSLOT = 1;

	enum BidState { 
		Open, 
		Accepted, // in progress

		// the following states MUST unlock the ADX amount (return to advertiser)
		// fail states
		Canceled,
		Expired,

		// success states
		Completed,
		Claimed
	}

	struct Bid {
		uint id;
		BidState state;

		// ADX reward amount
		uint amount;

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

		uint acceptedTime; // when was it accepted by a publisher

		// Requirements
		//RequirementType type;
		uint requiredPoints; // how many impressions/clicks/conversions have to be done
		uint requiredExecTime; // essentially a timeout

		// Results
		uint achievedPoints;
		bool confirmedByPublisher;
		bool confirmedByAdvertiser;

		// State channel peers
		bytes32[] peers;
	}

	//
	// MODIFIERS
	//
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

	modifier onlyExistingBid(uint _bidId) {
		require(bidsById[_bidId].id != 0);
		_;
	}

	modifier unonlyExistingBid(uint _bidId) {
		require(bidsById[_bidId].id == 0);
		_;
	}

	// Functions

	function ADXExchange(address _token, address _registry)
	{
		token = ERC20(_token);
		registry = ADXRegistry(_registry);
	}

	//
	// Bid actions
	// 

	// the bid is placed by the advertiser
	function placeBid(uint _adunitId, uint _rewardAmount, uint _timeout)
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

		Bid memory bid;

		bid.id = ++bidsCount; // start from 1, so that 0 is not a valid ID
		bid.state = BidState.Open; // XXX redundant, but done for code clarity

		bid.amount = _rewardAmount;

		bid.advertiser = advertiser;
		bid.advertiserWallet = advertiserWallet;

		bid.adUnit = _adunitId;
		bid.adUnitIpfs = adIpfs;

		bid.requiredExecTime = _timeout;

		bidsById[bid.id] = bid;
		bidsByAdunit[_adunitId].push(bid.id);

		token.transferFrom(advertiserWallet, address(this), _rewardAmount);

		LogBidOpened(bid.id, advertiser, _adunitId, adIpfs, _rewardAmount, _timeout);
	}

	// the bid is canceled by the advertiser
	function cancelBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidOwner(_bidId)
		onlyBidState(_bidId, BidState.Open)
	{
		var bid = bidsById[_bidId];
		bid.state = BidState.Canceled;
		token.transfer(bid.advertiserWallet, bid.amount);

		LogBidCanceled(bid.id);
	}

	// a bid is accepted by a publisher for a given ad slot
	function acceptBid(uint _bidId, uint _slotId) 
		onlyRegisteredAcc 
		onlyExistingBid(_bidId) 
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

		bid.acceptedTime = now;

		bidsByAdslot[_slotId].push(_bidId);

		LogBidAccepted(bid.id, publisher, _slotId, adSlotIpfs);
	}

	// both publisher and advertiser have to call this for a bid to be considered verified
	function verifyBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
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
	// claimBidReward is a separate function so as to define clearly who pays the gas for transfering the reward 
	function claimBidReward(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidAceptee(_bidId)
		onlyBidState(_bidId, BidState.Completed)
	{
		var bid = bidsById[_bidId];
		
		bid.state = BidState.Claimed;

		token.transfer(bid.publisherWallet, bid.amount);

		LogBidRewardClaimed(bid.id, bid.publisherWallet, bid.amount);
	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidOwner(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		var bid = bidsById[_bidId];
		require(bid.requiredExecTime > 0); // you can't refund if you haven't set a timeout
		require(SafeMath.add(bid.acceptedTime, bid.requiredExecTime) < now);

		bid.state = BidState.Expired;
		token.transfer(bid.advertiserWallet, bid.amount);

		LogBidExpired(bid.id);
	}

	//
	// Public constant functions
	//

	function getBidsFromArr(uint[] arr, uint _state) 
		internal
		returns (uint[])
	{
		uint[] memory all;
		uint count;
		BidState state = BidState(_state);
		for (uint i = 0; i != arr.length; i ++ ) {
			var id = arr[i];
			var bid = bidsById[id];
			if (bid.state == state) {
				all[count] = id;
				count += 1;
			}
		}
		return all;
	}

	function getAllBidsByAdunit(uint _adunitId) 
		constant 
		external
		returns (uint[])
	{
		return bidsByAdunit[_adunitId];
	}

	function getBidsByAdunit(uint _adunitId, uint _state)
		constant
		external
		returns (uint[])
	{
		return getBidsFromArr(bidsByAdunit[_adunitId], _state);
	}

	function getAllBidsByAdslot(uint _adslotId) 
		constant 
		external
		returns (uint[])
	{
		return bidsByAdslot[_adslotId];
	}

	function getBidsByAdslot(uint _adslotId, uint _state)
		constant
		external
		returns (uint[])
	{
		return getBidsFromArr(bidsByAdslot[_adslotId], _state);
	}

	function getBid(uint _bidId) 
		onlyExistingBid(_bidId)
		constant
		external
		returns (uint _state, uint _reward)
	{
		// TODO: others
		var bid = bidsById[_bidId];
		return (uint(bid.state), bid.amount);
	}

	//
	// Events
	//
	event LogBidOpened(uint bidId, address advertiser, uint adunitId, bytes32 adunitIpfs, uint rewardAmount, uint timeout);
	event LogBidAccepted(uint bidId, address publisher, uint adslotId, bytes32 adslotIpfs);
	event LogBidCanceled(uint bidId);
	event LogBidExpired(uint bidId);
	event LogBidCompleted(uint bidId);
	event LogBidRewardClaimed(uint _bidId, address _wallet, uint _amount);
}

