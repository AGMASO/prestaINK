// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/Script.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {MockApi3ReaderProxy} from "@api3/mock/MockApi3ReaderProxy.sol";
import {IApi3ReaderProxy} from "@api3/interfaces/IApi3ReaderProxy.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../../src/DecentralizedStablecoin.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {DeployDSCEngine} from "../../../script/DeployDSCEngine.s.sol";
import {ContinueOnRevertHandler} from "./ContinueOnRevertHandler.t.sol";

/// @title Stateful Test Invariant Handler-based for DSCEngine.sol contract
/// @author Agm
/// @notice Testing with Handler, the way to introduce boundaries to our Fuzzing test to make it works well in all the cases we need
/// @dev We need to define in the setUp() the targetContract.
//!  INVARIANTS: 1- Amount of Collateral value in Usd must be allways greater than PRINK amount minted.
contract ContinueOnRevertHandlerBasedInvariant is StdInvariant, Test {
    DSCEngine public s_dscEngine;
    DecentralizedStablecoin public s_PRINK;
    HelperConfig public s_helper;
    ContinueOnRevertHandler public s_handler;

    uint256 public amountCollateral = 10 ether;
    uint256 public amountToMint = 100 ether;
    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    address public wETH;
    address public s_mockApi3;

    uint256 private constant STARTING_VALUE = 10 ether;

    uint256 private constant FEED_PRECISION = 1e8;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant PRECISION = 1e18;

    uint256 private constant AMOUNT_DEPOSIT = 1 ether;
    uint256 private constant PRINK_TO_MINT_LIMIT = 1677500000000000000000;
    uint256 private constant PRINK_TO_MINT = 50000000000000000000;
    uint256 private constant PRINK_TO_MINT_HIGH = 1200000000000000000000;

    uint256 private constant MORE_THAN_HALF_COLLATERAL_VALUE = 1677500000000000000001;

    function setUp() public {
        DeployDSCEngine deployer = new DeployDSCEngine();
        (s_dscEngine, s_helper, s_PRINK) = deployer.run();
        vm.deal(USER, STARTING_VALUE);
        wETH = s_dscEngine.getSwETH();
        s_mockApi3 = s_dscEngine.getApi3PriceFeed();

        s_handler = new ContinueOnRevertHandler(s_dscEngine, s_PRINK, s_mockApi3);
        targetContract(address(s_handler));
    }

    /// forge-config: default.invariant.runs = 128
    /// forge-config: default.invariant.depth = 128
    /// forge-config: default.invariant.fail-on-revert = true
    function invariant_protocolMustHaveMoreValueThanSupplyFalse() public view {
        uint256 amountOfPRINKMinted = s_PRINK.totalSupply();
        console.log("TotalSupply of PRINK", amountOfPRINKMinted);

        uint256 totalWethDeposited = IERC20(wETH).balanceOf(address(s_dscEngine));

        uint256 wEthValue = s_dscEngine.getUsdValueETH(totalWethDeposited);
        console.log("Total WETH deposited as Collateral in USD: ", wEthValue);
        console.log("Times Mint Called: ", s_handler.timesMintCalled());

        assert(wEthValue >= amountOfPRINKMinted);
    }
}
