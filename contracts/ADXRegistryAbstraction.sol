pragma solidity ^0.4.13;

contract Registry {
	string public name;

	function isRegistered(address _addr)
		public
		constant
		returns (bool)
	{
		return _addr != 0; // hackish in order to avoid "_addr not used" warning
	}
}

