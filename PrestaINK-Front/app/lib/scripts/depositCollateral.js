const ethers = require("ethers");
import { abiDSCEngine, abiWETH } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");

export default async function depositCollateral(tokenAddress, amountToDeposit) {
  console.log("estoy aqui");
  const wEth = "0x4200000000000000000000000000000000000006";
  const addressContractDscEngine = "0xe5A5E33fb18CC4715360e8D28cfecb8529766cd8";
  const PRINKAddress = "0xEa54F59D3359B41fd5A86eaa0DC97Ab9e0F67634";
  console.log(tokenAddress);
  try {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    // Request access to the MetaMask account
    await window.ethereum.send("eth_requestAccounts");
    // Get the signer's address
    const signerAddress = (await provider.listAccounts())[0];
    console.log(signerAddress);

    // Create an instance of the signer using the provider and signer's address
    const signer = provider.getSigner(signerAddress);
    console.log(signer);

    console.log("estoy trabajando");

    const dscEngine = new ethers.Contract(
      addressContractDscEngine,
      abiDSCEngine,
      signer
    );

    if (tokenAddress == wEth) {
      console.log("TokenAddress equal to wETH");

      const tokenCollateral = new ethers.Contract(wEth, abiWETH, signer);

      const amountToDepositInWei = ethers.utils.parseEther(amountToDeposit);
      console.log("Amount To deposit in Wei", amountToDepositInWei.toString());

      const txApprove = await tokenCollateral.approve(
        addressContractDscEngine,
        amountToDepositInWei
      );
      const receiptApprove = await txApprove.wait();

      if (receiptApprove.status !== 1) {
        throw new Error("Approval transaction failed");
      }

      console.log("Approval successful, proceeding with deposit...");

      const tx = await dscEngine.depositCollateral(
        tokenAddress,
        amountToDepositInWei
      );
      await tx.wait();
      console.log(
        "Success to add Collateral to the Protocol__scriptDepositCollateral"
      );
    }
  } catch (error) {
    console.error("Error adding Collateral to the Protocol: ", error);
  }
}
