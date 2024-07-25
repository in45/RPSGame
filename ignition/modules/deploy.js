const { buildModule } = require('@nomiclabs/hardhat-ignition');

module.exports = buildModule('Deploy RockPaperScissors', (m) => {
  const [deployer] = m.getSigners();

  const rockPaperScissors = m.contract('RockPaperScissors', { from: deployer });

  m.save('RockPaperScissorsAddress', rockPaperScissors.address);

  return {
    rockPaperScissors,
  };
});
