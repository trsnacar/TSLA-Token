// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title StockPriceOracle
/// @notice Fetches an off-chain stock quote (e.g. TSLA) via a Chainlink oracle
///         and stores the last reported price on-chain.
/// @dev This is an educational example. The oracle/job configuration and the
///      external API referenced by the request are not production-ready and
///      must be reviewed before any real deployment.
contract StockPriceOracle is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    /// @notice Address of the Chainlink oracle node used to service requests.
    address public oracle;
    /// @notice Chainlink job ID used to service requests.
    bytes32 public jobId;
    /// @notice LINK fee (in wei) paid per request.
    uint256 public fee;

    /// @notice Last stock price reported by the oracle.
    int256 public price;

    /// @notice Emitted when a new price request is sent to the oracle.
    event PriceRequested(bytes32 indexed requestId, string symbol);
    /// @notice Emitted when the oracle fulfills a request with a new price.
    event PriceUpdated(bytes32 indexed requestId, int256 price);
    /// @notice Emitted when the oracle configuration is updated by the owner.
    event OracleConfigUpdated(address oracle, bytes32 jobId, uint256 fee);

    /// @param _link Address of the LINK token on the target network.
    /// @param _oracle Address of the Chainlink oracle node.
    /// @param _jobId Chainlink job ID to request.
    /// @param _fee LINK fee (in wei) to pay per request.
    constructor(address _link, address _oracle, bytes32 _jobId, uint256 _fee) {
        require(_link != address(0), "StockPriceOracle: zero LINK address");
        require(_oracle != address(0), "StockPriceOracle: zero oracle address");
        require(_jobId != bytes32(0), "StockPriceOracle: empty jobId");

        setChainlinkToken(_link);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;

        emit OracleConfigUpdated(_oracle, _jobId, _fee);
    }

    /// @notice Updates the oracle node, job ID and/or fee used for future requests.
    /// @dev Restricted to the contract owner to prevent misconfiguration or griefing.
    function setOracleConfig(address _oracle, bytes32 _jobId, uint256 _fee) external onlyOwner {
        require(_oracle != address(0), "StockPriceOracle: zero oracle address");
        require(_jobId != bytes32(0), "StockPriceOracle: empty jobId");

        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;

        emit OracleConfigUpdated(_oracle, _jobId, _fee);
    }

    /// @notice Requests the latest price for `symbol` from the configured oracle.
    /// @dev Restricted to the owner because each call spends the contract's LINK
    ///      balance; an unrestricted public function would let anyone drain it.
    /// @param symbol The stock ticker to query (e.g. "TSLA").
    function requestStockPrice(string memory symbol) external onlyOwner returns (bytes32 requestId) {
        require(bytes(symbol).length > 0, "StockPriceOracle: empty symbol");

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // NOTE: the URL/path below are illustrative and must be adapted to a
        // production-grade data source and API key management strategy.
        req.add("get", string(abi.encodePacked("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=", symbol, "&apikey=YourAlphaVantageAPIKey")));
        req.add("path", "Global Quote.05. price");

        requestId = sendChainlinkRequestTo(oracle, req, fee);
        emit PriceRequested(requestId, symbol);
    }

    /// @notice Callback invoked by the Chainlink oracle with the requested price.
    /// @dev `recordChainlinkFulfillment` ensures only the pending, matching
    ///      request can fulfill, preventing spoofed callbacks.
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId) {
        price = _price;
        emit PriceUpdated(_requestId, _price);
    }

    /// @notice Returns the last price reported by the oracle.
    function getPrice() external view returns (int256) {
        return price;
    }

    /// @notice Allows the owner to withdraw any LINK held by this contract.
    /// @dev Included so LINK funding the contract is never permanently stuck.
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        bool success = link.transfer(owner(), link.balanceOf(address(this)));
        require(success, "StockPriceOracle: LINK transfer failed");
    }
}
