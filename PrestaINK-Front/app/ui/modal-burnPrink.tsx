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

import burnPRINK from "../lib/scripts/burnPRINK";

export default function ModalBurnPRINK() {
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    amountToBurn: "",
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

    console.log(formData.amountToBurn);

    await burnPRINK(formData.amountToBurn);

    // Close the modal after submission
    setIsOpen(false);
    setIsLoading(false);
    window.location.href = "/protocol";
  };
  const handleCloseModal = () => {
    // Reset the form data when the modal is closed
    setFormData({
      amountToBurn: "",
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
        Return PRINK
      </Button>
      <Modal isOpen={isOpen} onClose={handleCloseModal} placement='top-center'>
        <ModalContent>
          <form onSubmit={handleSubmit}>
            <ModalHeader className='flex flex-col gap-1'>
              Return PRINK
            </ModalHeader>
            <ModalBody>
              <Input
                label='amountToBurn'
                placeholder='Enter Amount of PRINK to return'
                type='text'
                id='amountToBurn'
                name='amountToBurn'
                value={formData.amountToBurn}
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
                  Return PRINK
                </Button>
              ) : (
                <Button color='primary' isLoading>
                  Return PRINK
                </Button>
              )}
            </ModalFooter>
          </form>
        </ModalContent>
      </Modal>
    </>
  );
}
