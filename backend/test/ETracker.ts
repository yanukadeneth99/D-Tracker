import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { ContractFactory } from "ethers";

describe("ETracker Tests", () => {
  async function deployOneYearLockFixture() {
    const [owner, addr1] = await ethers.getSigners();

    const ETrackerV1 = (await ethers.getContractFactory(
      "ETracker"
    )) as ContractFactory;
    const etrackerv1 = await upgrades.deployProxy(ETrackerV1, { kind: "uups" });

    return { ETrackerV1, etrackerv1, owner, addr1 };
  }

  it("Runs", async function () {
    const { etrackerv1 } = await loadFixture(deployOneYearLockFixture);
  });
});
