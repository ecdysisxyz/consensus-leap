import { ethers } from "hardhat";

async function main() {

  const receiver = await ethers.deployContract("CCIPReceiverPlugin",["0xd0daae2231e9cb96b94c8512223533293c3693bf"]);

  await receiver.waitForDeployment();

  console.log(`deployed to ${receiver.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
