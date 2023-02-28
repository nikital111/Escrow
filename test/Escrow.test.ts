/* eslint-disable jest/valid-expect */
/* eslint-disable @typescript-eslint/no-unused-expressions */
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { ERC20, Escrow } from "../typechain-types";
const { expect } = require("chai");
const { ethers } = require("hardhat");

const address0 = "0x0000000000000000000000000000000000000000";
const amount = 150;

describe("Escrow", function () {
  async function deployEscrowFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    const TokenFactory = await ethers.getContractFactory("ERC20");
    const token: ERC20 = await TokenFactory.deploy("AAA", "AAA");

    await token.deployed();

    return { escrow, token, owner, otherAccount };
  }

  async function deployEscrowAndCreateTokenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    const TokenFactory = await ethers.getContractFactory("ERC20");
    const token: ERC20 = await TokenFactory.deploy("AAA", "AAA");

    await token.deployed();

    await escrow.createDeal(otherAccount.address, amount, token.address);

    const count = await escrow.count();

    return { escrow, token, owner, otherAccount, id: count };
  }

  async function deployEscrowAndCreateEthFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    const TokenFactory = await ethers.getContractFactory("ERC20");
    const token: ERC20 = await TokenFactory.deploy("AAA", "AAA");

    await token.deployed();

    await escrow.createDealNative(otherAccount.address, { value: amount });

    const count = await escrow.count();

    return { escrow, token, owner, otherAccount, id: count };
  }

  it("should be deployed", async function () {
    const { escrow, owner } = await loadFixture(deployEscrowFixture);

    const ownerOfContract = await escrow.owner();

    expect(escrow.address).to.be.properAddress;
    expect(ownerOfContract).to.eq(owner.address);
  });

  it("create a deal using custom token", async function () {
    const { escrow, token, owner, otherAccount } = await loadFixture(
      deployEscrowFixture
    );

    const id = await escrow.count();
    const commission = await escrow.currentCommission();
    const count = await escrow.count();

    const createTx = await escrow.createDeal(
      otherAccount.address,
      amount,
      token.address
    );

    const time = (await ethers.provider.getBlock(createTx.blockNumber))
      .timestamp;

    const newCount = await escrow.count();

    const deal = await escrow.getDeal(newCount);

    expect(deal.creator).to.eq(owner.address);
    expect(deal.performer).to.eq(otherAccount.address);
    expect(deal.token).to.eq(token.address);
    expect(deal.amount).to.eq(amount);
    expect(deal.date).to.eq(time);
    expect(deal.commission).to.eq(commission);
    expect(deal.status).to.eq(0);

    expect(count).to.eq(1);
    expect(newCount).to.eq(2);

    expect(createTx)
      .to.emit(escrow, "CreateDeal")
      .withArgs(
        id,
        owner.address,
        otherAccount.address,
        amount,
        token.address,
        time
      );

    await expect(
      escrow.createDeal(otherAccount.address, 0, token.address)
    ).to.be.revertedWith("Amount must be > 0");

    await expect(
      escrow.createDeal(address0, 1, token.address)
    ).to.be.revertedWith("Performer cannot be zero address");

    await expect(
      escrow.createDeal(owner.address, 1, token.address)
    ).to.be.revertedWith("Performer cannot be creator");

    await expect(
      escrow.createDeal(otherAccount.address, 1, address0)
    ).to.be.revertedWith("Token cannot be zero address");
  });

  it("create a deal using ETH", async function () {
    const { escrow, token, owner, otherAccount } = await loadFixture(
      deployEscrowFixture
    );

    const id = await escrow.count();
    const commission = await escrow.currentCommission();
    const count = await escrow.count();

    const createNativeTx = await escrow.createDealNative(otherAccount.address, {
      value: amount,
    });

    const time = (await ethers.provider.getBlock(createNativeTx.blockNumber))
      .timestamp;

    const newCount = await escrow.count();

    const deal = await escrow.getDeal(newCount);

    expect(deal.creator).to.eq(owner.address);
    expect(deal.performer).to.eq(otherAccount.address);
    expect(deal.token).to.eq(address0);
    expect(deal.amount).to.eq(amount);
    expect(deal.date).to.eq(time);
    expect(deal.commission).to.eq(commission);
    expect(deal.status).to.eq(0);

    expect(count).to.eq(1);
    expect(newCount).to.eq(2);

    expect(createNativeTx)
      .to.emit(escrow, "CreateDeal")
      .withArgs(
        id,
        owner.address,
        otherAccount.address,
        amount,
        address0,
        time
      );

    await expect(
      escrow.createDealNative(otherAccount.address, { value: 0 })
    ).to.be.revertedWith("Amount must be > 0");

    await expect(
      escrow.createDealNative(address0, { value: amount })
    ).to.be.revertedWith("Performer cannot be zero address");

    await expect(
      escrow.createDealNative(owner.address, { value: amount })
    ).to.be.revertedWith("Performer cannot be creator");
  });
});
