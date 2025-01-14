import {
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  Button,
  Input,
  Select,
  SelectSection,
  SelectItem,
} from "@nextui-org/react";
import { useState } from "react";

import redeemAndBurn from "../lib/scripts/redeemAndBurn";

export const tokens = [
  { key: "0x4200000000000000000000000000000000000006", label: "wETH" },
];

export default function ModalRedeemAndBurn() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    tokenCollateral: "",
    amountToRedeem: "",
    amountOfPRINKToBurn: "",
  });

  const handleChange = (e: any) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e: any) => {
    e.preventDefault();
    setIsLoading(true);

    console.log(formData.tokenCollateral, formData.amountToRedeem);

    await redeemAndBurn(
      formData.tokenCollateral,
      formData.amountToRedeem,
      formData.amountOfPRINKToBurn
    );

    // Close the modal after submission
    setIsLoading(false);

    window.location.href = "/protocol";
  };
  const handleCloseModal = () => {
    // Reset the form data when the modal is closed
    setFormData({
      tokenCollateral: "",
      amountToRedeem: "",
      amountOfPRINKToBurn: "",
    });
    setIsOpen(false);
  };

  return (
    <>
      <Button
        onPress={() => setIsOpen(true)}
        size='lg'
        className='bg-gradient-to-tr from-indigo-500 to-orange-300 text-white shadow-lg hover:scale-105'
      >
        Redeem Collateral and Burn PRINK
      </Button>
      <Modal isOpen={isOpen} onClose={handleCloseModal} placement='top-center'>
        <ModalContent>
          <form onSubmit={handleSubmit}>
            <ModalHeader className='flex flex-col gap-1'>
              Redeem and Burn PRINK / Debt
            </ModalHeader>
            <ModalBody>
              <Select
                className='max-w-xl'
                label='Select a Token for Collateral'
                id='tokenCollateral'
                name='tokenCollateral'
                value={formData.tokenCollateral}
                variant='bordered'
                onChange={handleChange}
              >
                {tokens.map((token) => (
                  <SelectItem key={token.key}>{token.label}</SelectItem>
                ))}
              </Select>
              <Input
                label='Amount to Redeem'
                placeholder='Enter the Amount To Redeem'
                type='text'
                id='amountToRedeem'
                name='amountToRedeem'
                value={formData.amountToRedeem}
                onChange={handleChange}
                variant='bordered'
                className=' text-indigo-600'
              />
              <Input
                label='Amount of PRINK to burn'
                placeholder='Amount of PRINK to burn'
                type='text'
                id='amountOfPRINKToBurn'
                name='amountOfPRINKToBurn'
                value={formData.amountOfPRINKToBurn}
                onChange={handleChange}
                variant='bordered'
                className=' text-indigo-600'
              />
            </ModalBody>
            <ModalFooter>
              <Button color='danger' variant='flat' onClick={handleCloseModal}>
                Close
              </Button>
              {!isLoading ? (
                <Button type='submit' color='primary'>
                  Redeem Collateral
                </Button>
              ) : (
                <Button color='primary' isLoading>
                  Redeem Collateral
                </Button>
              )}
            </ModalFooter>
          </form>
        </ModalContent>
      </Modal>
    </>
  );
}
