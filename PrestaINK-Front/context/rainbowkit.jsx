"use client";
import "@rainbow-me/rainbowkit/styles.css";
import {
  RainbowKitProvider,
  getDefaultConfig,
  Chain,
} from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";

const inkSepoliaChain = {
  id: 763373,
  name: "INKSepolia",
  network: "inkSepolia",
  iconUrl: "./PrestaINK-Front/public/iconINK.png",
  iconBackground: "#000",
  nativeCurrency: {
    name: "INK",
    symbol: "INK",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: [
        "https://ink-sepolia.g.alchemy.com/v2/CiEHHW5DLnln323ftL4unSrRHn7jr6EL",
      ],
    },
  },
  blockExplorers: {
    default: {
      name: "Blockscout INK Sepolia Explorer",
      url: "https://explorer-sepolia.inkonchain.com/",
    },
  },
  contracts: {
    multicall3: {
      address: "", // Replace with the Multicall3 contract address if available
      blockCreated: 0, // Replace with the block number where the contract was deployed
    },
  },
};

const config = getDefaultConfig({
  appName: "PrestINK",
  projectId: "8b366abcbb1b47041879ac29b38dcdac",
  chains: [inkSepoliaChain],
});

const queryClient = new QueryClient();

export function Rainbowkit({ children }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>{children}</RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
