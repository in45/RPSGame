const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RockPaperScissors", function () {
  let RockPaperScissors;
  let rockPaperScissors;
  let owner;
  let addr1;
  let addr2;
  let timeToCommit = 60;
  let timeToReveal = 60; 

  beforeEach(async function () {
    RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    [owner, addr1, addr2] = await ethers.getSigners();
    rockPaperScissors = await RockPaperScissors.deploy();
  });

  it("should create a player", async function () {
    await rockPaperScissors.connect(addr1).createPlayer();
    const playerInfo = await rockPaperScissors.getInfoPlayerByAddress(addr1.address);
    expect(playerInfo[0]).to.equal(0);
    expect(playerInfo[1]).to.equal(0);
  });

  it("should create a party", async function () {
    await rockPaperScissors.connect(addr1).createParty({ value: ethers.parseEther("1") });
    const partyInfo = await rockPaperScissors.getInfoPartyById(0);
    expect(partyInfo[2]).to.equal("created");
    expect(partyInfo[3]).to.equal(true);
  });

  it("should join a party", async function () {
    await rockPaperScissors.connect(addr1).createParty({ value: ethers.parseEther("1") });
    await rockPaperScissors.connect(addr2).joinParty(0, { value: ethers.parseEther("1") });
    const partyInfo = await rockPaperScissors.getInfoPartyById(0);
    expect(partyInfo[2]).to.equal("joined");
    expect(partyInfo[3]).to.equal(false);
  });

  it("should commit a move", async function () {
    await rockPaperScissors.connect(addr1).createParty({ value: ethers.parseEther("1") });
    await rockPaperScissors.connect(addr2).joinParty(0, { value: ethers.parseEther("1") });
    const choiceHash = ethers.keccak256(ethers.toUtf8Bytes("1"));
    await rockPaperScissors.connect(addr1).playMoveCommit(choiceHash, 0);
    await rockPaperScissors.connect(addr2).playMoveCommit(choiceHash, 0);
    const partyInfo = await rockPaperScissors.getInfoPartyById(0);
    expect(partyInfo[2]).to.equal("committed");
  });

  it("should reveal a move", async function () {
    // Create a party with addr1
    await rockPaperScissors.connect(addr1).createParty({ value: ethers.parseEther("1") });
    
    // Join the party with addr2
    await rockPaperScissors.connect(addr2).joinParty(0, { value: ethers.parseEther("1") });

    // Commit choices
    const choice1 = "1";
    const choice2 = "2";
    const choiceHash1 = ethers.keccak256(ethers.toUtf8Bytes(choice1));
    const choiceHash2 = ethers.keccak256(ethers.toUtf8Bytes(choice2));

    await rockPaperScissors.connect(addr1).playMoveCommit(choiceHash1, 0);
    await rockPaperScissors.connect(addr2).playMoveCommit(choiceHash2, 0);

    // Reveal choices
    await rockPaperScissors.connect(addr1).playMoveReveal(choice1, 0);
    await rockPaperScissors.connect(addr2).playMoveReveal(choice2, 0);

    // Check party state
    const partyInfo = await rockPaperScissors.getInfoPartyById(0);
    expect(partyInfo[2]).to.equal("revealed");
});

  it("should determine the winner", async function () {
    await rockPaperScissors.connect(addr1).createParty({ value: ethers.parseEther("1") });
    await rockPaperScissors.connect(addr2).joinParty(0, { value: ethers.parseEther("1") });
    const choiceHash1 = ethers.keccak256(ethers.toUtf8Bytes("1"));
    const choiceHash2 = ethers.keccak256(ethers.toUtf8Bytes("2"));
    await rockPaperScissors.connect(addr1).playMoveCommit(choiceHash1, 0);
    await rockPaperScissors.connect(addr2).playMoveCommit(choiceHash2, 0);
    await rockPaperScissors.connect(addr1).playMoveReveal("1", 0);
    await rockPaperScissors.connect(addr2).playMoveReveal("2", 0);
    const winner = await rockPaperScissors.getTheWinner(0);
    expect(winner).to.equal(addr2.address);
  });
});
