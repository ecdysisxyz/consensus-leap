  import {setBalance,loadFixture} from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  
  async function getReturnData(func: any) {
    const tx = await func;
    const receipt = await tx.wait();
    const returnValue = receipt.logs[0].args[0];
    return returnValue;
  }
  describe("CCIP", function () {
    async function deployFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

        const router = await ethers.deployContract("MockCCIPRouter");
        await router.waitForDeployment();

        const sender = await ethers.deployContract("CCIPSender",[await router.getAddress()]);
        await sender.waitForDeployment();

        const receiver = await ethers.deployContract("CCIPReceiverPlugin",[await router.getAddress(), ethers.ZeroAddress]);
        await receiver.waitForDeployment();

        const vote = await ethers.deployContract("VoteToken");
        await vote.waitForDeployment();

        const governror = await ethers.deployContract("MockGovernor",[await vote.getAddress(),await router.getAddress()]);
        await governror.waitForDeployment();

        return {owner, otherAccount,sender,receiver,router,vote,governror};
    
    };

    async function setupFixture() {
      const {owner, otherAccount,sender,receiver,router,vote,governror} = await loadFixture(deployFixture);

      await setBalance(await sender.getAddress(),ethers.parseEther("1"));
      await setBalance(await receiver.getAddress(),ethers.parseEther("1"));
      await setBalance(await router.getAddress(),ethers.parseEther("1"));
      await setBalance(await governror.getAddress(),ethers.parseEther("1"));

      await receiver.allowlistSourceChainSender(0,await sender.getAddress(),true);

      return {owner, otherAccount,sender,receiver,router,vote,governror};
    }

    describe("Deployment", function () {
      it("Success", async function () {
        await loadFixture(deployFixture);
      });
    });

    describe("CCIPSend", function () {
      it("Success", async function () {
        const {owner, sender,router,receiver} = await loadFixture(setupFixture);

        const messageId = await getReturnData(sender.triggerCCIPSend(0,await receiver.getAddress(),[owner.address],[0],["0x"]));
        await router.ccipTransfer(messageId);
      });
    });

    describe("Governor", function () {
      it("Propose Success", async function () {
        const {owner, otherAccount, sender,router,receiver,governror} = await loadFixture(setupFixture);

        governror["propose(uint64,address,address[],uint256[],bytes[],string)"](1,await receiver.getAddress(),[otherAccount.address],[ethers.parseEther('0.01')],["0x"],"test");
      });
      it("Execute Success", async function () {
        const {owner, otherAccount, sender,router,receiver,governror} = await loadFixture(setupFixture);
        
        const proposalId = await getReturnData(governror["propose(uint64,address,address[],uint256[],bytes[],string)"](1,await receiver.getAddress(),[otherAccount.address],[ethers.parseEther('0.01')],["0x"],"test"));

        await governror["execute(uint256)"](proposalId);
      });
    });
  });