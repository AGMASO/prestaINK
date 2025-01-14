// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSCEngine is Script {
    function run() external returns (DSCEngine, HelperConfig, DecentralizedStablecoin) {
        HelperConfig helperConfig = new HelperConfig();
        (address proxyApi3, address wEth, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        address deployerKeyAddress = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        DecentralizedStablecoin prink = new DecentralizedStablecoin(deployerKeyAddress);
        DSCEngine dsc = new DSCEngine(proxyApi3, wEth, address(prink));
        prink.transferOwnership(address(dsc));
        vm.stopBroadcast();

        // Ejecutamos el transferOwnerShip fuera del vm.startBroadcast porque si no el msg.sender es el deployerKey,
        // y en este caso necesitamos que sea DeployDSCEngine, ya que es el owner del DecentralizedStablecoin debido
        // a que hemos escrito address(this);
        //! SPOILER: Parece que funciona dentro de la broadcast.
        

        return (dsc, helperConfig, prink);
    }
}
