pragma solidity ^0.4.11;

contract mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */
    function mortal() { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract AdXtokens is mortal, owned {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public sellPrice;
    uint256 public buyPrice;

    
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function AdXtokens(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        buyPrice = 500;
        sellPrice = 400;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
    
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

   function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It's important
            throw;                                         // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }               
    }
    
   function () {
        throw;     // Prevents accidental sending of ether
    }
}