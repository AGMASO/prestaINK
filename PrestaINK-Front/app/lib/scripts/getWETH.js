const ethers = require("ethers");
import { abiDSCEngine, abiWETH, abiPRINK } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");

export default async function getWETH(amountToWrap) {
  console.log("estoy aqui");

  const addressWETH = "0x4200000000000000000000000000000000000006";
  

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

    const wETH = new ethers.Contract(
      addressWETH,
      abiWETH,
      signer
    );

    console.log("estoy trabajando2");
    const amountToWrapInWei = ethers.utils.parseEther(amountToWrap.toString());
    console.log(amountToWrapInWei);

    const tx = await wETH.deposit({value:amountToWrapInWei});
    await tx.wait();

    console.log("Success to Wrap and Mint WETH WETH__ScriptGetWETH");
  } catch (error) {
    console.error("Error to Wrap and Mint WETH WETH__ScriptGetWETH: ", error);
  }
}
