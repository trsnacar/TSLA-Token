# TSLA-Token — StockPriceOracle

A Solidity smart contract that uses [Chainlink](https://chain.link/) to fetch off-chain stock quotes (illustrated with the Tesla ticker, `TSLA`) and store the latest reported price on-chain.

> **Disclaimer:** This is an educational/experimental project. It contains no live price feed, no factual market data, and is **not audited**. Do not use it in production or to make financial decisions without a thorough security review and a production-grade data source.

## What it does

`StockPriceOracle` (`contract.sol`) is a [Chainlink Client](https://docs.chain.link/any-api/getting-started) contract that:

1. Lets the contract owner send a Chainlink "Any API" request asking an oracle node to fetch a stock quote from an external HTTP API (the example points at Alpha Vantage's `GLOBAL_QUOTE` endpoint).
2. Receives the oracle's response in a `fulfill` callback and stores it in the public `price` variable.
3. Exposes `getPrice()` as a convenience read function for the last stored price.

### Key features

- **Owner-gated requests** — `requestStockPrice` and oracle configuration changes are restricted to the contract owner (via OpenZeppelin's `Ownable`), since each request spends the contract's LINK balance.
- **Configurable oracle parameters** — the LINK token, oracle node address, job ID and fee are set in the constructor and can be updated later via `setOracleConfig`.
- **Events** — `PriceRequested`, `PriceUpdated`, and `OracleConfigUpdated` are emitted for off-chain observability of every state change.
- **LINK recovery** — `withdrawLink` lets the owner reclaim any LINK held by the contract.
- **Verified fulfillment** — the `fulfill` callback uses Chainlink's `recordChainlinkFulfillment` modifier so only the oracle's response to a specific outstanding request is accepted.

## Contract interface

| Function | Visibility | Description |
|---|---|---|
| `constructor(address link, address oracle, bytes32 jobId, uint256 fee)` | — | Deploys the contract and sets initial Chainlink parameters. |
| `setOracleConfig(address oracle, bytes32 jobId, uint256 fee)` | `onlyOwner` | Updates the oracle node, job ID and fee. |
| `requestStockPrice(string symbol)` | `onlyOwner` | Sends a Chainlink request for the given ticker symbol. |
| `fulfill(bytes32 requestId, int256 price)` | Chainlink oracle only | Callback that stores the returned price. |
| `getPrice()` | `view` | Returns the last stored price. |
| `withdrawLink()` | `onlyOwner` | Withdraws the contract's LINK balance to the owner. |

## Tech stack

- [Solidity](https://soliditylang.org/) `0.8.19`
- [Chainlink Contracts](https://github.com/smartcontractkit/chainlink) (`ChainlinkClient`, `LinkTokenInterface`)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) (`Ownable`)
- [Hardhat](https://hardhat.org/) + [Chai](https://www.chaijs.com/) (referenced by `test.js`, for running the included test)

## Repository layout

```
contract.sol   # StockPriceOracle contract
test.js        # Hardhat/Chai unit test
LICENSE        # MIT license
README.md      # This file
```

> Note: this repository ships only the contract and a test file — it does **not** include a `package.json`, `hardhat.config.js`, or lockfile. To compile and run the test locally you'll need to set up a Hardhat project yourself, as described below.

## Prerequisites

- [Node.js](https://nodejs.org/) (LTS recommended) and npm
- A [Chainlink-supported network](https://docs.chain.link/any-api/get-request/introduction) with a funded LINK balance and access to an oracle node/job for outbound HTTP requests, if you intend to actually send requests (not required just to compile or unit test the `fulfill` path)

## Installation / setup

1. Create a Hardhat project (or clone this repo into an existing one) and install the required dependencies:

   ```bash
   npm init -y
   npm install --save-dev hardhat chai
   npm install @chainlink/contracts @openzeppelin/contracts
   npx hardhat init
   ```

2. Copy `contract.sol` into your Hardhat project's `contracts/` directory and `test.js` into `test/`.

3. Configure `hardhat.config.js` with the Solidity version used by the contract (`0.8.19`) and, if deploying, your target network's RPC URL and a funded deployer account.

## Compiling and testing

```bash
npx hardhat compile
npx hardhat test
```

`test.js` deploys the contract with placeholder constructor arguments (no real LINK token or oracle is deployed in this minimal example) and checks: `getPrice()` starts at zero, `fulfill()` reverts when called by anything other than the pending request's oracle (the same guard that prevents spoofed price updates in production), and `requestStockPrice`/`setOracleConfig` revert for non-owner callers.

## Deploying and using the contract

1. Deploy `StockPriceOracle`, passing:
   - the LINK token address for your target network,
   - the address of a Chainlink oracle node that runs a job capable of making HTTP GET requests,
   - the job ID for that job,
   - the LINK fee (in wei) the job charges.
2. Fund the deployed contract with enough LINK to cover the requests you intend to make.
3. As the contract owner, call `requestStockPrice("TSLA")` (or another symbol) to trigger an off-chain data fetch.
4. Once the oracle responds, `fulfill` is called automatically and `getPrice()` returns the new value.
5. Adjust the request URL/JSON path in `requestStockPrice` and your API key management strategy to fit your actual data provider before using this beyond experimentation.

## Contract addresses

No contract has been deployed to any network as part of this repository — there are no addresses to reference.

## License

Distributed under the [MIT License](LICENSE). Copyright (c) 2024 Trusan ACAR.
