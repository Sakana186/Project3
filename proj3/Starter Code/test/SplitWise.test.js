const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Splitwise Contract", function () {
    let Splitwise, splitwise;
    let owner, addr1, addr2, addr3;

    beforeEach(async function () {
        Splitwise = await ethers.getContractFactory("Splitwise");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        splitwise = await Splitwise.deploy();
        await splitwise.deployed();
    });

    it("Should add IOU correctly", async function () {
        await splitwise.connect(addr1).addIOU(addr2.address, 100);
        expect((await splitwise.lookup(addr1.address, addr2.address)).toNumber()).to.equal(100);
    });

    it("Should not allow self IOU", async function () {
        await expect(splitwise.connect(addr1).addIOU(addr1.address, 50)).to.be.revertedWith("You cannot owe yourself money");
    });

    it("Should reduce debts when mutual debt exists", async function () {
        await splitwise.connect(addr1).addIOU(addr2.address, 100);
        await splitwise.connect(addr2).addIOU(addr1.address, 50);
        expect((await splitwise.lookup(addr1.address, addr2.address)).toNumber()).to.equal(50);
        expect((await splitwise.lookup(addr2.address, addr1.address)).toNumber()).to.equal(0);
    });

    it("Should correctly detect and resolve cycles", async function () {
        await splitwise.connect(addr1).addIOU(addr2.address, 100);
        await splitwise.connect(addr2).addIOU(addr3.address, 100);
        await splitwise.connect(addr3).addIOU(addr1.address, 100);

        expect((await splitwise.lookup(addr1.address, addr2.address)).toNumber()).to.equal(0);
        expect((await splitwise.lookup(addr2.address, addr3.address)).toNumber()).to.equal(0);
        expect((await splitwise.lookup(addr3.address, addr1.address)).toNumber()).to.equal(0);
    });

    it("Should return correct total owed", async function () {
        await splitwise.connect(addr1).addIOU(addr2.address, 100);
        await splitwise.connect(addr1).addIOU(addr3.address, 50);
        expect((await splitwise.getTotalOwed(addr1.address)).toNumber()).to.equal(150);
    });

    it("Should return correct list of users", async function () {
        await splitwise.connect(addr1).addIOU(addr2.address, 100);
        await splitwise.connect(addr2).addIOU(addr3.address, 50);
        const users = await splitwise.getUsers();
        expect(users).to.include.members([addr1.address, addr2.address, addr3.address]);
    });
});