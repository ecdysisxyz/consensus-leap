import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(deployer.address);

    const sender = await ethers.deployContract("CCIPSender",["0xa8c0c11bf64af62cdca6f93d3769b88bdd7cb93d"]);

    await sender.waitForDeployment();

    console.log(`deployed to ${sender.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
