const ethers = require("ethers");
import { abiDSCEngine, abiWETH, abiPRINK } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");

export default async function mintPRINK(amountPRINKToMint) {
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

    console.log("estoy trabajando2");
 
    const valuePrinkInWei = ethers.utils.parseEther(amountPRINKToMint.toString());
    console.log(valuePrinkInWei);

    const tx = await dscEngine.mintPRINK(valuePrinkInWei);
    await tx.wait();

    console.log("Success to mint PRINK__ScriptMintPRINK");
  } catch (error) {
    console.error("Error to mint PRINK__ScriptMintPRINK: ", error);
  }
}
