import { useState, useEffect } from "react";
import checkBalanceCollateral from "../lib/scripts/checkBalanceCollateral";
import { ethers } from "ethers"; // Importing ethers

import {
  Table,
  TableHeader,
  TableBody,
  TableColumn,
  TableRow,
  TableCell,
} from "@nextui-org/react";
import { LogoSmall } from "./logos/logoSmall.jsx";

export default function ProtocolCheckBalance({ addressUser }) {
  const [wETH, setwETH] = useState();
  const [balancePRINK, setBalancePRINK] = useState();
  const [usdValueCollateral, setUsdValueCollateral] = useState();

  // Utility function to format the address
  const formatAddress = `${addressUser.slice(0, 4)}...${addressUser.slice(-4)}`;

  useEffect(() => {
    async function checkBalanceCollateralEveryChange() {
      try {
        const { balanceWEth, balancePRINK, usdValueCollateral } =
          await checkBalanceCollateral(addressUser);

        console.log("Esto es usdValue", usdValueCollateral);
        setwETH(ethers.utils.formatUnits(balanceWEth, "ether"));
        setBalancePRINK(ethers.utils.formatUnits(balancePRINK, "ether"));
        setUsdValueCollateral(
          ethers.utils.formatUnits(usdValueCollateral, "ether")
        );
      } catch (error) {
        console.error("Failed to fetch balances: ", error);
      }
    }

    if (addressUser) {
      checkBalanceCollateralEveryChange();
    }
  }, [addressUser]); // Dependency on addressUser to re-run when it changes
  return (
    <>
      <div className=' flex felx-row w-[90%]'>
        <Table aria-label='Collateral Tokens'>
          <TableHeader className='flex'>
            <TableColumn className=' bg-lila text-white'>User</TableColumn>
            <TableColumn className=' bg-lila text-white'>
              <p>WEth</p>
            </TableColumn>

            <TableColumn className='flex items-center gap-2 bg-lila text-white'>
              <LogoSmall />
              <p>PRINK</p>
            </TableColumn>
            <TableColumn className=' bg-lila text-white'>
              Usd Value Collateral
            </TableColumn>
          </TableHeader>
          <TableBody>
            <TableRow key='1'>
              <TableCell className=' text-black'>{formatAddress} </TableCell>
              <TableCell className=' text-black'>
                {wETH || "Loading..."}
              </TableCell>

              <TableCell className=' text-black'>
                {balancePRINK !== undefined && balancePRINK !== null
                  ? balancePRINK
                  : "Loading..."}
              </TableCell>
              <TableCell className=' text-black'>
                {usdValueCollateral
                  ? `$ ${parseFloat(usdValueCollateral).toFixed(2)}`
                  : "Loading..."}
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>
    </>
  );
}
