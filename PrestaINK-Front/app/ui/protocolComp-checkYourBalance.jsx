import {
  Table,
  TableHeader,
  TableBody,
  TableColumn,
  TableRow,
  TableCell,
} from "@nextui-org/react";
import { LogoSmall } from "./logos/logoSmall.jsx";

export default function ProtocolCheckBalance({
  addressUser,
  wETHCollateral,
  prinkMinted,
  usdValueCollateral,
}) {
  // Utility function to format the address
  const formatAddress = `${addressUser.slice(0, 4)}...${addressUser.slice(-4)}`;

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
                {wETHCollateral || "Loading..."}
              </TableCell>

              <TableCell className=' text-black'>
                {prinkMinted !== undefined && prinkMinted !== null
                  ? prinkMinted
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
