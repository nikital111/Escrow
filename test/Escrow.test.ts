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
    const [owner, otherAccount, thirdAcc] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    const TokenFactory = await ethers.getContractFactory("ERC20");
    const token: ERC20 = await TokenFactory.deploy("AAA", "AAA");

    await token.deployed();

    await escrow.createDeal(otherAccount.address, amount, token.address);

    const count = await escrow.count();

    return { escrow, token, owner, otherAccount, thirdAcc, id: count };
  }

  async function deployEscrowAndCreateEthFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAcc] = await ethers.getSigners();

    const EscrowFactory = await ethers.getContractFactory("Escrow");
    const escrow: Escrow = await EscrowFactory.deploy();

    await escrow.deployed();

    const TokenFactory = await ethers.getContractFactory("ERC20");
    const token: ERC20 = await TokenFactory.deploy("AAA", "AAA");

    await token.deployed();

    await escrow.createDealNative(otherAccount.address, { value: amount });

    const count = await escrow.count();

    return { escrow, token, owner, otherAccount, thirdAcc, id: count };
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

    const balance = await token.balanceOf(owner.address);
    const balanceEscrow = await token.balanceOf(escrow.address);

    const createTx = await escrow.createDeal(
      otherAccount.address,
      amount,
      token.address
    );

    const time = (await ethers.provider.getBlock(createTx.blockNumber))
      .timestamp;

    const newCount = await escrow.count();
    const newId = await escrow.count();

    const newBalance = await token.balanceOf(owner.address);
    const newBalanceEscrow = await token.balanceOf(escrow.address);

    const deal = await escrow.getDeal(newCount);

    expect(deal.creator).to.eq(owner.address);
    expect(deal.performer).to.eq(otherAccount.address);
    expect(deal.token).to.eq(token.address);
    expect(deal.amount).to.eq(amount);
    expect(deal.date).to.eq(time);
    expect(deal.commission).to.eq(commission);
    expect(deal.status).to.eq(0);
    expect(newBalance).to.eq(balance.sub(amount));
    expect(newBalanceEscrow).to.eq(balanceEscrow.add(amount));

    expect(count).to.eq(1);
    expect(newCount).to.eq(2);

    await expect(createTx)
      .to.emit(escrow, "CreateDeal")
      .withArgs(
        newId,
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
    const newId = await escrow.count();

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

    await expect(() => createNativeTx).to.changeEtherBalances(
      [owner.address, escrow.address],
      [`-${amount.toString()}`, amount.toString()]
    );

    await expect(createNativeTx)
      .to.emit(escrow, "CreateDeal")
      .withArgs(
        newId,
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

  it("confirm the deal using custom token", async function () {
    const { escrow, token, owner, otherAccount, id } = await loadFixture(
      deployEscrowAndCreateTokenFixture
    );

    await expect(escrow.confirmDeal(id)).to.be.revertedWith(
      "You are not performer"
    );

    const confirmTx = await escrow.connect(otherAccount).confirmDeal(id);

    const time = (await ethers.provider.getBlock(confirmTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(1);

    await expect(confirmTx).to.emit(escrow, "ConfirmDeal").withArgs(id, time);

    await expect(
      escrow.connect(otherAccount).confirmDeal(id)
    ).to.be.revertedWith("Not pending deal");
  });

  it("confirm the deal using native", async function () {
    const { escrow, token, owner, otherAccount, id } = await loadFixture(
      deployEscrowAndCreateEthFixture
    );

    await expect(escrow.confirmDeal(id)).to.be.revertedWith(
      "You are not performer"
    );

    const confirmTx = await escrow.connect(otherAccount).confirmDeal(id);

    const time = (await ethers.provider.getBlock(confirmTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(1);

    await expect(confirmTx).to.emit(escrow, "ConfirmDeal").withArgs(id, time);

    await expect(
      escrow.connect(otherAccount).confirmDeal(id)
    ).to.be.revertedWith("Not pending deal");
  });

  it("complete the deal using custom token", async function () {
    const { escrow, token, owner, otherAccount, id } = await loadFixture(
      deployEscrowAndCreateTokenFixture
    );

    await escrow.connect(otherAccount).confirmDeal(id);

    await expect(
      escrow.connect(otherAccount).completeDeal(id)
    ).to.be.revertedWith("You are not creator");

    const balanceEscrow = await token.balanceOf(escrow.address);
    const balancePerformer = await token.balanceOf(otherAccount.address);

    const completeTx = await escrow.completeDeal(id);

    const time = (await ethers.provider.getBlock(completeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    const newBalanceEscrow = await token.balanceOf(escrow.address);
    const newBalancePerformer = await token.balanceOf(otherAccount.address);

    expect(deal.status).to.eq(2);

    // commission - 10%
    expect(newBalanceEscrow).to.eq(balanceEscrow.sub(amount * 0.9));
    expect(newBalancePerformer).to.eq(balancePerformer.add(amount * 0.9));

    await expect(completeTx).to.emit(escrow, "CompleteDeal").withArgs(id, time);

    await expect(escrow.completeDeal(id)).to.be.revertedWith("Not open deal");
  });

  it("complete the deal using native", async function () {
    const { escrow, token, owner, otherAccount, id } = await loadFixture(
      deployEscrowAndCreateEthFixture
    );
    await escrow.connect(otherAccount).confirmDeal(id);
    await expect(
      escrow.connect(otherAccount).completeDeal(id)
    ).to.be.revertedWith("You are not creator");

    const completeTx = await escrow.completeDeal(id);

    const time = (await ethers.provider.getBlock(completeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(2);

    // commission - 10%
    await expect(() => completeTx).to.changeEtherBalances(
      [escrow.address, otherAccount.address],
      [`-${(amount * 0.9).toString()}`, (amount * 0.9).toString()]
    );

    await expect(completeTx).to.emit(escrow, "CompleteDeal").withArgs(id, time);

    await expect(escrow.completeDeal(id)).to.be.revertedWith("Not open deal");
  });

  it("cancel the deal using custom token", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateTokenFixture);

    await expect(escrow.connect(thirdAcc).cancelDeal(id)).to.be.revertedWith(
      "You don't participate in this deal"
    );

    const cancelTx = await escrow.cancelDeal(id);

    const time = (await ethers.provider.getBlock(cancelTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(2);

    await expect(cancelTx).to.emit(escrow, "CancelDeal").withArgs(id, time);

    await expect(escrow.cancelDeal(id)).to.be.revertedWith("Not pending deal");
  });

  it("cancel the deal using native", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateEthFixture);

    await expect(escrow.connect(thirdAcc).cancelDeal(id)).to.be.revertedWith(
      "You don't participate in this deal"
    );

    const cancelTx = await escrow.cancelDeal(id);

    const time = (await ethers.provider.getBlock(cancelTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(2);

    await expect(cancelTx).to.emit(escrow, "CancelDeal").withArgs(id, time);

    await expect(escrow.cancelDeal(id)).to.be.revertedWith("Not pending deal");
  });

  it("close the deal using custom token on creator side", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateTokenFixture);

    await escrow.setAdmin(thirdAcc.address, true);

    await expect(escrow.closeDeal(id, false)).to.be.revertedWith("Not Admin");

    const balanceEscrow = await token.balanceOf(escrow.address);
    const balanceOwner = await token.balanceOf(owner.address);

    const closeTx = await escrow.connect(thirdAcc).closeDeal(id, false);

    const time = (await ethers.provider.getBlock(closeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    const newBalanceEscrow = await token.balanceOf(escrow.address);
    const newBalanceOwner = await token.balanceOf(owner.address);

    expect(deal.status).to.eq(2);

    // commission - 10%
    expect(newBalanceEscrow).to.eq(balanceEscrow.sub(amount * 0.9));
    expect(newBalanceOwner).to.eq(balanceOwner.add(amount * 0.9));

    await expect(closeTx)
      .to.emit(escrow, "CloseDeal")
      .withArgs(id, time, false);

    await expect(
      escrow.connect(thirdAcc).closeDeal(id, false)
    ).to.be.revertedWith("Deal is closed");
  });

  it("close the deal using custom token on performer side", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateTokenFixture);

    await escrow.setAdmin(thirdAcc.address, true);

    await expect(escrow.closeDeal(id, true)).to.be.revertedWith("Not Admin");

    const balanceEscrow = await token.balanceOf(escrow.address);
    const balancePerformer = await token.balanceOf(otherAccount.address);

    const closeTx = await escrow.connect(thirdAcc).closeDeal(id, true);

    const time = (await ethers.provider.getBlock(closeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    const newBalanceEscrow = await token.balanceOf(escrow.address);
    const newBalancePerformer = await token.balanceOf(otherAccount.address);

    expect(deal.status).to.eq(2);

    // commission - 10%
    expect(newBalanceEscrow).to.eq(balanceEscrow.sub(amount * 0.9));
    expect(newBalancePerformer).to.eq(balancePerformer.add(amount * 0.9));

    await expect(closeTx).to.emit(escrow, "CloseDeal").withArgs(id, time, true);

    await expect(
      escrow.connect(thirdAcc).closeDeal(id, true)
    ).to.be.revertedWith("Deal is closed");
  });

  it("close the deal using native on creator side", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateEthFixture);

    await escrow.setAdmin(thirdAcc.address, true);

    await expect(escrow.closeDeal(id, false)).to.be.revertedWith("Not Admin");

    const closeTx = await escrow.connect(thirdAcc).closeDeal(id, false);

    const time = (await ethers.provider.getBlock(closeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(2);

    // commission - 10%
    await expect(() => closeTx).to.changeEtherBalances(
      [escrow.address, owner.address],
      [`-${(amount * 0.9).toString()}`, (amount * 0.9).toString()]
    );

    await expect(closeTx)
      .to.emit(escrow, "CloseDeal")
      .withArgs(id, time, false);

    await expect(
      escrow.connect(thirdAcc).closeDeal(id, false)
    ).to.be.revertedWith("Deal is closed");
  });

  it("close the deal using native on creator side", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateEthFixture);

    await escrow.setAdmin(thirdAcc.address, true);

    await expect(escrow.closeDeal(id, true)).to.be.revertedWith("Not Admin");

    const closeTx = await escrow.connect(thirdAcc).closeDeal(id, true);

    const time = (await ethers.provider.getBlock(closeTx.blockNumber))
      .timestamp;

    const deal = await escrow.getDeal(id);

    expect(deal.status).to.eq(2);

    // commission - 10%
    await expect(() => closeTx).to.changeEtherBalances(
      [escrow.address, otherAccount.address],
      [`-${(amount * 0.9).toString()}`, (amount * 0.9).toString()]
    );

    await expect(closeTx).to.emit(escrow, "CloseDeal").withArgs(id, time, true);

    await expect(
      escrow.connect(thirdAcc).closeDeal(id, true)
    ).to.be.revertedWith("Deal is closed");
  });

  it("withdraw custom token from contract", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateTokenFixture);

    await expect(
      escrow
        .connect(otherAccount)
        .withdraw(otherAccount.address, token.address, amount)
    ).to.be.revertedWith("Not Owner");

    await expect(
      escrow.withdraw(otherAccount.address, token.address, amount)
    ).to.be.revertedWith("Amount greater than can be");

    await escrow.connect(otherAccount).confirmDeal(id);

    await expect(
      escrow.withdraw(otherAccount.address, token.address, 0)
    ).to.be.revertedWith("Amount must be > 0");

    await expect(
      escrow.withdraw(address0, token.address, 15)
    ).to.be.revertedWith("Receiver cannot be zero address");

    const balanceEscrow = await token.balanceOf(escrow.address);
    const balanceReceiver = await token.balanceOf(otherAccount.address);

    const withdrawTx = await escrow.withdraw(
      otherAccount.address,
      token.address,
      15
    );

    const time = (await ethers.provider.getBlock(withdrawTx.blockNumber))
      .timestamp;

    const newBalanceEscrow = await token.balanceOf(escrow.address);
    const newBalanceReceiver = await token.balanceOf(otherAccount.address);

    // commission - 10%
    expect(newBalanceEscrow).to.eq(balanceEscrow.sub(15));
    expect(newBalanceReceiver).to.eq(balanceReceiver.add(15));

    await expect(withdrawTx)
      .to.emit(escrow, "Withdraw")
      .withArgs(otherAccount.address, 15, token.address, time);
  });

  it("withdraw ETH from contract", async function () {
    const { escrow, token, owner, otherAccount, thirdAcc, id } =
      await loadFixture(deployEscrowAndCreateEthFixture);

    await expect(
      escrow.connect(otherAccount).withdrawNative(otherAccount.address, amount)
    ).to.be.revertedWith("Not Owner");

    await expect(
      escrow.withdrawNative(otherAccount.address, amount)
    ).to.be.revertedWith("Amount greater than can be");

    await escrow.connect(otherAccount).confirmDeal(id);

    await expect(
      escrow.withdrawNative(otherAccount.address, 0)
    ).to.be.revertedWith("Amount must be > 0");

    await expect(escrow.withdrawNative(address0, 15)).to.be.revertedWith(
      "Receiver cannot be zero address"
    );

    const withdrawTx = await escrow.withdrawNative(owner.address, 15);

    const time = (await ethers.provider.getBlock(withdrawTx.blockNumber))
      .timestamp;

    // commission - 10%
    await expect(() => withdrawTx).to.changeEtherBalances(
      [escrow.address, owner.address],
      [`-15`, "15"]
    );

    await expect(withdrawTx)
      .to.emit(escrow, "Withdraw")
      .withArgs(owner.address, 15, address0, time);
  });

  it("commission", async function () {
    const { escrow, token, owner, otherAccount } = await loadFixture(
      deployEscrowFixture
    );

    const commission = await escrow.currentCommission();
    const count = await escrow.count();

    await escrow.createDealNative(otherAccount.address, {
      value: amount,
    });

    await escrow.changeCommission(50);

    const newId = await escrow.count();
    const newCommission = await escrow.currentCommission();

    const deal = await escrow.getDeal(newId);

    expect(deal.commission).to.eq(commission);
    expect(newCommission).to.eq(50);

    await expect(escrow.changeCommission(0)).to.be.revertedWith(
      "Commission must be > 0 && < 100"
    );

    await expect(escrow.changeCommission(100)).to.be.revertedWith(
      "Commission must be > 0 && < 100"
    );
  });

  it("get ids by user", async function () {
    const { escrow, token, owner, otherAccount } = await loadFixture(
      deployEscrowFixture
    );

    const count = await escrow.count();

    await escrow.createDealNative(otherAccount.address, {
      value: amount,
    });

    const newId = await escrow.count();

    const dealsOwner = await escrow.getUserDealsId(owner.address);
    const dealsOther = await escrow.getUserDealsId(otherAccount.address);

    expect(dealsOwner.length).to.eq(1);
    expect(dealsOther.length).to.eq(1);

    console.log(dealsOwner.length);
  });
});
