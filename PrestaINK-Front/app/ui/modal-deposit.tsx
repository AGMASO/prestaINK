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

import depositCollateral from "../lib/scripts/depositCollateral";
export const tokens = [
  { key: "0x4200000000000000000000000000000000000006", label: "wETH" },
];

export default function ModalDeposit() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    tokenAddress: "",
    amountToDeposit: "",
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

    console.log(formData.tokenAddress, formData.amountToDeposit);

    await depositCollateral(formData.tokenAddress, formData.amountToDeposit);

    // Close the modal after submission
    setIsOpen(false);
    setIsLoading(false);
    window.location.href = "/protocol";
  };
  const handleCloseModal = () => {
    // Reset the form data when the modal is closed
    setFormData({
      tokenAddress: "",
      amountToDeposit: "",
    });
    setIsOpen(false);
  };

  return (
    <>
      <Button
        onPress={() => setIsOpen(true)}
        size='lg'
        className='bg-gradient-to-tr from-pink-500 to-yellow-500 text-white shadow-lg hover:scale-105'
      >
        Deposit Collateral
      </Button>
      <Modal isOpen={isOpen} onClose={handleCloseModal} placement='top-center'>
        <ModalContent>
          <form onSubmit={handleSubmit}>
            <ModalHeader className='flex flex-col gap-1'>
              Deposit Collateral
            </ModalHeader>
            <ModalBody>
              <Select
                className='max-w-xl'
                label='Select a Token for Collateral'
                id='tokenAddress'
                name='tokenAddress'
                value={formData.tokenAddress}
                variant='bordered'
                onChange={handleChange}
              >
                {tokens.map((token) => (
                  <SelectItem key={token.key}>{token.label}</SelectItem>
                ))}
              </Select>
              <Input
                label='amountToDeposit'
                placeholder='Enter the Amount To Deposit'
                type='text'
                id='amountToDeposit'
                name='amountToDeposit'
                value={formData.amountToDeposit}
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
                  Deposit
                </Button>
              ) : (
                <Button color='primary' isLoading>
                  Deposit
                </Button>
              )}
            </ModalFooter>
          </form>
        </ModalContent>
      </Modal>
    </>
  );
}
