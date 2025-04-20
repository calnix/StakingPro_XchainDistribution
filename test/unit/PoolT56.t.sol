// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT51.t.sol";

abstract contract StateT56_UsersClaimRewardsFromBothVaults is StateT51_BothVaultsFeesUpdated {

    // for reference
    DataTypes.Vault vault1_T56; 
    DataTypes.Vault vault2_T56;

    DataTypes.Distribution distribution0_T56;
    DataTypes.Distribution distribution1_T56;
    //vault1
    DataTypes.VaultAccount vault1Account0_T56;
    DataTypes.VaultAccount vault1Account1_T56;
    //vault2
    DataTypes.VaultAccount vault2Account0_T56;
    DataTypes.VaultAccount vault2Account1_T56;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T56;
    DataTypes.UserAccount user1Vault1Account1_T56;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T56;
    DataTypes.UserAccount user2Vault1Account1_T56;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T56;
    DataTypes.UserAccount user1Vault2Account1_T56;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T56;
    DataTypes.UserAccount user2Vault2Account1_T56;

    function setUp() public virtual override {
        super.setUp();

        // set t56
        vm.warp(56);

        // user1 claims rewards from vault1+2
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
            //pool.claimRewards(vaultId2, 1);
        vm.stopPrank();

        // user2 claims rewards from vault1+2
        vm.startPrank(user2);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId2, 1);
        vm.stopPrank();
        
        // save state
        vault1_T56 = pool.getVault(vaultId1);
        vault2_T56 = pool.getVault(vaultId2);
        
        distribution0_T56 = getDistribution(0); 
        distribution1_T56 = getDistribution(1);

        vault1Account0_T56 = getVaultAccount(vaultId1, 0);
        vault1Account1_T56 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T56 = getVaultAccount(vaultId2, 0);
        vault2Account1_T56 = getVaultAccount(vaultId2, 1);

        user1Vault1Account0_T56 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T56 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T56 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T56 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T56 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T56 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T56 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T56 = getUserAccount(user2, vaultId2, 1);
    }
}

/**

*/

contract StateT56_UsersClaimRewardsFromBothVaultsTest is StateT56_UsersClaimRewardsFromBothVaults {

    // does not revert. allows contract state to be updated. but user should not have anything tangible to claim    
    function testRepeatedClaimRewards_T56() public {
        // get initial states
        DataTypes.VaultAccount memory vault1AccountBefore = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2AccountBefore = getVaultAccount(vaultId2, 1);
        DataTypes.UserAccount memory user1Vault1AccountBefore = getUserAccount(user1, vaultId1, 1);
        DataTypes.UserAccount memory user2Vault1AccountBefore = getUserAccount(user2, vaultId1, 1);
        DataTypes.UserAccount memory user2Vault2AccountBefore = getUserAccount(user2, vaultId2, 1);

        // attempt to claim again
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        vm.startPrank(user2);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId2, 1);
        vm.stopPrank();

        // verify vault states unchanged
        DataTypes.VaultAccount memory vault1AccountAfter = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2AccountAfter = getVaultAccount(vaultId2, 1);
        assertEq(vault1AccountAfter.totalAccRewards, vault1AccountBefore.totalAccRewards, "vault1 total rewards changed");
        assertEq(vault2AccountAfter.totalAccRewards, vault2AccountBefore.totalAccRewards, "vault2 total rewards changed");
        assertEq(vault1AccountAfter.accCreatorRewards, vault1AccountBefore.accCreatorRewards, "vault1 creator rewards changed");
        assertEq(vault2AccountAfter.accCreatorRewards, vault2AccountBefore.accCreatorRewards, "vault2 creator rewards changed");

        // verify user states unchanged
        DataTypes.UserAccount memory user1Vault1AccountAfter = getUserAccount(user1, vaultId1, 1);
        DataTypes.UserAccount memory user2Vault1AccountAfter = getUserAccount(user2, vaultId1, 1);
        DataTypes.UserAccount memory user2Vault2AccountAfter = getUserAccount(user2, vaultId2, 1);

        assertEq(user1Vault1AccountAfter.accStakingRewards, user1Vault1AccountBefore.accStakingRewards, "user1 vault1 staking rewards changed");
        assertEq(user1Vault1AccountAfter.accNftStakingRewards, user1Vault1AccountBefore.accNftStakingRewards, "user1 vault1 nft rewards changed");
        assertEq(user1Vault1AccountAfter.accRealmPointsRewards, user1Vault1AccountBefore.accRealmPointsRewards, "user1 vault1 rp rewards changed");
        assertEq(user1Vault1AccountAfter.claimedStakingRewards, user1Vault1AccountBefore.claimedStakingRewards, "user1 vault1 claimed staking changed");
        assertEq(user1Vault1AccountAfter.claimedNftRewards, user1Vault1AccountBefore.claimedNftRewards, "user1 vault1 claimed nft changed");
        assertEq(user1Vault1AccountAfter.claimedRealmPointsRewards, user1Vault1AccountBefore.claimedRealmPointsRewards, "user1 vault1 claimed rp changed");
        assertEq(user1Vault1AccountAfter.claimedCreatorRewards, user1Vault1AccountBefore.claimedCreatorRewards, "user1 vault1 claimed creator changed");

        assertEq(user2Vault1AccountAfter.accStakingRewards, user2Vault1AccountBefore.accStakingRewards, "user2 vault1 staking rewards changed");
        assertEq(user2Vault1AccountAfter.accNftStakingRewards, user2Vault1AccountBefore.accNftStakingRewards, "user2 vault1 nft rewards changed");
        assertEq(user2Vault1AccountAfter.accRealmPointsRewards, user2Vault1AccountBefore.accRealmPointsRewards, "user2 vault1 rp rewards changed");
        assertEq(user2Vault1AccountAfter.claimedStakingRewards, user2Vault1AccountBefore.claimedStakingRewards, "user2 vault1 claimed staking changed");
        assertEq(user2Vault1AccountAfter.claimedNftRewards, user2Vault1AccountBefore.claimedNftRewards, "user2 vault1 claimed nft changed");
        assertEq(user2Vault1AccountAfter.claimedRealmPointsRewards, user2Vault1AccountBefore.claimedRealmPointsRewards, "user2 vault1 claimed rp changed");
        assertEq(user2Vault1AccountAfter.claimedCreatorRewards, user2Vault1AccountBefore.claimedCreatorRewards, "user2 vault1 claimed creator changed");

        assertEq(user2Vault2AccountAfter.accStakingRewards, user2Vault2AccountBefore.accStakingRewards, "user2 vault2 staking rewards changed");
        assertEq(user2Vault2AccountAfter.accNftStakingRewards, user2Vault2AccountBefore.accNftStakingRewards, "user2 vault2 nft rewards changed");
        assertEq(user2Vault2AccountAfter.accRealmPointsRewards, user2Vault2AccountBefore.accRealmPointsRewards, "user2 vault2 rp rewards changed");
        assertEq(user2Vault2AccountAfter.claimedStakingRewards, user2Vault2AccountBefore.claimedStakingRewards, "user2 vault2 claimed staking changed");
        assertEq(user2Vault2AccountAfter.claimedNftRewards, user2Vault2AccountBefore.claimedNftRewards, "user2 vault2 claimed nft changed");
        assertEq(user2Vault2AccountAfter.claimedRealmPointsRewards, user2Vault2AccountBefore.claimedRealmPointsRewards, "user2 vault2 claimed rp changed");
        assertEq(user2Vault2AccountAfter.claimedCreatorRewards, user2Vault2AccountBefore.claimedCreatorRewards, "user2 vault2 claimed creator changed");
    }

// ---------------- base assets ----------------

    function testPool_T56() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs - unchanged
        assertEq(pool.totalCreationNfts(), 6);
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length + vault2.creationTokenIds.length);

        // Check total staked assets: both users have committed in full
        assertEq(pool.totalStakedNfts(), 4);                         
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca);   
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp);  
        
        // check boosted assets: both vaults enjoy boosting
        
            // calculate boost factors for both vaults
            uint256 vault1BoostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
            uint256 vault2BoostFactor = 10_000 + (vault2.stakedNfts * pool.NFT_MULTIPLIER());
            
            // calculate boosted rp for each vault
            uint256 vault1BoostedRp = ((user1Rp + user2Rp/2) * vault1BoostFactor) / 10_000; // vault1 boost
            uint256 vault2BoostedRp = ((user2Rp/2) * vault2BoostFactor) / 10_000;           // vault2 boost
            uint256 expectedTotalBoostedRp = vault1BoostedRp + vault2BoostedRp;

            // calculate boosted tokens for each vault
            uint256 vault1BoostedTokens = ((user1Moca + user2Moca/2) * vault1BoostFactor) / 10_000;
            uint256 vault2BoostedTokens = ((user2Moca/2) * vault2BoostFactor) / 10_000;
            uint256 expectedTotalBoostedTokens = vault1BoostedTokens + vault2BoostedTokens;

        assertEq(pool.totalBoostedRealmPoints(), expectedTotalBoostedRp);       
        assertEq(pool.totalBoostedStakedTokens(), expectedTotalBoostedTokens);    
    }

    function testVault1_T56() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);    
        
        // Check base balances
        assertEq(vault1.stakedRealmPoints, user1Rp + user2Rp/2);
        assertEq(vault1.stakedTokens, user1Moca + user2Moca/2);
        assertEq(vault1.stakedNfts, 2);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault1.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault1.stakedTokens * boostFactor) / 10_000;
        
        assertEq(vault1.totalBoostFactor, boostFactor);
        assertEq(vault1.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault1.boostedStakedTokens, expectedBoostedTokens);

        // Check fee factors
        assertEq(vault1.nftFeeFactor, 1500);          
        assertEq(vault1.creatorFeeFactor, 0);         
        assertEq(vault1.realmPointsFeeFactor, 1500);  
    }

    function testVault2_T56() public {
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        
        // Check base balances
        assertEq(vault2.stakedRealmPoints, user2Rp/2);
        assertEq(vault2.stakedTokens, user2Moca/2);
        assertEq(vault2.stakedNfts, 2);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault2.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault2.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault2.stakedTokens * boostFactor) / 10_000;

        assertEq(vault2.totalBoostFactor, boostFactor);
        assertEq(vault2.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault2.boostedStakedTokens, expectedBoostedTokens);

        // Check fee factors
        assertEq(vault2.nftFeeFactor, 1250);          
        assertEq(vault2.creatorFeeFactor, 0);       
        assertEq(vault2.realmPointsFeeFactor, 750);  
    }

// ---------------- distribution 0 ----------------
    
    // stale: claimRewards does not update d0
    /*function testDistribution0_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** TODO
            index calc: t51 - t56   [delta: 5]
            - prev. index: 4.938e16 [t51: 49382279227480463]
            - totalEmittedSinceLastUpdate: 5e18 SP
            - vault1: (user1Rp + user2Rp/2) * 1.2 [boosted by 2 NFTs] = 1000 * 1.2 = 1200
            - vault2: (user2Rp/2) * 1.2 [boosted by 2 NFTs] = 500 * 1.2 = 600
            - totalBoostedRP = 1800e18
            index = 4.938e16 + [5e18 SP / 1800 RP]
                  = 49382279227480463 + 2777777777777777
                  ~ 5.216e16 [52160057005258240]
         */
        /*
        uint256 numOfNftsStaked = 2;                            // both vaults have 2 NFTs staked
        uint256 vault1RP = user1Rp + user2Rp/2;                 
        uint256 vault2RP = user2Rp/2;                           
        uint256 boostFactor = pool.PRECISION_BASE() + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = (vault1RP * boostFactor / pool.PRECISION_BASE()) + (vault2RP * boostFactor / pool.PRECISION_BASE());

        uint256 indexDelta = 5 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T51.index + indexDelta;
        console.log("distribution0_T51.index", distribution0_T51.index);
        console.log("indexDelta", indexDelta);
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 52160057005258240); // 5.216e16
        
        // dynamic
        assertEq(distribution.index, expectedIndex);    // 5.216e16
        assertEq(distribution.totalEmitted, distribution0_T51.totalEmitted + 5 ether);
        assertEq(distribution.lastUpdateTimeStamp, 56);
    }*/

    // stale: claimRewards does not update d0
    /*
    function testVault1Account0_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T46 - T51
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */
    /*
        // vault assets 
        uint256 stakedRp = vault1_T51.stakedRealmPoints;  
        uint256 stakedTokens = vault1_T51.stakedTokens;
        uint256 stakedNfts = vault1_T51.stakedNfts;

        uint256 boostedRp = vault1_T51.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T51.boostedRealmPoints + vault2_T51.boostedRealmPoints;

        uint256 prevVaultIndex = vault1Account0_T51.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T51.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T51.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T51.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T51.nftIndex;     // 4 nfts staked frm t31-t36
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T51.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, latestNftIndex);       
        assertEq(vaultAccount.rpIndex, latestRpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = newlyAccRewards + vault1Account0_T51.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T51.accCreatorRewards;
        uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T51.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T51.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account0_T51.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }*/

    // stale: claimRewards does not update d0
    /*
    function testVault2Account0_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        /** T46 - T51
            stakedTokens: user2Moca/2
            stakedRp: user2Rp/2
            stakedNfts: 2
         */
    /*
        // vault assets for t51-t56
        uint256 stakedRp = vault2_T51.stakedRealmPoints;  
        uint256 stakedTokens = vault2_T51.stakedTokens;
        uint256 stakedNfts = vault2_T51.stakedNfts;

        uint256 boostedRp = vault2_T51.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T51.boostedRealmPoints + vault2_T51.boostedRealmPoints;

        uint256 prevVaultIndex = vault2Account0_T51.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 
                // eval. rounding error
                uint256 emittedRewards = 5 ether;
                uint256 vault2ShareOfEmittedRewards = (boostedRp * emittedRewards) / poolBoostedRp;
                assertApproxEqAbs(newlyAccRewards, vault2ShareOfEmittedRewards, 466);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T51.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T51.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T51.realmPointsFeeFactor / 10_000;

            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account0_T51.nftIndex;   
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account0_T51.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, latestNftIndex);       
        assertEq(vaultAccount.rpIndex, latestRpIndex);  

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account0_T51.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account0_T51.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account0_T51.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account0_T51.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch"); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch"); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account0_T51.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch"); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }*/

        // stale: claimRewards does not update d0
        // --------------- d0:vault1:users --------------- 

        /*function testUser1_ForVault1Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);  
            
            //--- user1+vault1 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t51
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account0_T46.index;
                uint256 prevNftIndex = user1Vault1Account0_T46.nftIndex;
                uint256 prevRpIndex = user1Vault1Account0_T46.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account0_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account0_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account0_T46.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;
                
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch"); // 0
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");
        
            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }*/

        /*function testUser2_ForVault1Account0_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

            //--- user2+vault1: last updated at t41
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards

                // Calculate expected rewards for user2's staked tokens 
                uint256 prevUserIndex = user2Account0_T41.index;
                uint256 prevAccStakingRewards = user2Account0_T41.accStakingRewards;
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;     

                // Calculate expected rewards for nft staking
                uint256 prevAccNftStakingRewards = user2Account0_T41.accNftStakingRewards;
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T41.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 prevRpIndex = user2Account0_T41.rpIndex;
                uint256 prevAccRealmPointsRewards = user2Account0_T41.accRealmPointsRewards;
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");   //user 2 did not create vault

            //--------------------------------

            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 0);
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            
            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }*/

        // --------------- d0:vault2:users ---------------

        // user1 does not have any assets in vault2
        /*function testUser1_ForVault2Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user1+vault2
            uint256 stakedRP = 0;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0; 

            // should show 0 for all values
            
            assertEq(userAccount.index, 0, "userIndex mismatch");
            assertEq(userAccount.nftIndex, 0, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, 0, "rpIndex mismatch");

            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId2, 0);          
            uint256 expectedClaimableRewards = 0;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }*/

        /*function testUser2_ForVault2Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account0_T46.index;
                uint256 prevNftIndex = user2Vault2Account0_T46.nftIndex;
                uint256 prevRpIndex = user2Vault2Account0_T46.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account0_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account0_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T46.accRealmPointsRewards;


                // Calculate expected rewards for user2's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;               
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");    // user2: vault2 creator

            
            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 0);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);  
            
            //--- user1+vault1 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t51
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account0_T46.index;
                uint256 prevNftIndex = user1Vault1Account0_T46.nftIndex;
                uint256 prevRpIndex = user1Vault1Account0_T46.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account0_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account0_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account0_T46.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;
                
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch"); // 0
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");
        
            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }*/

// ---------------- distribution 1 ----------------

    function testDistribution1_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
            // emissions for T46-T51
            uint256 expectedEmitted = 5 ether;
            uint256 indexDelta = expectedEmitted * 1E18 / (vault1_T51.boostedStakedTokens + vault2_T51.boostedStakedTokens);
            uint256 expectedIndex = distribution1_T51.index + indexDelta;

            uint256 expectedTotalEmitted = distribution.emissionPerSecond * (block.timestamp - distribution.startTime);

        // dynamic
        assertEq(distribution.index, expectedIndex, "index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "totalEmitted mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 56, "lastUpdateTimeStamp mismatch");
    }

    function testVault1Account1_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

        /** T46 - T51
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */

        // vault assets: T51-T56
        uint256 stakedRp = user1Rp + user2Rp/2;  
        uint256 stakedTokens = user1Moca + user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault1Account1_T51.index;
        // boosted tokens
        uint256 boostedTokens = vault1_T51.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T51.boostedStakedTokens + vault2_T51.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T51.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T51.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T51.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T51.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T51.rpIndex;

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
    
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account1_T51.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T51.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T51.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T51.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T51.rewardsAccPerUnitStaked;

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards 
        // vaultAccount.totalClaimedRewards < vaultAccount.totalAccRewards | likely due to rounding from math operation in executeClaimRewards
        assertApproxEqAbs(vaultAccount.totalClaimedRewards, vaultAccount.totalAccRewards, 4314, "totalClaimedRewards mismatch");
    }

    function testVault2Account1_T56() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // vault assets: T51-T56
        uint256 stakedRp = user2Rp/2;  
        uint256 stakedTokens = user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault2Account1_T51.index;
        // boosted tokens
        uint256 boostedTokens = vault2_T51.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T51.boostedStakedTokens + vault2_T51.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T51.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T51.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T51.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account1_T51.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account1_T51.rpIndex;

        // Check indices match distribution at t41
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
        
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account1_T51.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account1_T51.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account1_T51.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account1_T51.accRealmPointsRewards;

        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");
        
        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account1_T51.rewardsAccPerUnitStaked;

        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        // vaultAccount.totalClaimedRewards < vaultAccount.totalAccRewards | likely due to rounding from math operation in executeClaimRewards
        assertApproxEqAbs(vaultAccount.totalClaimedRewards, vaultAccount.totalAccRewards, 4314, "totalClaimedRewards mismatch");
    }

        // --------------- d1:vault1:users ---------------

        function testUser1_ForVault1Account1_T56() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);  
            
            //--- user1+vault1 last updated at t51: consider the emissions from t51-t56
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t51
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account1_T51.index;
                uint256 prevNftIndex = user1Vault1Account1_T51.nftIndex;
                uint256 prevRpIndex = user1Vault1Account1_T51.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account1_T51.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account1_T51.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account1_T51.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;
                
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch"); // 0
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");
        
            // Check claimed rewards: token rewards can be claimed
            assertEq(userAccount.claimedStakingRewards, latestAccStakingRewards, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, latestAccNftStakingRewards, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, latestAccRealmPointsRewards, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, vaultAccount.accCreatorRewards, "claimedCreatorRewards mismatch");  //user1 is vault1 creator

            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;
            
            // just claimed all
            assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
        }

        function testUser2_ForVault1Account1_T56() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

            //--- user2+vault1: last updated at t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t56
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards

                // Calculate expected rewards for user2's staked tokens 
                uint256 prevUserIndex = user2Vault1Account1_T51.index;
                uint256 prevAccStakingRewards = user2Vault1Account1_T51.accStakingRewards;
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;     

                // Calculate expected rewards for nft staking
                uint256 prevAccNftStakingRewards = user2Vault1Account1_T51.accNftStakingRewards;
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Vault1Account1_T51.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 prevRpIndex = user2Vault1Account1_T51.rpIndex;
                uint256 prevAccRealmPointsRewards = user2Vault1Account1_T51.accRealmPointsRewards;
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, latestAccStakingRewards, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, latestAccNftStakingRewards, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, latestAccRealmPointsRewards, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");   //user 2 did not create vault1

            
            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            // just claimed all
            assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
        }


        // --------------- d1:vault2:users ---------------
        
        // user1 does not have any assets in vault2
        function testUser1_ForVault2Account1_T56() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user1+vault2
            uint256 stakedRP = 0;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0; 

            // should show 0 for all values
            assertEq(userAccount.index, 0, "userIndex mismatch");
            assertEq(userAccount.nftIndex, 0, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, 0, "rpIndex mismatch");

            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId2, 1);           
            assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
        }

        function testUser2_ForVault2Account1_T56() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user2+vault2 last updated at t51: consider the emissions from t51-t56
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2;
            uint256 numOfNfts = 2;

            // Check indices match vault@T56
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account1_T51.index;
                uint256 prevUserNftIndex = user2Vault2Account1_T51.nftIndex;
                uint256 prevUserRpIndex = user2Vault2Account1_T51.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account1_T51.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account1_T51.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account1_T51.accRealmPointsRewards;

                // Calculate expected rewards for user2's staked tokens
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevUserNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevUserRpIndex, 1E18) + prevAccRealmPointsRewards;
            
            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch");
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: token rewards are claimable
            assertEq(userAccount.claimedStakingRewards, latestAccStakingRewards, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, latestAccNftStakingRewards, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, latestAccRealmPointsRewards, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, vaultAccount.accCreatorRewards, "claimedCreatorRewards mismatch");    // user2 is vault2 creator

            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;
            
            // just claimed all
            assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
        }

    
// --------------- state transition ---------------

    function testNonCreatorCannotActivateCooldown_T56() public {
        
        vm.startPrank(user1);
            vm.expectRevert(Errors.UserIsNotCreator.selector);
            pool.activateCooldown(vaultId2);
        vm.stopPrank();
    }

    function testVault2ActivateCooldown_T56() public {
        uint256 expectedEndTime = block.timestamp + pool.VAULT_COOLDOWN_DURATION();

        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit VaultCooldownActivated(vaultId2, expectedEndTime);
            pool.activateCooldown(vaultId2);
        vm.stopPrank();

        // Check vault state
        DataTypes.Vault memory vault = pool.getVault(vaultId2);
        assertEq(vault.endTime, expectedEndTime, "Incorrect endTime");
    }

// ----- state transition: PoolT61p_UpdateVaultCooldown.t.sol -----
    function testUserCannotUpdateVaultCooldown_T56() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.updateVaultCooldown(5);
        vm.stopPrank();
    }
    
    function testOperatorCanUpdateVaultCooldown_T56() public {
        uint256 oldCooldown = pool.VAULT_COOLDOWN_DURATION();
        uint256 newCooldown = 5;
        assertNotEq(oldCooldown, newCooldown);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit VaultCooldownDurationUpdated(oldCooldown, newCooldown);
            pool.updateVaultCooldown(newCooldown);
        vm.stopPrank();

        // Check cooldown duration was updated
        assertEq(pool.VAULT_COOLDOWN_DURATION(), newCooldown);
    }
}   

