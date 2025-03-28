// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT36.t.sol";

/**
    Split timeline:
    -T26: user2 creates vault2
    -T31: user2 migrates half his RP to vault2
    -T36: user2 unstakes moca and 2 nfts from vault1
    -T41: user 2 stakes moca and 2 nfts in vault2

    we will create a parallel timeline on T41,
    - user2 unstakes from tokens from vault1; but does not restake tokens
    - instead OPERATOR stakes the same amount of tokens on behalf of user2
    - from a rewards perspective, user2 should be credited with the same rewards as main timeline

    we will check that:
    - pool state is updated correctly
    - vault assets are updated correctly
    - vault2 accounts are updated correctly
    - user2's vault2 accounts are updated correctly
    - after a timedelta of 5s, check that rewards are accrued correctly
 */

abstract contract StateT41_User2StakesToVault2_OperatorStakesOnBehalf is StateT36_User2UnstakesFromVault1 {

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

        vm.warp(41);
        
        uint256[] memory nftsToStake = new uint256[](2);
        nftsToStake[0] = user2NftsArray[0];
        nftsToStake[1] = user2NftsArray[1];

        //user2 stakes half of his moca + 2 nfts, in vault2
        vm.startPrank(user2);
            pool.stakeNfts(vaultId2, nftsToStake); 
        vm.stopPrank();

        // operator stakes on behalf of user2
        vm.startPrank(operator);
            
            bytes32[] memory vaultIds = new bytes32[](1);
            vaultIds[0] = vaultId2;
            
            address[] memory onBehalfOfs = new address[](1);
            onBehalfOfs[0] = user2;
            
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = user2Moca/2;

            mocaToken.approve(address(pool), user2Moca/2);
            pool.stakeOnBehalfOf(vaultIds, onBehalfOfs, amounts);
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


contract StateT41_User2StakesToVault2_OperatorStakesOnBehalfTest is StateT41_User2StakesToVault2_OperatorStakesOnBehalf {

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
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 
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
}

// forward 5s to check rewards are accrued correctly
// note: we clone T46 to test this, using updateVaultFees as an update trigger
abstract contract StateT46_CheckRewardsAccrued_AfterStakeOnBehalf is StateT41_User2StakesToVault2_OperatorStakesOnBehalf {
    
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
    }
}

contract StateT46_CheckRewardsAccrued_AfterStakeOnBehalfTest is StateT46_CheckRewardsAccrued_AfterStakeOnBehalf {

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
        uint256 boostFactor = pool.PRECISION_BASE() + (numOfNftsStaked * pool.NFT_MULTIPLIER());
        uint256 totalBoostedRp = (vault1RP * boostFactor / pool.PRECISION_BASE()) + (vault2RP * boostFactor / pool.PRECISION_BASE());

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
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 

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
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution.index, prevVaultIndex, 1E18); 
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

                // Calculate expected rewards for user2's staked tokens 
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
    
}