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
      await receiver.allowlistSourceChainSender(0,await sender.getAddress(),true);

      return {owner, otherAccount,sender,receiver,router,vote,governror};
    }

    describe("Deployment", function () {
      it("Success", async function () {
        await loadFixture(deployFixture);
      });
    });
    
    describe("Send", function () {
      it("Success", async function () {
        const {owner, sender,router,receiver} = await loadFixture(setupFixture);

        const messageId = await getReturnData(sender.triggerCCIPSend(0,await receiver.getAddress(),[await owner.getAddress()],[0],["0x"]));
        await router.ccipTransfer(messageId);
      });
    });
  });