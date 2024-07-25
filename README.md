# Rock Paper Scissors Game

This project is a decentralized Rock Paper Scissors game built with Solidity and tested with Hardhat.

## Features

- Create and join parties to play Rock Paper Scissors
- Commit and reveal moves using a hash-based commit-reveal scheme
- Automatic determination of the winner
- Claiming timeout functionality to handle inactive players

## Contract Details

The contract allows players to create parties, join existing parties, commit their moves, and then reveal them to determine the winner. The commit-reveal scheme ensures fairness and prevents cheating.


## Setup

### Prerequisites

- Node.js
- Yarn or npm

### Installation
1. Install dependencies
```shell
yarn install
```
or
```shell
npm install
```
2. Compile the smart contracts:
```shell
npx hardhat compile
```
3. other tasks

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/deploy.js
```
