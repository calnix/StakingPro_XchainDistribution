// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

abstract contract StateT46_BothVaultsFeesUpdated is StateT41_User2StakesToVault2 {

    // for reference
    DataTypes.Vault vault1_T46; 
    DataTypes.Vault vault2_T46;

    DataTypes.Distribution distribution0_T46;
    DataTypes.Distribution distribution1_T46;
    //vault1
    DataTypes.VaultAccount vault1Account0_T46;
    DataTypes.VaultAccount vault1Account1_T46;
    //vault2
    DataTypes.VaultAccount vault2Account0_T46;
    DataTypes.VaultAccount vault2Account1_T46;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T46;
    DataTypes.UserAccount user1Vault1Account1_T46;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T46;
    DataTypes.UserAccount user2Vault1Account1_T46;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T46;
    DataTypes.UserAccount user1Vault2Account1_T46;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T46;
    DataTypes.UserAccount user2Vault2Account1_T46;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(46);

        // Vault1 fees - user1 reduces creator fee, increases nft and rp fees
        uint256 creatorFeeFactor1 = 500; // Reduced from 1000
        uint256 nftFeeFactor1 = 1250;
        uint256 realmPointsFeeFactor1 = 1250;

        vm.startPrank(user1);
            pool.updateVaultFees(vaultId1, nftFeeFactor1, creatorFeeFactor1, realmPointsFeeFactor1);
        vm.stopPrank();

        // Vault2 fees - user2 reduces creator fee, increases nft and rp fees
        uint256 creatorFeeFactor2 = 250; // Reduced from 500
        uint256 nftFeeFactor2 = 1125;
        uint256 realmPointsFeeFactor2 = 625;

        vm.startPrank(user2);
            pool.updateVaultFees(vaultId2, nftFeeFactor2, creatorFeeFactor2, realmPointsFeeFactor2);
        vm.stopPrank();

        // save state
        vault1_T46 = pool.getVault(vaultId1);
        vault2_T46 = pool.getVault(vaultId2);
        
        distribution0_T46 = getDistribution(0); 
        distribution1_T46 = getDistribution(1);
        vault1Account0_T46 = getVaultAccount(vaultId1, 0);
        vault1Account1_T46 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T46 = getVaultAccount(vaultId2, 0);
        vault2Account1_T46 = getVaultAccount(vaultId2, 1);
        user1Vault1Account0_T46 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T46 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T46 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T46 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T46 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T46 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T46 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T46 = getUserAccount(user2, vaultId2, 1);
    }
}

/** check vaults: T46
     assets remain unchanged from T41
     fees have been updated
    
    check accounts: T41-46
     vault1: rp: user1Rp + user2Rp/2 | tokens: user1Moca + user2Moca/2 | nfts: 2
     vault2: rp: user1Rp + user2Rp/2 | tokens: user1Moca + user2Moca/2 | nfts: 2

      - user1+vault1 updated
      - user2+vault2 updated
*/

contract StateT46_BothVaultsFeesUpdatedTest is StateT46_BothVaultsFeesUpdated {

// ---------------- base assets ----------------

    function testPool_T46() public {
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
            uint256 vault2BoostedRp = ((user2Rp/2) * vault2BoostFactor) / 10_000; // vault2 boost
            uint256 expectedTotalBoostedRp = vault1BoostedRp + vault2BoostedRp;

            // calculate boosted tokens for each vault
            uint256 vault1BoostedTokens = ((user1Moca + user2Moca/2) * vault1BoostFactor) / 10_000;
            uint256 vault2BoostedTokens = ((user2Moca/2) * vault2BoostFactor) / 10_000;
            uint256 expectedTotalBoostedTokens = vault1BoostedTokens + vault2BoostedTokens;

        assertEq(pool.totalBoostedRealmPoints(), expectedTotalBoostedRp);       
        assertEq(pool.totalBoostedStakedTokens(), expectedTotalBoostedTokens);    
    }

    function testVault1_T46() public {
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
        assertEq(vault1.nftFeeFactor, 1250);          // 10%
        assertEq(vault1.creatorFeeFactor, 500);       // 5%
        assertEq(vault1.realmPointsFeeFactor, 1250);  // 5%
    }

    function testVault2_T46() public {
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
        assertEq(vault2.nftFeeFactor, 1125);          // 10%
        assertEq(vault2.creatorFeeFactor, 250);       // 5%
        assertEq(vault2.realmPointsFeeFactor, 625);  // 5%
    }

// ---------------- distribution 0 ----------------

    function testDistribution0_T46() public {

        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** TODO
            index calc: t41 - t46   [delta: 5]
            - prev. index: 4.382e16 [t41: 43826723671924909]
            - totalEmittedSinceLastUpdate: 5e18 SP
            - vault1: (user1Rp + user2Rp/2) * 1.2 [boosted by 2 NFTs] = 1000 * 1.2 = 1200
            - vault2: (user2Rp/2) * 1.2 [boosted by 2 NFTs] = 500 * 1.2 = 600
            - totalBoostedRP = 1800e18
            index = 4.382e16 + [5e18 SP / 1800 RP]
                  = 43826723671924909 + 2777777777777777
                  ~ 4.66e16 [46604501449702686]
         */

        uint256 numOfNftsStaked = 2;                            // both vaults have 2 NFTs staked
        uint256 vault1RP = user1Rp + user2Rp/2;                 
        uint256 vault2RP = user2Rp/2;                           
        uint256 boostFactor = Constants.PRECISION_BASE + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = (vault1RP * boostFactor / Constants.PRECISION_BASE) + (vault2RP * boostFactor / Constants.PRECISION_BASE);

        uint256 indexDelta = 5 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T41.index + indexDelta;
        console.log("distribution0_T41.index", distribution0_T41.index);
        console.log("indexDelta", indexDelta);
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 46604501449702686); // 4.66e16
        
        // dynamic
        assertEq(distribution.index, expectedIndex);    // 4.66e16
        assertEq(distribution.totalEmitted, distribution0_T41.totalEmitted + 5 ether);
        assertEq(distribution.lastUpdateTimeStamp, 46);
    }

    // vault1 accounts updated at T46; lastUpdate at t36 
    function testVault1Account0_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T41 - T46
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */

        // vault assets 
        uint256 stakedRp = vault1_T41.stakedRealmPoints;  
        uint256 stakedTokens = vault1_T41.stakedTokens;
        uint256 stakedNfts = vault1_T41.stakedNfts;

        uint256 boostedRp = vault1_T41.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T41.boostedRealmPoints + vault2_T41.boostedRealmPoints;

        uint256 prevVaultIndex = vault1Account0_T41.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T46.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T41.nftIndex;     // 4 nfts staked frm t31-t36
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T41.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index); // 46604501449702686 [4.66e16]
        assertEq(vaultAccount.nftIndex, latestNftIndex);       
        assertEq(vaultAccount.rpIndex, latestRpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = newlyAccRewards + vault1Account0_T41.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T41.accCreatorRewards;
        uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T41.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T41.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account0_T41.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }
    
    function testVault2Account0_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        /** T41 - T46
            stakedTokens: user2Moca/2
            stakedRp: user2Rp/2
            stakedNfts: 2
         */

        // vault assets for t41-t46
        uint256 stakedRp = vault2_T41.stakedRealmPoints;  
        uint256 stakedTokens = vault2_T41.stakedTokens;
        uint256 stakedNfts = vault2_T41.stakedNfts;

        uint256 boostedRp = vault2_T41.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T41.boostedRealmPoints + vault2_T41.boostedRealmPoints;

        uint256 prevVaultIndex = vault2Account0_T41.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T46.index, prevVaultIndex, 1E18); 
                // eval. rounding error
                uint256 emittedRewards = 5 ether;
                uint256 vault2ShareOfEmittedRewards = (boostedRp * emittedRewards) / poolBoostedRp;
                assertApproxEqAbs(newlyAccRewards, vault2ShareOfEmittedRewards, 466);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T41.realmPointsFeeFactor / 10_000;

            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account0_T41.nftIndex;   
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account0_T41.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, latestNftIndex);       
        assertEq(vaultAccount.rpIndex, latestRpIndex);  

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account0_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account0_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account0_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account0_T41.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch"); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch"); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account0_T41.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch"); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

        // --------------- d0:vault1:users --------------- 
        
        function testUser1_ForVault1Account0_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);  
            
            //--- user1+vault1 last updated at t36: consider the emissions from t36-t46
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account0_T41.index;
                uint256 prevNftIndex = user1Vault1Account0_T41.nftIndex;
                uint256 prevRpIndex = user1Vault1Account0_T41.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account0_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account0_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account0_T41.accRealmPointsRewards;

                // Calculate expected rewards for user2's staked tokens 
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
        }

        // stale: user2's account was last updated at t36
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
        function testUser1_ForVault2Account0_T46() public {
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
        }

        function testUser2_ForVault2Account0_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t31: consider the emissions from t31-t41
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account0_T41.index;
                uint256 prevNftIndex = user2Vault2Account0_T41.nftIndex;
                uint256 prevRpIndex = user2Vault2Account0_T41.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account0_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account0_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T41.accRealmPointsRewards;


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


// ---------------- distribution 1 ----------------
  
    function testDistribution1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
            // emissions for T41-T46
            uint256 expectedEmitted = 5 ether;
            uint256 indexDelta = expectedEmitted * 1E18 / (vault1_T41.boostedStakedTokens + vault2_T41.boostedStakedTokens);
            uint256 expectedIndex = distribution1_T41.index + indexDelta;

            uint256 expectedTotalEmitted = distribution.emissionPerSecond * (block.timestamp - distribution.startTime);

        // dynamic
        assertEq(distribution.index, expectedIndex, "index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "totalEmitted mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 46, "lastUpdateTimeStamp mismatch");
    }

    // updated at T46; lastUpdated at T36
    function testVault1Account1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

        /** T41 - T46
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */

        // vault assets: T41-T46
        uint256 stakedRp = user1Rp + user2Rp/2;  
        uint256 stakedTokens = user1Moca + user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault1Account1_T41.index;
        // boosted tokens
        uint256 boostedTokens = vault1_T41.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T41.boostedStakedTokens + vault2_T41.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T41.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T41.rpIndex;

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
    
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account1_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T41.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T41.rewardsAccPerUnitStaked;

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

    function testVault2Account1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // vault assets: T41-T46
        uint256 stakedRp = user2Rp/2;  
        uint256 stakedTokens = user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault2Account1_T41.index;
        // boosted tokens
        uint256 boostedTokens = vault2_T41.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T41.boostedStakedTokens + vault2_T41.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account1_T41.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account1_T41.rpIndex;

        // Check indices match distribution at t41
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
        
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account1_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account1_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account1_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account1_T41.accRealmPointsRewards;

        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");
        
        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account1_T41.rewardsAccPerUnitStaked;

        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

        // --------------- d1:vault1:users ---------------

        function testUser1_ForVault1Account1_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);  
            
            //--- user1+vault1 last updated at t36: consider the emissions from t36-t46
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account1_T41.index;
                uint256 prevNftIndex = user1Vault1Account1_T41.nftIndex;
                uint256 prevRpIndex = user1Vault1Account1_T41.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account1_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account1_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account1_T41.accRealmPointsRewards;

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
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");  //user1 is vault1 creator

            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

        // stale: user2's account was last updated at t36
        /*function testUser2_ForVault1Account1_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

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
                uint256 prevUserIndex = user2Account1_T41.index;
                uint256 prevAccStakingRewards = user2Account1_T41.accStakingRewards;
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;     

                // Calculate expected rewards for nft staking
                uint256 prevAccNftStakingRewards = user2Account1_T41.accNftStakingRewards;
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account1_T41.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 prevRpIndex = user2Account1_T41.rpIndex;
                uint256 prevAccRealmPointsRewards = user2Account1_T41.accRealmPointsRewards;
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");   //user 2 did not create vault1

            
            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }*/


        // --------------- d1:vault2:users ---------------

        // user1 does not have any assets in vault2
        function testUser1_ForVault2Account1_T46() public {
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

        function testUser2_ForVault2Account1_T46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user2+vault2 last updated at t41: consider the emissions from t41-t46
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2;
            uint256 numOfNfts = 2;

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account1_T41.index;
                uint256 prevUserNftIndex = user2Vault2Account1_T41.nftIndex;
                uint256 prevUserRpIndex = user2Vault2Account1_T41.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account1_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account1_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account1_T41.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens
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
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch"); // user2 is vault2 creator

            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

// ---- state transition tests: PoolT46p_MaintenanceMode.t.sol ----

    function testUserCannotUpdateMaximumFeeFactor() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.updateMaximumFeeFactor(1000);
        vm.stopPrank();
    }

    function testOperatorCanUpdateMaximumFeeFactor() public {
        uint256 initialMaximumFeeFactor = pool.MAXIMUM_FEE_FACTOR();
        assertEq(initialMaximumFeeFactor, 5000, "maximumFeeFactor is 50%");

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaximumFeeFactorUpdated(5000, 1000);
            pool.updateMaximumFeeFactor(1000);
        vm.stopPrank();

        assertEq(pool.MAXIMUM_FEE_FACTOR(), 1000, "maximumFeeFactor is 10%");
    }
}