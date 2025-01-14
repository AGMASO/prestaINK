methods {
    // External functions
    // function depositCollateralAndMintPRINK(address, uint256, uint256) external;
    // function redeemCollateral(address, uint256) external;
    // function redeemCollateralAndGiveBackPRINK(address, uint256, uint256) external;
    // function burnPRINK(uint256) external;
    // function liquidate(address, address, uint256) external;

    // // Public functions
    // function depositCollateral(address, uint256) external;
    // function mintPRINK(uint256) external;

    // View functions (envfree where applicable)
    function getHealthFactor(address) external returns (uint256) envfree;
    function getTokenAmountFromUsdValue(address, uint256) external returns (uint256) envfree;
    function getCollateralValueinUsd(address) external returns (uint256) envfree;
    function getBalanceCollateralInTokens(address, address) external returns (uint256) envfree;
    function getSPRINKMinted(address) external returns (uint256) envfree;
    function getApi3PriceFeed() external returns (address) envfree;
    function getSwETH() external returns (address) envfree;
    function readDataFeed() external returns (int224, uint32); // Cannot be envfree due to potential external oracle state
    function getThresholdForAmount(uint256) external returns (uint256) envfree;
}
