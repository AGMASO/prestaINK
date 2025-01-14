const ethers = require("ethers");
import { abiDSCEngine, abiWETH } from "../../../constants/index";
require("dotenv").config();
const { config } = require("dotenv");

export default async function checkBalanceCollateral(addressUser) {
  console.log("estoy aqui");
  const wEth = "0x4200000000000000000000000000000000000006";
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

    const balanceWEth = await dscEngine.getBalanceCollateralInTokens(
      addressUser,
      wEth
    );
    console.log(
      "The balance WEth of the user connected: ",
      balanceWEth.toString()
    );

    const balancePRINK = await dscEngine.getSPRINKMinted(addressUser);
    console.log(
      "The balance PRINK of the user connected: ",
      balancePRINK.toString()
    );

    const usdValueCollateral = await dscEngine.getCollateralValueinUsd(
      addressUser
    );

    console.log(
      "The value in USD of the user's collateral is: ",
      usdValueCollateral.toString()
    );
    return { balanceWEth, balancePRINK, usdValueCollateral };
  } catch (error) {
    console.error("Error adding Collateral to the Protocol: ", error);
  }
}
