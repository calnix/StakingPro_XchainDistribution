// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT26.t.sol";

//note: user2 migrates half his RP to vault2
abstract contract StateT31_User2MigrateRpToVault2 is StateT26_User2CreatesVault2 {

    // for reference
    DataTypes.Vault vault1_T31; 
    DataTypes.Vault vault2_T31;

    DataTypes.Distribution distribution0_T31;
    DataTypes.Distribution distribution1_T31;
    //vault1
    DataTypes.VaultAccount vault1Account0_T31;
    DataTypes.VaultAccount vault1Account1_T31;
    //vault2
    DataTypes.VaultAccount vault2Account0_T31;
    DataTypes.VaultAccount vault2Account1_T31;
    //user1+vault1
    DataTypes.UserAccount user1Account0_T31;
    DataTypes.UserAccount user1Account1_T31;
    //user2+vault1
    DataTypes.UserAccount user2Account0_T31;
    DataTypes.UserAccount user2Account1_T31;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T31;
    DataTypes.UserAccount user1Vault2Account1_T31;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T31;
    DataTypes.UserAccount user2Vault2Account1_T31;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(31);

        // user2 migrates half of assets to vault2 [migrateRp]
        vm.startPrank(user2);
            pool.migrateRealmPoints(vaultId1, vaultId2, user2Rp/2);
        vm.stopPrank();

        // save state
        vault1_T31 = pool.getVault(vaultId1);
        vault2_T31 = pool.getVault(vaultId2);
        
        distribution0_T31 = getDistribution(0);
        distribution1_T31 = getDistribution(1);
        vault1Account0_T31 = getVaultAccount(vaultId1, 0);
        vault1Account1_T31 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T31 = getVaultAccount(vaultId2, 0);
        vault2Account1_T31 = getVaultAccount(vaultId2, 1);
        user1Account0_T31 = getUserAccount(user1, vaultId1, 0);
        user1Account1_T31 = getUserAccount(user1, vaultId1, 1);
        user2Account0_T31 = getUserAccount(user2, vaultId1, 0);
        user2Account1_T31 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T31 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T31 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T31 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T31 = getUserAccount(user2, vaultId2, 1);
    }   
}

contract StateT31_User2MigrateRpToVault2Test is StateT31_User2MigrateRpToVault2 {

    /**
        note: test stuff related to migrating rp

        migrateRP by user2 frm vault1 to vault2.
         vault1 accounts updated.
         vault2 accounts updated.
         user2 accounts updated. [check: T16-T31]
         user1 NOT updated - stale. [t16 was lastupdate]

        vault2 created at T26, has accounts with both active distributions.
         but accrues no rewards of any kind to date, since nothing staked. 
         its vaultAccounts and related userAccounts should primarily be 0.
     */

// ---------------- base assets ----------------

    //pool & vaults should be updated
    function testPool_T31() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs - unchanged
        assertEq(pool.totalCreationNfts(), 5 + 1);
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length + vault2.creationTokenIds.length);

        // Check total staked assets - unchanged since migration just moves RP between vaults
        assertEq(pool.totalStakedNfts(), 4); // user2's 4 NFTs staked in vault1
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca);

        // RP totals
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp);
        assertEq(pool.totalStakedRealmPoints(), vault1.stakedRealmPoints + vault2.stakedRealmPoints);
        
        // Check vault1 balances
        assertEq(vault1.stakedRealmPoints, user1Rp + user2Rp/2); // Half of user2's RP moved out
        assertEq(vault1.stakedTokens, user1Moca + user2Moca); // Tokens unchanged
        assertEq(vault1.stakedNfts, 4); // user2's 4 NFTs

        // Check vault2 balances
        assertEq(vault2.stakedRealmPoints, user2Rp/2); // Half of user2's RP moved in
        assertEq(vault2.stakedTokens, 0);  // no tokens moved
        assertEq(vault2.stakedNfts, 0);    // no NFTs staked yet

        // Check boosted balances
        uint256 vault1BoostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 vault2BoostFactor = 10_000 + (vault2.stakedNfts * pool.NFT_MULTIPLIER());

        uint256 vault1BoostedRp = (vault1.stakedRealmPoints * vault1BoostFactor) / 10_000;
        uint256 vault2BoostedRp = (vault2.stakedRealmPoints * vault2BoostFactor) / 10_000;
        uint256 vault1BoostedTokens = (vault1.stakedTokens * vault1BoostFactor) / 10_000;

        assertEq(pool.totalBoostedRealmPoints(), vault1BoostedRp + vault2BoostedRp);
        assertEq(pool.totalBoostedStakedTokens(), vault1BoostedTokens); // Only vault1 has tokens
    }

    function testVault1_T31() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        
        // Check base balances
        assertEq(vault1.stakedRealmPoints, user1Rp + user2Rp/2);
        assertEq(vault1.stakedTokens, user1Moca + user2Moca);
        assertEq(vault1.stakedNfts, 4);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault1.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault1.stakedTokens * boostFactor) / 10_000;
        
        assertEq(vault1.totalBoostFactor, boostFactor);
        assertEq(vault1.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault1.boostedStakedTokens, expectedBoostedTokens);
    }

    function testVault2_T31() public {
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        
        // Check base balances
        assertEq(vault2.stakedRealmPoints, user2Rp/2);
        assertEq(vault2.stakedTokens, 0);
        assertEq(vault2.stakedNfts, 0);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault2.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault2.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault2.stakedTokens * boostFactor) / 10_000;

        assertEq(vault2.totalBoostFactor, boostFactor);
        assertEq(vault2.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault2.boostedStakedTokens, expectedBoostedTokens);
    }

// ---------------- distribution 0 ----------------

    function testDistribution0_T31() public {

        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, type(uint256).max);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** index calc: t16 - t30 [delta: 15]
            - prev. index: 3.111e16 [t16: 31111111111111111]
            - totalEmittedSinceLastUpdate: 15e18 SP
            - totalRpStaked: (500 + 1000)
            - totalBoostFactor: 1000 * 4 / PRECISION_BASE = 40% [40/100]
            - totalBoostedRP: (500 + 1000) * 1.4 = 2100e18
            index = 3.111e16 + [15e18 SP / 2100 RP]
                  = 3.111e16 + 0.714285e16
                  ~ 3.8253968253968253e16
         */

        uint256 totalRpStaked = user1Rp + user2Rp;
        uint256 numOfNftsStaked = 4;                            // user2: 4nfts staked for t16-t30
        uint256 boostedAmount = (totalRpStaked * (numOfNftsStaked * pool.NFT_MULTIPLIER()) / Constants.PRECISION_BASE);
        uint256 totalBoostedRp = totalRpStaked + boostedAmount;

        uint256 indexDelta = 15 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T16.index + indexDelta;
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 3.8253968253968253e16);
        
        // dynamic
        assertEq(distribution.index, expectedIndex);
        assertEq(distribution.totalEmitted, distribution0_T16.totalEmitted + 15 ether);
        assertEq(distribution.lastUpdateTimeStamp, 31);
    }

    function testVault1Account0_T31() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T16 - T31
            stakedTokens: user1 + user 2 
            stakedRp: user1 + user 2 
            stakedNfts: 4
         */
          
        // vault assets 
        uint256 stakedRp = user1Rp + user2Rp;  
        uint256 stakedTokens = user1Moca + user2Moca;
        uint256 stakedNfts = 4;
        uint256 prevVaultIndex = vault1Account0_T16.index;

        // calc. newly accrued rewards       
        uint256 boostFactor = Constants.PRECISION_BASE + (stakedNfts * pool.NFT_MULTIPLIER());
        uint256 boostedRpBalance = stakedRp * boostFactor / Constants.PRECISION_BASE;
        uint256 newlyAccRewards = calculateRewards(boostedRpBalance, distribution0_T31.index, prevVaultIndex, 1E18);
        // eval. rounding error
        uint256 newlyAccRewardsExpected = 15 ether;                   // ignores rounding 
        assertApproxEqAbs(newlyAccRewards, newlyAccRewardsExpected, 1800);

        // newly accrued fees since last update: based on newlyAccRewards
        uint256 newlyAccCreatorFee = newlyAccRewards * 1000 / 10_000;
        uint256 newlyAccTotalNftFee = newlyAccRewards * 1000 / 10_000;         
        uint256 newlyAccRealmPointsFee = newlyAccRewards * 1000 / 10_000;
        
        // latest indices
        uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T16.nftIndex;     // 4 nfts staked frm t16-t31
        uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T16.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index); // must match distribution index
        assertEq(vaultAccount.nftIndex, latestNftIndex);  // 4 nfts staked frm t16-t31
        assertEq(vaultAccount.rpIndex, latestRpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = newlyAccRewards + vault1Account0_T16.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T16.accCreatorRewards;
        uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T16.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T16.accRealmPointsRewards;

        // heck accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account0_T16.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    // vault2: created at t26, has no assets staked till t31
    function testVault2Account0_T31() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        // Check indices match distribution at t31
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0);
        assertEq(vaultAccount.accRealmPointsRewards, 0);

        // Check rewards per unit staked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);  

        // Check claimed rewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    // --------------- d0:vault1:users ---------------
    
    // stale: user1's account was last updated at t16. no action taken by user since.
    function testUser1_ForVault1Account0_T31() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user 1 last updated at t16
        uint256 stakedRP = user1Rp;
        uint256 stakedTokens = user1Moca;
        
        // Check indices match vault
        assertEq(userAccount.index, user1Account0_T16.index);
        assertEq(userAccount.nftIndex, user1Account0_T16.nftIndex);
        assertEq(userAccount.rpIndex, user1Account0_T16.rpIndex);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, user1Account0_T16.accStakingRewards); 
        assertEq(userAccount.accNftStakingRewards, user1Account0_T16.accNftStakingRewards);
        assertEq(userAccount.accRealmPointsRewards, user1Account0_T16.accRealmPointsRewards);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //-------------check view fn----------------

        // Calculate pending unbooked rewards from t16-t31
        uint256 pendingAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, user1Account0_T16.index, 1E18);
        uint256 pendingAccNftStakingRewards = 0; // 0 nfts staked
        uint256 pendingAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, user1Account0_T16.rpIndex, 1E18);

        // Add previously accumulated rewards from t16
        uint256 totalAccStakingRewards = pendingAccStakingRewards + user1Account0_T16.accStakingRewards;
        uint256 totalAccNftStakingRewards = pendingAccNftStakingRewards + user1Account0_T16.accNftStakingRewards;
        uint256 totalAccRealmPointsRewards = pendingAccRealmPointsRewards + user1Account0_T16.accRealmPointsRewards;

        // Calculate total expected rewards
        uint256 expectedClaimableRewards = totalAccStakingRewards + totalAccNftStakingRewards + totalAccRealmPointsRewards;
        if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        // Check against pool.getClaimableRewards
        uint256 actualClaimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
        assertEq(actualClaimableRewards, expectedClaimableRewards);
    }

    // user2: last updated at t31, via migrateRp()
    function testUser2_ForVault1Account0_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user2 last updated at t16: consider the emissions from t16-t31
        uint256 stakedRP = user2Rp;
        uint256 stakedTokens = user2Moca;
        uint256 numOfNfts = 4;

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

        // Calculate expected rewards for user1's staked tokens
        uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, user2Account0_T16.index, 1E18) + user2Account0_T16.accStakingRewards;      
        // Calculate expected rewards for nft staking
        uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T16.nftIndex) * numOfNfts) + user2Account0_T16.accNftStakingRewards; 
        // Calculate expected rewards for rp staking
        uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, user2Account0_T16.rpIndex, 1E18) + user2Account0_T16.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
        assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
        
        //--------------------------------
        
        // view fn: user2 gets their share of total rewards
        uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 0);
        
        uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
        if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 

        // view fn should match account state
        assertEq(claimableRewards, userAccount.accStakingRewards + userAccount.accNftStakingRewards + userAccount.accRealmPointsRewards, "viewFn accountState mismatch");
    }

    // --------------- d0:vault2:users ---------------

    /*
        vault2 account's should be 0, except for vaultAccount.rewardsAccPerUnitStaked
        which should follow distribution.index

        nothing staked in vault2, so no rewards accrued to both user and vault.
    */

    // user1: last updated at t16. no action taken by user since.
    function testUser1_ForVault2Account0_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch");
        assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
    }

    // user2: last updated at t31, via migrateRp()
    function testUser2_ForVault2Account0_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch");
        assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
    }


// ---------------- distribution 1 ----------------

    // STARTED AT T21
    function testDistribution1_T31() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        uint256 expectedTotalEmitted = 1 ether * (31 - 21);
        // first index update
        uint256 expectedIndex = (expectedTotalEmitted * 1E18 / pool.totalBoostedStakedTokens());

        // dynamic
        assertEq(distribution.index, expectedIndex, "distribution index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "total emitted rewards mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 31, "last update timestamp mismatch");
    }
    
    // vault1 has assets staked, should reflect rewards: T21-T31 [d1 started at t21]
    function testVault1Account1_T31() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
        
        // vault assets: T16-T31 
        uint256 stakedRp = user1Rp + user2Rp;  
        uint256 stakedTokens = user1Moca + user2Moca;
        uint256 stakedNfts = 4;

        // -------------- check indexes --------------
            // prev. vault index
            uint256 prevVaultIndex = 0;     // first update

            // calc. newly accrued rewards       
            uint256 boostFactor = Constants.PRECISION_BASE + (stakedNfts * pool.NFT_MULTIPLIER());
            uint256 boostedTokenBalance = stakedTokens * boostFactor / Constants.PRECISION_BASE;
            uint256 newlyAccRewards = calculateRewards(boostedTokenBalance, distribution.index, prevVaultIndex, 1E18); 
            // eval. rounding error
            uint256 newlyAccRewardsExpected = 10 ether;                   // d1 started @t21
            assertApproxEqAbs(newlyAccRewards, newlyAccRewardsExpected, 1800);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault.realmPointsFeeFactor / 10_000;
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + 0;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + 0;

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
        
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + 0;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + 0;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + 0;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + 0;

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + 0;

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

    // vault2: created at t26, has no assets staked till t31
    function testVault2Account1_T31() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // Check indices match distribution at t31
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0);
        assertEq(vaultAccount.accRealmPointsRewards, 0);

        // Check rewards per unit staked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);  

        // Check claimed rewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    // --------------- d1:vault1:users ---------------

    
    // stale: user1's account was last updated at t16. no action taken by user since.
    function testUser1_ForVault1Account1_T31() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

        //--- user 1 last updated at t16
        uint256 stakedRP = user1Rp;
        uint256 stakedTokens = user1Moca;
        
        // Check indices match vault
        assertEq(userAccount.index, 0);
        assertEq(userAccount.nftIndex, 0);
        assertEq(userAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0); 
        assertEq(userAccount.accNftStakingRewards, 0);
        assertEq(userAccount.accRealmPointsRewards, 0);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //-------------check view fn----------------

        // Calculate pending unbooked rewards from t21-t31
        uint256 pendingAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, 0, 1E18);
        uint256 pendingAccNftStakingRewards = 0; // 0 nfts staked
        uint256 pendingAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, 0, 1E18);

        // Add previously accumulated rewards from t16
        uint256 totalAccStakingRewards = pendingAccStakingRewards + 0;
        uint256 totalAccNftStakingRewards = pendingAccNftStakingRewards + 0;
        uint256 totalAccRealmPointsRewards = pendingAccRealmPointsRewards + 0;

        // Calculate total expected rewards
        uint256 expectedClaimableRewards = totalAccStakingRewards + totalAccNftStakingRewards + totalAccRealmPointsRewards;
        if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        // Check against pool.getClaimableRewards
        uint256 actualClaimableRewards = pool.getClaimableRewards(user1, vaultId1, 1);
        assertEq(actualClaimableRewards, expectedClaimableRewards);
    }

    // user2: last updated at t31, via migrateRp()
    function testUser2_ForVault1Account1_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

        //--- user2 last updated at t16: consider the emissions from t16-t31
        uint256 stakedRP = user2Rp;
        uint256 stakedTokens = user2Moca;
        uint256 numOfNfts = 4;

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

        // Check accumulated rewards
            uint256 prevUserIndex = 0;
            uint256 prevUserNftIndex = 0;
            uint256 prevUserRpIndex = 0;
            uint256 prevAccStakingRewards = 0;
            uint256 prevAccNftStakingRewards = 0;
            uint256 prevAccRealmPointsRewards = 0;

            // Calculate expected rewards for user1's staked tokens
            uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
            // Calculate expected rewards for nft staking
            uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevUserNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
            // Calculate expected rewards for rp staking
            uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevUserRpIndex, 1E18) + prevAccRealmPointsRewards;

        
        assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
        assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
        
        //--------------------------------
        
        // view fn: user2 gets their share of total rewards
        uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 1);
        
        uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
        if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 

        // view fn should match account state
        assertEq(claimableRewards, userAccount.accStakingRewards + userAccount.accNftStakingRewards + userAccount.accRealmPointsRewards, "viewFn accountState mismatch");
    }

    // --------------- d1:vault2:users ---------------

    // user1: last updated at t16. no action taken by user since.
    function testUser1_ForVault2Account1_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch");
        assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
    }

    // user2: last updated at t31, via migrateRp(). 
    // user2 staked nothing into vault2 till T31
    function testUser2_ForVault2Account1_T31() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        //--- user2 last updated at t31: consider the emissions from t21-t31
        uint256 stakedRP = 0;
        uint256 stakedTokens = 0;
        uint256 numOfNfts = 0;

        // Check indices match vault@t31
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

        // Check accumulated rewards       
        assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
        assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
        assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
        assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
        assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
        assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
        
        //--------------------------------
        
        // view fn: user2 gets their share of total rewards
        uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
        
        uint256 expectedClaimableRewards = 0 + 0 + 0;
        if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 

        // view fn should match account state
        assertEq(claimableRewards, userAccount.accStakingRewards + userAccount.accNftStakingRewards + userAccount.accRealmPointsRewards, "viewFn accountState mismatch");
    }

// ---------------- others ----------------

    // TODO connector fns
    // 1. user2 cannot unstake nfts not present within vault1
    // 2. user2 can unstake the correct nfts from vault1

    function testCannotUnstakeZero_T31() public {
        vm.startPrank(user2);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.unstake(vaultId1, 0, new uint256[](0));
        vm.stopPrank();
    }

    function testCannotUnstakeMoreTokensThanStaked_T31() public {
        vm.startPrank(user2);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.unstake(vaultId1, user2Moca + 1, new uint256[](0));
        vm.stopPrank();
    }
    
    function testCannotUnstakeMoreNftsThanStaked_T31() public {
        uint256[] memory nftsToUnstake = new uint256[](6);
        nftsToUnstake[0] = user2NftsArray[0];
        nftsToUnstake[1] = user2NftsArray[1];
        nftsToUnstake[2] = user2NftsArray[2];
        nftsToUnstake[3] = user2NftsArray[3];
        nftsToUnstake[4] = user2NftsArray[4];
        nftsToUnstake[5] = 6;


        vm.startPrank(user2);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.unstake(vaultId1, 0, nftsToUnstake);
        vm.stopPrank();
    }

    function testCannotUnstakeNftsNotStaked_T31() public {
        vm.startPrank(user3);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.unstake(vaultId1, 0, user3NftsArray);
        vm.stopPrank();
    }

    function testCannotUnstakeIncorrectNfts_T31() public {
        vm.startPrank(user2);
            vm.expectRevert();
            pool.unstake(vaultId1, 0, user3NftsArray);
        vm.stopPrank();
    }

    function testCannotUnstakeNftsStakedByOtherUser_T31() public {
        vm.startPrank(user3);
            vm.expectRevert(Errors.InvalidAmount.selector);

            pool.unstake(vaultId1, 0, new uint256[](2));
        vm.stopPrank();
    }

    // user2 unstakes half their tokens and 2 nfts, from vault1
    function testUser2CanUnstakeAssets_T31() public {
        // vault state before unstake
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        DataTypes.User memory user2VaultBefore = pool.getUser(user2, vaultId1);
        // pool state before unstake
        uint256 poolNftsBefore = pool.totalStakedNfts();
        uint256 poolTokensBefore = pool.totalStakedTokens();
        uint256 poolBoostedTokensBefore = pool.totalBoostedStakedTokens(); // 2.1e20
        uint256 poolBoostedRpBefore = pool.totalBoostedRealmPoints();      // 1.9e21
        // token balances
        uint256 user2TokenBalanceBefore = mocaToken.balanceOf(user2);

        // user2 unstakes first 2 NFTs and half tokens from vault1
        uint256 tokenAmount = user2Moca/2;
        
        // Calculate the boosted tokens from token unstaking
        uint256 tokenBoostedDelta = (tokenAmount * vaultBefore.totalBoostFactor) / Constants.PRECISION_BASE;

        uint256[] memory nftsToUnstake = new uint256[](2);
            nftsToUnstake[0] = user2NftsArray[0];
            nftsToUnstake[1] = user2NftsArray[1];
        
        // Calculate boost factor reduction
        uint256 boostFactorReduction = 2 * pool.NFT_MULTIPLIER();
        
        // Calculate NFT effect on remaining tokens
        // Note: We use (vaultBefore.stakedTokens - tokenAmount) since the NFT boost affects tokens AFTER tokens are unstaked
        uint256 nftBoostedTokensDelta = ((vaultBefore.stakedTokens - tokenAmount) * boostFactorReduction) / Constants.PRECISION_BASE;

        // Calculate the total boosted tokens delta for global state
        uint256 totalBoostedTokensDelta = tokenBoostedDelta + nftBoostedTokensDelta;

        // Calculate realm points effect
        uint256 totalBoostedRealmPointsDelta = (vaultBefore.stakedRealmPoints * boostFactorReduction) / Constants.PRECISION_BASE;

        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit UnstakedTokens(user2, vaultId1, tokenAmount, tokenBoostedDelta);

            vm.expectEmit(true, true, true, true);
            emit UnstakedNfts(user2, vaultId1, nftsToUnstake, nftBoostedTokensDelta, totalBoostedRealmPointsDelta);

            pool.unstake(vaultId1, tokenAmount, nftsToUnstake);
        vm.stopPrank();

        // check token balances
        uint256 user2TokenBalanceAfter = mocaToken.balanceOf(user2);
        assertEq(user2TokenBalanceAfter, user2TokenBalanceBefore + tokenAmount, "user2 token balance mismatch");

        // Check vault balances updated
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedTokens, vaultBefore.stakedTokens - tokenAmount, "Vault tokens not reduced correctly");
        assertEq(vaultAfter.stakedNfts, vaultBefore.stakedNfts - 2, "Vault NFTs not reduced correctly");

        // Check pool balances updated
        assertEq(pool.totalStakedNfts(), poolNftsBefore - 2, "Pool NFTs not reduced correctly");
        assertEq(pool.totalStakedTokens(), poolTokensBefore - tokenAmount, "Pool tokens not reduced correctly");

        // Check boosted balances updated
        uint256 expectedVaultBoostFactor = Constants.PRECISION_BASE + ((vaultAfter.stakedNfts) * pool.NFT_MULTIPLIER());
        uint256 expectedVaultBoostedTokens = (vaultAfter.stakedTokens * expectedVaultBoostFactor) / Constants.PRECISION_BASE;
        uint256 expectedVaultBoostedRp = (vaultAfter.stakedRealmPoints * expectedVaultBoostFactor) / Constants.PRECISION_BASE;

        // vault
        assertEq(vaultAfter.totalBoostFactor, expectedVaultBoostFactor, "Vault boost factor not updated correctly");
        assertEq(vaultAfter.boostedStakedTokens, expectedVaultBoostedTokens, "Vault boosted tokens not updated correctly");
        assertEq(vaultAfter.boostedRealmPoints, expectedVaultBoostedRp, "Vault boosted RP not updated correctly");
        
        // pool
        assertEq(pool.totalBoostedStakedTokens(), poolBoostedTokensBefore - totalBoostedTokensDelta, "Pool boosted tokens not updated correctly");
        assertEq(pool.totalBoostedRealmPoints(), poolBoostedRpBefore - totalBoostedRealmPointsDelta, "Pool boosted RP not updated correctly");
    }
}