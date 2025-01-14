// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockApi3ReaderProxy} from "@api3/mock/MockApi3ReaderProxy.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    uint256 public DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    struct NetworkConfig {
        address proxyApi3;
        address wEth;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 763373) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 57073) {
            activeNetworkConfig = getMainConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilNetworkConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaNetworkConfig = NetworkConfig({
            proxyApi3: 'your api',
            wEth: 0x4200000000000000000000000000000000000006, //Ink Sepolia and Mainnet
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        return sepoliaNetworkConfig;
    }

    function getMainConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory MainNetworkConfig = NetworkConfig({
            proxyApi3: 'your api', //not from mainnet
            wEth: 0x4200000000000000000000000000000000000006, //Ink Sepolia and Mainnet
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        return MainNetworkConfig;
    }

    function getOrCreateAnvilNetworkConfig()
        public
        returns (NetworkConfig memory)
    {
        //Check if activeNetwaor already has something

        if (activeNetworkConfig.proxyApi3 != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        ERC20Mock wEthMock = new ERC20Mock();
        MockApi3ReaderProxy mockApi3 = new MockApi3ReaderProxy();
        mockApi3.mock(3355000000000000000000, 171111111);
        vm.stopBroadcast();

        NetworkConfig memory anvilLocalNetworkConfig = NetworkConfig({
            proxyApi3: address(mockApi3),
            wEth: address(wEthMock),
            deployerKey: DEFAULT_ANVIL_KEY
        });

        return anvilLocalNetworkConfig;
    }
}
