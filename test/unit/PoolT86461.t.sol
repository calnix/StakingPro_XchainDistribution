// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT61.t.sol";

// 61 + 1 day
abstract contract StateT86461_Vault2Ended is StateT61_Vault2CooldownActivated {

    // for reference
    DataTypes.Vault vault1_T86461; 
    DataTypes.Vault vault2_T86461;

    DataTypes.Distribution distribution0_T86461;
    DataTypes.Distribution distribution1_T86461;
    //vault1
    DataTypes.VaultAccount vault1Account0_T86461;
    DataTypes.VaultAccount vault1Account1_T86461;
    //vault2
    DataTypes.VaultAccount vault2Account0_T86461;
    DataTypes.VaultAccount vault2Account1_T86461;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T86461;
    DataTypes.UserAccount user1Vault1Account1_T86461;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T86461;
    DataTypes.UserAccount user2Vault1Account1_T86461;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T86461;
    DataTypes.UserAccount user1Vault2Account1_T86461;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T86461;
    DataTypes.UserAccount user2Vault2Account1_T86461;

    function setUp() public virtual override {
        super.setUp();

        // 61 + 1 day
        vm.warp(61 + 86400);

        // end vault2
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId2;

        pool.endVaults(vaultIds);
    
        // save state
        vault1_T86461 = pool.getVault(vaultId1);
        vault2_T86461 = pool.getVault(vaultId2);
        
        distribution0_T86461 = getDistribution(0); 
        distribution1_T86461 = getDistribution(1);

        vault1Account0_T86461 = getVaultAccount(vaultId1, 0);
        vault1Account1_T86461 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T86461 = getVaultAccount(vaultId2, 0);
        vault2Account1_T86461 = getVaultAccount(vaultId2, 1);

        user1Vault1Account0_T86461 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T86461 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T86461 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T86461 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T86461 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T86461 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T86461 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T86461 = getUserAccount(user2, vaultId2, 1);
    }
}

contract StateT86461_Vault2EndedTest is StateT86461_Vault2Ended {

    function testCannotActivateCooldownOnEndedVault_T86461() public {
        vm.startPrank(user2);
            vm.expectRevert(abi.encodeWithSelector(Errors.VaultEndTimeSet.selector, vaultId2));
            pool.activateCooldown(vaultId2);
        vm.stopPrank();
    }

// ---------------- base assets ----------------
    function testPool_T86461() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs - unchanged
        assertEq(pool.totalCreationNfts(), 5);        // only vault1 left
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length);

        // Check total staked assets: vault2 assets are gone
        assertEq(pool.totalStakedNfts(), 2);                         // vault1 has 2 staked
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca/2);   
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp/2);  
        // x-ref pool against vault1
        assertEq(pool.totalStakedNfts(), vault1_T86461.stakedNfts);                       
        assertEq(pool.totalStakedTokens(), vault1_T86461.stakedTokens);   
        assertEq(pool.totalStakedRealmPoints(), vault1_T86461.stakedRealmPoints);
        assertEq(pool.totalBoostedStakedTokens(), vault1_T86461.boostedStakedTokens);   
        assertEq(pool.totalBoostedRealmPoints(), vault1_T86461.boostedRealmPoints);
        
        // check boosted assets: vault1 enjoys boosting
        
            // calculate boost factors for both vaults
            uint256 vault1BoostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
            
            // calculate boosted rp for each vault
            uint256 vault1BoostedRp = ((user1Rp + user2Rp/2) * vault1BoostFactor) / 10_000; // vault1 boost
            uint256 expectedTotalBoostedRp = vault1BoostedRp;

            // calculate boosted tokens for each vault
            uint256 vault1BoostedTokens = ((user1Moca + user2Moca/2) * vault1BoostFactor) / 10_000;
            uint256 expectedTotalBoostedTokens = vault1BoostedTokens;

        assertEq(pool.totalBoostedRealmPoints(), expectedTotalBoostedRp);       
        assertEq(pool.totalBoostedStakedTokens(), expectedTotalBoostedTokens);
    }

    function testVault1_T86461() public {
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

    // vault2 assets are removed from the system, but still exist in the vault
    function testVault2_T86461() public {
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        assertEq(vault2.removed, 1);
        
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
    
    // previously updated at T61
    function testDistribution0_T86461() public {
        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** TODO
            index calc: t61 - t61+1day   [delta: 86400]
            - prev. index: 5.494e16 [t61: 54937834783036018]
            - totalEmittedSinceLastUpdate: 86400e18 SP
            - vault1: (user1Rp + user2Rp/2) * 1.2 [boosted by 2 NFTs] = 1000 * 1.2 = 1200
            - vault2: (user2Rp/2) * 1.2 [boosted by 2 NFTs] = 500 * 1.2 = 600
            - totalBoostedRP = 1800e18
            index = 5.494e16 + [86400e18 SP / 1800 RP]
                  = 54937834783036018 + 48000000000000000000
                  ~ 4.805e19 [48054937834783036018]
         */

        
        uint256 numOfNftsStaked = 2;                            // both vaults have 2 NFTs staked
        uint256 vault1RP = user1Rp + user2Rp/2;                 
        uint256 vault2RP = user2Rp/2;                           
        uint256 boostFactor = pool.PRECISION_BASE() + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = (vault1RP * boostFactor / pool.PRECISION_BASE()) + (vault2RP * boostFactor / pool.PRECISION_BASE());

        uint256 indexDelta = 86400 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T61.index + indexDelta;
        console.log("distribution0_T61.index", distribution0_T61.index);    
        console.log("indexDelta", indexDelta);
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 48054937834783036018); // 4.805e19
        
        // dynamic
        assertEq(distribution.index, expectedIndex);    // 4.805e19
        assertEq(distribution.totalEmitted, distribution0_T61.totalEmitted + 86400 ether);
        assertEq(distribution.lastUpdateTimeStamp, 61 + 86400);
    }

    // stale since T51: vault1 accounts not updated
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

    // previously updated at T61: 86400 ether emitted
    function testVault2Account0_T86461() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        /** T61 - T61+1day
            stakedTokens: user2Moca/2
            stakedRp: user2Rp/2
            stakedNfts: 2
         */
    
        // vault assets for t61-t61+1day
        uint256 stakedRp = vault2_T61.stakedRealmPoints;  
        uint256 stakedTokens = vault2_T61.stakedTokens;
        uint256 stakedNfts = vault2_T61.stakedNfts;

        uint256 boostedRp = vault2_T61.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T61.boostedRealmPoints + vault2_T61.boostedRealmPoints;

        uint256 prevVaultIndex = vault2Account0_T61.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 
                // eval. rounding error
                uint256 emittedRewards = 86400 ether;
                uint256 vault2ShareOfEmittedRewards = (boostedRp * emittedRewards) / poolBoostedRp;
                assertApproxEqAbs(newlyAccRewards, vault2ShareOfEmittedRewards, 466);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T61.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T61.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T61.realmPointsFeeFactor / 10_000;

            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account0_T61.nftIndex;   
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account0_T61.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, latestNftIndex);       
        assertEq(vaultAccount.rpIndex, latestRpIndex);  

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account0_T61.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account0_T61.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account0_T61.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account0_T61.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch"); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch"); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account0_T61.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch"); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }
    
        // --------------- d0:vault1:users --------------- 

        // stale since T51: activateCooldown(vault2) OR endVaults(vault2) does not update vault1


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


        // --------------- d0:vault2:user2 ---------------
      
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

        // previously updated at T61: userAccounts not updated at t61+1day
        /*function testUser2_ForVault2Account0_T61And1Day() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t51: consider the emissions from t51-t61
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t61
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account0_T61.index;
                uint256 prevNftIndex = user2Vault2Account0_T61.nftIndex;
                uint256 prevRpIndex = user2Vault2Account0_T61.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account0_T61.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account0_T61.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T61.accRealmPointsRewards;

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
        }*/

// ---------------- distribution 1 ----------------

    function testDistribution1_T86461() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
            // emissions for T61-T61+1day
            uint256 expectedEmitted = 86400 ether;
            uint256 indexDelta = expectedEmitted * 1E18 / (vault1_T61.boostedStakedTokens + vault2_T61.boostedStakedTokens);
            uint256 expectedIndex = distribution1_T61.index + indexDelta;

            uint256 expectedTotalEmitted = distribution.emissionPerSecond * (block.timestamp - distribution.startTime);

        // dynamic
        assertEq(distribution.index, expectedIndex, "index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "totalEmitted mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 61 + 86400, "lastUpdateTimeStamp mismatch");
    }

    //vault1 accounts not updated
    /*function testVault1Account1_T86461() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

        /** T51 - T61
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */
    /*
        // vault assets: T51-T56
        uint256 stakedRp = user1Rp + user2Rp/2;  
        uint256 stakedTokens = user1Moca + user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault1Account1_T56.index;
        // boosted tokens
        uint256 boostedTokens = vault1_T56.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T56.boostedStakedTokens + vault2_T56.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T56.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T56.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T56.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T56.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T56.rpIndex;

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
    
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account1_T56.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T56.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T56.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T56.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T56.rewardsAccPerUnitStaked;

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards 
        // vaultAccount.totalClaimedRewards < vaultAccount.totalAccRewards | likely due to rounding from math operation in executeClaimRewards
        assertApproxEqAbs(vaultAccount.totalClaimedRewards, vaultAccount.totalAccRewards, 4314, "totalClaimedRewards mismatch");
    }*/

    function testVault2Account1_T86461() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // vault assets: T61-T61+1day
        uint256 stakedRp = user2Rp/2;  
        uint256 stakedTokens = user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault2Account1_T61.index;
        // boosted tokens
        uint256 boostedTokens = vault2_T61.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T61.boostedStakedTokens + vault2_T61.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T61.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T61.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T61.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account1_T61.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account1_T61.rpIndex;

        // Check indices match distribution at t61+1day
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
        
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account1_T61.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account1_T61.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account1_T61.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account1_T61.accRealmPointsRewards;

        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");
        
        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account1_T61.rewardsAccPerUnitStaked;

        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards: claiming occured at T56
        // vaultAccount.totalClaimedRewards < vaultAccount.totalAccRewards | likely due to rounding from math operation in executeClaimRewards
        assertApproxEqAbs(vaultAccount.totalClaimedRewards, vault2Account1_T56.totalAccRewards, 4314, "totalClaimedRewards mismatch");
    }


// --------------- state transition ---------------

    function testUser2CanUnstakeAfterVault2Ended() public {
        
        // get initial token balances
        uint256 initialUserMocaBalance = mocaToken.balanceOf(user2);
        uint256 initialPoolMocaBalance = mocaToken.balanceOf(address(pool));

        // get initial user state
        DataTypes.User memory initialUser = pool.getUser(user2, vaultId2);
        assertEq(initialUser.tokenIds.length, 2, "User staked NFTs mismatch");
        assertEq(initialUser.stakedTokens, user2Moca/2, "User staked tokens mismatch");
        assertEq(initialUser.stakedRealmPoints, user2Rp/2, "User staked RP mismatch");

        // get initial pool state
        uint256 initialPoolTotalStaked = pool.totalStakedTokens();
        uint256 initialPoolStakedNfts = pool.totalStakedNfts();
        uint256 initialPoolStakedRealmPoints = pool.totalStakedRealmPoints();
        uint256 initialPoolBoostedStaked = pool.totalBoostedStakedTokens();
        uint256 initialPoolBoostedRealmPoints = pool.totalBoostedRealmPoints();
        
        // get initial vault state
        DataTypes.Vault memory initialVault = pool.getVault(vaultId2);
        assertEq(initialVault.removed, 1, "vault2 not removed");
        assertEq(initialVault.stakedNfts, 2, "Vault staked NFTs mismatch");
        assertEq(initialVault.stakedTokens, user2Moca/2, "Vault staked tokens mismatch");
        assertEq(initialVault.stakedRealmPoints, user2Rp/2, "Vault staked RP mismatch");
        // Calculate boost factor: 10% boost per NFT
        uint256 boostFactor = pool.PRECISION_BASE() + (initialVault.stakedNfts * pool.NFT_MULTIPLIER());
        assertEq(initialVault.boostedStakedTokens, user2Moca/2 * boostFactor / pool.PRECISION_BASE(), "Vault boosted staked mismatch");
        assertEq(initialVault.boostedRealmPoints, user2Rp/2 * boostFactor / pool.PRECISION_BASE(), "Vault boosted RP mismatch");

        // User2 unstakes from vault2
        vm.startPrank(user2);
            pool.unstake(vaultId2, initialUser.stakedTokens, initialUser.tokenIds);
        vm.stopPrank();

        // Check final token balances
        assertEq(mocaToken.balanceOf(user2), initialUserMocaBalance + initialUser.stakedTokens, "User MOCA balance not increased");
        assertEq(mocaToken.balanceOf(address(pool)), initialPoolMocaBalance - initialUser.stakedTokens, "Pool MOCA balance not decreased");

        // Check user vault assets cleared
        DataTypes.User memory userAfter = pool.getUser(user2, vaultId2);
        assertEq(userAfter.stakedTokens, 0, "User staked tokens not cleared");
        assertEq(userAfter.tokenIds.length, 0, "User staked NFTs not cleared");
        assertEq(userAfter.stakedRealmPoints, initialUser.stakedRealmPoints, "Rp incorrectly cleared");

        // Check vault state
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId2);
        assertEq(vaultAfter.stakedNfts, 0, "Vault staked NFTs mismatch");
        assertEq(vaultAfter.stakedTokens, 0, "Non-zero stakedTokens in vault2");
        assertEq(vaultAfter.boostedStakedTokens, 0, "Non-zero boostedStakedTokens in vault2");
        // rp should remain unchanged - except for boosting update
        assertEq(vaultAfter.stakedRealmPoints, initialVault.stakedRealmPoints, "Rp incorrectly cleared");
        assertEq(vaultAfter.boostedRealmPoints, initialVault.stakedRealmPoints, "Non-zero boostedRealmPoints in vault2");

        // Check pool state updated
        assertEq(pool.totalStakedTokens(), initialPoolTotalStaked, "Pool total staked not decreased");
        assertEq(pool.totalStakedNfts(), initialPoolStakedNfts, "Pool total staked NFTs not decreased");
        assertEq(pool.totalBoostedStakedTokens(), initialPoolBoostedStaked, "Pool boosted staked not decreased"); 
        // rp should remain unchanged - except for boosting update
        assertEq(pool.totalStakedRealmPoints(), initialPoolStakedRealmPoints, "Rp incorrectly decreased");
        assertEq(pool.totalBoostedRealmPoints(), initialPoolBoostedRealmPoints, "Pool boosted RP not correctly updated");
    }

}
