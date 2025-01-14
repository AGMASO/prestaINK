// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//import {console} from "forge-std/Script.sol";
import {IApi3ReaderProxy} from "@api3/interfaces/IApi3ReaderProxy.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import {DecentralizedStablecoin} from "./DecentralizedStablecoin.sol";

/// @title DSCENGINE Smart Contract
/// @notice The contract ensures a 1:1 peg between the USDD token and USD.
/// @notice It is similar to DAI but without a DAO, fees, and is backed only by wETH.
/// @notice It provides functionality for minting, redeeming, depositing, and withdrawing collateral.
/// @dev The system is designed to remain over-collateralized to ensure stability.

contract DSCEngine {
    //Mappings//

    mapping(address => mapping(address => uint256)) private s_balanceCollateralInTokens;

    mapping(address user => uint256 amountPRINKMinted) private s_PRINKMinted;

    mapping(address tokenAddress => bool allowed) private tokenAllowance;

    //State variables//
    //AggregatorV3Interface private s_priceFeedETH;
    address private immutable s_wETH;
    address private immutable i_PRINK;
    address private immutable i_proxyApi3;

    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; //0.1 bonus to the people whi liquidates others

    //Events//
    event CollateralAdded(address indexed sender, address indexed tokenAddress, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed tokenAdress, uint256 amount
    );
    event PRINKMintedCorrectly(address indexed caller, address indexed tokenMinted, uint256 indexed amountMinted);
    event PRINKBurned(address indexed burner, uint256 indexed amount);

    //Errors//
    error DSCEngine__CantBeAddressZero();
    error DSCEngine__CantBeZero();
    error DCSEngine__NotAllowedTokenToFund();
    error DSCEngine__SafeTransferError();
    error DSCEngine__MintError();
    error DSCEngine__NotPossibleToRedeemMoreThanCollateralBalance();
    error DSCEngine__YouAreUnderCollaterized();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthNotImproved();
    error IApi3Oracle__ValueNotPositiveSign();
    error IApi3Oracle__Timestamp();

    //Types//
    //using OracleLib for AggregatorV3Interface;

    //Modifiers//
    modifier CantBeAddressZero(address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert DSCEngine__CantBeAddressZero();
        }
        _;
    }

    modifier CantBeZeroAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__CantBeZero();
        }
        _;
    }

    modifier AllowedTokenToFund(address _tokenAddress) {
        if (!tokenAllowance[_tokenAddress]) {
            revert DCSEngine__NotAllowedTokenToFund();
        }
        _;
    }

    ///////////////////
    // Constructor
    ///////////////////

    /// @notice Initializes the DSCEngine contract with essential parameters..
    /// @param wETH The address of the wETH token.
    /// @param _PRINK The address of the PRINK stablecoin.
    constructor(address _proxyApi3, address wETH, address _PRINK) {
        if (wETH == address(0)) {
            revert DSCEngine__CantBeZero();
        }
        s_wETH = wETH;
        tokenAllowance[wETH] = true;
        if (_PRINK == address(0)) {
            revert DSCEngine__CantBeZero();
        }
        i_PRINK = _PRINK;
        if (_proxyApi3 == address(0)) {
            revert DSCEngine__CantBeZero();
        }
        i_proxyApi3 = _proxyApi3;
    }

    ///////////////////
    // External Functions
    ///////////////////

    /// @notice Deposits collateral and mints PRINK in a single transaction.
    /// @param _tokenAddress The token address of the collateral.
    /// @param _amountofCollateral The amount of collateral to deposit.
    /// @param _amountPRINKtoMint The amount of PRINK to mint in WEI.
    /// @dev In the front end we have to convert the amount of Dollars or PrinkToMint to WEI.
    /// User write 50 units of PRINK == 50 usd ==> we have to translate to WEI when giving to the FN
    function depositCollateralAndMintPRINK(
        address _tokenAddress,
        uint256 _amountofCollateral,
        uint256 _amountPRINKtoMint
    ) external {
        depositCollateral(_tokenAddress, _amountofCollateral);
        mintPRINK(_amountPRINKtoMint);
    }

    /// @notice Redeems collateral while ensuring the health factor remains above 1.
    /// @param tokenCollateral The token address of the collateral.
    /// @param amountToRedeem The amount of collateral to redeem.
    function redeemCollateral(address tokenCollateral, uint256 amountToRedeem)
        public
        CantBeAddressZero(tokenCollateral)
        CantBeZeroAmount(amountToRedeem)
        AllowedTokenToFund(tokenCollateral)
    {
        _redeemCollateral(tokenCollateral, msg.sender, msg.sender, amountToRedeem);
        //After redeem is done, we check that the HealthFactor is not broken, if so, we revert all the Tx
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /// @notice Redeems collateral and burns PRINK in a single transaction.
    /// @param tokenCollateral The token address of the collateral.
    /// @param amountOfCollateralToRedeem The amount of collateral to redeem.
    /// @param amountPRINKToBurn The amount of PRINK to burn.
    function redeemCollateralAndGiveBackPRINK(
        address tokenCollateral,
        uint256 amountOfCollateralToRedeem,
        uint256 amountPRINKToBurn
    ) external {
        burnPRINK(amountPRINKToBurn);
        redeemCollateral(tokenCollateral, amountOfCollateralToRedeem);
    }

    /// @notice Burns PRINK to improve the health factor or reduce debt.
    /// @param amountToBurn The amount of PRINK to burn.
    function burnPRINK(uint256 amountToBurn) public CantBeZeroAmount(amountToBurn) {
        _burnPRINK(amountToBurn, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); //Ejemplo para auditar seguridad y optimizar quitandolo ya que al quemar USDD nunca va a romper el HelathFactor
    }

    /// @notice Liquidates an under-collateralized position.
    /// @param collateralTokenAddress The token address of the collateral.
    /// @param user The address of the under-collateralized user.
    /// @param debtToCover The amount of PRINK to burn to cover the user's debt.
    function liquidate(address collateralTokenAddress, address user, uint256 debtToCover)
        external
        CantBeAddressZero(collateralTokenAddress)
        CantBeZeroAmount(debtToCover)
    {
        //Checks
        //Check to discard liquidations for Users with HealthFactorOk
        uint256 startingHealthFactor = _healthFactor(user);
        if (startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        uint256 tokenAmountToGetAfterDebtCovered = getTokenAmountFromUsdValue(collateralTokenAddress, debtToCover);
        //////console.log("Esto es cuantos tokens to get ", tokenAmountToGetAfterDebtCovered);
        uint256 bonus = (tokenAmountToGetAfterDebtCovered * LIQUIDATION_BONUS) / 100;
        uint256 totalAmountYield = tokenAmountToGetAfterDebtCovered + bonus;
        ////console.log("Esto es el totalAmountTOYield", totalAmountYield);

        //Interactions
        _redeemCollateral(collateralTokenAddress, user, msg.sender, totalAmountYield);

        _burnPRINK(debtToCover, user, msg.sender);

        //Again checks
        uint256 endingHealthFactor = _healthFactor(user);
        if (endingHealthFactor <= startingHealthFactor) {
            revert DSCEngine__HealthNotImproved();
        }
        //Check the HealthFactor of the Liquidator user
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    ///////////////////
    // Public Functions
    ///////////////////

    /// @notice Deposits collateral into the system.
    /// @dev This function increases the user's collateral balance and transfers the specified amount of tokens to the contract.
    ///      It emits a `CollateralAdded` event upon successful deposit.
    /// @param _tokenAddress The ERC20 token address of the collateral being deposited.
    /// @param _amount The amount of collateral to deposit.
    /// @notice You need to approve for the _tokenAddress the DSCEngine first.
    function depositCollateral(address _tokenAddress, uint256 _amount)
        public
        CantBeAddressZero(_tokenAddress)
        CantBeZeroAmount(_amount)
        AllowedTokenToFund(_tokenAddress)
    {
        s_balanceCollateralInTokens[msg.sender][_tokenAddress] += _amount;
        emit CollateralAdded(msg.sender, _tokenAddress, _amount);

        bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert DSCEngine__SafeTransferError();
        }
    }

    /// @notice Mints PRINK stablecoins against the user's deposited collateral.
    /// @dev The function first checks if the health factor will remain above the minimum threshold after minting.
    ///      If the health factor is violated, the mint operation is reverted.
    ///      It emits a `PRINKMintedCorrectly` event upon successful minting.
    /// @param _amountPRINKToMint The amount of PRINK stablecoins to mint.
    function mintPRINK(uint256 _amountPRINKToMint) public CantBeZeroAmount(_amountPRINKToMint) {
        //CEI
        //Checks
        //* First, we add the _amountUSDDToMint to the mapping to calculate whether the HealthFactor
        //* would break or not. If it doesn’t break, we allow the function to proceed and send the minted stablecoins.
        //* In case it does break, the function will revert entirely, and the mapping will remain unchanged.
        s_PRINKMinted[msg.sender] += _amountPRINKToMint;
        _revertIfHealthFactorIsBroken(msg.sender);

        //Effects
        emit PRINKMintedCorrectly(msg.sender, i_PRINK, _amountPRINKToMint);
        //Interactions
        bool minted = DecentralizedStablecoin(i_PRINK).mint(msg.sender, _amountPRINKToMint);
        if (!minted) {
            revert DSCEngine__MintError();
        }
    }

    ///////////////////
    // Internal & Private Functions
    ///////////////////

    /// @notice Burns PRINK and updates the system state.
    /// @dev This is a low-level function that requires health factor checks externally.
    /// @param amountToBurn The amount of USDD to burn.
    /// @param onBehalfOf The user whose debt is being reduced.
    /// @param PRINKFrom The address from which PRINK is taken.
    function _burnPRINK(uint256 amountToBurn, address onBehalfOf, address PRINKFrom) private {
        s_PRINKMinted[onBehalfOf] -= amountToBurn;
        emit PRINKBurned(PRINKFrom, amountToBurn);

        bool success = DecentralizedStablecoin(i_PRINK).transferFrom(PRINKFrom, address(this), amountToBurn);
        if (!success) {
            revert DSCEngine__SafeTransferError();
        }
        DecentralizedStablecoin(i_PRINK).burn(amountToBurn);
    }

    /// @notice Internal function to redeem collateral.
    function _redeemCollateral(
        address tokenCollateral,
        address liquidatedUser,
        address callerLiquidation,
        uint256 amountToRedeem
    ) private {
        uint256 balancePriorSubAmountToRedeem = s_balanceCollateralInTokens[liquidatedUser][tokenCollateral];

        //console.log("Esto es el Balance del token colateral escogido", balancePriorSubAmountToRedeem);
        if (amountToRedeem > balancePriorSubAmountToRedeem) {
            revert DSCEngine__NotPossibleToRedeemMoreThanCollateralBalance();
        }

        s_balanceCollateralInTokens[liquidatedUser][tokenCollateral] -= amountToRedeem;
        //console.log(
        //     "Esto es el balance despues de restar el amountToRedeem",
        //     s_balanceCollateralInTokens[liquidatedUser][tokenCollateral]
        // );
        //Effects
        emit CollateralRedeemed(liquidatedUser, callerLiquidation, tokenCollateral, amountToRedeem);
        //Interactions
        bool success = IERC20(tokenCollateral).transfer(callerLiquidation, amountToRedeem);
        if (!success) {
            revert DSCEngine__SafeTransferError();
        }
    }

    /// @notice Get a factor uint256 indicating how close is the user to liquidation in relation
    /// @notice with the collateral and the minted PRINK that he has.
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalMintedPRINK, uint256 collateralValueInUSD) = _getAccountInformation(user);
        //console.log("This is totalMintedPRINK", totalMintedPRINK); // @Eliminate when deploying to Net
        //console.log("This is collateralValueInUSD", collateralValueInUSD); // @Eliminate when deploying to Net

        //Check for when the User has no Minted PRINK
        if (totalMintedPRINK == 0) {
            return MIN_HEALTH_FACTOR;
        }

        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / 100;
        //console.log("This is collateralAdjustedForThreshold", collateralAdjustedForThreshold);
        uint256 healthFactor = ((collateralAdjustedForThreshold * PRECISION) / totalMintedPRINK);

        //console.log("This is HealthFactor: ", healthFactor);
        return healthFactor;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        if (_healthFactor(user) < MIN_HEALTH_FACTOR) {
            revert DSCEngine__YouAreUnderCollaterized();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Retrieves the total minted PRINK and the collateral value in USD for a specific user.
    /// @dev This function aggregates the total PRINK minted by the user and calculates the USD value of their collateral.
    /// @param user The address of the user whose account information is being queried.
    /// @return totalMintedPRINK The total amount of PRINK minted by the user.
    /// @return collateralValueInUSD The total value of the user's collateral in USD.
    function _getAccountInformation(address user)
        public
        view
        returns (uint256 totalMintedPRINK, uint256 collateralValueInUSD)
    {
        totalMintedPRINK = s_PRINKMinted[user];
        collateralValueInUSD = getCollateralValueinUsd(user);
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function getTokenAmountFromUsdValue(address tokenAddress, uint256 usdAmountOfDebt)
        public
        view
        AllowedTokenToFund(tokenAddress)
        returns (uint256 TokenAmountFromUsdValue)
    {
        (int224 value, uint32 timestamp) = IApi3ReaderProxy(i_proxyApi3).read();
        if(value < 0){
            revert IApi3Oracle__ValueNotPositiveSign();
        }
        //!Api3 Oracle in INK Testnet has a heartBeat of 24h, so this require is only for Mainnet
        // if(timestamp + 1 days < block.timestamp){
        //     revert IApi3Oracle__Timestamp older than one day();
        // }

        return (usdAmountOfDebt * PRECISION) / uint256(uint224(value));
    }

    /// @notice Return the value in USD of the collateral for one address
    function getCollateralValueinUsd(address user) public view returns (uint256) {
        uint256 collateralETHAmount = s_balanceCollateralInTokens[user][s_wETH];
        uint256 totalCollateralInUsd = getUsdValueETH(collateralETHAmount);

        return totalCollateralInUsd;
    }
    /// @notice Calls the Pyth oracle to get the price of an amount of Eth(wei)

    function getUsdValueETH(uint256 amount) public view returns (uint256) {
        (int224 value, uint32 timestamp) = IApi3ReaderProxy(i_proxyApi3).read();
         if(value < 0){
            revert IApi3Oracle__ValueNotPositiveSign();
        }
        //!Api3 Oracle in INK Testnet has a heartBeat of 24h, so this require is only for Mainnet
        // if(timestamp + 1 days < block.timestamp){
        //     revert IApi3Oracle__Timestamp older than one day();
        // }
        return (amount * uint256(int256(value))) / PRECISION;
    }

    function getBalanceCollateralInTokens(address user, address token) external view returns (uint256) {
        return s_balanceCollateralInTokens[user][token];
    }

    function getSPRINKMinted(address user) external view returns (uint256) {
        return s_PRINKMinted[user];
    }

    function getApi3PriceFeed() external view returns (address) {
        return i_proxyApi3;
    }

    function getSwETH() external view returns (address) {
        return s_wETH;
    }

    function readDataFeed() external view returns (int224 value, uint32 timestamp) {
        (value, timestamp) = IApi3ReaderProxy(i_proxyApi3).read();
    }

    function getThresholdForAmount(uint256 amount) external view returns (uint256) {
        uint256 collateralValueInUSD = getUsdValueETH(amount);

        //console.log("This is collateralValueInUSD", collateralValueInUSD); // @Eliminate when deploying to Net

        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / 100;
        return collateralAdjustedForThreshold;
    }
}
