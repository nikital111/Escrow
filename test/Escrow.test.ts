/* eslint-disable jest/valid-expect */
/* eslint-disable @typescript-eslint/no-unused-expressions */
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { Escrow } from "../typechain-types";
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Escrow", function () {
  async function deployEscrowFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    return { escrow, owner, otherAccount };
  }

  it("should be deployed", async function () {
    const { escrow, owner } = await loadFixture(deployEscrowFixture);

    const ownerOfContract = await escrow.owner();

    expect(escrow.address).to.be.properAddress;
    expect(ownerOfContract).to.eq(owner.address);
  });
});
