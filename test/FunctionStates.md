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

Contract states:
- Contract not started (should revert) | testCannotStakeTokensWhenNotStarted
- Contract ended (should revert) | testCannotStakeTokensAfterContractEnded
- Contract paused (should revert) | testCannotStakeTokensWhenPaused
- Contract under maintenance (should revert) | testCannotStakeTokensWhenInMaintenanceMode

(-) Amount = 0 (revert: `InvalidAmount`) | testCannotStakeZeroTokens
(-) `vault.endTime > 0` | testCannotStakeTokensOnceCooldownActivated

(+) Sufficient balance and approval (should succeed)

## stakeNfts + executeStakeNfts

Contract states:
- Contract not started (should revert) | testCannotStakeNftsWhenNotStarted
- Contract ended (should revert) | testCannotStakeNftsAfterContractEnded
- Contract paused (should revert) | testCannotStakeNftsWhenPaused
- Contract under maintenance (should revert) | testCannotStakeNftsWhenInMaintenanceMode

Vault states:
(-) No NFTs provided | testCannotStakeZeroNfts
(-) `vault.endTime > 0` | testCannotStakeNftsOnceCooldownActivated

NFT validation states:
(-) NFTs not owned by caller (revert on: `checkIfUnassignedAndOwned`) | testCannotStakeNotOwnedNfts
(-) NFTs already staked in another vault (revert on: `checkIfUnassignedAndOwned`) | testCannotStakeAssignedNfts
(+) NFTs properly owned and unstaked (should succeed: check `_concatArrays`)

## stakeRP + executeStakeRP

Contract states:
- Contract not started (should revert) | testCannotStakeRPWhenNotStarted
- Contract ended (should revert) | testCannotStakeRpAfterContractEnded
- Contract paused (should revert) | testCannotStakeRPWhenPaused
- Contract under maintenance (should revert) | testCannotStakeRPWhenInMaintenanceMode

RP validation states:
(-) expiry < block.timestamp revert Errors.SignatureExpired() | testCannotStakeRpExpiredSignature
(-) amount < MINIMUM_REALMPOINTS_REQUIRED revert Errors.MinimumRpRequired() | testCannotStakeRpLessThanMinimumRealmPoints
(-) signer != STORED_SIGNER revert Errors.InvalidSignature() | testCannotStakeRpInvalidSignature

Vault states:
(-) `vault.endTime > 0` | testCannotStakeRpOnceCooldownActivated

## migrateRealmPoints + executeMigrateRealmPoints

Contract states:
- Contract not started (should revert) | testCannotMigrateRpWhenNotStarted
- Contract ended (should revert) | testCannotMigrateRpAfterContractEnded
- Contract paused (should revert) | testCannotMigrateRpWhenPaused
- Contract under maintenance (should revert) | testCannotMigrateRpWhenInMaintenanceMode

Vault states:
(-) Source vault does not exist | testCannotMigrateRpFromNonExistentVault_T26
(-) Target vault does not exist | testCannotMigrateRpToNonExistentVault_T26
(-) Target vault.endTime > 0 | testCannotMigrateRpToVaultOnceCooldownActivated
(+) Source vault.endTime > 0 | testCanMigrateRpFromEndedVault

RP validation states:
(-) Amount = 0 (revert: `InvalidAmount`) | testCannotMigrateZeroRp_T26
(-) VaultIds match (revert: `InvalidVaultId`)| testCannotMigrateRpToSameVault_T26
(-) Amount > staked amount (revert: `InsufficientBalance`) | testCannotMigrateMoreThanStakedRp_T26
(-) User has nothing staked in source vault (revert: `UserHasNothingStaked`) | testCannotMigrateRpWhenNothingStakedInFrom_T26
(+) Amount <= staked amount (should succeed)

**consider additional states wrt to `flag`, `totalBoostedDelta` and if-else loop in `migrateRealmPoints`**

## unstake + executeUnstake

Contract states:
(-) Contract not started (should revert) | testCannotUnstakeWhenNotStarted
(-) Contract paused (should revert) | testCannotUnstakeWhenPaused
(-) Contract under maintenance (should revert) | testCannotUnstakeWhenInMaintenanceMode

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
