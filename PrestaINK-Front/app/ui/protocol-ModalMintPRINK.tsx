import {
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  Button,
  Input,
} from "@nextui-org/react";
import { useState } from "react";

import mintPRINK from "../lib/scripts/mintPRINK";

export default function ModalMint() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    amountPRINKToMint: "",
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

    console.log(formData.amountPRINKToMint);

    await mintPRINK(formData.amountPRINKToMint);

    // Close the modal after submission
    //setIsOpen(false);
    setIsLoading(false);
    window.location.href = "/protocol";
  };
  const handleCloseModal = () => {
    // Reset the form data when the modal is closed
    setFormData({
      amountPRINKToMint: "",
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
        Take Loan / Mint PRINK
      </Button>
      <Modal isOpen={isOpen} onClose={handleCloseModal} placement='top-center'>
        <ModalContent>
          <form onSubmit={handleSubmit}>
            <ModalHeader className='flex flex-col gap-1'>
              Take Loan / Mint PRINK
            </ModalHeader>
            <ModalBody>
              <Input
                autoFocus
                label='Mint PRINK'
                type='text'
                id='mintPRINK'
                name='amountPRINKToMint'
                placeholder='How much PRINK to mint'
                variant='bordered'
                value={formData.amountPRINKToMint}
                onChange={handleChange}
                className=' text-indigo-600'
              />
            </ModalBody>
            <ModalFooter>
              <Button color='danger' variant='flat' onClick={handleCloseModal}>
                Close
              </Button>
              {!isLoading ? (
                <Button type='submit' color='primary'>
                  Mint PRINK
                </Button>
              ) : (
                <Button color='primary' isLoading>
                  Mint PRINK
                </Button>
              )}
            </ModalFooter>
          </form>
        </ModalContent>
      </Modal>
    </>
  );
}
