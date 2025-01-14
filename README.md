# PrestaInk Protocol

## Description
The **PrestaInk Protocol** is a decentralized stablecoin system designed to maintain a 1:1 peg with the USD. This protocol is built exclusively for the **INK** blockchain and uses **wETH** as the sole collateral. Its design ensures the system remains over-collateralized, guaranteeing that the collateral value always exceeds the issued stablecoins.

The main contract, **DSCEngine**, allows users to interact with the system through functionalities such as:

- **Collateral deposit and withdrawal**.
- **Stablecoin (PRINK) minting and burning**.
- **Liquidation of under-collateralized positions**.

## Key Features

- **No DAO or fees:** Unlike protocols like DAI, the PrestaInk Protocol does not rely on a decentralized organization or impose fees.
- **Exclusive collateral:** Only wETH is accepted as collateral.
- **Stability:** Designed to ensure a health factor above 1, preventing under-collateralized positions.
- **Incentivized liquidations:** Provides a 0.1 (10%) bonus to users who liquidate others' positions.

## Functionalities

### Deposit and Minting
Users can deposit wETH as collateral and mint **PRINK**, the system's stablecoin. Minting is restricted to ensure the system maintains a high level of collateralization.

### Withdrawal and Burning
Users can withdraw collateral and burn **PRINK** as long as the required health factor is maintained.

### Liquidations
The protocol allows users to liquidate under-collateralized positions, ensuring the system's stability.

# Try Out
The app is live and ready for interaction. You can test it at the following address:
[https://prestaink.vercel.app/](https://prestaink.vercel.app/)


# Installation

### BackEnd
1. Clone this repository:
   ```bash
   https://github.com/AGMASO/prestaINK.git
   ```
2. Set the .env file with your credentials: 
    ```javascript
    
    RPC_URL_INK_SEPOLIA=
    BLOCKSCOUT_API_KEY=
    PRIVATE_KEY=
    DEPLOYER_ADDRESS=
    CERTORAKEY=

    ```
3. Configure the `HelperConfig.sol` file with your credentials:
    ```javascript

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaNetworkConfig = NetworkConfig({
            proxyApi3: 'your api',
            wEth: 0x4200000000000000000000000000000000000006, //INK Sepolia and Mainnet
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        return sepoliaNetworkConfig;
    }
    ```

4. Install the required dependencies:
   ```bash
   forge install
   ```

## Usage

1. Deploy the contract on the **INK** blockchain.
   - Use the script ```make deploy ARGS="--network INKsepolia"``` to deploy all contracts to the INK Sepolia Blockchain.

## Contributions
Contributions are welcome. Please open a **pull request** or report issues in the **issues** section.

## License
This project is licensed under the [MIT License](LICENSE).


### FrontEnd

## Getting Started

1. npm install to install all the packages of the package.json

2. Add a .env with your data:

   ALCHEMY_ID=
   RPC_URL_INK_SEPOLIA=
   



3. run the development server:

```bash
npm run dev

```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.
