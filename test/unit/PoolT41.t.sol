// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT36.t.sol";

abstract contract StateT41_User2StakesToVault2 is StateT36_User2UnstakesFromVault1 {

    // for reference
    DataTypes.Vault vault1_T41; 
    DataTypes.Vault vault2_T41;

    DataTypes.Distribution distribution0_T41;
    DataTypes.Distribution distribution1_T41;
    //vault1
    DataTypes.VaultAccount vault1Account0_T41;
    DataTypes.VaultAccount vault1Account1_T41;
    //vault2
    DataTypes.VaultAccount vault2Account0_T41;
    DataTypes.VaultAccount vault2Account1_T41;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T41;
    DataTypes.UserAccount user1Vault1Account1_T41;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T41;
    DataTypes.UserAccount user2Vault1Account1_T41;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T41;
    DataTypes.UserAccount user1Vault2Account1_T41;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T41;
    DataTypes.UserAccount user2Vault2Account1_T41;

    function setUp() public virtual override {
        super.setUp();

        // set t41
        vm.warp(41);

        uint256[] memory nftsToStake = new uint256[](2);
        nftsToStake[0] = user2NftsArray[0];
        nftsToStake[1] = user2NftsArray[1];

        //user2 stakes half of his moca + 2 nfts, in vault2
        vm.startPrank(user2);
            mocaToken.approve(address(pool), user2Moca/2);
            pool.stakeTokens(vaultId2, user2Moca/2);
            pool.stakeNfts(vaultId2, nftsToStake); //user2NftsArray[0,1];
        vm.stopPrank();
    
        // save state
        vault1_T41 = pool.getVault(vaultId1);
        vault2_T41 = pool.getVault(vaultId2);
        
        distribution0_T41 = getDistribution(0);
        distribution1_T41 = getDistribution(1);
        vault1Account0_T41 = getVaultAccount(vaultId1, 0);
        vault1Account1_T41 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T41 = getVaultAccount(vaultId2, 0);
        vault2Account1_T41 = getVaultAccount(vaultId2, 1);
        user1Vault1Account0_T41 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T41 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T41 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T41 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T41 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T41 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T41 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T41 = getUserAccount(user2, vaultId2, 1);
    }
    
}

/** check assets: T41
    check vault2 assets according to stake action at t41
    
    check accounts: T36-41
     vault1: rp: user1Rp + user2Rp/2 | tokens: user1Moca + user2Moca/2 | nfts: 2
     vault2: rp: user2Rp/2           | tokens: user2Moca/2             | nfts: 0

    check vault2 accounts + user 2 accounts were updated at t41
    - vault1 accounts are stale at t36 - no action taken since
    - user1 accounts are stale at t16 - no action taken since
 */

contract StateT41_User2StakesToVault2Test is StateT41_User2StakesToVault2 {

// ---------------- base assets ----------------

    function testPool_T41() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs - unchanged
        assertEq(pool.totalCreationNfts(), 6);
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length + vault2.creationTokenIds.length);

        // Check total staked assets
        assertEq(pool.totalStakedNfts(), 4);                         // user2 staked 2 nfts to vault2
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca);   // user2 staked half of tokens to vault2
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp);  // unchanged: migrateRp
        
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
    
    // user2 unstaked half of tokens + 2 nfts 
    function testVault1_T41() public {
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
    function testVault2_T41() public {
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
    }

// ---------------- distribution 0 ----------------

    // updated: T36-T41
    function testDistribution0_T41() public {

        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** TODO
            index calc: t36 - t41   [delta: 5]
            - prev. index: 4.088e16 [t36: 40885547201336674]
            - totalEmittedSinceLastUpdate: 5e18 SP
            - totalRpStaked: v1(user1Rp + user2Rp/2) + v2(user2Rp/2)
            - boostableRp:   v1(user1Rp + user2Rp/2), unboostableRp: v2(user2Rp/2)
            - totalBoostFactor: 1000 * 2 / PRECISION_BASE = 20% [20/100]
            - totalBoostedRP: [(500 + 500) * 1.2] + 500 = 1700e18
            index = 4.088e16 + [5e18 SP / 1700 RP]
                  = 40885547201336674 + 2941176470588235
                  ~ 4.3826723e16 [43826723671924909]
         */

        uint256 numOfNftsStaked = 2;                            // vault1: 2nfts staked for t36-41
        uint256 vault1RP = user1Rp + user2Rp/2;                 // vault1 RP
        uint256 vault2RP = user2Rp/2;                           // vault2 RP (no boost)
        uint256 boostFactor = pool.PRECISION_BASE() + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = (vault1RP * boostFactor / pool.PRECISION_BASE()) + vault2RP;

        uint256 indexDelta = 5 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = distribution0_T36.index + indexDelta;
        console.log("distribution0_T36.index", distribution0_T36.index);
        console.log("indexDelta", indexDelta);
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 43826723671924909); // 4.382e16
        
        // dynamic
        assertEq(distribution.index, expectedIndex);    // 4.382e16
        assertEq(distribution.totalEmitted, distribution0_T36.totalEmitted + 5 ether);
        assertEq(distribution.lastUpdateTimeStamp, 41);
    }

    // vault1 accounts are stale at t36 - no action taken since
    function testVault1Account0_T41() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T31 - T36
            stakedTokens: user1Moca + user2Moca
            stakedRp: user1Rp + user2Rp/2 [changed at T31]
            stakedNfts: 4
         */

        // vault assets 
        //uint256 stakedRp = vault1_T31.stakedRealmPoints;  
        //uint256 stakedTokens = vault1_T31.stakedTokens;
        //uint256 stakedNfts = vault1_T31.stakedNfts;
        //uint256 prevVaultIndex = vault1Account0_T31.index;
        //uint256 boostedRp = vault1_T31.boostedRealmPoints;

        //uint256 poolBoostedRp = vault1_T31.boostedRealmPoints + vault2_T31.boostedRealmPoints;

        // check indices

            // calc. newly accrued rewards       
            //uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T36.index, prevVaultIndex, 1E18); 
                // eval. rounding error
                //uint256 emittedRewards = 5 ether;
                //uint256 vault1ShareOfEmittedRewards = (boostedRp * emittedRewards) / poolBoostedRp;
                //assertApproxEqAbs(newlyAccRewards, vault1ShareOfEmittedRewards, 1800);

            // newly accrued fees since last update: based on newlyAccRewards
            //uint256 newlyAccCreatorFee = newlyAccRewards * 1000 / 10_000;
            //uint256 newlyAccTotalNftFee = newlyAccRewards * 1000 / 10_000;         
            //uint256 newlyAccRealmPointsFee = newlyAccRewards * 1000 / 10_000;
            
            // latest indices
            //uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T31.nftIndex;     // 4 nfts staked frm t31-t36
            //uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T31.rpIndex;

        // check indices
        assertEq(vaultAccount.index, vault1Account0_T36.index); // must match distribution index
        assertEq(vaultAccount.nftIndex, vault1Account0_T36.nftIndex);       
        assertEq(vaultAccount.rpIndex, vault1Account0_T36.rpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = /*newlyAccRewards +*/ vault1Account0_T36.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = /*newlyAccCreatorFee +*/ vault1Account0_T36.accCreatorRewards;
        uint256 latestAccTotalNftFee = /*newlyAccTotalNftFee +*/ vault1Account0_T36.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = /*newlyAccRealmPointsFee +*/ vault1Account0_T36.accRealmPointsRewards;

        // heck accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        //uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = /*(latestAccRewardsLessOfFees * 1E18 / stakedTokens) +*/ vault1Account0_T36.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    // vault2 accounts are updated at t41
    function testVault2Account0_T41() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        /** T36 - T41
            stakedTokens: 0
            stakedRp: user2Rp/2
            stakedNfts: 0
         */

        // vault assets for t36-t41
        uint256 stakedRp = vault2_T36.stakedRealmPoints;  
        uint256 stakedTokens = vault2_T36.stakedTokens;
        uint256 stakedNfts = vault2_T36.stakedNfts;

        uint256 boostedRp = vault2_T36.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T36.boostedRealmPoints + vault2_T36.boostedRealmPoints;

        uint256 prevVaultIndex = vault2Account0_T36.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T41.index, prevVaultIndex, 1E18); 
                //uint256 emittedForT31_T36 = 5 ether;
                //uint256 vault1ShareOfEmittedRewardsForT31_T36 = (vault1Account0_T36.totalAccRewards - vault1Account0_T31.totalAccRewards); 
                //uint256 newlyAccRewardsForT31_T36 = emittedForT31_T36 - vault1ShareOfEmittedRewardsForT31_T36;
    
                //uint256 emittedForT36_T41 = 5 ether;
                //uint256 vault1ShareOfEmittedRewardsForT36_T41 = (vault1Account0_T41.totalAccRewards - vault1Account0_T36.totalAccRewards); 
                //uint256 newlyAccRewardsForT36_T41 = emittedForT36_T41 - vault1ShareOfEmittedRewardsForT36_T41;
                //uint256 newlyAccRewards = newlyAccRewardsForT31_T36 + newlyAccRewardsForT36_T41;

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2.creatorFeeFactor / 10_000;
            //uint256 newlyAccTotalNftFee = newlyAccRewards * vault2.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2.realmPointsFeeFactor / 10_000;

            // latest indices
            //uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account0_T36.nftIndex;   
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account0_T36.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, 0);       
        //assertEq(vaultAccount.rpIndex, latestRpIndex, "RP index should match calculated latest RP index");  

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account0_T36.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account0_T36.accCreatorRewards;
            //uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account0_T36.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account0_T36.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch"); 
        assertEq(vaultAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch"); 

            // rewardsAccPerUnitStaked: for moca stakers
            //uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - 0 - newlyAccRealmPointsFee;
            //uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account0_T36.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0, "rewardsAccPerUnitStaked mismatch"); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

        // --------------- d0:vault1:users --------------- 

        // stale: user1's account was last updated at t16. no action taken by user since.
        /*function testUser1_ForVault1Account0_T41() public {}*/

        // stale: vault1 accounts are stale at t36 - no action taken since
        /*function testUser2_ForVault1Account0_T41() public {}*/

        // --------------- d0:vault2:user2 ---------------
        
        // user1 does not have any assets in vault2

        // updated at T41
        function testUser2_ForVault2Account0_T41() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t31: consider the emissions from t31-t41
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = 0; 
            uint256 numOfNfts = 0; 

            // Check indices match vault@t41
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
                uint256 prevRpIndex = user2Vault2Account0_T31.rpIndex;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T31.accRealmPointsRewards;
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");
        }

    // ---------------- distribution 1 ----------------

    // STARTED AT T21
    function testDistribution1_T41() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
            // emissions for T36-T41
            uint256 expectedEmitted = 5 ether;
            uint256 indexDelta = expectedEmitted * 1E18 / (vault1_T36.boostedStakedTokens + vault2_T36.boostedStakedTokens);
            uint256 expectedIndex = distribution1_T36.index + indexDelta;

            uint256 expectedTotalEmitted = distribution.emissionPerSecond * (block.timestamp - distribution.startTime);

        // dynamic
        assertEq(distribution.index, expectedIndex, "index mismatch");
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "totalEmitted mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 41, "lastUpdateTimeStamp mismatch");
    }

    // stale: not updated at T41; lastUpdated at T36
    /*function testVault1Account1_T36() public {
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
    }*/

    // updated at T41; lastUpdated at T31. accrued nothing, since 0 stakedTokens.
    function testVault2Account1_T41() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // vault assets: T31-T36
        uint256 stakedRp = user2Rp/2;  
        uint256 stakedTokens = 0;
        uint256 stakedNfts = 0;
        // prev. vault index
        uint256 prevVaultIndex = vault2Account1_T36.index;

        // -------------- check indices --------------

        // Check indices match distribution at t41
        assertEq(vaultAccount.index, distribution1_T41.index);
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
        /*function testUser1_ForVault1Account1_T41() public {}*/

        // stale: lastUpdated at T31
        /*function testUser2_ForVault1Account1_T41() public {
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
        }*/

        // --------------- d1:vault2:users ---------------

        // stale: user1's account was last updated at t16. no action taken by user since.
        /*function testUser1_ForVault2Account1_T41() public {}*/

        // updated at T41; lastUpdated at T31
        function testUser2_ForVault2Account1_T41() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user2 last updated at t31: consider the emissions from t31-t36
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0;

            // Check indices match vault@t41
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
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
            
            //uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            //if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
        }

// ---- state transition: for PoolT46.t.sol ----

    function testUserCannotUpdateVaultFees_T41() public {
        vm.startPrank(user2);
            vm.expectRevert(Errors.UserIsNotCreator.selector);
            pool.updateVaultFees(vaultId1, 1000, 1000, 1000);
        vm.stopPrank();
    }

    function testCannotExceedMaximumFeeFactor_T41() public {
        // Get current creator fee
        uint256 currentCreatorFee = pool.getVault(vaultId1).creatorFeeFactor;
        
        // Try to set fees that would exceed maximum
        uint256 nftFeeFactor = 2500;
        uint256 realmPointsFeeFactor = 2500;
        
        vm.startPrank(user1);
            vm.expectRevert(Errors.MaximumFeeFactorExceeded.selector);
            pool.updateVaultFees(vaultId1, nftFeeFactor, currentCreatorFee, realmPointsFeeFactor);
        vm.stopPrank();
    }

    function testCreatorCannotIncreaseCreatorFees_T41() public {
        // Get current creator fee
        uint256 currentCreatorFee = pool.getVault(vaultId1).creatorFeeFactor;
        
        // Try to increase creator fee
        uint256 higherCreatorFee = currentCreatorFee + 100;
        
        vm.startPrank(user1);
            vm.expectRevert(Errors.CreatorFeeCanOnlyBeDecreased.selector);
            pool.updateVaultFees(vaultId1, 1000, higherCreatorFee, 1000);
        vm.stopPrank();
    }

    function testCreatorCannotDecreaseNftFees_T41() public {
        // Get current nft fee
        uint256 currentNftFee = pool.getVault(vaultId1).nftFeeFactor;
        
        // Try to decrease nft fee
        uint256 lowerNftFee = currentNftFee - 100;
        
        vm.startPrank(user1);
            vm.expectRevert(Errors.NftFeeCanOnlyBeIncreased.selector);
            pool.updateVaultFees(vaultId1, lowerNftFee, 500, 1000);
        vm.stopPrank();
    }

    function testCreatorCannotDecreaseRpFees_T41() public {
        // Get current rp fee
        uint256 currentRpFee = pool.getVault(vaultId1).realmPointsFeeFactor;
        
        // Try to decrease rp fee
        uint256 lowerRpFee = currentRpFee - 100;
        
        vm.startPrank(user1);
            vm.expectRevert(Errors.RealmPointsFeeCanOnlyBeIncreased.selector);
            pool.updateVaultFees(vaultId1, 1000, 500, lowerRpFee);
        vm.stopPrank();
    }

    // creator can only increase other fees, by the portion he is reducing creator fees
    function testCreatorCannotIncreaseOtherFeesMoreThanReduction_T41() public {
        // Get current fees
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        uint256 delta = 500;
        uint256 creatorFeeFactor1 = vault.creatorFeeFactor - delta;
        uint256 nftFeeFactor1 = vault.nftFeeFactor + (delta * 2);
        uint256 realmPointsFeeFactor1 = vault.realmPointsFeeFactor + (delta * 2);

        vm.startPrank(user1);
            vm.expectRevert(Errors.IncorrectFeeComposition.selector);
            pool.updateVaultFees(vaultId1, nftFeeFactor1, creatorFeeFactor1, realmPointsFeeFactor1);
        vm.stopPrank();
    }
    function testCreatorCanUpdateVaultFees_T41() public {
        // incoming fees
        // Vault1 fees - user1 reduces creator fee, increases nft and rp fees
        uint256 creatorFeeFactor1 = 500; // Reduced from 1000
        uint256 nftFeeFactor1 = 1250;
        uint256 realmPointsFeeFactor1 = 1250;
        
        // Get current fees
        DataTypes.Vault memory vault = pool.getVault(vaultId1);
        
        // Check fees are different
        if (vault.creatorFeeFactor == creatorFeeFactor1 &&
            vault.nftFeeFactor == nftFeeFactor1 &&
            vault.realmPointsFeeFactor == realmPointsFeeFactor1) {
            revert("New fees must be different from current fees");
        }

        vm.startPrank(user1);
            // events
            vm.expectEmit(true, true, false, false);
            emit CreatorFeeFactorUpdated(vaultId1, vault.creatorFeeFactor, creatorFeeFactor1);
            vm.expectEmit(true, true, false, false);
            emit NftFeeFactorUpdated(vaultId1, vault.nftFeeFactor, nftFeeFactor1);
            vm.expectEmit(true, true, false, false);
            emit RealmPointsFeeFactorUpdated(vaultId1, vault.realmPointsFeeFactor, realmPointsFeeFactor1);

            pool.updateVaultFees(vaultId1, nftFeeFactor1, creatorFeeFactor1, realmPointsFeeFactor1);
        vm.stopPrank();

        assertEq(pool.getVault(vaultId1).creatorFeeFactor, creatorFeeFactor1);
        assertEq(pool.getVault(vaultId1).nftFeeFactor, nftFeeFactor1);
        assertEq(pool.getVault(vaultId1).realmPointsFeeFactor, realmPointsFeeFactor1);
    }

// ---- state transition: for PoolT46p_EndDistribution.t.sol ----

    function testUserCannotEndDistribution() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, pool.OPERATOR_ROLE()));
            pool.endDistribution(1);
        vm.stopPrank();
    }

    function testOperatorCannotEndDistribution0() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionId.selector);
            pool.endDistribution(0);
        vm.stopPrank();
    }

    function testOperatorCannotEndNonExistentDistribution() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.NonExistentDistribution.selector);
            pool.endDistribution(99);
        vm.stopPrank();
    }

    function testOperatorCannotEndAlreadyEndedDistribution() public {
        // Warp to after distribution end time
        vm.warp(distribution1_T41.endTime + 1);
        
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionEnded.selector);
            pool.endDistribution(1);
        vm.stopPrank();
    }

    function testCannotSetRewardsVaultIfActiveDistribution() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.ActiveTokenDistributions.selector);
            pool.setRewardsVault(address(rewardsVault));
        vm.stopPrank();
    }
    

    function testOperatorCanEndDistribution() public {

        // get totalRequired on rewards vault contract
        DataTypes.Distribution memory distributionInitial = getDistribution(1);
        uint256 totalRequiredInitial = distributionInitial.emissionPerSecond * (distributionInitial.endTime - distributionInitial.startTime);

        (, , uint256 totalRequiredInitialOnRewardsVault, , ) = rewardsVault.distributions(1);    
        assertEq(totalRequiredInitial, totalRequiredInitialOnRewardsVault);

        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionEnded(1, block.timestamp, distribution1_T41.totalEmitted);
            
            // Expect rewards vault call
            vm.expectCall(address(pool.REWARDS_VAULT()), abi.encodeCall(IRewardsVault.endDistribution, (1, distribution1_T41.totalEmitted)));
            
            pool.endDistribution(1);
        vm.stopPrank();

        // check pool
        assertEq(pool.getActiveDistributionsLength(), 1);

        // Check distribution was updated correctly on pool
        DataTypes.Distribution memory distribution = getDistribution(1);
        assertEq(distribution.manuallyEnded, 1);
        assertEq(distribution.endTime, block.timestamp);
        
        // Check rewards vault contract was updated correctly
        (, , uint256 totalRequired, , ) = rewardsVault.distributions(1);    
        assertEq(totalRequired, distribution.totalEmitted);
        assertNotEq(totalRequired, totalRequiredInitial);
    }


    // ---- state transition: for PoolT46p_MaintenanceMode.t.sol ----

    function testUserCannotEnableMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, pool.OPERATOR_ROLE()));
            pool.enableMaintenance();
        vm.stopPrank();
    }

    function testOperatorCannotDisableMaintenanceMode() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.NotInMaintenance.selector);
            pool.disableMaintenance();
        vm.stopPrank();
    }

    function testOperatorCanEnableMaintenanceMode() public {
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaintenanceEnabled(block.timestamp);
            pool.enableMaintenance();
        vm.stopPrank();

        assertEq(pool.isUnderMaintenance(), 1);
    }


}