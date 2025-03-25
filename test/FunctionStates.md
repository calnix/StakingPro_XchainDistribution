# StakingPro: Function states

- Contract not started: PoolT0
- Contract ended: PoolT86471_ContractEnded
- Contract paused: PoolT56p_Risk
- Contract under maintenance: PoolT46p_MaintenanceMode

## Pool Logic functions

- cache: testCacheRevertsIfVaultDoesNotExist

## createVault

Contract states:
- Contract not started (should revert) | testCannotCreateVault
- Contract ended (should revert) | testCannotCreateVaultAfterContractEnded
- Contract paused (should revert) | testCannotCreateVaultWhenPaused
- Contract under maintenance (should revert) | testCannotCreateVaultWhenInMaintenanceMode
- No active distributions (should revert) | testCannotCreateVaultWhenNoActiveDistributions

(-) Number of NFTs != CREATION_NFTS_REQUIRED (revert: `InvalidCreationNfts`) | testCannotCreateVaultInvalidCreationNfts
(-) NFTs not owned by caller (revert on: `checkIfUnassignedAndOwned`) | testCannotCreateVaultWithOthersNfts  
(-) NFTs already staked in another vault (revert on: `checkIfUnassignedAndOwned`) | testCannotCreateAnotherVaultWithLockedNfts
(-) Total fees > MAXIMUM_FEE_FACTOR | testCannotCreateVaultWithInvalidFeeFactors

(+) NFTs properly owned and unstaked
(+) CREATION_NFTS_REQUIRED = 0 (should succeed without NFTs)

Fee factor states:
(+) Total fees <= MAXIMUM_FEE_FACTOR (should succeed)

VaultId collision states:
- First generated vaultId already exists (should generate new one)
- First generated vaultId available (should use it)

## stakeTokens + executeStakeTokens

- Contract not started (should revert) | testCannotStakeTokensWhenNotStarted
- Contract ended (should revert) | testCannotStakeTokensAfterContractEnded
- Contract paused (should revert) | testCannotStakeTokensWhenPaused
- Contract under maintenance (should revert) | testCannotStakeTokensWhenInMaintenanceMode

(-) Amount = 0 (revert: `InvalidAmount`) | testCannotStakeZeroTokens
(-) `vault.endTime > 0` | testCannotStakeTokensOnceCooldownActivated

(+) Sufficient balance and approval (should succeed)

## stakeNfts + executeStakeNfts

Contract states:
- Contract not started (should revert)
- Contract ended (should revert)
- Contract paused (should revert)
- Contract under maintenance (should revert)

Vault states:
(-) Vault does not exist [`_cache`]
(-) `vault.endTime > 0`

NFT validation states:
(-) No NFTs provided
(-) NFTs not owned by caller (revert on: `checkIfUnassignedAndOwned`)
(-) NFTs already staked in another vault (revert on: `checkIfUnassignedAndOwned`)
(+) NFTs properly owned and unstaked (should succeed: check `_concatArrays`)

## stakeRP + executeStakeRP

Contract states:
- Contract not started (should revert)
- Contract ended (should revert)
- Contract paused (should revert)
- Contract under maintenance (should revert)

RP validation states:
(-) expiry < block.timestamp revert Errors.SignatureExpired()
(-) amount < MINIMUM_REALMPOINTS_REQUIRED revert Errors.MinimumRpRequired()
(-) signer != STORED_SIGNER revert Errors.InvalidSignature()
(-) RP transfer not approved (revert on RP transfer)
(+) Sufficient balance and approval (should succeed)

Vault states:
(-) Vault does not exist [`_cache`]
(-) `vault.endTime > 0`

## unstake + executeUnstake

Contract states:
(-) Contract not started (should revert)
(-) Contract paused (should revert)
(-) Contract under maintenance (should revert)

Token validation states:
(-) Amount = 0 (revert: `InvalidAmount`)
(-) Amount > staked amount (revert: `InsufficientBalance`)
(+) Amount <= staked amount (should succeed)

NFT validation states:
(-) NFTs not staked in vault (revert: `NftNotStaked`)
(-) NFTs not owned by vault (revert: `NftNotStaked`) 
(+) NFTs properly staked in vault (should succeed)

Vault states:
(-) Vault does not exist [`_cache`]
(-) `vault.endTime > 0`

RP validation states:
(-) Amount > staked RP (revert: `InsufficientBalance`)
(+) Amount <= staked RP (should succeed)

## _updateUserAccounts
