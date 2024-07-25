// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RockPaperScissors is Ownable(msg.sender) {
    event PlayMoveCommitted(uint256 indexed partyId, address indexed caller);
    event PlayMoveRevealed(uint256 indexed partyId, address indexed caller);
    event WinGame(uint256 indexed partyId, address indexed winner);
    event PartyCreated(uint256 indexed partyId);
    event PartyJoined(uint256 indexed partyId, address indexed caller);
    event PartyCanceled(uint256 indexed partyId, address indexed caller);

    uint256 public constant wei2Eth = 10 ** 18;
    uint256 public priceToPlay = 1 * wei2Eth; // Price to play or join a party
    uint256 public priceToWin = (3 * wei2Eth) / 2; // Winner's prize
    uint256 public timeToCommit = 60; 
    uint256 public timeToReveal = 60; 

    struct Player {
        uint256 totalWin;
        uint256 totalLoose;
    }

    struct Party {
        uint256 timeCreated;
        uint256 timeBegan;
        uint256 timeCommitted;
        bytes1 choiceCreator;
        bytes1 choiceOtherPlayer;
        address winner;
        bool available;
        string state;
        mapping(address => bytes32) players;
        address[] playerId;
    }

    mapping(bytes1 => bytes1) public beatenBy;
    mapping(address => Player) public players;
    mapping(uint256 => Party) public parties;
    uint256[] public partiesId;

    constructor() {
        beatenBy["1"] = "2";
        beatenBy["2"] = "3";
        beatenBy["3"] = "1";
    }

    modifier hasMoney() {
        require(msg.value == priceToPlay, "You Should Pay More!");
        _;
    }

    modifier canPlay(uint256 partyId) {
        require(parties[partyId].players[msg.sender] != 0x00, "You Can't Play in This Party");
        _;
    }

    modifier validState(uint256 partyId, string memory state) {
        require(keccak256(abi.encodePacked((parties[partyId].state))) == keccak256(abi.encodePacked((state))), "Invalid State!");
        _;
    }

    function createPlayer() public {
        players[msg.sender] = Player(0, 0);
    }

    function getInfoPlayerByAddress(address player) public view returns (uint256, uint256) {
        return (players[player].totalWin, players[player].totalLoose);
    }

    function createParty() public payable hasMoney {
        Party storage party = parties[partiesId.length];
        party.timeCreated = block.timestamp;
        party.available = true;
        party.state = "created";
        partiesId.push(partiesId.length);
        party.players[msg.sender] = bytes32("n");
        party.playerId.push(msg.sender);
        emit PartyCreated(partiesId.length - 1);
    }

    function cancelParty(uint256 partyId) public validState(partyId, "created") {
        require(msg.sender == parties[partyId].playerId[0], "You are not the Creator of This Party");
        parties[partyId].available = false;
        parties[partyId].state = "over";
        payable(msg.sender).transfer(priceToPlay);
        emit PartyCanceled(partyId, msg.sender);
    }

    function getInfoPartyById(uint256 partyId) public view returns (uint256, uint256, string memory, bool) {
        Party storage party = parties[partyId];
        return (party.timeCreated, party.timeBegan, party.state, party.available);
    }

    function joinParty(uint256 partyId) public payable hasMoney validState(partyId, "created") {
        require(parties[partyId].available == true, "Party is not available");
        Party storage party = parties[partyId];
        party.available = false;
        party.timeBegan = block.timestamp;
        party.players[msg.sender] = bytes32("n");
        party.playerId.push(msg.sender);
        party.state = "joined";
        emit PartyJoined(partyId, msg.sender);
    }

    function playMoveCommit(bytes32 choiceHash, uint256 partyId) public canPlay(partyId) validState(partyId, "joined") {
        require(parties[partyId].timeBegan + timeToCommit > block.timestamp, "Too Late To Commit");
        Party storage party = parties[partyId];
        party.players[msg.sender] = choiceHash;
        if (party.players[party.playerId[0]] != bytes32("n") && party.players[party.playerId[1]] != bytes32("n")) {
            party.state = "committed";
            party.timeCommitted = block.timestamp;
        }
        emit PlayMoveCommitted(partyId, msg.sender);
    }

    function playMoveReveal(string memory choice, uint256 partyId) public canPlay(partyId) validState(partyId, "committed") {
        require(parties[partyId].timeCommitted + timeToReveal > block.timestamp, "Too Late to Reveal");
        Party storage party = parties[partyId];
        require(party.players[msg.sender] == keccak256(abi.encodePacked(choice)), "Incorrect Reveal!");
        bytes memory byteChoiceStatus = bytes(choice);
        require(byteChoiceStatus[0] == "1" || byteChoiceStatus[0] == "2" || byteChoiceStatus[0] == "3", "Invalid Choice!");
        if (msg.sender == party.playerId[0]) {
            party.choiceCreator = byteChoiceStatus[0];
        } else {
            party.choiceOtherPlayer = byteChoiceStatus[0];
        }
        if (party.choiceOtherPlayer != 0x00 && party.choiceCreator != 0x00) {
            party.state = "revealed";
            determineWinner(partyId);
        }
        emit PlayMoveRevealed(partyId, msg.sender);
    }

    function determineWinner(uint256 partyId) internal {
        Party storage party = parties[partyId];
        if (party.choiceCreator == party.choiceOtherPlayer) {
            payable(party.playerId[0]).transfer(priceToPlay);
            payable(party.playerId[1]).transfer(priceToPlay);
        } else if (beatenBy[party.choiceCreator] == party.choiceOtherPlayer) {
            payable(party.playerId[1]).transfer(priceToWin);
            party.winner = party.playerId[1];
        } else {
            payable(party.playerId[0]).transfer(priceToWin);
            party.winner = party.playerId[0];
        }
        emit WinGame(partyId, party.winner);
    }

    function claimTimeout(uint256 partyId) public canPlay(partyId) {
        Party storage party = parties[partyId];
        require(keccak256(abi.encodePacked(party.state)) != keccak256(abi.encodePacked("over")), "The Party is Over!");
        address creator = party.playerId[0];
        address otherPlayer = party.playerId[1];

        if (block.timestamp > party.timeBegan + timeToCommit && keccak256(abi.encodePacked(party.state)) == keccak256(abi.encodePacked("joined"))) {
            if (party.players[creator] == bytes32("n") && party.players[otherPlayer] == bytes32("n")) {
                payable(creator).transfer(priceToPlay);
                payable(otherPlayer).transfer(priceToPlay);
                party.state = "over";
                party.available = false;
            } else if (party.players[creator] != bytes32("n") && party.players[otherPlayer] == bytes32("n")) {
                payable(creator).transfer(priceToWin);
                party.state = "over";
                party.available = false;
            } else if (party.players[creator] == bytes32("n") && party.players[otherPlayer] != bytes32("n")) {
                payable(otherPlayer).transfer(priceToWin);
                party.state = "over";
                party.available = false;
            }
        } else if (block.timestamp > party.timeCommitted + timeToReveal && keccak256(abi.encodePacked(party.state)) == keccak256(abi.encodePacked("committed"))) {
            if (party.choiceCreator == 0x00 && party.choiceOtherPlayer == 0x00) {
                payable(creator).transfer(priceToPlay);
                payable(otherPlayer).transfer(priceToPlay);
                party.state = "over";
                party.available = false;
            } else if (party.choiceCreator != 0x00 && party.choiceOtherPlayer == 0x00) {
                payable(creator).transfer(priceToWin);
                party.state = "over";
                party.available = false;
            } else if (party.choiceCreator == 0x00 && party.choiceOtherPlayer != 0x00) {
                payable(otherPlayer).transfer(priceToWin);
                party.state = "over";
                party.available = false;
            }
        }
    }

    function setPriceToPlay(uint256 price) public onlyOwner {
        priceToPlay = price;
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    function getTheWinner(uint256 partyId) public view returns (address) {
        return parties[partyId].winner;
    }
}
