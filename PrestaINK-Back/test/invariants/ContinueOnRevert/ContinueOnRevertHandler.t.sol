// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Script.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../../src/DecentralizedStablecoin.sol";

import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {MockApi3ReaderProxy} from "@api3/mock/MockApi3ReaderProxy.sol";

//! KEY for this handler:  No se podrá usar redeemCollateral si no hay Collateral deposited.
contract ContinueOnRevertHandler is Test {
    DSCEngine s_dscEngine;
    DecentralizedStablecoin s_PRINK;
    address public s_mockApi3;
    address public wETH;

    uint256 public timesMintCalled = 0;
    uint256 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    address public USER = makeAddr("user");
    uint256 constant STARTING_VALUE = 10 ether;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    address[] public s_collateralDepositors;
    int224 public EthPrice = 3355000000000000000000;

    constructor(DSCEngine _DscEngine, DecentralizedStablecoin _prink, address _mockApiAddress) {
        s_dscEngine = _DscEngine;
        s_PRINK = _prink;
        vm.deal(USER, STARTING_VALUE);
        s_mockApi3 = _mockApiAddress;
        wETH = s_dscEngine.getSwETH();
    }
    //!en los Handler SC , todos los parametros que se indiquen en la Fn van a ser randomizados.Importante saber

    function depositCollateral(uint256 _amount) public {
        //!Usamos bound para limitar overflows and underflows errors, ya que si enviamos
        //! 0 amount revertira nuestra Fn, y si enviamos un numero muy grande, dara fallo por overflow.
        uint256 validAmountBounded = bound(_amount, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        ERC20Mock(wETH).mint(msg.sender, validAmountBounded);
        ERC20Mock(wETH).approve(address(s_dscEngine), validAmountBounded);
        s_dscEngine.depositCollateral(wETH, validAmountBounded);
        s_collateralDepositors.push(msg.sender);

        vm.stopPrank();

        // EthPrice = EthPrice - 10000000000000000000;
        // MockApi3ReaderProxy(s_mockApi3).mock(EthPrice, 171111112);
    }

    function redeemCollateral(uint256 _collateralSeed, uint256 _amountToRedeem) public {
        //Escogemos a una address dentro del array de depositors randomly.
        address[] memory depositors = s_collateralDepositors;
        if (depositors.length == 0) {
            return;
        }
        uint256 indexOfDepositor = _collateralSeed % depositors.length;
        address depositorToRedeem = depositors[indexOfDepositor];

        uint256 maxAmountPossibleToRedeem = s_dscEngine.getBalanceCollateralInTokens(depositorToRedeem, wETH);
        console.log("Esto es el balance de collateral", maxAmountPossibleToRedeem);
        if (maxAmountPossibleToRedeem == 0) {
            return;
        }

        _amountToRedeem = bound(_amountToRedeem, 0, maxAmountPossibleToRedeem);
        console.log("Esto es el bound", _amountToRedeem);
        if (_amountToRedeem == 0) {
            return;
        }
        //Section to avoid revert on test if it breaks the HealthFactor
        if (_getCalculationOfHealthFactor(_amountToRedeem, depositorToRedeem) <= MIN_HEALTH_FACTOR) {
            return;
        }

        vm.startPrank(depositorToRedeem);
        s_dscEngine.redeemCollateral(wETH, _amountToRedeem);
        vm.stopPrank();
        // EthPrice = EthPrice + 10000000000000000000;
        // MockApi3ReaderProxy(s_mockApi3).mock(EthPrice, 171111113);
    }

    function mintUSDD(uint256 _collateralSeed, uint256 _amountToMint) public {
        //Escogemos a una address dentro del array de depositors randomly.
        address[] memory depositors = s_collateralDepositors;
        if (depositors.length == 0) {
            return;
        }
        uint256 indexOfDepositor = _collateralSeed % depositors.length;
        address depositorToRedeem = depositors[indexOfDepositor];
        (uint256 totalMintedPRINK, uint256 collateralValueInUSD) = s_dscEngine._getAccountInformation(depositorToRedeem);

        int256 maxPRINKToMint = (int256(collateralValueInUSD) / 2) - int256(totalMintedPRINK);

        if (maxPRINKToMint < 0) {
            return;
        }

        _amountToMint = bound(_amountToMint, 0, uint256(maxPRINKToMint));
        if (_amountToMint == 0) {
            return;
        }

        vm.startPrank(depositorToRedeem);
        s_dscEngine.mintPRINK(_amountToMint);
        timesMintCalled++;
        vm.stopPrank();
        // EthPrice = EthPrice - 10000000000000000000;
        // MockApi3ReaderProxy(s_mockApi3).mock(EthPrice, 171111112);
    }

    //Liquidate//

    function liquidate(uint256 _collateralSeed, uint256 _debtToCover) public {
        //Escogemos a una address dentro del array de depositors randomly.
        address[] memory depositors = s_collateralDepositors;
        if (depositors.length == 0) {
            return;
        }
        uint256 indexOfDepositor = _collateralSeed % depositors.length;
        //Address User to liquidate
        address depositorToLiquidate = depositors[indexOfDepositor];

        //Bounding _debtToCover
        uint256 totalMintedPRINK = s_dscEngine.getSPRINKMinted(depositorToLiquidate);
        if (totalMintedPRINK == 0) {
            return;
        }

        uint256 health = s_dscEngine.getHealthFactor(depositorToLiquidate);
        console.log("Esto es healfactor en Liquidate", health);
        if (health >= MIN_HEALTH_FACTOR) {
            return;
        }
        _debtToCover = bound(_debtToCover, totalMintedPRINK, totalMintedPRINK);
        if (_debtToCover == 0) {
            return;
        }

        //Minting PRINK for the Liquidator in this case USER
        vm.prank(address(s_dscEngine));
        s_PRINK.mint(USER, _debtToCover);

        vm.startPrank(USER);
        s_PRINK.approve(address(s_dscEngine), _debtToCover);
        s_dscEngine.liquidate(wETH, depositorToLiquidate, _debtToCover);
        vm.stopPrank();
    }

    function _getCalculationOfHealthFactor(uint256 _amountToRedeem, address _depositorToRedeem)
        internal
        returns (uint256)
    {
        uint256 balanceOfTOkensbefore = s_dscEngine.getBalanceCollateralInTokens(_depositorToRedeem, wETH);
        uint256 balanceOfTokensAfter = balanceOfTOkensbefore - _amountToRedeem;
        uint256 balanceOfPRINK = s_dscEngine.getSPRINKMinted(_depositorToRedeem);
        uint256 totalValeuUSD = s_dscEngine.getUsdValueETH(balanceOfTokensAfter);
        uint256 collateralAdjustedForThreshold = (totalValeuUSD * LIQUIDATION_THRESHOLD) / 100;
        console.log("This is collateralAdjustedForThreshold", collateralAdjustedForThreshold);
        if (balanceOfPRINK == 0) {
            return MIN_HEALTH_FACTOR;
        }

        uint256 healthFactor = ((collateralAdjustedForThreshold * PRECISION) / balanceOfPRINK);

        console.log("This is HealthFactor: ", healthFactor);
        return healthFactor;
    }
}
