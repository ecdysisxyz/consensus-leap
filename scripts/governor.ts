import { ethers } from "hardhat";

async function main() {
  const vote = await ethers.deployContract("VoteToken");
  await vote.waitForDeployment();

  const governror = await ethers.deployContract("MockGovernor",[await vote.getAddress(),"0xa8c0c11bf64af62cdca6f93d3769b88bdd7cb93d"]);
  await governror.waitForDeployment()

  console.log(`deployed to ${governror.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
