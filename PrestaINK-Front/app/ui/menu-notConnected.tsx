"use client";
import React from "react";
import { usePathname } from "next/navigation";
import {
  Navbar,
  NavbarBrand,
  NavbarContent,
  NavbarItem,
  Button,
} from "@nextui-org/react";
import Link from "next/link.js";

import { Logo } from "./logos/logo.jsx";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function MenuNotConnected() {
  const pathname = usePathname();
  return (
    <Navbar shouldHideOnScroll isBordered className=' bg-transparent'>
      <NavbarBrand>
        <NavbarItem
          href='/'
          as={Link}
          className='text-white flex flex-row justify-center items-center gap-2'
        >
          <Logo />
          <p className='font-bold text-inherit'>PrestaInk</p>
        </NavbarItem>
      </NavbarBrand>

      <NavbarContent justify='center'>
        <NavbarItem className='hidden md:flex'>
          <ConnectButton></ConnectButton>
        </NavbarItem>
      </NavbarContent>
    </Navbar>
  );
}
