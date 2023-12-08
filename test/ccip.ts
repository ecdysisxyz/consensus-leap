  import {setBalance,loadFixture} from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { TypedContractMethod } from "../typechain-types/common";
  
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

        const token = await ethers.deployContract("ERC20Mock",["Mock","Mock",owner.address,1]);
        await token.waitForDeployment();

        const sender = await ethers.deployContract("CCIPSender",[await router.getAddress(),await token.getAddress()]);
        await sender.waitForDeployment();

        const receiver = await ethers.deployContract("CCIPReceiverPlugin",[await router.getAddress()]);
        await receiver.waitForDeployment();

        return {owner, otherAccount,token,sender,receiver,router};
    
    };

    async function setupFixture() {
      const {owner, otherAccount,token,sender,receiver,router} = await loadFixture(deployFixture);

      await setBalance(await sender.getAddress(),ethers.parseEther("1"));
      await receiver.allowlistSourceChainSender(0,await sender.getAddress(),true);

      return {owner, otherAccount,token,sender,receiver,router};
    }
    describe("Deployment", function () {
      it("Success", async function () {
        await loadFixture(deployFixture);
      });
    });
    describe("Send", function () {
      it("Success", async function () {
        const {sender,router,receiver} = await loadFixture(setupFixture);

        const messageId = await getReturnData(sender.sendTrigger(0,await receiver.getAddress(),ethers.encodeBytes32String("hello"),0));
        await router.ccipTransfer(messageId);
      });
    });
  });