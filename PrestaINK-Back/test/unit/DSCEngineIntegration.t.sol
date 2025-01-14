// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSCEngine} from "../../script/DeployDSCEngine.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
//import {MockV3Aggregator} from "../mocks/MockV3Aggregator.t.sol";
import {MockApi3ReaderProxy} from "@api3/mock/MockApi3ReaderProxy.sol";
import {IApi3ReaderProxy} from "@api3/interfaces/IApi3ReaderProxy.sol";

contract DSCEngineIntegration is Test {
    DSCEngine public s_dscEngine;
    DecentralizedStablecoin public s_prink;
    HelperConfig public s_helper;

    uint256 public amountCollateral = 10 ether;
    uint256 public amountToMint = 100 ether;
    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    address public wETH;
    address public s_mockApi3;

    uint256 private constant SEND_VALUE = 0.1 ether;
    uint256 private constant STARTING_VALUE = 10 ether;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant AMOUNT_DEPOSIT = 1 ether;
    uint256 private constant PRINK_TO_MINT_LIMIT = 1677500000000000000000;
    uint256 private constant PRINK_TO_MINT = 50000000000000000000;
    uint256 private constant PRINK_TO_MINT_HIGH = 1200000000000000000000;

    uint256 private constant MORE_THAN_HALF_COLLATERAL_VALUE = 1677500000000000000001;

    function setUp() public {
        DeployDSCEngine deployer = new DeployDSCEngine();
        (s_dscEngine, s_helper, s_prink) = deployer.run();
        vm.deal(USER, STARTING_VALUE);
        wETH = s_dscEngine.getSwETH();
        s_mockApi3 = s_dscEngine.getApi3PriceFeed();
       
    }

    //CONSTRUCTOR//
    function testConstructorValuesIntegration() external view {
        assertEq(s_dscEngine.getSwETH(), wETH);
        assertEq(s_dscEngine.getApi3PriceFeed(), s_mockApi3);
    }
    //PRICE FEED TEST//
    //getCollateralValueinUsd//

    function testGetCollateralValueinUsd() external deposit {
        uint256 collaterallValueExpected = AMOUNT_DEPOSIT * 3355;
        uint256 collaterallValueActual = s_dscEngine.getCollateralValueinUsd(USER);

        assertEq(collaterallValueExpected, collaterallValueActual);
    }

    //getTokenAmountFromUsdValue()//
    function testCorrectAmountOfTokens() external view {
        //La keyword ether consigue representar el numero que le indequemos en 1e18 , es decir en WEI
        //En este caso, queremos representar unidades de stablecoin por lo que nos vale usar esta especificacion.
        uint256 usdAmountOfDebtinWei = 100 ether;
        uint256 expectedValue = usdAmountOfDebtinWei / 3355; //Obtenemos el value en 1e18
        console.log(expectedValue);

        uint256 actualValue = s_dscEngine.getTokenAmountFromUsdValue(wETH, 100 ether);
        console.log(actualValue);

        assertEq(expectedValue, actualValue);
    }

    function testGetUsdValueETH() public view {
        uint256 ethAmount = 15e18;
        //15e18 * 3355/ETH = 50325e18
        uint256 expectedUsd = 50325e18;
        uint256 priceEthNow = s_dscEngine.getUsdValueETH(ethAmount);
        console.log(priceEthNow);
        assertEq(expectedUsd, priceEthNow);
    }

    //DEPOSITCOLLATERAL//

    function testRevertForDepositIntegrations() external {
        vm.expectRevert(DSCEngine.DSCEngine__CantBeAddressZero.selector);
        s_dscEngine.depositCollateral(address(0), 100);
        vm.expectRevert(DSCEngine.DSCEngine__CantBeZero.selector);
        s_dscEngine.depositCollateral(wETH, 0);
    }

    function testCorrectDepositIntegration() external {
        vm.prank(USER);
        ERC20Mock(wETH).mint(USER, AMOUNT_DEPOSIT);
        uint256 total = ERC20Mock(wETH).balanceOf(USER);
        console.log(total);
        vm.prank(USER);
        ERC20Mock(wETH).approve(address(s_dscEngine), AMOUNT_DEPOSIT);
        vm.prank(USER);
        s_dscEngine.depositCollateral(wETH, AMOUNT_DEPOSIT);

        uint256 balanceCollateralInTokens = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        console.log("Esto es su balance en mapping", balanceCollateralInTokens);

        assert(balanceCollateralInTokens == AMOUNT_DEPOSIT);
        assert(ERC20Mock(wETH).balanceOf(address(s_dscEngine)) == AMOUNT_DEPOSIT);
    }

    function testEmitEventCorrectlyDuringDeposit() external mintWethTokensToUSer {
        vm.expectEmit(true, true, true, false, address(s_dscEngine));
        emit DSCEngine.CollateralAdded(USER, wETH, 200);
        vm.prank(USER);
        s_dscEngine.depositCollateral(wETH, 200);
    }

    modifier mintWethTokensToUSer() {
        vm.prank(USER);
        ERC20Mock(wETH).mint(USER, AMOUNT_DEPOSIT);
        vm.prank(USER);
        ERC20Mock(wETH).approve(address(s_dscEngine), AMOUNT_DEPOSIT);

        _;
    }

    function testDepositAndMint() external mintWethTokensToUSer {
        vm.startPrank(USER);
        s_dscEngine.depositCollateralAndMintPRINK(wETH, AMOUNT_DEPOSIT, 1677500000000000000000);
        uint256 balanceCollateralInTokens = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);

        assert(balanceCollateralInTokens == AMOUNT_DEPOSIT);
        assert(ERC20Mock(wETH).balanceOf(address(s_dscEngine)) == AMOUNT_DEPOSIT);
        assert(s_prink.balanceOf(address(USER)) == 1677500000000000000000);
    }
    // //REDEEMCOLLATERAL//

    modifier deposit() {
        vm.startPrank(USER);
        ERC20Mock(wETH).mint(USER, AMOUNT_DEPOSIT);
        ERC20Mock(wETH).approve(address(s_dscEngine), AMOUNT_DEPOSIT);
        s_dscEngine.depositCollateral(wETH, AMOUNT_DEPOSIT);
        vm.stopPrank();
        _;
    }

    modifier depositAndMint() {
        vm.startPrank(USER);
        ERC20Mock(wETH).mint(USER, AMOUNT_DEPOSIT);
        ERC20Mock(wETH).approve(address(s_dscEngine), AMOUNT_DEPOSIT);
        s_dscEngine.depositCollateralAndMintPRINK(wETH, AMOUNT_DEPOSIT, PRINK_TO_MINT);
        vm.stopPrank();
        _;
    }

    function testRedeemCollateralRevert() external deposit {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__CantBeAddressZero.selector);
        s_dscEngine.redeemCollateral(address(0), 50);
        vm.expectRevert(DSCEngine.DSCEngine__CantBeZero.selector);
        s_dscEngine.redeemCollateral(wETH, 0);
        vm.expectRevert(DSCEngine.DCSEngine__NotAllowedTokenToFund.selector);
        s_dscEngine.redeemCollateral(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, 50);
    }

    function testRedeemCollateralPrivateUpdatingBalance() external deposit {
        vm.startPrank(USER);
        uint256 startingBalance = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        console.log(startingBalance);

        s_dscEngine.redeemCollateral(wETH, AMOUNT_DEPOSIT);
        uint256 endingBalance = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        console.log(endingBalance);

        assertEq(startingBalance - AMOUNT_DEPOSIT, endingBalance);
    }

    function testExpectRevertWhenRedeemingMoreThanYouHave() external deposit {
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__NotPossibleToRedeemMoreThanCollateralBalance.selector);
        s_dscEngine.redeemCollateral(wETH, 5 ether);
    }
    

    function testRedeemETHFuzz(uint256 _amountToRedeem) external deposit {
        vm.startPrank(USER);

        uint256 startingBalance = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        console.log(startingBalance);
        _amountToRedeem = bound(_amountToRedeem, 1, startingBalance);
        s_dscEngine.redeemCollateral(wETH, _amountToRedeem);
        uint256 endingBalance = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        console.log(endingBalance);

        assertEq(startingBalance - _amountToRedeem, endingBalance);
    }

    function testRedeemCollateralEmitEvent() external deposit {
        vm.startPrank(USER);
        vm.expectEmit(true, true, true, true, address(s_dscEngine));
        emit DSCEngine.CollateralRedeemed(USER, USER, wETH, 200);
        s_dscEngine.redeemCollateral(wETH, 200);
        vm.stopPrank();
    }

    function testCorrectTransfer() external deposit {
        vm.startPrank(USER);
        uint256 startingBalanceOfUSER = ERC20Mock(wETH).balanceOf(USER);
        s_dscEngine.redeemCollateral(wETH, 200);
        uint256 endingBalanceOfUSER = ERC20Mock(wETH).balanceOf(USER);
        assertEq(startingBalanceOfUSER + 200, endingBalanceOfUSER);
        vm.stopPrank();
    }
    //_revertIfHealthFactorIsBroken//

    function testRevertWhenHealthFactorBroken() external deposit {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__YouAreUnderCollaterized.selector);

        s_dscEngine.mintPRINK(MORE_THAN_HALF_COLLATERAL_VALUE); // just exactly the limit to be undervolateralized
    }

    function testHealthFactorNotBrokenFuzz(uint256 _amount) external deposit {
        _amount = bound(_amount, 1, AMOUNT_DEPOSIT / 2);
        vm.startPrank(USER);
        s_dscEngine.mintPRINK(_amount);
    }

    function testHealthFactorIsBrokenFuzz(uint256 _amount) external deposit {
        vm.assume(_amount != 0);
        _amount = bound(_amount, PRINK_TO_MINT_LIMIT, type(uint256).max);
        vm.startPrank(USER);
        vm.expectRevert();
        s_dscEngine.mintPRINK(_amount);
    }

    //_getAccountInformation//
    function testGetAccountInformationWorks() external depositAndMint {
        (uint256 totalMintedPRINK, uint256 collateralValueInUSD) = s_dscEngine._getAccountInformation(USER);

        assert(totalMintedPRINK == PRINK_TO_MINT);
        uint256 expectedCollateralValueInUSD = AMOUNT_DEPOSIT * 3355;
        assert(collateralValueInUSD == expectedCollateralValueInUSD);
    }

    //burnUSDD//
    function testCantBeZeroAmount() external {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__CantBeZero.selector);
        s_dscEngine.burnPRINK(0);
    }

    function testBurnPRINKPrivateUpdatingBalance() external depositAndMint {
        vm.startPrank(USER);
        
        uint256 startingBalance = s_dscEngine.getSPRINKMinted(USER);
        s_prink.approve(address(s_dscEngine), PRINK_TO_MINT);
        s_dscEngine.burnPRINK(PRINK_TO_MINT);
        uint256 endingBalance = s_dscEngine.getSPRINKMinted(USER);
        assert(startingBalance == endingBalance + startingBalance);
    }

    function testBurnPRINKEmitEvent() external depositAndMint {
        vm.startPrank(USER);
        s_prink.approve(address(s_dscEngine), PRINK_TO_MINT);
        vm.expectEmit(true, true, false, false, address(s_dscEngine));
        emit DSCEngine.PRINKBurned(USER, PRINK_TO_MINT);
        s_dscEngine.burnPRINK(PRINK_TO_MINT);
        vm.stopPrank();
    }

    function testProveThatTokensAreBurned() external depositAndMint {
        vm.startPrank(USER);

        s_prink.approve(address(s_dscEngine), PRINK_TO_MINT);
        s_dscEngine.burnPRINK(PRINK_TO_MINT);
        assertEq(s_prink.balanceOf(address(s_dscEngine)), 0);
        vm.stopPrank();
    }

    //redeemCollateralAndGiveBackUSDD//

    function testRedeemCollateralAndGiveBackPRINK() external depositAndMint {
        vm.startPrank(USER);

        s_prink.approve(address(s_dscEngine), PRINK_TO_MINT);
        s_dscEngine.redeemCollateralAndGiveBackPRINK(wETH, AMOUNT_DEPOSIT, PRINK_TO_MINT);

        assert(s_dscEngine.getSPRINKMinted(USER) == 0);
        assert(ERC20Mock(wETH).balanceOf(USER) == AMOUNT_DEPOSIT);
        assert(s_prink.balanceOf(address(s_dscEngine)) == 0);
    }

    //FuzzRedeemCollateralAndGiveBackUSDD//
    //! Check
    function testFuzzRedeemCollateralAndGiveBackPRINK(uint256 _collateralToRedeem, uint256 _prinkToBurn)
        external
        depositAndMint
    {
        vm.startPrank(USER);

        // Fetch initial balances and collateral information
        uint256 collateralInTokens = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);
        uint256 prinkMintedInitial = s_dscEngine.getSPRINKMinted(USER);

        // Log initial states for debugging
        console.log("PRINK Minted Initial: ", prinkMintedInitial);
        console.log("Collateral in Tokens: ", collateralInTokens);

        // Bound `_collateralToRedeem` to ensure it is within valid range
        _collateralToRedeem = bound(_collateralToRedeem, 1, collateralInTokens);

        // Get the maximum allowable PRINK to burn for the given collateral
        uint256 maxThreshold = s_dscEngine.getThresholdForAmount(_collateralToRedeem);

        // Dynamically bound `_prinkToBurn` to ensure health factor remains valid
        uint256 maxPrinkBurnable = (maxThreshold < prinkMintedInitial) ? maxThreshold : prinkMintedInitial;
        _prinkToBurn = bound(_prinkToBurn, maxPrinkBurnable, maxPrinkBurnable);

        // Log bounded values for debugging
        console.log("Collateral to Redeem: ", _collateralToRedeem);
        console.log("PRINK to Burn: ", _prinkToBurn);

        // Approve the DSC Engine to spend `_prinkToBurn`
        s_prink.approve(address(s_dscEngine), _prinkToBurn);

        // Redeem collateral and burn PRINK
        s_dscEngine.redeemCollateralAndGiveBackPRINK(wETH, _collateralToRedeem, _prinkToBurn);

        // Assertions to ensure proper state transitions
        assertEq(
            s_dscEngine.getSPRINKMinted(USER), prinkMintedInitial - _prinkToBurn, "PRINK Minted mismatch after burning"
        );
        assertEq(ERC20Mock(wETH).balanceOf(USER), _collateralToRedeem, "Collateral balance mismatch");
    }

    //Liquidate Fn//

    function testLiquidateHealthFactorOk() external depositAndMint {
        vm.startPrank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        s_dscEngine.liquidate(wETH, USER, 50);
    }

    function testLiquidateWorksGood() external {
        vm.startPrank(USER);
        ERC20Mock(wETH).mint(USER, AMOUNT_DEPOSIT);
        ERC20Mock(wETH).approve(address(s_dscEngine), AMOUNT_DEPOSIT);
        s_dscEngine.depositCollateralAndMintPRINK(wETH, AMOUNT_DEPOSIT, PRINK_TO_MINT_HIGH);
        uint256 balancePRINKUser = s_prink.balanceOf(USER);
        console.log("Esto es balance the USER en PRINK", balancePRINKUser);
        vm.stopPrank();
        //We prank the owner of PRINK StablceCoin to mint to LIQUIDATOR. This gives the possibility to
        // executes liquidations for the LIQUIDATOR
        vm.prank(address(s_dscEngine));
        s_prink.mint(LIQUIDATOR, PRINK_TO_MINT_HIGH);
        uint256 balancePRINKliquidator = s_prink.balanceOf(LIQUIDATOR);
        console.log("Esto es balance the LIQUIDATOR", balancePRINKliquidator);

        uint256 health = s_dscEngine.getHealthFactor(USER);
        console.log("Health", health);

        //vamos a actualizar el price de priceFeed para simular que ha bajado 1000$ por ETH
        //Luego LIQUIDATOR va a ejecutar liquidate
        vm.startPrank(LIQUIDATOR);
        MockApi3ReaderProxy(s_mockApi3).mock(2000000000000000000000, 171111111);

        health = s_dscEngine.getHealthFactor(USER);
        console.log("Health 2 ", health);
        uint256 startingBalanceCollateralUSER = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);

        s_prink.approve(address(s_dscEngine), PRINK_TO_MINT_HIGH);
        s_dscEngine.liquidate(wETH, USER, PRINK_TO_MINT_HIGH);
        uint256 finalBalanceOfCollateralLIQUIDATOR = ERC20Mock(wETH).balanceOf(LIQUIDATOR);
        uint256 endingBalanceCollateralUSER = s_dscEngine.getBalanceCollateralInTokens(USER, wETH);

        uint256 endingBalanceOfPRINKLIQUIDATOR = s_prink.balanceOf(LIQUIDATOR);
        assertEq(endingBalanceCollateralUSER, startingBalanceCollateralUSER - finalBalanceOfCollateralLIQUIDATOR);

        assertEq(endingBalanceOfPRINKLIQUIDATOR, 0);
    }

    //GetHeathFactor

    function testGetHealthFactor() external mintWethTokensToUSer {
        vm.startPrank(USER);
        s_dscEngine.depositCollateralAndMintPRINK(wETH, AMOUNT_DEPOSIT, PRINK_TO_MINT);

        uint256 healthFactor = s_dscEngine.getHealthFactor(USER);
        console.log(healthFactor);
    }
    
}
