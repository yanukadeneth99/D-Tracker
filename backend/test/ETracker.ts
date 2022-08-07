import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { ContractFactory } from "ethers";
import { ETracker } from "../typechain-types";

describe("ETracker Tests", () => {
  async function deployOneYearLockFixture() {
    const [owner, addr1] = await ethers.getSigners();

    const ETrackerV1 = (await ethers.getContractFactory(
      "ETracker"
    )) as ContractFactory;
    const etrackerv1 = (await upgrades.deployProxy(ETrackerV1, {
      kind: "uups",
    })) as ETracker;

    return { ETrackerV1, etrackerv1, owner, addr1 };
  }

  it("Runs", async function () {
    const { etrackerv1 } = await loadFixture(deployOneYearLockFixture);
  });

  it("CRUD Account", async () => {
    const { etrackerv1, addr1 } = await loadFixture(deployOneYearLockFixture);
    await etrackerv1
      .connect(addr1)
      .createAccount(ethers.utils.formatBytes32String("Henry"));
    expect(await etrackerv1.connect(addr1).getName()).to.equal("Henry");
    await etrackerv1.connect(addr1).updateName("James");
    expect(await etrackerv1.connect(addr1).getName()).to.equal("James");
    await etrackerv1.connect(addr1).deleteAccount();
    expect(await etrackerv1.connect(addr1).getAccount()).to.be.false;
  });
});
