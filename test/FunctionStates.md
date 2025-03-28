# StakingPro: Function states

- Contract not started: PoolT0
- Contract ended: PoolT86471_ContractEnded
- Contract paused: PoolT56p_Risk
- Contract under maintenance: PoolT46p_MaintenanceMode

**TODO**

Check if repeating the exact same actions more than once and see if it breaks something.

- stakeNfts
- stakeRp [same nonce]
- claimRewards [no double claiming]  | testRepeatedClaimRewards_T56
- createVault [w/ same nfts]
- activateCooldown | testCannotActivateCooldownRepeatedly_T61
- endVaults |

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
(+) Contract ended | testCanUnstakeAfterContractEnded

Token validation states:
(-) Amount = 0 (revert: `InvalidAmount`) | testCannotUnstakeZero_T31
(-) Amount > staked amount (revert: `InsufficientBalance`) | testUserCannotUnstakeMoreThanStaked_T31
(+) Amount <= staked amount (should succeed) | testUser2CanUnstakeAssets_T31

NFT validation states:
(-) userVaultAssets.tokenIds.length <= numOfNftsToUnstake | testCannotUnstakeMoreNftsThanStaked_T31
(-) NFTs not staked in vault (revert: `NftNotStaked`) | testCannotUnstakeNftsNotStaked_T31
(-) TokenIds do not match what user has staked | testCannotUnstakeIncorrectNfts_T31
(-) NFTS not owned by user (revert: `NftNotStaked`) | testCannotUnstakeNftsStakedByOtherUser_T31
(-) Cannot unstake repeatedly | testCannotUnstakeRepeatedly_T36
(+) NFTs properly staked in vault (should succeed) | testUser2CanUnstakeAssets_T31

Vault states:
(-) `vault.endTime > 0` | testCanUnstakeTokensOnceCooldownActivated

**consider additional cases, as per conditional logic in unstake()**

## claimRewards + executeClaimRewards

Contract states:
(-) Contract not started (should revert) | testCannotClaimRewardsWhenNotStarted
(-) Contract paused (should revert) | testCannotClaimRewardsWhenPaused
(-) Contract under maintenance (should revert) | testCannotClaimRewardsWhenInMaintenanceMode
(+) Contract ended | testCanClaimRewardsAfterContractEnded

Distribution states:
(-) Distribution Zero; cannot claim | testCannotClaimForStakingPowerDistribution_T51
(-) Distribution does not exist (revert: `DistributionDoesNotExist`) | testCannotClaimFromNonExistentDistribution_T51
(-) Distribution not started | testCannotClaimFromDistributionNotStarted_T16
(+) Distribution manually ended | PoolT46p_EndDistribution.t.sol
(+) Distribution active | testClaimRewards_T51

Vault states:
(-) User has nothing staked in vault (revert: `UserHasNothingStaked`) | testCannotClaimWhenNothingStaked_T51
(-) Vault does not exist (revert: `NonExistentVault`) | testCannotClaimFromNonExistentVault_T51
(+) User has assets staked in vault | testClaimRewards_T51

Reward states:
(+) No rewards to claim | testRepeatedClaimRewards_T56
(+) Rewards available to claim | testClaimRewards_T51

## updateVaultFees + executeUpdateVaultFees

Contract states:
(-) Contract not started | testCannotUpdateVaultFeesWhenNotStarted
(-) Contract paused (should revert) | testCannotUpdateVaultFeesWhenPaused
(-) Contract under maintenance (should revert) | testCannotUpdateVaultFeesWhenInMaintenanceMode
(-) Contract ended | testCannotUpdateVaultFeesAfterContractEnded

Vault states:
(-) Vault cooldown activated (revert: `VaultEndTimeSet`) | testCannotUpdateFeesAfterCooldownActivated
(-) Caller is not vault creator (revert: `UserIsNotCreator`) | testUserCannotUpdateVaultFees_T41

Fee validation states:
(-) Total fees > MAXIMUM_FEE_FACTOR (revert: `MaximumFeeFactorExceeded`) | testCannotExceedMaximumFeeFactor_T41
(-) Creator fee increased (revert: `CreatorFeeCanOnlyBeDecreased`) | testCreatorCannotIncreaseCreatorFees_T41
(-) NFT fee decreased (revert: `NftFeeCanOnlyBeIncreased`) | testCreatorCannotDecreaseNftFees_T41
(-) RP fee decreased (revert: `RealmPointsFeeCanOnlyBeIncreased`) | testCreatorCannotDecreaseRpFees_T41
(-) Creator reduces creator fee but increases other fees by more than reduction (revert: `IncorrectFeeComposition`) | testCreatorCannotIncreaseOtherFeesMoreThanReduction_T41

(+) Creator can update fees (decrease creator fee, increase NFT/RP fees) within MAXIMUM_FEE_FACTOR | testCreatorCanUpdateVaultFees_T41

## activateCooldown + executeActivateCooldown

Contract states:
(-) Contract not started (should revert) | testCannotActivateCooldownWhenNotStarted
(-) Contract paused (should revert) | testCannotActivateCooldownWhenPaused
(-) Contract under maintenance (should revert) | testCannotActivateCooldownWhenInMaintenanceMode
(+) Contract ended | testCanActivateCooldownAfterContractEnded

Vault states:
(-) Vault cooldown already activated (revert: `VaultEndTimeSet`) | testCannotActivateCooldownRepeatedly_T61
(-) Caller is not vault creator (revert: `UserIsNotCreator`) | testNonCreatorCannotActivateCooldown_T56
(-) Cannot activateCooldown on ended vault (revert: `VaultEndTimeSet`) | testCannotActivateCooldownOnEndedVault_T86461
(+) Creator can activate cooldown on their vault | testVault2ActivateCooldown_T56

## endVaults

Contract states:
(-) Contract not started (should revert) | testCannotEndVaultWhenNotStarted
(-) Contract paused (should revert) | testCannotEndVaultWhenPaused
(-) Contract under maintenance (should revert) | testCannotEndVaultWhenInMaintenanceMode
(+) Contract ended | testCanEndVaultsAfterContractEnded

Vault states:

(-) Invalid Array | testCannotEndVaultsInvalidArray_T61
(-) Vault does not exist (continue) | testContinueEndVaultsOnNonExistentVault_T61
(-) Vault cooldown not activated (continue) | testContinueEndVaultsOnVaultWithNoEndTime_T61
(-) Cooldown period not elapsed (continue) | testContinueEndVaultsOnVaultWithNoElapsedCooldown_T61
(-) Vault already ended (revert: `VaultAlreadyEnded`) | testContinueEndVaultsIfVaultRemoved_T86461
(+) endVaults executes as expected when conditions are met | testAnyoneCanEndVault

**check that track assets in executeEndVaults() only executes once, on the final**

## stakeOnBehalfOf + executeStakeOnBehalfOf

Contract states:
(-) Contract not started (should revert) | testCannotStakeOnBehalfWhenNotStarted
(-) Contract paused (should revert) | testCannotStakeOnBehalfWhenPaused
(-) Contract under maintenance (should revert) | testCannotStakeOnBehalfWhenInMaintenanceMode
(-) Contract ended (should revert) | testCannotStakeOnBehalfAfterContractEnded

Inputs checks:
(-) Invalid amounts array (revert: `InvalidArray`) | testCannotStakeOnBehalfInvalidAmountsArray_T36
(-) Invalid vaultId length (revert: `InvalidVaultId`) | testCannotStakeOnBehalfInvalidVaultIdArray_T36
(-) Invalid onBehalfOfs length (revert: `InvalidAddress`) | testCannotStakeOnBehalfInvalidAddressArray_T36

Vault states:
(-) Vault cooldown activated (revert: `VaultEndTimeSet`) | testCannotStakeOnBehalfAfterCooldownActivated_T61
(-) Vault ended (revert: `VaultEndTimeSet`) | testCannotStakeOnBehalfToEndedVault_T86461

(-) Users cannot call (revert) | testUserCannotStakeOnBehalfOf_T36
(+) Successful stakeOnBehalfOf| testOperatorCanStakeOnBehalfOfUser2_T36
