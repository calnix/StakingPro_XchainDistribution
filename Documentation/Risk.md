# Risk

## Contracts + Chains

Mainnet

- NftLocker
- MocaTokenAdapter
- NftStreaming

Base

- StakingPro
- RewardsVault
- NftRegistry

Away

- EVMVault

## Approach

Pause everything everywhere first.
Remediate and unpause accordingly.

**X-Chain flows**

1. StakingPro > RewardsVault > EvmVault
2. nftLocker <> nftRegistry
3. mocaTokenAdapter <> mocaOft

Call `pause` on all contracts immediately.

Contracts will enter paused state at differing times, since different chains will queue the pause txn differently.

This means that there might be some in-flight txns that could be malicious.
Before, unpausing, we should check the in-flight txns and assess if they all should be allowed to land or some should be rejected.

This would impact NFTlocker+Registry and MocaToken contracts. 

### StakingPro

### RewardsVaultV1

User fns
- setReceiverEvm

POOL_ROLE
- `setupDistribution` 
- `updateDistribution`
- `endDistribution`
- `payRewards`

MONEY_MANAGER_ROLE
- deposit
- withdraw

MONITOR_ROLE [eoa]
- pause

DEFAULT_ADMIN_ROLE [multisig]
- unpause
- exit  [to withdraw any ERC20 tokens when paused]

**Monitor script is expected to pause contract when something untoward.**

If POOL_ROLE is compromised, attacker could:
- create malicious distributions
- update distribution amounts
- trigger unauthorized reward payments

If MONEY_MANAGER_ROLE is compromised:
- drain funds through withdraw function

- `setupDistribution`, `updateDistribution`, `endDistribution` fns are only callable by POOL_ROLE.
- If pool is paused, these functions cannot be called, unless there is another address with POOL_ROLE.

### EVMVault

User fns:
- collectUnclaimedRewards

MONEY_MANAGER_ROLE:
- deposit
- withdraw

MONITOR_ROLE [eoa]
- pause

DEFAULT_ADMIN_ROLE [multisig]
- unpause

LZ fn:
_lzReceive