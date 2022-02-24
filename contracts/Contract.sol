pragma solidity ^0.8.12;

contract CompetitionBetweenTwo {
    struct Wager {
        bytes32 identifier; // can use string, but bytes32 is cheaper=
        address[2] players;
        uint bet;
    }

    struct GameHistory {
        Wager wager;
        address winner;
    }


    uint public initialSupply = 100000 * 10**18;
    string public symbol = 'FooBarFights';
    address public referee; // This is 


    mapping(address => uint) public balances;
    mapping(bytes32 => Wager) public activeWagers;
    GameHistory[] public history;
    

    constructor() {
        // Permanent owner of contract
        referee = msg.sender;
        balances[msg.sender] = initialSupply;
    }

    event gameStarted(Wager dual);
    event gameEnded(address indexed winner, bytes32 indexed identifier, uint indexed bet);

    function hasAmount(address owner, uint amount) private view returns(bool) {
       return balances[owner] > amount;
    }

    function isRefereeTransaction() private view returns(bool) {
        return msg.sender == referee;
    }

    function hashTwoAddresses(address a1, address a2) private pure returns(bytes32) {
        return sha256(abi.encodePacked(a1, a2));
    }

    function sendTo(address target, uint amount) public {
        require(isRefereeTransaction(), "Invalid transaction");
        require(hasAmount(msg.sender, amount), "Balance too low");
        require(msg.sender != target, "Dont be dumb! Sending to yourself is a waste of precious GWEI");

        balances[target] += amount;
        balances[msg.sender] -= amount;
    }

    function newGame(address pl1, address pl2, uint bet) public {
        require(isRefereeTransaction(), "Invalid transaction");
        bytes32 hashString = hashTwoAddresses(pl1, pl2);
        Wager memory game = activeWagers[hashString];

        // Dont want to have players start games. No rage quitting
        require(game.bet == 0, "A game is already in progress");

        // Players both need to lock up some moola. They cant be broke bro
        require(hasAmount(pl1, bet), "Player 1 balance is too low");
        require(hasAmount(pl2, bet), "Player 2 balance is too low");

        // Create a game, return identifier
        activeWagers[hashString] = Wager({
            identifier: hashString,
            players: [pl1, pl2],
            bet: bet
        });

        // Lock up player balance
        balances[pl1] -= bet;
        balances[pl2] -= bet;

        emit gameStarted(activeWagers[hashString]);
    }

    function endGame(address winner, bytes32 identifier) public {
        // Sender must be referee
        require(isRefereeTransaction(), "Invalid transaction");
        Wager memory game = activeWagers[identifier];
        // Can only submit one winner, once
        // Identifier must be valid
        require(game.bet > 0, "Game does not exist");

        // We need to notify for Blockchain to record event, interact with external APIs
        balances[winner] += (game.bet * 2);
        history.push(GameHistory({
            wager: game,
            winner: winner
        }));
        delete activeWagers[identifier];

        emit gameEnded(winner, identifier, game.bet);
    }
}

// What we do
// Transfer balances to x2 addresses
// Check balance of referee, and x2 addresses
// Start a wager between the addresses
// Declare a winner
// Check the address balances

