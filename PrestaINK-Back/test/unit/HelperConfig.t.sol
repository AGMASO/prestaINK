// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract Api3ReaderProxy is Test {
    DSCEngine public s_dsc;
    DecentralizedStablecoin public prink;
    HelperConfig public helper;
    address public USER = makeAddr("user");
    address public deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");

    function testSepoliaInkHelperConfig() public {
        string memory rpcUrl = vm.envString("RPC_URL_INK_SEPOLIA");
        uint256 forkId = vm.createSelectFork(rpcUrl);
        vm.selectFork(forkId);

        helper = new HelperConfig();
        (address proxyApi3, address wEth, uint256 deployerKey) = helper.activeNetworkConfig();

        assert(proxyApi3 == 0x5b0cf2b36a65a6BB085D501B971e4c102B9Cd473);
        assert(wEth == 0x4200000000000000000000000000000000000006);
        assert(deployerKey == vm.envUint("PRIVATE_KEY"));
    }
    //HelperConfig//

    function testMainInkHelperConfig() external {
        string memory rpcUrl = vm.envString("RPC_URL_INK_MAIN");
        uint256 forkId = vm.createSelectFork(rpcUrl);
        vm.selectFork(forkId);

        helper = new HelperConfig();
        (address proxyApi3, address wEth, uint256 deployerKey) = helper.activeNetworkConfig();

        assert(proxyApi3 == 0x5b0cf2b36a65a6BB085D501B971e4c102B9Cd473);
        assert(wEth == 0x4200000000000000000000000000000000000006);
        assert(deployerKey == vm.envUint("PRIVATE_KEY"));
    }
}
