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

import getWETH from "../lib/scripts/getWETH";

export default function ModalGetWeth() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    amountToWrap: "",
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

    console.log(formData.amountToWrap);

    await getWETH(formData.amountToWrap);

    // Close the modal after submission
    //setIsOpen(false);
    setIsLoading(false);
  };
  const handleCloseModal = () => {
    // Reset the form data when the modal is closed
    setFormData({
      amountToWrap: "",
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
        Wrap Eth to get wETH
      </Button>
      <Modal isOpen={isOpen} onClose={handleCloseModal} placement='top-center'>
        <ModalContent>
          <form onSubmit={handleSubmit}>
            <ModalHeader className='flex flex-col gap-1'>
              Wrap Eth to get wETH
            </ModalHeader>
            <ModalBody>
              <Input
                autoFocus
                label='Get wETH'
                type='text'
                id='amountToWrap'
                name='amountToWrap'
                placeholder='How much ETH wrap '
                variant='bordered'
                value={formData.amountToWrap}
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
                  Wrap Eth to get wETH
                </Button>
              ) : (
                <Button color='primary' isLoading>
                  Wrap Eth to get wETH
                </Button>
              )}
            </ModalFooter>
          </form>
        </ModalContent>
      </Modal>
    </>
  );
}
