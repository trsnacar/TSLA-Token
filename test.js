const { expect } = require("chai");

describe("StockPriceOracle", function () {
  // Valid, checksummed placeholder addresses (no real LINK token or oracle
  // is deployed in this minimal example, so requestStockPrice/fulfill are
  // not exercised end-to-end here — see notes below on each test).
  const linkAddress = "0x000000000000000000000000000000000000dEaD";
  const oracleAddress = "0x000000000000000000000000000000000000bEEF";
  const jobId = ethers.utils.formatBytes32String("job-id");
  const fee = ethers.utils.parseUnits("0.1", 18);

  async function deploy() {
    const StockPriceOracle = await ethers.getContractFactory("StockPriceOracle");
    const stockPriceOracle = await StockPriceOracle.deploy(linkAddress, oracleAddress, jobId, fee);
    await stockPriceOracle.deployed();
    return stockPriceOracle;
  }

  it("Should start with a price of zero", async function () {
    const stockPriceOracle = await deploy();
    expect((await stockPriceOracle.getPrice()).toNumber()).to.equal(0);
  });

  it("Should reject fulfill() calls that don't come from the pending request's oracle", async function () {
    const stockPriceOracle = await deploy();
    const [, notTheOracle] = await ethers.getSigners();

    // No request is outstanding (requestStockPrice needs a funded, real LINK
    // token contract to actually reach an oracle, which isn't set up in this
    // minimal example), so recordChainlinkFulfillment must reject the call
    // regardless of who sends it. This exercises the same guard that
    // protects fulfill() from spoofed price updates in production.
    let reverted = false;
    try {
      await stockPriceOracle.connect(notTheOracle).fulfill(ethers.utils.formatBytes32String("req-1"), 1234567890);
    } catch (err) {
      reverted = true;
      expect(err.message).to.include("Source must be the oracle of the request");
    }
    expect(reverted).to.equal(true);

    expect((await stockPriceOracle.getPrice()).toNumber()).to.equal(0);
  });

  it("Should restrict requestStockPrice and setOracleConfig to the owner", async function () {
    const stockPriceOracle = await deploy();
    const [, notOwner] = await ethers.getSigners();

    let requestReverted = false;
    try {
      await stockPriceOracle.connect(notOwner).requestStockPrice("TSLA");
    } catch (err) {
      requestReverted = true;
      expect(err.message).to.include("Ownable: caller is not the owner");
    }
    expect(requestReverted).to.equal(true);

    let configReverted = false;
    try {
      await stockPriceOracle.connect(notOwner).setOracleConfig(oracleAddress, jobId, fee);
    } catch (err) {
      configReverted = true;
      expect(err.message).to.include("Ownable: caller is not the owner");
    }
    expect(configReverted).to.equal(true);
  });
});
