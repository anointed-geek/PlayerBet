pragma solidity ^0.8.11;

struct GameInProgress {
    string identifier;
    address player1;
    address player2;
    uint bet;
}

struct GameComplete {
    string identifier;
    address player1;
    address player2;
    uint bet;
    address winner;
}

contract PlayerBet {
    mapping(address => uint) public balances;
    mapping(string => GameInProgress) public activeGames;
    GameComplete[] public history;
    address public referee;

    constructor() {
        // Permanent owner of contract
        referee = msg.sender;
        balances[msg.sender] = 10000;
    }

    event gameStarted(GameInProgress game);
    event gameEnded(address indexed winner, string indexed identifier, uint indexed bet);

    function hasAmount(address owner, uint amount) private returns(bool) {
       return balances[owner] > amount;
    }

    function isRefereeTransaction() private returns(bool) {
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
        string memory hashString = string(abi.encodePacked(hashTwoAddresses(pl1, pl2)));
        GameInProgress memory game = activeGames[hashString];

        // Dont want to have players start games. No rage quitting
        require(game.bet == 0, "A game is already in progress");

        // Players both need to lock up some moola. They cant be broke bro
        require(hasAmount(pl1, bet), "Player 1 balance is too low");
        require(hasAmount(pl2, bet), "Player 2 balance is too low");

        // Create a game, return identifier
        activeGames[hashString] = GameInProgress({
            identifier: hashString,
            player1: pl1,
            player2: pl2,
            bet: bet
        });

        // Lock up player balance
        balances[pl1] -= bet;
        balances[pl2] -= bet;

        emit gameStarted(activeGames[hashString]);
    }

    function endGame(address winner, string memory identifier) public {
        // Sender must be referee
        require(isRefereeTransaction(), "Invalid transaction");
        GameInProgress memory game = activeGames[identifier];
        // Can only submit one winner, once
        // Identifier must be valid
        require(game.bet > 0, "Game does not exist");

        // We need to notify for Blockchain to record event, interact with external APIs
        balances[winner] += (game.bet * 2);
        history.push(GameComplete({
            identifier: game.identifier,
            player1: game.player1,
            player2: game.player2,
            bet: game.bet,
            winner: winner
        }));
        delete activeGames[identifier];

        emit gameEnded(winner, identifier, game.bet);
    }
}
