"use client";

import { useAccount } from "wagmi";
import checkBalanceCollateral from "../lib/scripts/checkBalanceCollateral";
import { ethers } from "ethers"; // Importing ethers
import { useState, useEffect } from "react";

import MenuMain from "../ui/menu-main";
import CodersComp from "../ui/coderscomp";
import MenuNotConnected from "../ui/menu-notConnected";
import ProtocolCheckBalance from "../ui/protocolComp-checkYourBalance";
import ProtocolActions from "../ui/protocolComp-Actions";

export default function Protocol() {
  const { address, isConnected, isDisconnected } = useAccount();
  const [wETH, setwETH] = useState();
  const [balancePRINK, setBalancePRINK] = useState();
  const [usdValueCollateral, setUsdValueCollateral] = useState();

  useEffect(() => {
    async function checkBalanceCollateralEveryChange() {
      try {
        const { balanceWEth, balancePRINK, usdValueCollateral } =
          await checkBalanceCollateral(address);

        console.log("Esto es usdValue", usdValueCollateral);
        setwETH(ethers.utils.formatUnits(balanceWEth, "ether"));
        console.log(
          "Esto es TTTTTT",
          ethers.utils.formatUnits(balancePRINK, "ether")
        );
        setBalancePRINK(ethers.utils.formatUnits(balancePRINK, "ether"));
        setUsdValueCollateral(
          ethers.utils.formatUnits(usdValueCollateral, "ether")
        );
      } catch (error) {
        console.error("Failed to fetch balances: ", error);
      }
    }

    if (address) {
      checkBalanceCollateralEveryChange();
    }
  }, [address]); // Dependency on address to re-run when it changes

  return (
    <div className='min-h-screen'>
      {isDisconnected && <MenuNotConnected></MenuNotConnected>}
      {isConnected && <MenuMain></MenuMain>}
      <main className='flex-col justify-center'>
        <div className='flex-col justify-center mb-[70px] min-h-[60vh]'>
          {isConnected ? (
            <>
              <div className='flex flex-col w-[100%]'>
                <div className='flex justify-center items-center  mt-20'>
                  <p className='line text-2xl text-white font-bold'>
                    Welcome to the PrestaINK Protocol
                  </p>
                </div>
              </div>
              <div className='flex flex-row w-[100%]'>
                <div className='flex flex-col justify-center items-center  w-[50%]'>
                  <p className=' text-white text-center mb-10 mt-10'>
                    Your Stats in the Protocol
                  </p>
                  <ProtocolCheckBalance
                    addressUser={address}
                    wETHCollateral={wETH}
                    prinkMinted={balancePRINK}
                    usdValueCollateral={usdValueCollateral}
                  />
                </div>
                <div className='flex flex-col justify-center items-center  w-[50%]'>
                  <p className=' text-white text-center mb-10 mt-10'></p>
                  <ProtocolActions
                    addressUser={address}
                    prinkMinted={balancePRINK}
                    usdValueCollateral={usdValueCollateral}
                  ></ProtocolActions>
                </div>
              </div>
            </>
          ) : (
            <div className='flex flex-col w-[100%]'>
              <div className='flex justify-center items-center  mt-20'>
                <p className='line text-2xl text-white font-bold'>
                  Connect Your Wallet Please
                </p>
              </div>
            </div>
          )}
        </div>
        <div className='w-[100%] h-36 bottom-0'>
          <div className='sm:w-[100%] h-full'>
            <CodersComp></CodersComp>
          </div>
        </div>
      </main>
    </div>
  );
}
