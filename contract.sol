// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StockPriceOracle is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // Oracle için gerekli parametreler
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Son fiyatı saklamak için değişken
    int256 public price;

    // Chainlink Token adresi için ağa bağlı olarak değişebilir
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xOracleAddress; // Oracle adresini buraya girin
        jobId = "JobID"; // Job ID'yi buraya girin
        fee = 0.1 * 10 ** 18; // Chainlink ağı için fee (örnek: 0.1 LINK)
    }

    // Hisse senedi fiyatını dış API'den talep eden fonksiyon
    function requestStockPrice(string memory symbol) public {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // Bu URL ve path, API'ninize ve ihtiyaçlarınıza göre değiştirilmelidir
        req.add("get", string(abi.encodePacked("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=", symbol, "&apikey=YourAlphaVantageAPIKey")));
        req.add("path", "Global Quote.05. price"); // JSON yanıtındaki ilgili veriye erişim yolu
        sendChainlinkRequestTo(oracle, req, fee);
    }

    // Oracle'dan gelen yanıtı işleyen fonksiyon
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId) {
        price = _price;
    }

    // Fiyatı okumak için helper fonksiyon
    function getPrice() public view returns (int256) {
        return price;
    }
}
