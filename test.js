const { expect } = require("chai");

describe("StockPriceOracle", function () {
  it("Should return the new stock price once it's updated", async function () {
    const StockPriceOracle = await ethers.getContractFactory("StockPriceOracle");
    const stockPriceOracle = await StockPriceOracle.deploy();
    await stockPriceOracle.deployed();

    const updatePriceTx = await stockPriceOracle.requestStockPrice("TSLA");

    // Oracle güncellemesini taklit etmek için, bu örnek testte doğrudan `fulfill` fonksiyonunu çağırıyoruz.
    // Gerçekte, bu Chainlink Oracle tarafından otomatik olarak yapılacaktır.
    await updatePriceTx.wait();
    const fulfillTx = await stockPriceOracle.fulfill(ethers.utils.formatBytes32String(""), 1234567890);

    // İşlemin tamamlanmasını bekle
    await fulfillTx.wait();

    // Fiyatı kontrol et
    expect(await stockPriceOracle.getPrice()).to.equal(1234567890);
  });
});
