Dopex dpxETH gas opt
====================

August/September 2023


contracts/reLP/ReLPContract.sol
-------------------------------




Line 273

```solidity
    mintokenAAmount =
      (((amountB / 2) * tokenAInfo.tokenAPrice) / 1e8) -
      (((amountB / 2) * tokenAInfo.tokenAPrice * slippageTolerance) / 1e16);
```

this can be rewritten, resulting in higher accuracy and less operations

$$
\frac{\text{amountB \cdot \text{tokenAPrice}}{2 10^{8}} * (10^8 - \frac{\text{slippageTolerance} }{10^8)
$$



Line 229

```solidity
    uint256 baseReLpRatio = (reLPFactor *
      Math.sqrt(tokenAInfo.tokenAReserve) *
      1e2) / (Math.sqrt(1e18)); // 1e6 precision

    uint256 tokenAToRemove = ((((_amount * 4) * 1e18) /
      tokenAInfo.tokenAReserve) *
      tokenAInfo.tokenALpReserve *
      baseReLpRatio) / (1e18 * DEFAULT_PRECISION * 1e2);

```

can be calculated in less ops as:

```solidity
    uint256 baseReLpRatio = (reLPFactor *
      Math.sqrt(tokenAInfo.tokenAReserve) ) / 1e6; 

    uint256 tokenAToRemove = ((baseReLpRatio)*tokenAInfo.tokenALpReserve *((_amount * 4) * 1e18) /
      (tokenAInfo.tokenAReserve * 1e18 * DEFAULT_PRECISION * 1e2);


```

contracts/core/RdpxV2Core.sol
-----------------------------





Line 1163

```solidity
     uint256 bondDiscount = (bondDiscountFactor *
        Math.sqrt(IRdpxReserve(addresses.rdpxReserve).rdpxReserve()) *
        1e2) / (Math.sqrt(1e18)); // 1e8 precision

```


is 


```solidity
     uint256 bondDiscount = (bondDiscountFactor *
        Math.sqrt(IRdpxReserve(addresses.rdpxReserve).rdpxReserve())) / 1e6

```

to save ops and save face for dev


contracts/amo/UniV2LiquidityAmo.sol
contracts/amo/UniV3LiquidityAmo.sol
contracts/core/RdpxV2Bond.sol
contracts/decaying-bonds/RdpxDecayingBonds.sol
contracts/dpxETH/DpxEthToken.sol
contracts/perp-vault/PerpetualAtlanticVault.sol
contracts/perp-vault/PerpetualAtlanticVaultLP.sol
