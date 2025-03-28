// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT31.t.sol";

abstract contract StateT36_User2UnstakesFromVault1 is StateT31_User2MigrateRpToVault2 {
    
    // for reference
    DataTypes.Vault vault1_T36; 
    DataTypes.Vault vault2_T36;

    DataTypes.Distribution distribution0_T36;
    DataTypes.Distribution distribution1_T36;
    //vault1
    DataTypes.VaultAccount vault1Account0_T36;
    DataTypes.VaultAccount vault1Account1_T36;
    //vault2
    DataTypes.VaultAccount vault2Account0_T36;
    DataTypes.VaultAccount vault2Account1_T36;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T36;
    DataTypes.UserAccount user1Vault1Account1_T36;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T36;
    DataTypes.UserAccount user2Vault1Account1_T36;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T36;
    DataTypes.UserAccount user1Vault2Account1_T36;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T36;
    DataTypes.UserAccount user2Vault2Account1_T36;


    function setUp() public virtual override {
        super.setUp();

        vm.warp(36);

        uint256[] memory nftsToUnstake = new uint256[](2);
        nftsToUnstake[0] = user2NftsArray[0];
        nftsToUnstake[1] = user2NftsArray[1];

        vm.startPrank(user2);
            // user2 unstakes half of tokens and 2nfts
            pool.unstake(vaultId1, user2Moca/2, nftsToUnstake);
        vm.stopPrank();

        // save state
        vault1_T36 = pool.getVault(vaultId1);
        vault2_T36 = pool.getVault(vaultId2);
        
        distribution0_T36 = getDistribution(0);
        distribution1_T36 = getDistribution(1);
        vault1Account0_T36 = getVaultAccount(vaultId1, 0);
        vault1Account1_T36 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T36 = getVaultAccount(vaultId2, 0);
        vault2Account1_T36 = getVaultAccount(vaultId2, 1);
        user1Vault1Account0_T36 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T36 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T36 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T36 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T36 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T36 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T36 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T36 = getUserAccount(user2, vaultId2, 1);
    }   
}   


contract StateT36_User2UnstakesFromVault1Test is StateT36_User2UnstakesFromVault1 {

    /**
        note: test stuff related to unstaking tokens+nfts
     */

    function testCannotUnstakeRepeatedly_T36() public {
        uint256[] memory nftsToUnstake = new uint256[](2);
        nftsToUnstake[0] = user2NftsArray[0];
        nftsToUnstake[1] = user2NftsArray[1];

        vm.startPrank(user2);
            vm.expectRevert();
            pool.unstake(vaultId1, 0, nftsToUnstake);
        vm.stopPrank();
    }

    // ---------------- base assets ----------------

    function testPool_T36() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs - unchanged
        assertEq(pool.totalCreationNfts(), 6);
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length + vault2.creationTokenIds.length);

        // Check total staked assets
        assertEq(pool.totalStakedNfts(), 2);                         // user2 unstaked 2 nfts frm vault1
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca/2); // user2 unstaked half of tokens
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp);  // unchanged: migrateRp
        
        // check boosted assets
        
            // only vault 1 assets enjoy boosting
            uint256 expectedBoostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
            
            // check boosted rp
            uint256 expectedUnboostedRp = user2Rp/2; // vault2 has no boost
            uint256 expectedBoostedRp = ((user1Rp + user2Rp/2) * expectedBoostFactor) / 10_000; // vault1 boost
            uint256 expectedTotalBoostedRp = expectedUnboostedRp + expectedBoostedRp;
            uint256 expectedBoostedTokens = ((user1Moca + user2Moca/2) * expectedBoostFactor) / 10_000; // vault1 boost

        assertEq(pool.totalBoostedRealmPoints(), expectedTotalBoostedRp);       
        assertEq(pool.totalBoostedStakedTokens(), expectedBoostedTokens);    
    }
    
    // user2 unstaked half of tokens + 2 nfts 
    function testVault1_T36() public {
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
    }

    // vault2 should be stale as per T31
    function testVault2_T36() public {
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

    /**
        T31 - T36: user2 migrates half his RP to vault2
         distr_0 + distr_1 updated.
         vault1 accounts updated.
         vault2 accounts NOT updated at T36 [stale T31 indexes]
         user2 accounts updated. [check: T31-T36]
         user1 NOT updated - stale. [lastupdate: t16]
         > test vault1, vault2, user2 accounts

        vault2 created at T26:
         accrues SP from T31-T36, due to migrated rp.
         does not accrue rewards from d1, no tokens staked.
         not updated at T36. stale as per T31
    */

    // ---------------- distribution 0 ----------------

    // updated: T31-T36
    function testDistribution0_T36() public {

        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** index calc: t31 - t36   [delta: 5]
            - prev. index: 3.825e16 [t31: 38253968253968253]
            - totalEmittedSinceLastUpdate: 5e18 SP
            - totalRpStaked: (500 + 500) + 500
            - boostableRp: (500 + 500), unboostableRp: 500
            - totalBoostFactor: 1000 * 4 / PRECISION_BASE = 40% [40/100]
            - totalBoostedRP: [(500 + 500) * 1.4] + 500 = 1900e18
            index = 3.825e16 + [5e18 SP / 1900 RP]
                  = 38253968253968253 + 2631578947368421
                  ~ 4.0885547e16 [40885547201336674]
         */

        uint256 numOfNftsStaked = 4;                            // user2: 4nfts staked for t31-36
        uint256 boostableRP = user1Rp + user2Rp/2;
        uint256 boostFactor = pool.PRECISION_BASE() + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = boostableRP * boostFactor / pool.PRECISION_BASE() + user2Rp/2;

        uint256 indexDelta = 5 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T31.index + indexDelta;
        console.log("distribution0_T31.index", distribution0_T31.index);
        console.log("indexDelta", indexDelta);
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 40885547201336674); // 4.088e16
        
        // dynamic
        assertEq(distribution.index, expectedIndex);    // 4.088e16
        assertEq(distribution.totalEmitted, distribution0_T31.totalEmitted + 5 ether);
        assertEq(distribution.lastUpdateTimeStamp, 36);
    }

    function testVault1Account0_T36() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T31 - T36
            stakedTokens: user1Moca + user2Moca
            stakedRp: user1Rp + user2Rp/2 [changed at T31]
            stakedNfts: 4
         */

        // vault assets 
        uint256 stakedRp = vault1_T31.stakedRealmPoints;  
        uint256 stakedTokens = vault1_T31.stakedTokens;
        uint256 stakedNfts = vault1_T31.stakedNfts;
        uint256 prevVaultIndex = vault1Account0_T31.index;
        uint256 boostedRp = vault1_T31.boostedRealmPoints;

        uint256 poolBoostedRp = vault1_T31.boostedRealmPoints + vault2_T31.boostedRealmPoints;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T36.index, prevVaultIndex, 1E18); 
                // eval. rounding error
                uint256 emittedRewards = 5 ether;
                uint256 vault1ShareOfEmittedRewards = (boostedRp * emittedRewards) / poolBoostedRp;
                assertApproxEqAbs(newlyAccRewards, vault1ShareOfEmittedRewards, 1800);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * 1000 / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * 1000 / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * 1000 / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T31.nftIndex;     // 4 nfts staked frm t31-t36
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T31.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index); // must match distribution index
        assertEq(vaultAccount.nftIndex, latestNftIndex);  // 4 nfts staked frm t31-t36
        assertEq(vaultAccount.rpIndex, latestRpIndex);    

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account0_T31.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T31.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T31.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T31.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account0_T31.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    // accrues SP from T31-T36, but NOT updated at T36; stale as per T31
    function testVault2Account0_T36() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        // Check indices match distribution at t31
        assertEq(vaultAccount.index, distribution0_T31.index);
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
        /*function testUser1_ForVault1Account0_T36() public {}*/

        // updated at T36, via unstake()
        function testUser2_ForVault1Account0_T36() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

            //--- user2 last updated at t31: consider the emissions from t31-t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca;
            uint256 numOfNfts = 4;

            // Check indices match vault@t36
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards

                // Calculate expected rewards for user1's staked tokens
                uint256 prevUserIndex = user2Account0_T31.index;
                uint256 prevAccStakingRewards = user2Account0_T31.accStakingRewards;
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 prevAccNftStakingRewards = user2Account0_T31.accNftStakingRewards;
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T31.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 prevRpIndex = user2Account0_T31.rpIndex;
                uint256 prevAccRealmPointsRewards = user2Account0_T31.accRealmPointsRewards;
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

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

        // stale: user1's account was last updated at t16. no action taken by user since.
        /*function testUser1_ForVault2Account0_T36() public {}*/
        
        // stale: updated at T31, via migrateRp()
        function testUser2_ForVault2Account0_T36() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2 last updated at t31: consider the emissions from t31-t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = 0; // no tokens staked in vault2
            uint256 numOfNfts = 0; // no NFTs staked in vault2

            // Check indices match vault@t36
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards

                // Calculate expected rewards for user2's staked tokens 
                //uint256 prevUserIndex = user2Account0_T31.index;
                //uint256 prevAccStakingRewards = user2Account0_T31.accStakingRewards;
                //uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                //uint256 prevAccNftStakingRewards = user2Account0_T31.accNftStakingRewards;
                //uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T31.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                //uint256 prevRpIndex = user2Vault2Account0_T31.rpIndex;
                //uint256 prevAccRealmPointsRewards = user2Vault2Account0_T31.accRealmPointsRewards;
                //uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

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
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 0);
            
            // calc. expected claimable rewards
                uint256 latestAccStakingRewards = 0;      
                uint256 latestAccNftStakingRewards = 0;
                
                uint256 vault2ShareOfEmissions = (5 ether * vault2_T31.boostedRealmPoints) / (vault1_T31.boostedRealmPoints + vault2_T31.boostedRealmPoints);
                // vault2 has no staked tokens, only staked RP - receives only rp fee
                uint256 user2vault2ReceivedRewards = (vault2ShareOfEmissions * (vault2_T31.realmPointsFeeFactor + vault2_T31.creatorFeeFactor)) / pool.PRECISION_BASE();
                uint256 latestAccRealmPointsRewards = user2vault2ReceivedRewards;

            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            //if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertApproxEqAbs(claimableRewards, expectedClaimableRewards, 27, "claimableRewards mismatch");

            // view fn should match account state
            //assertEq(claimableRewards, userAccount.accStakingRewards + userAccount.accNftStakingRewards + userAccount.accRealmPointsRewards, "viewFn accountState mismatch");
        }


    // ---------------- distribution 1 ----------------
    
    // STARTED AT T21
    function testDistribution1_T36() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
            // emissions for T31-T36; no change in pool.totalBoostedStakedTokens()
            uint256 expectedEmitted = 1 ether * (36 - 31);
            uint256 indexDelta = expectedEmitted * 1E18 / (vault1_T31.boostedStakedTokens + vault2_T31.boostedStakedTokens);
            uint256 expectedIndex = distribution1_T31.index + indexDelta;

            uint256 expectedTotalEmitted = distribution.emissionPerSecond * (block.timestamp - distribution.startTime);

        // dynamic
        assertEq(distribution.index, expectedIndex, "distribution index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "total emitted rewards mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 36, "last update timestamp mismatch");
    }

    // updated at t36
    function testVault1Account1_T36() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

        // vault assets: T31-T36
        uint256 stakedRp = user1Rp + user2Rp/2;  
        uint256 stakedTokens = user1Moca + user2Moca;
        uint256 stakedNfts = 4;
        // prev. vault index
        uint256 prevVaultIndex = vault1Account1_T31.index;

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 boostFactor = pool.PRECISION_BASE() + (stakedNfts * pool.NFT_MULTIPLIER());
            uint256 boostedTokenBalance = stakedTokens * boostFactor / pool.PRECISION_BASE();
            uint256 newlyAccRewards = calculateRewards(boostedTokenBalance, distribution.index, prevVaultIndex, 1E18); 
            // eval. rounding error
            uint256 newlyAccRewardsExpected = 5 ether;                   // d1 emitted 5 ether from t31-t36; only vault1 has stakedTokens
            assertApproxEqAbs(newlyAccRewards, newlyAccRewardsExpected, 1800);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault.realmPointsFeeFactor / 10_000;
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T31.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T31.rpIndex;

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
    
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account1_T31.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T31.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T31.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T31.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T31.rewardsAccPerUnitStaked;

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }
    
    // accrues SP from T31-T36, but NOT updated at T36; stale as per T31
    function testVault2Account1_T36() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // Check indices match distribution at t31
        assertEq(vaultAccount.index, distribution1_T31.index);
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
        /*function testUser1_ForVault1Account1_T36() public {}*/

        // updated at t36: unstake()
        function testUser2_ForVault1Account1_T36() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

            //--- user2 last updated at t31: consider the emissions from t31-t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca;
            uint256 numOfNfts = 4;

            // Check indices match vault@t36
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");
                
            // Check accumulated rewards
                uint256 prevUserIndex = user2Account1_T31.index;
                uint256 prevUserNftIndex = user2Account1_T31.nftIndex;
                uint256 prevUserRpIndex = user2Account1_T31.rpIndex;
                uint256 prevAccStakingRewards = user2Account1_T31.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Account1_T31.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Account1_T31.accRealmPointsRewards;

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

        // stale: user1's account was last updated at t16. no action taken by user since.
        /*function testUser1_ForVault2Account1_T36() public {}*/

        // updated at t36: unstake()
        function testUser2_ForVault2Account1_T36() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user2 last updated at t31: consider the emissions from t31-t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0;

            // Check indices match vault@t36
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards: NONE, since no stakedTokens
                //uint256 prevUserIndex = user2Account1_T31.index;
                //uint256 prevUserNftIndex = user2Account1_T31.nftIndex;
                //uint256 prevUserRpIndex = user2Account1_T31.rpIndex;
                //uint256 prevAccStakingRewards = user2Account1_T31.accStakingRewards;
                //uint256 prevAccNftStakingRewards = user2Account1_T31.accNftStakingRewards;
                //uint256 prevAccRealmPointsRewards = user2Account1_T31.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens
                //uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                //uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevUserNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                //uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevUserRpIndex, 1E18) + prevAccRealmPointsRewards;
            
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
            
        }
        
 /*   
    // connector: TODO
    function testUser2CanStakeToVault2() public {

        // initial token balances
        uint256 initialUserMocaBalance = mocaToken.balanceOf(user2);
        //uint256 initialVaultMocaBalance = mocaToken.balanceOf(vaultId2);
        uint256 initialPoolMocaBalance = mocaToken.balanceOf(address(pool));

        // Check NFT ownership via registry
        address owner0; bytes32 vaultIdOfTokenId0;
        address owner1; bytes32 vaultIdOfTokenId1;
        (owner0, vaultIdOfTokenId0) = nftRegistry.nfts(user2NftsArray[0]);
        (owner1, vaultIdOfTokenId1) = nftRegistry.nfts(user2NftsArray[1]);
        assertEq(owner0, user2); assertEq(vaultIdOfTokenId0, 0);
        assertEq(owner1, user2); assertEq(vaultIdOfTokenId1, 0);
        
        uint256[] memory nftsToStake = new uint256[](2);
        nftsToStake[0] = user2NftsArray[0];
        nftsToStake[1] = user2NftsArray[1];

        // stake
        vm.startPrank(user2);
            mocaToken.approve(address(pool), user2Moca/2);
            pool.stakeTokens(vaultId2, user2Moca/2);
            pool.stakeNfts(vaultId2, nftsToStake);
        vm.stopPrank();

        // Check token transfers
        assertEq(mocaToken.balanceOf(user2), initialUserMocaBalance - user2Moca/2);
        assertEq(mocaToken.balanceOf(address(pool)), initialPoolMocaBalance + user2Moca/2);

        // Check NFT ownership via registry
        (owner0, vaultIdOfTokenId0) = nftRegistry.nfts(user2NftsArray[0]);
        (owner1, vaultIdOfTokenId1) = nftRegistry.nfts(user2NftsArray[1]);
        assertEq(owner0, address(pool));
        assertEq(owner1, address(pool));
        assertEq(vaultIdOfTokenId0, vaultId2);
        assertEq(vaultIdOfTokenId1, vaultId2);

        // Check vault2 assets
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        assertEq(vault2.stakedTokens, user2Moca/2);
        assertEq(vault2.stakedRealmPoints, user2Rp/2);
        assertEq(vault2.stakedNfts, 2);

        // Check boosted values
        uint256 boostFactor = pool.PRECISION_BASE() + (vault2.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault2.stakedRealmPoints * boostFactor) / pool.PRECISION_BASE();
        uint256 expectedBoostedTokens = (vault2.stakedTokens * boostFactor) / pool.PRECISION_BASE();

        assertEq(vault2.totalBoostFactor, boostFactor);
        assertEq(vault2.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault2.boostedStakedTokens, expectedBoostedTokens);

        // Check pool totals
        assertEq(pool.totalStakedTokens(), user2Moca + user1Moca);
        assertEq(pool.totalStakedRealmPoints(), user2Rp + user1Rp);
        //assertEq(pool.totalBoostedStakedTokens(), expectedBoostedTokens);
        //assertEq(pool.totalBoostedRealmPoints(), expectedBoostedRp);
    }*/


// --------------- state transition: for PoolT41p_StakeOnBehalfOf.t.sol ---------------

    function testCannotStakeOnBehalfInvalidAmountsArray_T36() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId2;
        address[] memory onBehalfOfs = new address[](1);
        onBehalfOfs[0] = user2;
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(Errors.InvalidArray.selector);
        pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
    }

    function testCannotStakeOnBehalfInvalidVaultIdArray_T36() public {
        bytes32[] memory vaultIds = new bytes32[](0);
        
        address[] memory onBehalfOfs = new address[](1);
        onBehalfOfs[0] = user2;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = user2Moca/2;

        vm.expectRevert(Errors.InvalidVaultId.selector);
        pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
    }   

    function testCannotStakeOnBehalfInvalidAddressArray_T36() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId2;
        address[] memory onBehalfOfs = new address[](0);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = user2Moca/2;

        vm.expectRevert(Errors.InvalidAddress.selector);
        pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
    }

    function testUserCannotStakeOnBehalfOf_T36() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId2;
        
        address[] memory onBehalfOfs = new address[](1);
        onBehalfOfs[0] = user2;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = user2Moca/2;

        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, pool.OPERATOR_ROLE()));
            pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
        vm.stopPrank();
    }

    function testOperatorCanStakeOnBehalfOfUser2_T36() public {
        // check initial token balances
        uint256 operatorInitialBalance = mocaToken.balanceOf(operator);
        uint256 poolInitialBalance = mocaToken.balanceOf(address(pool));

        // get vault2 assets before operator stakes
        DataTypes.Vault memory vault2Before = pool.getVault(vaultId2);
        assertEq(vault2Before.stakedTokens, 0);
        
        // operator stakes on behalf of user2
        vm.startPrank(operator);
            
            bytes32[] memory vaultIds = new bytes32[](1);
            vaultIds[0] = vaultId2;
            
            address[] memory onBehalfOfs = new address[](1);
            onBehalfOfs[0] = user2;
            
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = user2Moca/2;
            
            mocaToken.approve(address(pool), user2Moca/2);
            
            vm.expectEmit(true, true, true, true);
            emit StakedOnBehalfOf(onBehalfOfs, vaultIds, amounts);
            
            pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
        vm.stopPrank();

        // check token transfers
        assertEq(mocaToken.balanceOf(operator), operatorInitialBalance - user2Moca/2, "Operator balance not reduced correctly");
        assertEq(mocaToken.balanceOf(address(pool)), poolInitialBalance + user2Moca/2, "Pool balance not increased correctly");

        // check vault2 assets
        DataTypes.Vault memory vault2After = pool.getVault(vaultId2);
        assertEq(vault2After.stakedTokens, user2Moca/2);
    }
    
}