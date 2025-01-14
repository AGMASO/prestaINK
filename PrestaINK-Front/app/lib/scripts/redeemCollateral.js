const ethers = require("ethers");
import { abiDSCEngine, abiWETH, abiPRINK } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");
import { getNetwork } from "wagmi";

export default async function redeemCollateral(
  tokenCollateral,
  amountToRedeem
) {
  //TODO Creates a way to detect which cahin.id to apply the right params
  // const { chain } = getNetwork();
  // if(chain?.id === 763373){
  //   const wEth = "0x4200000000000000000000000000000000000006";
  //   const addressContractDscEngine =
  //     "0xE56f48ABcEfedFbFDF5d1976E30d0ba9258fae10";
  // }else{
  //   alert("This application is only available on the INK network (ID: 763373). Please switch your network in MetaMask.");
  //   return;
  // }

  const addressContractDscEngine = "0xe5A5E33fb18CC4715360e8D28cfecb8529766cd8";

  console.log("estoy aqui");
  console.log(tokenCollateral);


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
    
    const amountToRedeemInWei = ethers.utils.parseEther(amountToRedeem);
   
    const tx = await dscEngine.redeemCollateral(
      tokenCollateral,
      amountToRedeemInWei
    );
    const receiptApprove = await tx.wait();

    if (receiptApprove.status !== 1) {
      throw new Error("Approval transaction failed");
    }

    console.log("Success to redeem collateral__ScriptRedeemCollateral");
  } catch (error) {
    console.error(
      "Error to redeem collateral__ScriptRedeemCollateral: ",
      error
    );
  }
}
