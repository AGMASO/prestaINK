import ModalMint from "./protocol-ModalMintPRINK";
import ModalRedeemAndBurn from "./protocol-ModalRedeemAndBurn";
import ModalRedeem from "./protocol-ModalRedeem";
import ModalDeposit from "./modal-deposit";
import ModalBurnPRINK from "./modal-burnPrink";

export default function ProtocolActions({
  addressUser,
  prinkMinted,
  usdValueCollateral,
}) {
  const maxPrink = Math.floor(usdValueCollateral / 2 - prinkMinted);
  const maxPrinkMedium = Math.floor(usdValueCollateral / 3 - prinkMinted);

  return (
    <>
      <div className='flex flex-col w-[100%]'>
        <div className=' flex flex-col justify-center items-center gap-3'>
          <div>
            <ModalDeposit></ModalDeposit>
          </div>
          <div>
            <ModalMint
              amountPrinkHigh={maxPrink}
              amountPrinkMedium={maxPrinkMedium}
            ></ModalMint>
          </div>
          <div>
            <ModalBurnPRINK></ModalBurnPRINK>
          </div>
          <div>
            <ModalRedeem></ModalRedeem>
          </div>
          <div>
            <ModalRedeemAndBurn></ModalRedeemAndBurn>
          </div>
        </div>
      </div>
    </>
  );
}
