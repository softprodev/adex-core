pragma solidity ^0.4.11;

include "../zeppelin-solidity/contracts/ownership/Ownable.sol"

contract ADXUserRegistry is Ownable {
	mapping (address => User) users;

	struct User {
		bytes32 uid;
		address walletAddr;

	}
}
