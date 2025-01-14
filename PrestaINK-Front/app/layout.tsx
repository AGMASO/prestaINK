import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Rainbowkit } from "../context/rainbowkitINK";
import { Providers } from "./providers";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "PrestaINK",
  description: "",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang='en'>
      <body className={inter.className}>
        <Rainbowkit>
          <Providers>{children}</Providers>
        </Rainbowkit>
      </body>
    </html>
  );
}
