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
(-) amount < MINIMUM_REALMPOINTS_REQUIRED revert Errors.MinimumRealmPointsRequired() | testCannotStakeRpLessThanMinimumRealmPoints
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
(+) User has nothing staked in vault | testNothingToClaimWhenNothingStaked_T51
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

## setEndTime

Contract states:
(-) Contract paused (should revert)    | testCannotSetEndTimeWhenPaused
(+) Contract under maintenance         | testCanSetEndTimeWhenInMaintenanceMode
(+) Contract not started               | testCanSetEndTimeWhenNotStarted
(+) Contract ended                     | testCanSetEndTimeAfterContractEnded

(-) Zero end time (revert: `InvalidEndTime`) | testCannotSetZeroEndTime
(-) Past end time (revert: `InvalidEndTime`) | testCannotSetEndTimeInPast
(-) Users cannot set end time (revert)       | testUserCannotSetEndTime
(-) Operator cannot set endTime when ended   | testCannotSetEndTimeAfterContractEnded
(+) Operator can set and overwrite end Time  | testCanSetEndTimeMultipleTimes
(+) Operator can set end time                | testSetContractEndTime

## setRewardsVault

Contract states:
(+) Contract not started                          | testCanSetRewardsVaultWhenNotStarted
(-) Contract paused (should revert)               | testCannotSetRewardsVaultWhenPaused
(-) Contract under maintenance (should revert)    | testCannotSetRewardsVaultWhenInMaintenanceMode
(-) Contract ended                                | testCannotSetRewardsVaultAfterContractEnded

(-) Invalid address (revert: `InvalidAddress`)                      | testCannotSetZeroAddressAsRewardsVault
(-) Active token distributions (revert: `ActiveTokenDistributions`) | testCannotSetRewardsVaultWhenTokenDistributionExists_T11
(-) Users cannot set rewards vault (revert)                         | testUserCannotSetRewardsVault

## updateMaxActiveDistributions

Contract states:
- (+) Contract not started                                | testCanUpdateActiveDistributionsWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateActiveDistributionsWhenPaused
- (+) Contract under maintenance                          | testCanUpdateActiveDistributionsWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateActiveDistributionsAfterContractEnded

- (-) Users cannot update active distributions (revert)              | testUserCannotUpdateActiveDistributions_T11
- (-) Invalid max active allowed (revert: `InvalidMaxActiveAllowed`) | testCannotSetMaxActiveDistributionsToZero_T11
- (-) Operator cannot update to decrease from current active (revert: `MaxActiveDistributions`) | testCannotUpdateActiveDistributionsToLessThanCurrent_T11
- (+) Operator can update active distributions to increase           | testCanUpdateActiveDistributionsToBeGreaterThanCurrent_T11

## updateMaximumFeeFactor

Contract states:
- (+) Contract not started                                | testCanUpdateMaximumFeeFactorWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateMaximumFeeFactorWhenPaused
- (+) Contract under maintenance                          | testCanUpdateMaximumFeeFactorWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateMaximumFeeFactorAfterContractEnded

- (-) Users cannot update maximum fee factor (revert)     | testUserCannotUpdateMaximumFeeFactor_T41
- (-) Invalid fee factor (revert: `InvalidFeeFactor`)     | testCannotSetInvalidMaximumFeeFactor_T41
- (+) Operator can update maximum fee factor              | testOperatorCanUpdateMaximumFeeFactor_T41
- (+) Operator can decrease maximum fee factor            | testCanDecreaseMaximumFeeFactor
- (+) Operator can increase maximum fee factor            | testCanIncreaseMaximumFeeFactor

## updateMinimumRealmPoints

Contract states:
- (+) Contract not started                                | testCanUpdateMinimumRealmPointsWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateMinimumRealmPointsWhenPaused
- (+) Contract under maintenance                          | testCanUpdateMinimumRealmPointsWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateMinimumRealmPointsAfterContractEnded

- (-) Users cannot update minimum realm points (revert)   | testUserCannotUpdateMinimumRealmPoints_T6
- (-) Cannot set minimum realm points to zero (revert)    | testCannotSetMinimumRealmPointsToZero_T6
- (+) Operator can update minimum realm points            | testOperatorCanUpdateMinimumRealmPoints_T6

## updateCreationNfts

Contract states:
- (+) Contract not started                                | testCanUpdateCreationNftsWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateCreationNftsWhenPaused
- (+) Contract under maintenance                          | testCanUpdateCreationNftsWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateCreationNftsAfterContractEnded

- (-) Users cannot update creation NFTs (revert)          | testUserCannotUpdateCreationNfts_T16
- (+) Can set creation NFTs to zero                       | testOperatorSetCreationNftsToZero_T16 [tests zero nft vault creation]
- (+) Operator can update creation NFTs                   | testOperatorCanUpdateCreationNfts_T16 [user 2 creates vault w/ 1 nft]

## updateVaultCooldown

Contract states:
- (+) Contract not started                                | testCanUpdateVaultCooldownWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateVaultCooldownWhenPaused
- (+) Contract under maintenance                          | testCanUpdateVaultCooldownWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateVaultCooldownAfterContractEnded

- (-) Users cannot update vault cooldown (revert)         | testUserCannotUpdateVaultCooldown_T56
- (+) Operator can update vault cooldown                  | PoolT61p_UpdateVaultCooldown.t.sol
- (+) Operator can update vault cooldown to ZERO          | PoolT61p_UpdateVaultCooldownZero.t.sol

## setupDistribution

Contract states:
- (+) Contract not started                                | testOperatorCanSetupDistributionWhenNotStarted_T0
- (-) Contract paused (should revert)                     | testCannotSetupDistributionWhenPaused
- (+) Contract under maintenance                          | testCanSetupDistributionWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotSetupDistributionAfterContractEnded

- (-) Exceeds max active distributions (revert)           | testCannotSetupDistributionExceedsMaxActiveDistributions_T6
- (-) 1st distribution NOT D0 (revert)                    | testFirstDistributionMustBeD0_T0
- (-) Zero token precision (revert)                       | testCannotSetupDistributionWithZeroTokenPrecision_T0
- (-) Invalid emission rate (revert)                      | testCannotSetupDistributionWithZeroEmissionRate_T0
- (-) Invalid distribution start time (revert)                         | testCannotSetupDistributionStartTimeBeforeContractStartTime_T6
- (-) Distribution startTime exceeds contract end time (revert) | testCannotSetupDistributionWithStartTimeExceedingEndTime_T86471
- (-) Distribution endTime exceeds contract end time (revert) | testCannotSetupDistributionWithEndTimeExceedingContractEndTime_T86471
- (-) Rebased emission rate is zero (revert)              | testCannotSetupDistributionWithRebasedEmissionRateZero_T0
- (-) Invalid distribution end time (revert)              | testCannotSetupTokenDistributionStartTimeGreaterThanEndTime_T6
- (-) Invalid Dst Eid (revert)                            | testCannotSetupTokenDistributionWithInvalidDstEid_T6
- (-) Invalid Token address (revert)                      | testCannotSetupTokenDistributionWithInvalidTokenAddress_T6
- (-) Cannot reuse distribution id                        | testCannotSetupDistributionIdDistributionAlreadySetup_T11
- (-) Invalid rewards vault (revert: `InvalidAddress`)    | testCannotSetupDistributionWithInvalidRewardsVault_T11
- (+) Emits DistributionCreated event                     | testSetupDistributionEmitsEvent_T11

- (-) Users cannot setup distribution (revert)            | testUserCannotSetupDistribution_T0 & testUserCannotSetupDistribution_T6
- (+) Operator can setup distribution                     | testOperatorCanSetupDistribution_T6

TODO

- x-chain distribution setup

## updateDistribution: PoolT16p_UpdateDistributionNotStarted.t.sol

- D0 started
- D1 not started

Contract states:

- (+) Contract not started                                | testCanUpdateDistributionWhenContractNotStarted_T0
- (-) Contract paused (should revert)                     | testCannotUpdateDistributionWhenPaused
- (+) Contract under maintenance                          | testCanUpdateDistributionWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateDistributionAfterContractEnded

### General

- (-) New startTime before contract startTime (revert)    | testCannotUpdateDistributionToStartBeforeContractStartTime_T0
- (-) New endTime exceeds contract endTime (revert)       | testCannotUpdateDistributionWithEndTimeExceedingContractEndTime_T86471
- (-) New startTime exceeds contract endTime (revert)     | testCannotUpdateDistributionWithStartTimeExceedingContractEndTime_T86471
- (-) Cannot update; all null inputs (revert)             | testCannotUpdateDistributionWithNullInputs_T0
- (-) Distribution does not exist (revert)                | testCannotUpdateNonExistentDistribution_T16p
- (-) Distribution already ended [except D0] (revert)     | testCannotUpdateEndedDistribution_T16p

### updateDistribution: startTime modification only

- (-) Cannot update startTime if distribution started (revert) | test_StartTimeModification_CannotUpdateIfStarted_T16p
- (-) New startTime must be greater than current time (revert) | test_StartTimeModification_NewStartTimeMustBeGreaterThanCurrent_T16p
- (+) Can update startTime if distribution not started         | test_StartTimeModification_CanUpdateStartTimeIfNotStarted_T16p

### updateDistribution: endTime modification only

- (-) Cannot update endTime for distribution 0 (revert)      | test_EndTimeModification_CannotUpdateEndTimeIfD0_T16p
- (-) New endTime must be greater than current time (revert) | test_EndTimeModification_CannotUpdateEndTimeIfInPast_T16p
- (-) New endTime must be after startTime (revert)           | test_EndTimeModification_CannotUpdateEndTimeIfAfterStartTime_T16p
- (-) Cannot update both times if end before start (revert)  | test_EndTimeModification_CannotUpdateBothTimesIfEndBeforeStart_T16p
- (+) Can update endTime if after startTime                  | test_EndTimeModification_CanUpdateEndTimeIfAfterStartTime_T16p
- (+) Can update both times if end after start               | test_EndTimeModification_CanUpdateBothTimesIfEndAfterStart_T16p

### updateDistribution: emissionPerSecond modification only

- (-) Cannot update emission rate to zero (revert)        | same test as testCannotUpdateDistributionWithNullInputs_T0
- (+) Can update to lower emission rate                   | test_EmissionRateModification_LowerEmissionRate_T16p
- (+) Can update to higher emission rate                  | test_EmissionRateModification_HigherEmissionRate_T16p

### updateDistribution: multiple updates

```solidity
    // 1. update startTime, endTime
    // 2. update startTime, emissionPerSecond
    // 3. update endTime, emissionPerSecond
    // 4. update startTime, endTime, emissionPerSecond
```

- (+) Can update startTime and endTime                    | testCanUpdateStartTimeAndEndTimeD1_T16p
- (+) Can update startTime and emissionPerSecond          | testCanUpdateStartTimeAndEmissionPerSecondD1_T16p
- (+) Can update endTime and emissionPerSecond            | testCanUpdateEndTimeAndEmissionPerSecondD1_T16p
- (+) Can update all fields simultaneously                | testCanUpdateAllFieldsD1_T16p

## updateDistribution: PoolT26p_UpdateDistributionStarted.t.sol

Scenario: Both D0 & D1 have started

#### D0 (Distribution 0) Update Attempts:
- (-) Cannot update startTime (revert)                    | testCannotUpdateD0StartTimeWhenStarted_T26p
- (-) Cannot update endTime (revert)                      | testCannotUpdateD0EndTimeWhenStarted_T26p
- (+) Can update emissionPerSecond                        | testCanUpdateD0EmissionRateWhenStarted_T26p
- (-) Cannot update any combination of fields (revert)    | testCannotUpdateD0MultipleFieldsWhenStarted_T26p

#### D1 (Distribution 1) Update Attempts:
- (-) Cannot update startTime (revert)                    | testCannotUpdateD1StartTimeWhenStarted_T26p
- (+) Can update endTime to extend distribution           | testCanExtendD1EndTimeWhenStarted_T26p
- (+) Can update endTime to shorten distribution          | testCanShortenD1EndTimeWhenStarted_T26p
- (+) Can update emissionPerSecond to increase rate       | testCanIncreaseD1EmissionRateWhenStarted_T26p
- (+) Can update emissionPerSecond to decrease rate       | testCanDecreaseD1EmissionRateWhenStarted_T26p
- (+) Can update both endTime and emissionPerSecond       | testCanUpdateD1EndTimeAndEmissionRateWhenStarted_T26p
- (-) Any combination of startTime should revert          | testCannotUpdateD1MultipleFieldsWhenStarted_T26p

## updateDistribution: PoolT86471p_UpdateDistributionContractEndTimeSet.t.sol

Scenario: Both D0 & D1 have started, Contract End Time set

### General

- (-) Cannot update distribution w/ endTime beyond contract endTime    | testInvalidEndTimeVersusContractEndTime_T86471p
- (-) Cannot update distribution w/ startTime beyond contract endTime  | testInvalidStartTimeVersusContractEndTime_T86471p

### D0 (Distribution 0) Update Attempts:

- (-) Cannot update endTime (revert)                      | testCannotUpdateD0EndTimeWithEndTimeSet_T86471p
- (+) Can update emissionPerSecond (revert)               | testCanUpdateD0EmissionRateWithEndTimeSet_T86471p
- (-) Cannot update any combination of fields (revert)    | testCannotUpdateD0MultipleFieldsWithEndTimeSet_T86471p

### D1 (Distribution 1) Update Attempts:

- (-) Cannot update endTime beyond contract end time      | testCannotExtendD1EndTimeBeyondContractEndTime_T86471p
- (+) Can update endTime within contract end time         | testCanUpdateD1EndTimeWithinContractEndTime_T86466
- (+) Can update emissionPerSecond                        | testCanUpdateD1EmissionRateWithEndTimeSet_T86471p
- (+) Can update both valid endTime and emissionPerSecond | testCanUpdateD1ValidEndTimeAndEmissionRate_T86471p

## endDistribution

- PoolT46p_EndDistribution.t.sol
- [PoolT41_EndDistribution Section: line 752](../test/unit/PoolT41.t.sol)

### Contract States:

- (+) Contract not started                                | testCanEndDistributionWhenStakingNotStarted
- (-) Contract paused (should revert)                     | testCannotEndDistributionWhenPaused
- (+) Contract under maintenance                          | testCanEndDistributionWhenInMaintenanceMode
- (-) Contract ended                                      | testCannotEndDistributionAfterContractEnded

### Distribution States:

- (+) Distribution not started                            | testCanEndDistributionBeforeDistributionStarts_T16
- (+) Distribution in progress                            | testCanEndDistributionWhileDistributionInProgress_T26
- (-) Distribution already ended (should revert)          | testCannotEndAlreadyEndedDistribution_T41 + testCannotEndAlreadyEndedDistribution_T46p
- (-) Distribution0 cannot be ended (special case)        | testCannotEndDistribution0_T46p
- (-) Cannot end non-existent distribution (revert)       | testCannotEndNonExistentDistribution_T46p
- (-) Cannot end distribution that was manually ended     | testCannotEndDistributionManuallyEnded_T46p

### Authorization:

- (-) Users cannot end distribution (revert)              | testUserCannotEndDistribution_T41
- (+) Operator can end distribution                       | testOperatorCanEndDistribution_T41

### RewardsVault:

- (+) Ending updates totalEmitted correctly               | testEndDistributionUpdatesTotalEmittedCorrectly
- (+) Ending updates RewardsVault state correctly         | testEndDistributionUpdatesRewardsVaultState

## popEndedDistribution

### Contract States:

- (+) Contract not started                                | testCanPopEndedDistributionWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotPopEndedDistributionWhenPaused
- (+) Contract under maintenance                          | testCanPopEndedDistributionWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotPopEndedDistributionAfterContractEnded

### Distribution States:

- (-) Cannot pop Distribution0 (special case, should revert) | testCannotPopDistribution0_T46p
- (-) Cannot pop non-existent distribution (should revert)   | testCannotPopNonExistentDistribution_T46p
- (-) Cannot pop unended distribution (should revert)        | testCannotPopActiveDistribution_T41
- (-) Cannot pop distribution if ended but not updated       | testCannotPopDistributionIfEndedButNotUpdated_T41
- (-) Cannot pop already popped distribution (should revert) | testCannotPopPoppedDistribution_T46p

### Authorization States:

- (-) Users cannot pop ended distribution (should revert)    | testUserCannotPopEndedDistribution_T46p
- (+) Operator can pop ended distribution                    | testCanPopEndedDistribution_T46p

# Maintenance Mode

- PoolT46p_MaintenanceMode.t.sol

## enableMaintenance

### Contract States:

- (+) Contract not started                                | testCanEnableMaintenanceWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotEnableMaintenanceWhenPaused
- (+) Contract not under maintenance                      | testOperatorCanEnableMaintenanceMode_T41
- (-) Contract already under maintenance (should revert)  | testOperatorCannotEnableMaintenanceWhenAlreadyInMaintenance_T46p
- (-) Contract ended (should revert)                      | testCannotEnableMaintenanceAfterContractEnded

### Authorization:

- (-) Users cannot enable maintenance (should revert)     | testUserCannotEnableMaintenanceMode_T41
- (+) Operator can enable maintenance                     | testOperatorCanEnableMaintenanceMode_T41

## disableMaintenance

### Contract States:

- (+) Contract not started                                | testCanDisableMaintenanceWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotDisableMaintenanceWhenPaused
- (-) Contract not under maintenance (should revert)      | testOperatorCannotDisableMaintenanceModeWhenNotInMaintenance_T41
- (-) Contract ended (should revert)                      | testCannotDisableMaintenanceAfterContractEnded

### Authorization:

- (-) Users cannot disable maintenance (should revert)    | testUserCannotDisableMaintenanceMode_T46p
- (+) Operator can disable maintenance                    | testOperatorCanDisableMaintenanceMode_T46p

## updateActiveDistributions

### Contract States:

- (+) Contract not started                                | testCanUpdateActiveDistributionsWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateActiveDistributionsWhenPaused
- (+) Contract under maintenance                          | testOperatorCanUpdateDistributions
- (-) Contract not under maintenance (should revert)      | testCannotUpdateActiveDistributionsWhenNotInMaintenance_T41
- (-) Contract ended (should revert)                      | testCannotUpdateActiveDistributionsAfterContractEnded

### Authorization:

- (-) Users cannot update active distributions (revert)   | testUserCannotUpdateActiveDistributions_T46p
- (+) Operator can update active distributions            | testOperatorCanUpdateDistributions

## updateAllVaultAccounts

### Contract States:

- (-) Contract not started (should revert)                | testCannotUpdateAllVaultAccountsWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateAllVaultAccountsWhenPaused
- (+) Contract under maintenance                          | testOperatorCanUpdateAllVaultAccounts
- (-) Contract not under maintenance (should revert)      | testCannotUpdateAllVaultAccountsWhenNotInMaintenance
- (-) Contract ended (should revert)                      | testCannotUpdateAllVaultAccountsAfterContractEnded

### Authorization:

- (+) CRON_JOB role can update vault accounts when not in maintenance       | testCRONJOBCanUpdateAllVaultAccountsOutOfMaintenance_T41
- (-) Operator cannot update vault accounts when not in maintenance (revert)| testOperatorCannotUpdateAllVaultAccountsOutOfMaintenance_T41
- (-) CRON_JOB role cannot update vault accounts in maintenance (revert)    | testCRONJOBCannotUpdateAllVaultAccountsInMaintenance
- (-) Users cannot update all vault accounts (revert)                       | testUserCannotUpdateAllVaultAccounts
- (+) Operator can update all vault accounts                                | testOperatorCanUpdateAllVaultAccounts

### Functionality:

- (+) Updates all vault accounts with latest distribution data            | testOperatorCanUpdateAllVaultAccounts
- (+) Works with multiple vaults                                          | testOperatorCanUpdateAllVaultAccounts
- (-) Empty vault array reverts with InvalidArray                         | testUpdateAllVaultAccounts_InvalidArray
- (-) Cannot update accounts when distribution hasn't started (revert)    | testCannotUpdateAllVaultAccounts_DistributionNotStarted_T11
- (+) Skips accounts that are already updated                             | testUpdateAllVaultAccounts_Skip_AccountAlreadyUpdated
- (+) Skips vaults that have been removed                                 | testUpdateAllVaultAccounts_Skip_VaultRemoved
- (+) Skips vaults with zero boosted balance                              | testUpdateAllVaultAccounts_Skip_ZeroBoostedBalance
- (+) Repeated calls to updateAllVaultAccounts have no effect             | testRepeatedCallOfUpdateAllVaultAccountsIsImmaterial

## updateNftMultiplier

Contract states:
- (+) Contract not started                                | testCanUpdateNftMultiplierWhenNotStarted
- (-) Contract paused (should revert)                     | testCannotUpdateNftMultiplierWhenPaused
- (+) Contract under maintenance                          | testCanUpdateNftMultiplierWhenInMaintenanceMode
- (-) Contract ended (should revert)                      | testCannotUpdateNftMultiplierAfterContractEnded

- (-) Users cannot update NFT multiplier (revert)         | testUserCannotUpdateNftMultiplier_T46p
- (-) Cannot set NFT multiplier to zero (revert)          | testCannotSetNftMultiplierToZero_T46p
- (+) Operator can update NFT multiplier                  | testOperatorCanUpdateNftMultiplier_T46p
