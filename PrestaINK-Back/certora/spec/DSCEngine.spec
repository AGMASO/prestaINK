import "methods/IDSCEngine.spec";

using DecentralizedStablecoin as prink; 
using MockApi3ReaderProxy as api3;
using ERC20Mock as weth;

methods{
   
}

rule neverRevertWithGetBalanceCollateralInTokens(){
    
    address account;
    address token;
   
    getBalanceCollateralInTokens@withrevert(account,token );
    assert(lastReverted == false);

}
