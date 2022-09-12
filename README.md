# SimpleStaking.sol

[Solidity Development 101](https://dacade.org/communities/ethereum/courses/sol-101)

This is simple staking contract. 
To allow users to earn rewards, owner must use `addLiquidity` function to add ETH to the treasury. Now users can stake their ETH and earn interest from it. After passing 2 minutes users can withdraw their funds + interest.
Owner can pause contract and remove all liquidity in case of emergency.