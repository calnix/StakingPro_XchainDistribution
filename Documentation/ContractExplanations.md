# Overview

StakingPro is a contract that allows users to stake tokens, nfts and earn rewards.

- Users stake MOCA tokens, MocaNFTs, and Realm Points (RP) into vaults to earn rewards.
- Each vault is created by a MocaNFT holder who locks a certain amount of NFTs and sets the fee structure.
- Vaults have no expiry date unless deactivated by the creator.
- Vault levy fees on the rewards it accrues.
- Rewards come in the form of ERC20 tokens and Staking Power (an off-chain resource).
- There are no limits on the amount of assets that can be staked.
- The contract does not issue receipt tokens (e.g. stkMOCA) for staked assets.

MocaNfts are bridged over from Mainnet to Base via [NftLocker/Registry](https://github.com/mocaverse/NftLocker) pair of contracts.

MocaTokens will be bridged over from Mainnet to Base via LayerZero.

RealmPoints are and off-chain resource, that is "onboarded" to the contract via signatures.

## Versioning

- StakingPro will be initially deployed on Base, paired with a RewardsVaultV1.sol contract.
- Subsequently, StakingPro will be updated with paired with a RewardsVaultV2.sol contract.

V1 supports distributing token rewards on Base only.
V2 supports distributing token rewards X-chain via LayerZero. This utilizes EVMVault.sol as remote deployed peers to RewardsVaultV2.sol

# Distributions, Vaults and Accounts

## Distributions

A distribution is a schedule for distributing token rewards to users for a defined period of staking activity.

Attributes of a distribution:

```solidity
    struct Distribution {
        uint256 distributionId;  // 0 for staking power
        uint256 TOKEN_PRECISION; // cannot be 0. min 1e0

        uint256 endTime;
        uint256 startTime;
        uint256 emissionPerSecond;        

        uint256 index;
        uint256 totalEmitted;
        uint256 lastUpdateTimeStamp;  

        // state
        uint256 manuallyEnded;
    }
```

Each distribution has an id. This allows for two different distributions to have the same token, but different distribution schedules.

Note that since each distribution could have a different token precision, it is important to ensure that the token precision is correctly set and handled for each distribution. We elaborate on this in the section on handling varying decimal precisions of reward tokens.

DistributionId:0 is reserved for staking power.

- staking power is an off-chain resource, and not represented by ERC20 tokens
- D0 will not emit any token rewards, and there will be no asset transfers.
- StakingPro will simply serve to account on-chain the total StakingPower accrued.

>Distribution ids are expected to be sequential, starting from 0.

### Staking Power

Staking power is distributionId:0.

- only distribution allowed to have an indefinite endTime
- only distribution that does not emit token rewards

Staking power is an off-chain resource - the contract only serves to record the allocation and accruals to users.

- not meant to be claimed by users.
- not represented as an ERC20 token.

## Vaults

A vault is a collection of staked assets by users:

- users create vaults for staking.
- users stake into vaults.
- users unstake from vaults.

Each vault has a unique id, that is generated randomly. See `_generateVaultId()`.

A vault can be thought of as a unique grouping of boosting effects and fees:

- nfts staked contribute boosting effects to other staking assets: staked Moca, staked RealmPoints.
- fees are levied on the rewards accrued by the vault.
- vault creator determines fees on vault creation and is free to update them, at any point in time.

We will explain boosting and fees in later sections.

```solidity
    struct Vault {
        address creator;
        uint256[] creationTokenIds;     // nfts staked for creation

        uint256 startTime;              
        uint256 endTime;                // cooldown ends at this time
        uint256 removed;                // flag to indicate if vault has been removed

        // fees: pct values, sum <= MAXIMUM_FEE_FACTOR
        // fee factors are expressed as w/ 1e18 precision
        uint256 nftFeeFactor;
        uint256 creatorFeeFactor;   
        uint256 realmPointsFeeFactor;

        // staked assets
        uint256 stakedNfts;            //2^8 -1 NFTs. uint8
        uint256 stakedTokens;
        uint256 stakedRealmPoints;

        // boosted balances 
        uint256 totalBoostFactor;   // no. of nfts * nftBoostFactor | 1.XXX
        uint256 boostedRealmPoints;
        uint256 boostedStakedTokens; 
    }
```

## Accounts [user, vault]

There are two types of accounts:

1. User accounts
2. Vault accounts

Since there could be multiple distributions, each with their own token rewards, there will be a unique vault account for each distribution.

- Vault account will record the vault's accrued and claimed rewards for that specific distribution.
- Will track the total rewards earned by the vault before fees are deducted.

```solidity
    //Note: Each vault has an account for each distribution
    struct VaultAccount {

        // index: reward token
        uint256 index;             //rewardsAccPerUnitBoostedBalance
        uint256 nftIndex;          //rewardsAccPerNFT
        uint256 rpIndex;           //rewardsAccPerRealmPoint 

        // rewards: reward token | based on allocPoints
        uint256 totalAccRewards;
        uint256 accCreatorRewards;   
        uint256 accNftStakingRewards;            
        uint256 accRealmPointsRewards;

        uint256 rewardsAccPerUnitStaked;    // rewardsAccPerUnitStaked: per unit rp or staked moca
        uint256 totalClaimedRewards;        // total: staking, nft, creator, rp
    }
```

Similarly, each user who stakes in a vault will have a user account per distribution that tracks:

- Their share of the vault's rewards after fees
- Their claimed rewards from that distribution
- The index used to calculate their rewards, which helps determine unclaimed rewards

This dual account system allows precise tracking of rewards at both the vault and individual user level across multiple reward distributions.

```solidity
    struct UserAccount {

        // indexes: precision is based on reward tokens
        uint256 index; 
        uint256 nftIndex;
        uint256 rpIndex;           

        //rewards: from staking MOCA; less of fees
        uint256 accStakingRewards;          // receivable      
        uint256 claimedStakingRewards;      // received

        //rewards: NFTs
        uint256 accNftStakingRewards; 
        uint256 claimedNftRewards;

        //rewards: RP
        uint256 accRealmPointsRewards; 
        uint256 claimedRealmPointsRewards;

        //rewards: creatorFees
        uint256 claimedCreatorRewards;
    }
```

### User accounts: pairwise combination of vault and distribution

**Each user account records the user's accrued and claimed rewards for that specific vault and distribution.**

Example:

- 2 distributions: d0, d1
- 2 vaults: vA, vB

Assuming user 1 has staked into both vaults, user 1 will have the following accounts:

- vA_d0: User 1's account for vault vA and distribution d0
- vA_d1: User 1's account for vault vA and distribution d1
- vB_d0: User 1's account for vault vB and distribution d0
- vB_d1: User 1's account for vault vB and distribution d1

A user will have a unique user account for each pair-wise combination of vault and distribution.

This is because each vault is a unique grouping of boosting effects, fees and therefore rewards accrued. Hence this approach.

>By this point, it should be clear that while for each distribution, a vault has a unique vaultAccount, a user has a unique userAccount for each vault.
>Implying, that if a user has staked into multiple vaults, they will have multiple userAccounts, for the same distribution.

## Update process for vaultAccount and userAccount, for a specific vault & distribution

Before enacting a state change upon a vault (e.g. stake/unstake, etc), the vault account must be updated first.
Consider the example where we want to stake to a vault. The process is as follows:

1. update all active distributions
2. update all vault accounts for specified vault [per distribution]
3. update all user accounts for specified vault  [per distribution]
4. book stake and update vault assets

The vault account is updated first, accounting for boosting effects and fees.
I.e. the vault considers its boosted balance relative to the total boosted balance of all vaults, to calculate the rewards accrued by the vault.

The user account is updated next, accounting for the user's share of the rewards accrued by the vault.

- The user account considers its unboosted balance relative to the vault's total unboosted balance, to calculate the rewards accrued by the user.
- This is because all users within the same vault enjoy the same NFT_MULTIPLIER effects.
- So we can compare them on normal terms, and ignore boosting.

*Illustration:*

![Update Flow](./updateFlow.png)

Link to the illustration: https://link.excalidraw.com/l/ZeH3y0tOi6/8T00wtHkie9

## Fees and rewards

Fees are levied on the vault's accrued rewards, before the rewards are distributed to the vault's stakers.

- creatorFee: levied to pay for the creation of the vault
- nftStakingFee: levied to pay for the staking of NFTs
- rpStakingFee: levied to pay for the staking of RP

Total fees must stay within `MAXIMUM_FEE_FACTOR`

- Creator can only decrease the creator fee share, either to reduce total fees or to increase nft/rp staking fees proportionally.
- MOCA stakers receive vault rewards after fees are deducted. Their share is calculated as `(10_000 - totalFeeFactors)` of total rewards, applying to both token and staking power rewards.

# Handling varying decimal precisions of reward tokens and staking assets

Handling varying decimal precision for reward tokens, and ensuring that the index and emission calculations are correct.

- Moca: 1e18
- Realm Points: 1e18
- Staking Power: 1e18

## 1. Decimal Precision for indexes and rewards

All indexes, rewards, fees are recorded in `1E18` precision.
Rewards are rebased to its native precision before being being transferred to the user, as per `claimRewards`.

While this has no impact on tokens of 1e18 precision, it is much more sympathetic towards tokens of lesser precision and does not subject them to intermediate rebasing actions which will result in compounded rounding down effect.

Downside, tokens with more than 1E18 precision suffer; but there aren't many of those, so its acceptable.

There should not be any issues with rewards and index calculations, as long as none of the following variables are zero:

- `timeDelta`
- `distribution.emissionPerSecond`
- `distribution.TOKEN_PRECISION`
- `totalBalance`: which could be either `totalBoostedRealmPoints` or `totalBoostedStakedTokens` [in `_updateDistributionIndex`]
- `boostedBalance`: which could be either `vault.boostedRealmPoints` or `vault.boostedStakedTokens` [in `_updateVaultAccount`]
- `user.stakedTokens`: in `_updateUserAccount`

## 2. Decimal Precision for feeFactors and NFT multiplier

`PRECISION_BASE` is expressed as `10_000`, for 2dp precision.

This applies to fee factors and NFT multiplier.

`PRECISION_BASE` is set to `10_000`.
This is used to express fee factors and NFT multiplier in 2dp precision (XX.yy%).

**On 2dp a base:**
- 100% : 10_000
- 50%  : 5000
- 1%   : 100
- 0.5% : 50
- 0.25%: 25
- 0.05%: 5
- 0.01%: 1

### 2.1 NFT Multiplier

Therefore for an nft multiplier of 10%, `NFT_MULTIPLIER` must be set to `1000`, when `PRECISION_BASE` is expressed as `10_000`.
Increasing `NFT_MULTIPLIER` beyond `10_000` changes the boost from fractional to whole number (e.g., `20_000` = 200% boost).

```solidity
        // calc. boostedStakedTokens
        uint256 incomingBoostedStakedTokens = (amount * vault.totalBoostFactor) / PRECISION_BASE;
```

Example:

```solidity
    function ret() external pure returns(uint256) {
        
        uint256 PRECISION_BASE = 10_000;
        
        uint256 vaultTotalBoostFactor = PRECISION_BASE; //init at 100%  

        uint256 NFT_MULTIPLIER = 1000;                     // 10% = 1000/10_000 = 1000/PRECISION_BASE 
        vaultTotalBoostFactor = vaultTotalBoostFactor + (1 * NFT_MULTIPLIER);   // 10_000 + 1000 = 11_000
        
        uint256 amount = 10;
        uint256 incomingBoostedStakedTokens = (amount * vaultTotalBoostFactor) / PRECISION_BASE; // amount * (11_000/10_000) = amount * 11

        return incomingBoostedStakedTokens; // RETURNS 11
    }
```

Exceeding `10_000` is acceptable for NFT_MULTIPLIER, and it can still retain 2dp precision.

```solidity
    function nftPrecision() public pure returns(uint256) {
        
        uint256 PRECISION_BASE = 10_000;
        
        uint256 amount = 1 ether;
        uint256 vault_totalBoostFactor = 20_050 * 1;  // assume 1 nft staked
        // 20_050 = 200.5%

        uint256 incomingBoostedStakedTokens = (amount * vault_totalBoostFactor) / PRECISION_BASE;

        return incomingBoostedStakedTokens;
        // 1 ether: 2005000000000000000 = 2.005 tokens 
        // 1.23 ether: 2466150000000000000 = 2.46615 tokens -> 200.5%
    }
```

**In the above example, by setting `NFT_MULTIPLIER` to `20_050`, we are able to retain 2dp precision; which is reflective of 200.5% boost.**

### 2.2 Fee Factors

Fee factors cannot exceed `MAXIMUM_FEE_FACTOR`.
In `createVault`, we check if the total fee factor exceeds `MAXIMUM_FEE_FACTOR`:

```solidity
        uint256 totalFeeFactor = fees.nftFeeFactor + fees.creatorFeeFactor + fees.realmPointsFeeFactor;
        if(totalFeeFactor > MAXIMUM_FEE_FACTOR) revert TotalFeeFactorExceeded();
```

**This is to ensure that MOCA stakers receive at least 50% of rewards.**

In `_updateUserAccount`, we calculate the fees accrued by the user:

```solidity
    // calc. creator fees
    if(vault.creatorFeeFactor > 0) {
        // fees are kept in 1E18 during intermediate calculations
        accCreatorFee = (totalAccRewards * vault.creatorFeeFactor) / params.PRECISION_BASE;
    }

    // nft fees accrued only if there were staked NFTs
    if(vault.stakedNfts > 0) {
        if(vault.nftFeeFactor > 0) {

            // indexes are denominated in 1E18 | fees are kept in 1E18 during intermediate calculations
            accTotalNftFee = (totalAccRewards * vault.nftFeeFactor) / params.PRECISION_BASE;
            vaultAccount.nftIndex += (accTotalNftFee / vault.stakedNfts);      // nftIndex: rewardsAccPerNFT            
        }
    }

    // rp fees accrued only if there were staked RP 
    if(vault.stakedRealmPoints > 0) {
        if(vault.realmPointsFeeFactor > 0) {

            // indexes are denominated in 1E18 | fees are kept in 1E18 during intermediate calculations | realmPoints are denominated in 1E18
            accRealmPointsFee = (totalAccRewards * vault.realmPointsFeeFactor) / params.PRECISION_BASE;
            vaultAccount.rpIndex += (accRealmPointsFee * 1E18) / vault.stakedRealmPoints;      // rpIndex: rewardsAccPerRP
        }
    } 
```

### 2.3 Precision_Base reference

If we only wanted to express fee factors in integer values, (meaning 0 precision), we could set `PRECISION_BASE` to `100`.

- 100% : 100
- 50%  : 50
- 1%   : 1
- 0.5% : 5
- 0.25%: 2.5
- 0.05%: 0.5
- 0.01%: 0.1

---

# Contract Walkthrough

## Constructor & Initial setup

```solidity
    constructor(
        address nftRegistry, address stakedToken, uint256 startTime_, 
        /*uint256 maxFeeFactor, uint256 minRpRequired,*/ uint256 nftMultiplier, 
        uint256 creationNftsRequired, uint256 vaultCoolDownDuration,
        address owner, address monitor, address operator,
        address storedSigner, string memory name, string memory version) payable EIP712(name, version) {...}
```

On deployment, the following must be defined:

1. address of nft registry
2. address of staked token [MOCA]
3. startTime:
    - user are only able to call staking functions after startTime.
    - Must be greater than current block timestamp.
4. nftMultiplier: multiplier factor per nft.
    - Must be greater than 0. Used to calculate rewards boost from staked NFTs
5. creationNftsRequired
6. vaultCoolDownDuration
7. owner: address that will be granted `DEFAULT_ADMIN_ROLE`, `OPERATOR_ROLE` and `MONITOR_ROLE`.
8. monitor: address that will be granted `MONITOR_ROLE` for calling `pause()`.
9. operator: address that will be granted `OPERATOR_ROLE` for parameter updates.
10. storedSigner: address used for signature verification.
11. name: name string used for EIP712 domain separator
12. version: version string used for EIP712 domain separator

This expects that the nft registry contract should be deployed in advance.

After deployment, we need to:

1. Deploy RewardsVault contract
2. Set RewardsVault address on stakingPro contract: `setRewardsVault`
3. Call `setPool` on NftRegistry contract

## Roles & Addresses

Addresses:

1. Owner multiSig
2. Risk monitoring script [EOA]
3. Operator [EOA]
4. Cron job [EOA]

Roles:

1. `MONITOR_ROLE`: For risk monitoring scripts to call `pause()`
2. `OPERATOR_ROLE`: For updating pool parameters.
3. `DEFAULT_ADMIN_ROLE`: Owner multiSig that can assign/revoke roles
4. `CRON_JOB_ROLE`: For updating vaultAccounts when a distribution ends; and calling `stakeOnBehalfOf()`.

> Roles are referred to by their bytes32 identifier

The `DEFAULT_ADMIN_ROLE`:

- Is the global admin that can grant/revoke all roles
- Is its own admin (can grant/revoke itself)
- Cannot call role-restricted functions unless explicitly granted those roles

*Note*

1. Admins can add other admins.
2. Admins can grant and revoke roles to any addresses.
3. The only way for an admin to lose its admin role is to renounce from it.

**Role Assignments:**

Owner multiSig:

- Has all roles (`MONITOR_ROLE`, `OPERATOR_ROLE`, `DEFAULT_ADMIN_ROLE`)
- Can assign/revoke roles, pause contract, update parameters

Risk Monitor [EOA]:

- Has `MONITOR_ROLE` only
- Can pause contract only

Operator [EOA]:

- Has `OPERATOR_ROLE` only
- Can update pool parameters
- Role remains unassigned by default
- When needed, Owner multisig grants role to operator
- Operator revokes own role after use

> Owner multisig calls grantRole(bytes32 role, address account) to assign the operator role.
> Operator calls revokeRole(bytes32 role, address account) to revoke the operator role from itself.

## Pool States

- ended
- paused/unpaused
- frozen
- underMaintenance

1. ended: contract is ended, as dictated by its endTime. Users can only claim rewards and unstake.
2. paused: contract is paused, all user functions revert.
3. frozen: contract is frozen, all user functions revert except for emergencyExit().
4. underMaintenance: contract is under maintenance, all user functions revert. Other privileged functions are also blocked.

### Pause/Unpause

Pausing should be used to verify any potential security issues.

- If they are not found, the contract can be unpaused.
- If there are security issues, the contract is frozen.

### Frozen

Contract is set to `frozen` when there are irreparable issues with the contract.
This is to prevent any further damage to the contract, and to ensure that the contract is not used anymore.

Once frozen, users can only call `emergencyExit()`, which will allow users to reclaim their principal staked assets.
Any unclaimed rewards and fees are forfeited.

Note: `emergencyExit()` assumes that the contract is broken and any state updates made to be invalid; hence it does not update rewards and fee calculations.

### Under Maintenance

Contract is set to `underMaintenance` when there is a need to update the `NFT_MULTIPLIER` value.

Process:
    1. enableMaintenance
    2. updateDistributions
    3. updateAllVaultAccounts
    4. updateNftMultiplier
    5. updateBoostedBalances
    6. disableMaintenance

Setting the contract to `underMaintenance` will prevent users from staking, unstaking, claiming rewards, or creating new vaults.
This is to ensure that the `NFT_MULTIPLIER` is updated correctly, and that the boosted balances are updated correctly.

### Why have both states [paused & underMaintenance]?

- maintenance fns should not be callable during a paused state.
- consider the case when a security event occurs during maintenance mode
- maintenance **should not** be allowed to continue, should stop to assess the situation.

We want the risk controls to be able to override and lock the contract if an issue occurs during maintenance process.

# User functions

## createVault

```solidity
createVault(
    uint256[] calldata tokenIds, 
    uint256 nftFeeFactor, 
    uint256 creatorFeeFactor, 
    uint256 realmPointsFeeFactor) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance
```

Creates a new vault for staking with specified fee parameters:

- `nftFeeFactor`: fee factor per nft
- `creatorFeeFactor`: fee factor for creator
- `realmPointsFeeFactor`: fee factor for realm points

Requires the creator to have the required number of creation NFTs

- creation NFTs are registered on the NFT_REGISTRY contract, and are locked.
- creation NFTs do not count towards rewards calculations.

**Known and accepted behaviour: Vault can be created, and immediately, creator can call activateCooldown() to make it cooldown.**

## stakeTokens

```solidity
stakeTokens(bytes32 vaultId, uint256 amount) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance
```

Allows users to stake tokens into a specified vault:

- Checks that the vault exists and is not ended
- Transfers tokens from user to contract

## stakeNfts

```solidity
stakeNfts(bytes32 vaultId, uint256[] calldata tokenIds) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance
```

Allows users to stake NFTs into a specified vault:

- Checks that the vault exists and is not ended
- Calls `NFT_REGISTRY.checkIfUnassignedAndOwned()`, to check if the NFTs are unassigned and owned by the user
- Calls `NFT_REGISTRY.recordStake()`, to record vault assignment so that the NFTs cannot be staked in another vault

The staked NFTs contribute to boosting the vault's staked Tokens and Realm Points, which determines its share of rewards from active distributions.

## stakeRealmPoints

```solidity
stakeRealmPoints(bytes32 vaultId, uint256 amount, uint256 expiry, bytes calldata signature) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance
```

Allows users to stake Realm Points into a specified vault:

- Checks that the vault exists and is not ended
- Amount must be greater than `MINIMUM_REALMPOINTS_REQUIRED`
- Signature must not be expired or already executed
- Signature must be valid and from the stored signer

While OZ's ECDSA.sol::recover() handles signature malleability, we incorporate a nonce to prevent race conditions.
I.e. multiple payloads with same nonce for a user can only be executed once.

Hence, the mapping `mapping(address user => uint256 nonce) public userNonces;`, reflects the next nonce for a user.
All prior nonces have been used up.

> [signature malleability](https://github.com/kadenzipfel/smart-contract-vulnerabilities/blob/master/vulnerabilities/signature-malleability.md)

## migrateRealmPoints

```solidity
migrateRealmPoints(bytes32 oldVaultId, bytes32 newVaultId, uint256 amount) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance 
```

Allows users to migrate their staked RP from one vault to another:

- Checks that the old vault exists
- Checks that the new vault exists and is not ended
- Migrates the specified amount of staked RP from the old vault to the new vault

## unstake

```solidity
unstake(bytes32 vaultId, uint256 amount, uint256[] calldata tokenIds) external whenStarted whenNotPaused whenNotUnderMaintenance
```

Allows users to unstake their staked tokens and Nfts from a specified vault:

- Checks that the vault exists and is not ended
- Unstakes the specified amount of staked tokens and/or Nfts
- Updates NFT_REGISTRY to record unstake (NFT_REGISTRY.recordUnstake)
- Users are able to unstake even if the contract's end time has been exceeded.

**Will revert w/o error if the tokenIds provided are not staked by the user.**

- The dynamic nature of the fn limits how many Nfts can be unstaked at once, due to gas cost involving array manipulations.
- The greater the number of Nfts needed to be unstaked at once, will result in increasing gas costs.
- This has no impact on unstaking tokens.

## claimRewards

```solidity
claimRewards(bytes32 vaultId, uint256 distributionId) external whenStarted whenNotPaused whenNotUnderMaintenance
```

Allows users to claim rewards from a specified vault:

- Checks that the distributionId is not 0.
- Calls RewardsVault to transfer rewards to the user

**Users are able to claim rewards even if the contract's end time has been exceeded.**


## updateVaultFees

```solidity
updateVaultFees(bytes32 vaultId, uint256 nftFeeFactor, uint256 creatorFeeFactor, uint256 realmPointsFeeFactor) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance
```

Updates the vault fee structure. Only the vault creator can update fees, with restrictions:

- Creator can only decrease their creator fee factor (but may increase other fees proportionally)
- Total fees (NFT + creator + realm points) cannot exceed `MAXIMUM_FEE_FACTOR`
- Creator cannot increase fees unilaterally

## activateCooldown

```solidity
activateCooldown(bytes32 vaultId) external whenStarted whenNotPaused whenNotUnderMaintenance
```

Activates the cooldown period for a vault:

- If `VAULT_COOLDOWN_DURATION` is 0, vault is immediately removed from circulation
- When removed, all vault's staked assets are deducted from global totals

If `VAULT_COOLDOWN_DURATION` is of non-zero value, the vault's endTime is set to `block.timestamp` + `VAULT_COOLDOWN_DURATION`.
This only sets the endTime of the vault, it does not remove from circulation.
That would be handled by the `endVaults()` function.

## endVaults

```solidity
endVaults(bytes32[] calldata vaultIds) external whenStarted whenNotPaused whenNotUnderMaintenance
```

- Ends multiple vaults
- Removes all staked assets from circulation and updates global totals
- Callable by anyone; no access control restrictions
- Checks if endTime was set, as per `activateCooldown()`, else skips to next vault

# Pool Management functions

`OPERATOR_ROLE` is required to call the following functions:

## stakeOnBehalfOf

```solidity
stakeOnBehalfOf(bytes32[] calldata vaultIds, address[] calldata onBehalfOfs, uint256[] calldata amounts) external whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance onlyRole(OPERATOR_ROLE)
```

Allows the operator/owner to stake on behalf of users:

- Checks that the vault exists and is not ended
- Transfers tokens from the function caller to the contract

## setEndTime

```solidity
setEndTime(uint256 endTime_) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- endTime can be moved forward or backward; as long its a future timestamp
- Only callable when contract is not ended or frozen

> fn updates the endTime of active distributions that have far-dated endTimes(> endTime_)
> on repeated calls, where the endTime is extended then shorted, we may want to separately update the endTime of the distributions

## setRewardsVault

```solidity
setRewardsVault(address newRewardsVault) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the rewards vault address; cannot be set to a zero address
- Only callable when contract is not ended or frozen
- Should only be updated when there are no active distributions, else reverts and txn fails will occur.

Key aspects:

- Allows deploying enhanced rewards vault contracts without modifying StakingPro
- Preserves all staked assets and earned rewards
- Takes effect immediately for future reward distributions

This provides flexibility to upgrade reward distribution logic while maintaining core staking functionality.

## updateActiveDistributions

```solidity
updateActiveDistributions(uint256 newMaxActiveAllowed) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the maximum number of active distributions allowed
- Cannot reduce below current number of active distributions

## updateMaximumFeeFactor

```solidity
updateMaximumFeeFactor(uint256 newFactor) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the storage variable `MAXIMUM_FEE_FACTOR`; which is referenced in `updateVaultFees()`.
- Can increase/decrease it to dictate total possible fees on a vault. 
- Zero amount not allowed.

> Moca stakers receive at rewards less of fees.

## updateMinimumRealmPoints

```solidity
updateMinimumRealmPoints(uint256 newAmount) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the storage variable `MINIMUM_REALMPOINTS_REQUIRED`; which is referenced in `stakeRealmPoints()`.
- Can increase/decrease it to adjust the barrier to entry.
- Zero amount not allowed.

## updateCreationNfts

```solidity
updateCreationNfts(uint256 newAmount) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the storage variable `CREATION_NFTS_REQUIRED`; which is referenced in `createVault()`.
- Zero values are accepted, allowing vault creation without NFT requirements.

## updateVaultCooldown

```solidity
updateVaultCooldown(uint256 newDuration) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- Updates the storage variable `VAULT_COOLDOWN_DURATION`; which is referenced in `activateCooldown()`.
- Zero values are accepted, allowing vaults to be ended immediately.

## setupDistribution

```solidity
setupDistribution(uint256 distributionId, uint256 distributionStartTime, uint256 distributionEndTime, uint256 emissionPerSecond, uint256 tokenPrecision,
        uint32 dstEid, bytes32 tokenAddress
    ) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE) 
```

Creates a new distribution with specified parameters:

- distributionId: Unique identifier for the distribution
- distributionStartTime: When distribution begins emitting rewards
- distributionEndTime: When distribution stops emitting rewards
- emissionPerSecond: Rate of reward token emissions
- tokenPrecision: Decimal precision of the reward token (e.g. 1e18)
- dstEid: EID of the destination chain
- tokenAddress: Address of the reward token

### Staking Power

- Distribution ID 0 is special and used only for staking power
- Runs indefinitely (endTime = 0)
- Uses 18 decimals precision
- No LayerZero parameters needed

### Token

- Distribution requires both start and end times to be specified to prevent indefinite token emissions
- Sets up the corresponding Distribution in the RewardsVault contract
- Token deposits can occur after distribution setup is complete
- StakingPro contract simply forwards claim requests to RewardsVault without checking deposit status

### LayerZero

- dstEid: EID of the destination chain
- tokenAddress: Address of the reward token

Use of bytes32 for tokenAddress is to standardize across evm and non-evm chains.

## updateDistribution

```solidity
updateDistribution(uint256 distributionId, uint256 newStartTime, uint256 newEndTime, uint256 newEmissionPerSecond) external whenNotEnded whenNotFrozen onlyRole(OPERATOR_ROLE)
```

Allows modification of parameters of an existing distribution:

- distributionId: ID of the distribution to update
- newStartTime: Can only be modified if distribution hasn't started yet. Must be in the future.
- newEndTime: Can be extended or shortened, but must be after current timestamp [`newEndTime > block.timestamp`]
- newEmissionPerSecond: Can be modified at any time to adjust reward rate

Key constraints:

- At least one parameter must be modified (non-zero)
- Cannot modify start time after distribution has begun
- New end time must be after start time
- Cannot set emission rate to 0
- Cannot modify ended distributions

This function enables flexible management of reward distributions by allowing adjustments to timing and emission rates while maintaining key invariants.

## endDistributionImmediately

```solidity
endDistributionImmediately(uint256 distributionId) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

Allows owner to immediately terminate an active distribution:

- distributionId: ID of the distribution to end
- Enables emergency termination of a distribution by setting its end time to the current block timestamp.
- Effectively stops any further rewards from being distributed while preserving all rewards earned up to that point.
- Distribution must exist and be active (not ended).
- Calls RewardsVault to set the flag `manuallyEnded=1`

This provides an emergency mechanism to halt reward distributions if needed, while ensuring already-earned rewards remain claimable.

## popEndedDistribution

```solidity
popEndedDistribution(uint256 distributionId) external whenNotEnded whenNotPaused onlyRole(OPERATOR_ROLE)
```

- executes some sanity checks before popping the distributionId from `activeDistributions`
- expects that distribution should have ended [manually or otherwise], and the final update to the distribution should have occurred
- This fn call should always follow `endDistributionImmediately`
- This fn should be called via script every time a distribution comes to an end.

# Ending Distributions

- Ended distributions are not removed automatically from activeDistributions array.
- This is intentional.
- It is the responsibility of the operator to remove ended distributions from the activeDistributions array.
- This is done via the popEndedDistribution function.

**Process:**
    1. Operator calls updateAllVaultAccounts(vaultIds[], distributionId)
    2. Ensure all vaults are updated against the recently ended distribution
    3. Once confirmed, call popEndedDistribution(distributionId)

## Why?

In a prior design, distributions would execute a final update check after ending and would be automatically popped from activeDistributions array.

However, this lead to the issue where if a vault hibernates [no state updates for extended period], and the distribution ends, the vault would not receive rewards as expected.
Since no txns updated the vault's accounts while the distribution was active, nothing would be accrued; and once the distribution ends, vaultAccounts cannot be updated against it.

### Scenario 1: Partially unbooked rewards

![hibernation_scenario1](hibernation_scenario1.png)

1. Vault is active and distribution is active.
2. Vault has staking activity that makes it eligible for rewards from distribution.
3. Vault hibernates. No txns occur for a time.
4. Distribution ends; popped from array.
5. Some time after, Vault is ended and removed
6. Delta btw vault hibernating and distribution ending is valid period for rewards
7. Since no state updating txn hit the vault in that period, the vaults indexes are stale.
8. Vault indexes remain stale till it's removed.
9. Once removed, no further updates are allowed. So users lose out on rewards for the duration of hibernation till the end.

In short, if there exists such a hibernation period for vault before it ends. It's a problem.

### Scenario 2: Completely unbooked rewards

Also, if the vault’s last staking activity was before the start of distribution - problem.

![hibernation_scenario2](hibernation_scenario2.png)

In this instance, the vault is oblivious that a new distribution occurred, since the distribution started and ended during its time of hibernation.

## Initial Solution

The crux of the problem is that a distribution ends during a vault’s hibernation phase.
This results in the inability to update the vault to match the distribution’s final index - and therefore lesser rewards.
Whether a distribution begins within a vault’s hibernation phase only determines if rewards are partially or completely unbooked.

Put differently, as long as a distribution ends before the vault, there are no issues. The vault would have come out of hibernation, and updated itself wrt to that distribution.

The initial solution was a final update check in `_updateVaultAccount`; when users claim rewards for a specified distribution, it would check if the vault had a hibernation period.

- Hibernation checks done on comparing start and end times
- If there was a hibernation period, update the vault index to match the distribution’s final index.
- However, there remains an issue with updating vault fees. See below.

![hibernation_initialSolution](hibernation_initialSolution.png)

Given that vault fees can only be lowered by the creator to benefit other participants of a vault, perhaps this is acceptable?
- This means for an affected distribution, rewards and fees are calculated once on the final update, based on the fee structure at that time.
- Assuming no one called claimRewards, the fee structure could change multiple times till the first call. 
- Changes to the vault fee structure after the first claimRewards, will have no impact. All fees and rewards have been calculated, and the book is closed.

## Alternative Solution

We opt for the alternative solution: Off-chain cron job

- When distribution ends, keep it in the activeDistributions array; do not pop.
- Operator calls `updateAllVaultAccounts` for the distribution that ended and all vaults; brings all vaults up to date.
- Operator pops the distribution, but can only be done for distributions where `block.timestamp > distribution.endTime`.

**This approach has 2 minor failings in that:**
1. This would require continued maintenance.
2. Execution gas.

We find these to be acceptable.

# Maintenance Mode functions [To update: NFT_Multiplier]

    /**    
        1. enableMaintenance
        2. updateActiveDistributions
        3. updateAllVaultAccounts
        4. updateNftMultiplier
        5. updateBoostedBalances
        6. disableMaintenance
     */

- First we update all active distributions to current timestamp.
- Relative to the snapshot, we update each vault's account, for each distribution.
- Regardless how long the updateAllVaultAccounts takes, we will not update the distribution data again.
- Since vault accounts accruals are calculated relative to the distribution indexes (i.e. delta btw v.Index and d.Index), there will not be any drift, due to time passing.
- Essentially, we are taking a snapshot of the distribution data at the start of the maintenance mode, and updating the vault accounts relative to this snapshot.
- Regardless how long updating all the vault accounts takes, the snapshot remains constant, so effectively we are updating everything to the same timestamp.
- Whatever time the update process takes, distributions will be next updated to book this period and its rewards, under the updated boosted balances.

**This is important to note that if `updateActiveDistributions` is called again, we must restarted the entire process with updating all vault accounts, as our reference point has changed.**

## Risk Management

- The expectation is that there `OPERATOR_ROLE` is only assigned to the owner multiSig at rest.
- When there is requirement to call these functions, the owner multiSig will assign and EOA address to the `OPERATOR_ROLE`.
- This EOA address is expected to be a trusted address, and will be used to power a script that will call these functions.
- Once the update process is complete, the EOA will renounce the OPERATOR_ROLE.
- Owner multiSig will continue to hold the `MONITOR_ROLE`.

## enableMaintenance

```solidity
enableMaintenance() external whenNotPaused whenNotUnderMaintenance onlyRole(OPERATOR_ROLE) 
```

- Enables maintenance mode, which disables all user functions.
- Only callable when contract is not paused.

## disableMaintenance

```solidity
disableMaintenance() external whenNotPaused whenUnderMaintenance onlyRole(OPERATOR_ROLE)
```

- Disables maintenance mode, which re-enables all user functions.
- Only callable when contract is not paused.

## updateActiveDistributions

```solidity
updateActiveDistributions() external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(OPERATOR_ROLE)
```

- Updates all active distributions to current timestamp
- This ensures all rewards are properly calculated and booked

**Note that an active distribution may be popped as part of this update process. This is why we we specify the distributionIds when calling updateAllVaultAccounts.**

## updateAllVaultAccounts

```solidity
    function updateAllVaultAccounts(bytes32[] calldata vaultIds, uint256 distributionId) external whenNotEnded whenNotPaused {
        
        if(isUnderMaintenance == 1){
            // caller must have OPERATOR role
            if(!hasRole(OPERATOR_ROLE, msg.sender)) revert Errors.InvalidCaller();
        } else {
            // caller must have CRON_JOB role
            if(!hasRole(CRON_JOB_ROLE, msg.sender)) revert Errors.InvalidCaller();
        }
        ...
```

- Updates all vault accounts for a specified distribution
- Operator must be careful to ensure that distributionIds are specified comprehensively, covering both active and recently popped distributions.
- This ensures all rewards are properly calculated and booked

## updateNftMultiplier

```solidity
updateNftMultiplier(uint256 newMultiplier) external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(OPERATOR_ROLE)
```

- Updates the NFT multiplier
- Only callable when contract is under maintenance.

## updateBoostedBalances

```solidity
updateBoostedBalances(bytes32[] calldata vaultIds) external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(OPERATOR_ROLE)
```

- This function is expected to be called multiple times, until all vaults have been updated to use the latest `NFT_MULTIPLIER` value
- Also updates the global boosted balances, based on the delta of the update to vault's boosted balances

**After cycling through all vaults, we should sanity check that the updated global boosted balances match up with the expected values. If they do not match up, we should end the contract and redeploy.**

# Risk Management functions

In the event of a suspected security issue, we pause the contract.
Pausing should only lead to unpausing or freezing.

1. Confirmed security issue: pause -> freeze -> emergencyExit
2. Security issue proves to be invalid: pause -> unpause

Functions like `endDistributionImmediately` are not remediative functions.
Where token exfiltration is the concern, RewardsVault should be similarly paused and assets withdrawn.

## pause

```solidity
pause() external whenNotPaused onlyRole(MONITOR_ROLE)
```

- pause contract
- only callable by MONITOR_ROLE
- MONITOR_ROLE is expected to be assigned to the monitoring script as well as owner multiSig

## unpause

```solidity
unpause() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE)
```

- unpause contract
- only callable by DEFAULT_ADMIN_ROLE

## freeze

```solidity
freeze() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE)
```

- freeze contract
- only callable by DEFAULT_ADMIN_ROLE
- allows `emergencyExit` to be called

## emergencyExit

Assuming black swan event, users call `emergencyExit` to exit their principal assets.
`OPERATOR_ROLE` can assist users by calling on their behalf.

1. pause(): all user fns are disabled
2. freeze(): cannot unpause; only emergencyExit() can be called
3. emergencyExit(): exfil all principal assets

```solidity
emergencyExit(bytes32[] calldata vaultIds, address onBehalfOf) external whenStarted 
```

- only callable when contract is paused and frozen
- callable by users to exfil their assets
- rewards and fees are not withdrawn; indexes are not updated.

> does not allow users to recover their rewards or fees.

**This is the contrasting point versus calling `unstakeAll` and `emergencyExit`. Why?**

- The assumption here is that the contract can no longer be trusted, and calculations and updates should not be trusted or engaged with.
- So we only look to recover the principal assets.
- Can worry about calculating what is owed off-chain at our leisure once users assets are secured.

**Function is callable by anyone, but asset transfers are made to the correct beneficiary**

- This is done by checking the `onBehalfOf` address.
- The reason for this is to allow both users and us to call the function, to allow for a swift exit.

# Execution Flows

## 1. Creating a distribution

- `setupDistribution` is called on stakingPro
- has nested call to rewardsVault to communicate necessary values: `totalRequired`, `dstEid`, `tokenAddress`
- `totalRequired` is the total amount of tokens required to be deposited
- `dstEid` is the destination EID, (assuming its a remote token)
- `tokenAddress` is the address of the token to be deposited
- `tokenAddress` is stored as bytes32, to standardize across evm and non-evm chains

Nested call within stakingPro so that we do not have to make 2 independent txns to setup distribution; reducing human error.

**The rewardsVault must be set before any distributions can be created**

- Via `pool.setRewardsVault(address(rewardsVault));`
- If not, distributions cannot be created as the nested call to rewardsVault will revert.
- Address cannot be set to a zero address.
- If RewardsVault contract is paused, distributions cannot be created or ended, rewards cannot be claimed. [revert]

## 2. Deposit tokens [Financing a distribution]

### Local token

- Token exists on the same chain as the StakingPro
- Address with `MONEY_MANAGER` role to call `deposit()` on rewardsVault
- `deposit(uint256 distributionId, uint256 amount, address from) onlyRole(MONEY_MANAGER_ROLE) external`

### Remote token

2 txn process:

- Token exists on a different chain as the StakingPro
- `MONEY_MANAGER` to call `deposit()` on **EvmVault**, which exists on the remote chain
- Increment `totalDeposited` on RewardsVault, by calling `updateRemoteBalance()`.

## 3. Withdraw tokens

### Local token

- MONEY_MANAGER to call withdraw() on rewardsVault
- `withdraw(uint256 distributionId, uint256 amount, address to) onlyRole(MONEY_MANAGER_ROLE) external`

### Remote token

2 txn process:

- MONEY_MANAGER to call `withdraw()` on EvmVault, which exists on the remote chain
- `withdraw(address token, uint256 amount, address to, uint256 distributionId) external onlyOwner`
- Decrement `totalDeposited` on RewardsVault, by calling `updateRemoteBalance()`.

## 4. Users claiming Rewards

- User to call `claimRewards()` on StakingPro
- `claimRewards(bytes32 vaultId, uint256 distributionId) external`
- After calculating rewards, will make an external call to RewardsVault to transfer rewards to user
- if the token is local, RewardsVault will transfer the rewards to the user
- if the token is remote, RewardsVault will fire off a X-chain message to the remote chain, instructing the EvmVault there to transfer rewards to the user
- `totalClaimed` is incremented on rewardsVault

Note that the RewardsVault only supports local, other remote evm chains.

> Solana is work in progress

## 5. Cooldown & Ending vaults: activateCooldown() and endVaults()

Process:

1. First, the vault creator must activate the cooldown by calling `activateCooldown()`. This sets the end time on a vault.
2. Once the end time is reached, `endVaults()` must be called on the vault. This removes the vault's staked assets from the system and updates the global boosted balances.

### activateCooldown()

- `activateCooldown()` is called when the vault creator wants to activate the cooldown period of a vault
- this signifies that the vault will come to an end in the near future
- `vault.endTime` is set to `block.timestamp` + `VAULT_COOLDOWN_DURATION`
- once `vault.endTime` is a non-zero value, users would not be able to stake anymore
- however user can continue to claim rewards and unstake at their leisure

### endVaults()

- `endVaults()` is called when the vault's end time is reached and the weight of its staked assets must be removed from the system
- this prevents assets from accruing rewards and diluting the rewards of the other active vaults
- this is necessary as there is no automated manner for this to occur
- currently this is callable by anyone, with no access control restrictions
- vault's staked assets are removed from the system
- global boosted balances are also decremented

The expectation is that we call `endVaults()` on all the vaults that have come to an end, via script.

## 6. Updating NFT_MULTIPLIER (enableMaintenance, update, disableMaintenance)

Process:

        1. enableMaintenance
        2. updateDistributions: updates all distribution indexes
        3. updateAllVaultAccounts: updates all vault indexes
        4. updateNftMultiplier: updates NFT multiplier
        5. updateBoostedBalances: updates boosted balances
        6. disableMaintenance

We will need to call `updateBoostedBalances()` multiple times to ensure all vaults have been updated.
During this process, user functions are disabled, as calling them during this process will result in incorrect calculations.

E.g. an unstake() could slip in btw `updateBoostedBalances()` calls and wreck havoc on calculations.

Hence, lock the contract, update, verify that the updated totalBoosted global values tally with the expected values.
If verification fails, end the contract and redeploy.

When all the vaults have been updated to use the latest `NFT_MULTIPLIER` value, `totalBoostedStakedTokens` and `totalBoostedRealmPoints` should match up.
This serves as a sanity check to ensure that the multiplier is updated correctly, as well as the vaults are updated correctly.

## 7. How to end stakingPro and/or migrate to a new stakingPro contract (endTime)

- Set endTime global variable via `setEndTime`.
- Users will be able to call: `unstakeAll` and `claimRewards` after `endTime`.
- `setEndTime` can be called repeatedly, by owner, to update `endTime`.
- `endTime` can be moved forward or backward.

**What if endTime is set, but there are still active distributions continuing beyond endTime?**

- `setEndTime` checks if there active distributions which would end beyond the proposed endTime input.
- For those distributions it will shorten their endTimes to the proposed endTime input.
- `totalRequired` gets updated on both StakingPro and RewardsVault as well.

## 8. Ending a distribution

- `endDistributionImmediately(uint256 distributionId)` followed by `popEndedDistribution(uint256 distributionId)`
- This function enables immediate termination of a distribution by setting its end time to the current block timestamp.
- Effectively stops any further rewards from being distributed while preserving all rewards earned up to that point.
- Distribution must exist and be active (not ended).

## 9. Migrating from old rewardsVault (V1) to new rewardsVault (V2)

Process:

1. end all active distributions on stakingPro  [users have may unclaimed rewards]
2. switch to rewardsVaultV2
3. setup old distributions on rewardsVaultV2 [via setupDistribution]

Step 3 will require an EOA address to be granted the POOL_ROLE, to be able to call setupDistribution.

Additionally, `totalClaimed` and `totalDeposited` will start from `0` on rewardsVaultV2.
These values will not be migrated over from V1 - so we must be mindful of this when migrating.

# V2: How does RewardsVaultV2 work w/ EVMVault

![alt text](image.png)

When claiming rewards for a remote distribution:

1. User calls `claimRewards()` on StakingPro
2. StakingPro calculates rewards and calls `payRewards()` on RewardsVaultV2, instructing it to pay user the calculated figure.
3. RewardsVaultV2 initiates LayerZero message to EVMVault on remote chain
4. EVMVault receives message and transfers tokens to user

The flow requires:

- EVMVault to be deployed on remote chain where reward token exists
- EVMVault to have sufficient token balance
- LayerZero messaging to be operational

>If LayerZero messaging fails, we will move to distribute rewards to users directly, via airdrop or similar.

Key considerations:

- Gas costs are higher for remote claims due to cross-chain messaging
- Slight delay between claim initiation and token receipt due to cross-chain communication
- EVMVault balance must be monitored and topped up as needed
- Owner intervention possible if LayerZero experiences issues

## 1. setupDistribution

- Call on stakingPro
- Nested call to rewardsVaultV2, token info registered
- Remains the same as setting up a local distribution, except that `dstEid` must be correctly specified

## 2. deposit tokens [financing distribution]

2 txn process:

- On the remote chain, tokens get deposited to EVMVault.sol
- Increment `totalDeposited` on RewardsVault, by calling `updateRemoteBalance()`.

**We opt to not have `EVMVault::deposit` to callback RewardsVault via LZ, as it could create a race condition:**

Example:

- 1000 token deposited on remote, 1000 tokens already recorded on home.
- 600 tokens withdrawn, 400 left. [pending update on home]
- user claimsRewards for 600 tokens
- home is stale w/ 1000 tokens, so txn clears on home.
- however on remote, txn fails, since there are insufficient tokens.

## 3. Withdraw remote tokens

2 txn process:

- Withdraw from EVMVault, since thats where the tokens were deposited to.
- Decrement `totalDeposited` on RewardsVault, by calling `updateRemoteBalance()`.

## 4. Claiming Remote Rewards

1. User calls `claimRewards()` on StakingPro
2. StakingPro calculates rewards and calls `payRewards()` on RewardsVaultV2
3. RewardsVaultV2 checks `dstEid`, and `payRewards` will trigger `_lzsend` to the corresponding EvmVault
4. EvmVault will initiate token transfer to user on remote, via `_lzReceive`

![Claiming Remote Rewards Flow](claimingRemote.png)

## 5. Updating distribution

1. Call `updateDistribution` on Pool, `totalRequired` changes
2. `totalRequired` is updated on RewardsVaultV2
3. Nothing done on EvmVault - it has no concept `totalRequired`

**Problem:**

- withdraw on remote
- home not updated, user calls [balance checks clears]
- revert on remote due to insufficient token balance

**What this means for deposit, withdraw and claiming?**

- Can deposit/withdraw freely on EVMVault. `totalRequired` must be manually referenced.
- Updates between home and remote have to be async
- Could lead to situations where `totalDeposited` on home is stale, and reflects a larger figures than the actual balance on remote
- Hence, home claimRewards txns would not revert, while those on remote would, leading to a situation where storage on home incorrectly reflects what a user has claimed.

**To avoid this, it is sensible to design it such that reverts are not an issue.**

- If `_lzReceive` fails on EVMVault.sol due to insufficient balance, store difference as unclaimable.
- When updating, avoid a situation where the incoming update could lead to shortage or invalid claims.

### If withdraw [or totalRequired decreases]

1. Reduce on home, via `updatedDistribution` on StakingPro
2. Then withdraw on remote

Incoming claimRewards calls will be immediately treated on the update, as StakingPro and RewardsVault are updated.
This prevents invalid claimRewards txns from going x-chain.

        However:

        there could be claimRewards txns in mid-flight, that were initiated just before step 1.
        due to the latency of cross-chain calls, these txns would `fail`; users would have token balances stored as 'unclaimable'.

        To avoid this issue:
         - allow some downtime between steps 1 and 2, to ensure all mid-flight claimRewards txns have time to complete.
         - once they are, proceed with step 2.

        If withdraw is immediately done step 1, some users may have their claimRewards txns 'fail'.
        - these would be perceived as legitimate txns are they were initiated on home, before step 1 occured. 
        - users will have token balances stored as 'unclaimable'
        - as their claimRewards txns were in mid-flight, when the totalRequired was updated.
        
        To avoid this, user can call `collectUnclaimedRewards` to claim their rewards.

### If deposit [or totalRequired increases]

1. Deposit on remote first.
2. Update on home, via `updatedDistribution` on StakingPro

claimRewards txns revert until sufficient balance is available on remote chain.

### other cases

Other cases of concern would be when partial deposits are made instead of the full amount upfront.
The onus in upon the operator to keep track and update accordingly.