# Overview

- 2 distributions
- 2 vaults
- 2 users

Local distribution: all on same chain. Will not involve EVMVault.sol
Use of RewardsVaultV1.sol.

## Unit Testing flow: Main timeline

1. T0: Deployment
   - Deploy contracts + configuration

2. T1: Staking starts
   - User1 creates vault1
   - User1 stakes 50% of both tokens and RP into vault1

3. T6: User2 stakes into vault1
   - User2 stakes 50% of both tokens and RP into vault1
   - User2 stakes 2 NFTs into vault1

4. T11: Distribution 1 setup
   - Distribution 1 only starts at T21

5. T16: Additional staking
   - User1 stakes all remaining tokens/RP into vault1 [50% remaining]
   - User2 stakes all remaining tokens/RP + 2 NFTs into vault1 [50% remaining + 2 NFTs]

6. T21: Distribution 1 begins
   - Update creation NFTs
   - Check pending rewards view functions
   *add: check view fns for pending rewards*

7. T26: User2 creates vault2
   - vault2 is created 5 seconds into distribution 1
   - Check pool.CreationNfts()
   - Verify stale checks
    *stale checks: maybe move to 21, together w/ check view.*

8. T31: RP migration
   - User2 migrates 50% of his RP to from vault1 to vault2
   - Both vaults updated due to migrateRp()
   - Verify updates on both vaults and accounts for both distributions
    *both vaults updated due to migration: check both vaults and vaultAccounts for both distributions*

9. T36: Partial unstake
   - User2 unstakes half of his tokens+2nfts from vault1
   - Vault1 updated due to unstake()
   - Verify vault1 and account updates
    *vault1 updated due to unstake: can check vault1 and vaultAccounts for both distributions - maybe can drop due to t30 checks*

10. T41: New stake into vault2 by user2
    - User2 stakes half of his tokens+2nfts into vault2
    - vault2 updated due to stake()
    - vault1 stale

11. T46: Vault fee updates
    - Vault1: User1 updates fees
    - Vault2: User2 updates fees
    - Check proportional fee adjustments
    - [fees are dropped and increased proportionally, net transfer from creator to others]
    - [check both vaults accrue rewards from both distributions; assets staked since t46]

    Updated:
    - both distributions updated  
    - both vault accounts updated
    - user1+vault1 updated
    - *user2+vault1 NOT updated*
    - *user1+vault2 NOT updated*
    - user2+vault2 updated

12. T51: Additional fee updates
    - Vault1: User1 drops creator fees entirely [other fees remain unchanged]
    - Vault2: User2 drops creator fees entirely [other fees remain unchanged]
    - Verify fees are redistributed proportionally to other fee types
    - Check that rewards are accrued correctly, accounting for recent fee changes

    Updated:
    - both distributions updated
    - both vault accounts updated
    - user1+vault1 updated
    - user2+vault1 NOT updated
    - user1+vault2 NOT updated
    - user2+vault2 updated

13. T56: Claim Rewards
    - user1 claims rewards from vault1+d1
    - user2 claims rewards from vault2+d1
    - user1 cannot claim rewards from vault2+d1 -> nothing staked
    - This checks the combo: (user2+vault1), (user1+vault2); which was not checked at t46 or t51
    - Check that rewards are accrued correctly, accounting for recent fee changes

    Updated:
    - both distributions updated
    - both vault accounts updated
    - user1+vault1 NOT updated
    - user2+vault1 updated
    - user1+vault2 updated
    - user2+vault2 NOT updated

14. T61: Vault2: activateCooldown
    - both distributions updated
    - vault2 accounts updated
    - user2 accounts updated
    - stale: vault1 accounts, user1 accounts

15. T61+1day: Vault2: endVaults [T86461]
    - both distributions updated
    - vault2 accounts for all distributions updated
    - stale: vault1 accounts, all user accounts

16. T66+1day: Vault2: user2 unstakes [T86466]
    - unstake after vault ended: make sure its vault assets are decremented
    - claimRewards after vault ended: make sure its not earning

17. T86471: `setEndTime`
    - transition fn checks setEndTime
    - on transition, check other fns's endTime checks
    - check claimRewards

## Risk testing: parallel timeline

- test risk-related fns: pause, unpause, freeze, emergencyExit
- PoolT56p_Risk.t.sol

## Pool Management fns: parallel timeline

### `stakeOnBehalfOf`

- PoolT41p_StakeOnBehalf.t.sol
- Splits off on vault2 creation
- User2 restakes nfts and migrates RP to vault2
- User2 unstakes from tokens from vault1; but does not restake tokens
- Instead OPERATOR restakes on behalf of user2.
- User2 should be credited with the same rewards as main timeline.
- Vault2 checks and user2 accounts should tally as per main timeline's values

### `updateActiveDistributions`

- PoolT16p_UpdateActiveDistributions.t.sol
- Split at T16. [D1 created at T11]
- Update active distributions and check new limit

### `updateMaximumFeeFactor`

```solidity
// createVault()
        uint256 totalFeeFactor = nftFeeFactor + creatorFeeFactor + realmPointsFeeFactor;
        if(totalFeeFactor > MAXIMUM_FEE_FACTOR) revert Errors.MaximumFeeFactorExceeded();
```

- sum of fee factors cannot exceed maximumFeeFactor
- maximumFeeFactor determines how much of the rewards are taken as fees.
- `(1 - maximumFeeFactor)` = amount of rewards given to moca staker
- split on T46; both users update fees on both vaults

Others

- totalFeeFactor cannot exceed maximumFeeFactor.
- if maximumFeeFactor is lowered: amount of rewards taken as fees is lowered.
- if maximumFeeFactor is raised: amount of rewards taken as fees is increased.
- creatorFeeFactor can only be lowered;

> PoolT46p_MaintenanceMode.t.sol

### `updateMinimumRealmPoints`

- PoolT6p_UpdateMinimumRealmPoints.t.sol
- t1: user1 staked half their rp
- t6: user2 staked half their rp
- transition fn on T1: updateMinimumRealmPoints
- split on T6: user2 stakes lower amount of rp

`updateCreationNfts`
- transition fn: T16
- state tested on T21

`updateVaultCooldown`
- split before activateCooldown is called on vault2
- run is parallel to main timeline, when vault2 can end in 5 seconds
- transition fn: T56 - test `updateVaultCooldown`
- split test on T61: activateCooldown w/ new cooldown period [copy T61 tests]

# `updateDistribution`[!!!]
- split sometime after distribution 1 is created
- might need a couple of parallels to test different scenarios
startTime, endTime, emissionPerSecond
- increase/decrease all vars
- combo checks: increase/decrease in totalRequired: {not started, midway}
- test endDistribution error: `if(distribution.manuallyEnded == 1) revert Errors.DistributionManuallyEnded();`

`endDistribution`
- split at T46
- end D1 then warp to T46: check that rewards are only accrued till T41, nothing further
- check claimRewards
`setRewardsVault`
- continue on the same split

## Update NFT_MULTIPLIER process

- PoolT46p_MaintenanceMode.t.sol

## Others

- partial deposits for distributions

# TODO

## Integration testing

## Migration

- v1 to v2: rewardsVault

# Future

## X-Chain

- will involve EVMVault.sol
- lz: refund
- https://docs.layerzero.network/v2/developers/evm/technical-reference/api#send
