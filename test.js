const { expect } = require("chai");

describe("StockPriceOracle", function () {
  it("Should return the new stock price once it's updated", async function () {
    const [owner] = await ethers.getSigners();

    // Minimal LINK-like mock could be deployed here in a full Hardhat setup;
    // for illustration purposes we pass placeholder constructor arguments.
    const linkAddress = "0x0000000000000000000000000000000000dEaD";
    const oracleAddress = "0x0000000000000000000000000000000000bEEF";
    const jobId = ethers.utils.formatBytes32String("job-id");
    const fee = ethers.utils.parseUnits("0.1", 18);

    const StockPriceOracle = await ethers.getContractFactory("StockPriceOracle");
    const stockPriceOracle = await StockPriceOracle.deploy(linkAddress, oracleAddress, jobId, fee);
    await stockPriceOracle.deployed();

    // requestStockPrice is restricted to the owner and requires a funded
    // LINK balance to actually reach the oracle; here we exercise the
    // fulfillment path directly, as the real oracle response would in
    // production.
    const fulfillTx = await stockPriceOracle
      .connect(owner)
      .fulfill(ethers.utils.formatBytes32String(""), 1234567890);
    await fulfillTx.wait();

    expect(await stockPriceOracle.getPrice()).to.equal(1234567890);
  });
});
