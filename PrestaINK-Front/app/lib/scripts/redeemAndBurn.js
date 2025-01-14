const ethers = require("ethers");
import { abiDSCEngine, abiWETH, abiPRINK } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");

export default async function redeemAndBurn(
  tokenCollateral,
  amountOfCollateralToRedeem,
  amountToPRINKToBurn
) {
  console.log("estoy aqui");
  

  const addressContractDscEngine = "0xe5A5E33fb18CC4715360e8D28cfecb8529766cd8";
  const PRINKAddress = "0xEa54F59D3359B41fd5A86eaa0DC97Ab9e0F67634";

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
    const prink = new ethers.Contract(PRINKAddress, abiPRINK, signer);

    const amountOfCollateralToRedeemInWei = ethers.utils.parseEther(
      amountOfCollateralToRedeem
    );
    const amountToPRINKToBurnInWei = ethers.utils.parseEther(amountToPRINKToBurn);
    console.log(amountToPRINKToBurnInWei);

    const tx1 = await prink.approve(
      addressContractDscEngine,
      amountToPRINKToBurnInWei
    );

    await tx1.wait();

    //!NOT WORKING await txApproval.wait(); saying is not a function
    // const receiptApproveUsdd = await txApproval.wait();

    // if (receiptApproveUsdd.status !== 1) {
    //   throw new Error("Approval transaction failed");
    // }

    console.log("Approval successful, proceeding with deposit...");
    
    

    const tx = await dscEngine.redeemCollateralAndGiveBackPRINK(
      tokenCollateral,
      amountOfCollateralToRedeemInWei,
      amountToPRINKToBurnInWei
    );
    await tx.wait();

    console.log(
      "Success to redeem collateral and return USDD__ScriptRedeemCollateralAndBurn"
    );
  } catch (error) {
    console.error(
      "Error redeeming Collateral and Burning__USDD__ScriptRedeemCollateralAndBurn: ",
      error
    );
  }
}
