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
    address public s_wEth;

    function setUp() public {
        
        string memory rpcUrl = vm.envString("RPC_URL_INK_SEPOLIA");
        uint256 forkId = vm.createSelectFork(rpcUrl);
        vm.selectFork(forkId);

        helper = new HelperConfig();
        (address proxyApi3, address wEth, uint256 deployerKey) = helper
            .activeNetworkConfig();

        vm.startPrank(deployerAddress);
        prink = new DecentralizedStablecoin(deployerAddress);
        DSCEngine dsc = new DSCEngine(proxyApi3, wEth, address(prink));
        prink.transferOwnership(address(dsc));
        s_dsc = dsc;
        s_wEth = wEth;
        
    }

    function testOwnerOfPrink() public view {
        assert(prink.owner() == address(s_dsc));
    }

    function testReadFeed() public view {
        (int224 value, uint32 timeStamp) = s_dsc.readDataFeed();
    }

    function testGetUsdValueETH() public view {
        uint256 OneEth = s_dsc.getUsdValueETH(1000000000000000000);
        console.log(OneEth);
    }

    function testgetTokenAmountFromUsdValue() public view {
        uint256 amountOfTokens = s_dsc.getTokenAmountFromUsdValue(
            s_dsc.getSwETH(),
            1000
        );
        console.log(amountOfTokens);
    }
    //HelperConfig//

    function testRightInizialization() public view {}
    
}
