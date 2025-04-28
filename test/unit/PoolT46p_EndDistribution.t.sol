// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

abstract contract StateT41_EndDistribution is StateT41_User2StakesToVault2 {

    function setUp() public virtual override {
        super.setUp();

        // changed
        vm.startPrank(operator);
            pool.endDistributionManually(1);
        vm.stopPrank();
    }
}

abstract contract StateT46_UpdateEndedDistribution is StateT41_EndDistribution {

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

    // additional
    uint256 user1Vault1ClaimableAtT41ViewFn;        
    uint256 user2Vault1ClaimableAtT41ViewFn;
    uint256 user1Vault1ClaimableAtT46ViewFn;
    uint256 user2Vault1ClaimableAtT46ViewFn;

    uint256 user1BalanceBefore;
    uint256 user2BalanceBefore;
    uint256 user1BalanceAfter;
    uint256 user2BalanceAfter;

    function setUp() public virtual override {
        super.setUp();

        // snapshot T41 rewards before triggering update:
        user1Vault1ClaimableAtT41ViewFn = pool.getClaimableRewards(user1, vaultId1, 1);
        user2Vault1ClaimableAtT41ViewFn = pool.getClaimableRewards(user2, vaultId1, 1);

        // Get user's token balance before claiming
        user1BalanceBefore = rewardsToken1.balanceOf(user1);
        user2BalanceBefore = rewardsToken1.balanceOf(user2);
    
        // T41 rewards
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        vm.startPrank(user2);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId2, 1);
        vm.stopPrank();

        // Get user's token balance after claiming
        user1BalanceAfter = rewardsToken1.balanceOf(user1);
        user2BalanceAfter = rewardsToken1.balanceOf(user2);

        // snapshot T41 rewards: overwrites PoolT41.t.sol
        vault1_T41 = pool.getVault(vaultId1);
        vault2_T41 = pool.getVault(vaultId2);
        distribution0_T41 = getDistribution(0);
        distribution1_T41 = getDistribution(1);
        //vault1
        vault1Account0_T41 = getVaultAccount(vaultId1, 0);
        vault1Account1_T41 = getVaultAccount(vaultId1, 1);  
        //vault2
        vault2Account0_T41 = getVaultAccount(vaultId2, 0);
        vault2Account1_T41 = getVaultAccount(vaultId2, 1);
        //user1+vault1
        user1Vault1Account0_T41 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T41 = getUserAccount(user1, vaultId1, 1);
        //user2+vault1
        user2Vault1Account0_T41 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T41 = getUserAccount(user2, vaultId1, 1);
        //user1+vault2
        user1Vault2Account0_T41 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T41 = getUserAccount(user1, vaultId2, 1);
        //user2+vault2
        user2Vault2Account0_T41 = getUserAccount(user2, vaultId2, 0);      
        user2Vault2Account1_T41 = getUserAccount(user2, vaultId2, 1);


        vm.warp(46);

        // T46 rewards
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        vm.startPrank(user2);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId2, 1);
        vm.stopPrank();

        // snapshot T46 rewards:
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

        // snapshot T46 rewards after claiming:
        user1Vault1ClaimableAtT46ViewFn = pool.getClaimableRewards(user1, vaultId1, 1);
        user2Vault1ClaimableAtT46ViewFn = pool.getClaimableRewards(user2, vaultId1, 1);

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

/** changed
    check that rewards accrued are the same at T41
    no rewards accrued from T41 - T46
 */

contract StateT46_UpdateEndedDistributionTest is StateT46_UpdateEndedDistribution {

    function testDistribution1EndedSuccessfully_T46p() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        assertEq(distribution.endTime, 41, "distribution end time mismatch");
        assertEq(distribution.manuallyEnded, 1, "distribution manually ended mismatch");
    }

    function testCannotEndAlreadyEndedDistribution_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionEnded.selector);
            pool.endDistributionManually(1);
        vm.stopPrank();
    }

    function testCannotEndDistributionManuallyEnded_T46p() public {
        // setup new distribution
        uint256 distributionId = 3;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 100;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1e18;
        bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
        
        vm.startPrank(operator);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        // end distribution
        vm.startPrank(operator);
            pool.endDistributionManually(distributionId);
        vm.stopPrank();
        assertEq(getDistribution(distributionId).manuallyEnded, 1, "distribution manually ended mismatch");

        vm.warp(block.timestamp - 1);
        // end distribution
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionManuallyEnded.selector);
            pool.endDistributionManually(distributionId);
        vm.stopPrank();
    }

    function testCannotEndDistribution0_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionId.selector);
            pool.endDistributionManually(0);
        vm.stopPrank();
    }

    function testCannotEndNonExistentDistribution_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.NonExistentDistribution.selector);
            pool.endDistributionManually(3);
        vm.stopPrank();
    }

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

        // distributions: 2 in array | 1 active
        assertTrue(pool.getActiveDistributionsLength() == 2, "active distributions mismatch");
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
    }

// ---------------- distribution 1 ----------------
  
    function testDistribution1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 41);             // CHANGED
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 1);        // CHANGED
        
        // note: emissions for T41-T46: 0. lastUpdate: 41

        // sanity check
        assertEq(distribution.totalEmitted, 20 ether, "calc. totalEmitted mismatch");
        uint256 expectedTotalEmitted = distribution.emissionPerSecond * (distribution.endTime - distribution.startTime);
        assertEq(distribution.totalEmitted, expectedTotalEmitted, "expected totalEmitted mismatch");

        // should match T41
        assertEq(distribution.index, distribution1_T41.index, "index mismatch");
        assertEq(distribution.totalEmitted, distribution1_T41.totalEmitted, "totalEmitted mismatch");
        assertEq(distribution.lastUpdateTimeStamp, 41, "lastUpdateTimeStamp mismatch");

        // vault received and distribution emitted should be the same        
        DataTypes.VaultAccount memory vault1Account1 = getVaultAccount(vaultId1, 1);        
        DataTypes.VaultAccount memory vault2Account1 = getVaultAccount(vaultId2, 1);

        assertApproxEqAbs(vault1Account1.totalAccRewards, 20 ether, 200,"vault1Account1.totalAccRewards mismatch");
        assertEq(vault2Account1.totalAccRewards, 0, "vault2Account1.totalAccRewards mismatch");
        assertApproxEqAbs(distribution.totalEmitted, vault1Account1.totalAccRewards + vault2Account1.totalAccRewards, 200, "total vault receivable mismatch");
    }

    // updated at T46; lastUpdated at T36
    function testVault1Account1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution1_T41.index, "vaultAccount index mismatch");
        assertEq(vaultAccount.nftIndex, vault1Account1_T41.nftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, vault1Account1_T41.rpIndex, "vaultAccount rpIndex mismatch");

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, vault1Account1_T41.totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, vault1Account1_T41.accCreatorRewards, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, vault1Account1_T41.accNftStakingRewards, "accNftStakingRewards mismatch");
        assertEq(vaultAccount.accRealmPointsRewards, vault1Account1_T41.accRealmPointsRewards, "accRealmPointsRewards mismatch");

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, vault1Account1_T41.rewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, vault1Account1_T41.totalClaimedRewards, "totalClaimedRewards mismatch");
    }

    function testVault2Account1_T46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);
        
        // note:vault2 created at T26, but only has stakedTokens at T41 - so earns nothing.

        // Check indices match distribution
        assertEq(vaultAccount.index, distribution1_T41.index, "vaultAccount index mismatch");

        // rp and nft indexes are 0 - no tokens staked, no rewards accrued
        assertEq(vaultAccount.nftIndex, 0, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, 0, "vaultAccount rpIndex mismatch");
        assertEq(vaultAccount.nftIndex, vault2Account1_T41.nftIndex, "vaultAccount nftIndex mismatch");
        assertEq(vaultAccount.rpIndex, vault2Account1_T41.rpIndex, "vaultAccount rpIndex mismatch");
        
        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, vault2Account1_T41.totalAccRewards, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, vault2Account1_T41.accCreatorRewards, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, vault2Account1_T41.accNftStakingRewards, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, vault2Account1_T41.accRealmPointsRewards, "accRealmPointsRewards mismatch");
        // sanity check against 0
        assertEq(vaultAccount.totalAccRewards, 0, "totalAccRewards mismatch");
        assertEq(vaultAccount.accCreatorRewards, 0, "accCreatorRewards mismatch");
        assertEq(vaultAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch"); 
        assertEq(vaultAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

        // Check rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, vault2Account1_T41.rewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0, "rewardsAccPerUnitStaked mismatch");

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

        // --------------- d1:vault1:users ---------------

        function testUser1_ForVault1Account1_T46p() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);  

            //--- user1+vault1 last updated at t36: consider the emissions from t36-t46
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account1_T36.index;
                uint256 prevNftIndex = user1Vault1Account1_T36.nftIndex;
                uint256 prevRpIndex = user1Vault1Account1_T36.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account1_T36.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account1_T36.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account1_T36.accRealmPointsRewards;
                
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
            assertEq(userAccount.claimedStakingRewards, userAccount.accStakingRewards, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, userAccount.accNftStakingRewards, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, userAccount.accRealmPointsRewards, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, vaultAccount.accCreatorRewards, "claimedCreatorRewards mismatch");  //user1 is vault1 creator
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

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, user2Vault2Account1_T41.accStakingRewards, "accStakingRewards mismatch");
            assertEq(userAccount.accNftStakingRewards, user2Vault2Account1_T41.accNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, user2Vault2Account1_T41.accRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: token rewards are claimable
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch"); // user2 is vault2 creator

            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
            
            uint256 expectedClaimableRewards = user2Vault2Account1_T41.accStakingRewards + user2Vault2Account1_T41.accNftStakingRewards + user2Vault2Account1_T41.accRealmPointsRewards;
            if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

    //--------------------------------

    // claim rewards
    function testUser1_ClaimDistribution1_Vault1_T46() public {
        
        // rewards at t41
        uint256 accruedAtT41 = user1Vault1Account1_T41.accStakingRewards + user1Vault1Account1_T41.accNftStakingRewards + user1Vault1Account1_T41.accRealmPointsRewards + vault1Account1_T41.accCreatorRewards;
        uint256 claimedAtT41 = user1Vault1Account1_T41.claimedStakingRewards + user1Vault1Account1_T41.claimedNftRewards + user1Vault1Account1_T41.claimedRealmPointsRewards + user1Vault1Account1_T41.claimedCreatorRewards; 
        uint256 claimableAtT41 = accruedAtT41 - claimedAtT41;
        
        // rewards at t46
        uint256 accruedAtT46 = user1Vault1Account1_T46.accStakingRewards + user1Vault1Account1_T46.accNftStakingRewards + user1Vault1Account1_T46.accRealmPointsRewards + vault1Account1_T46.accCreatorRewards;
        uint256 claimedAtT46 = user1Vault1Account1_T46.claimedStakingRewards + user1Vault1Account1_T46.claimedNftRewards + user1Vault1Account1_T46.claimedRealmPointsRewards + user1Vault1Account1_T46.claimedCreatorRewards; 
        uint256 claimableAtT46 = accruedAtT46 - claimedAtT46;

        // check claimed does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(claimedAtT41, claimedAtT46, "claimedAtT41 and claimedAtT46 mismatch");
        // check accrued does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(accruedAtT41, accruedAtT46, "accruedAtT41 and accruedAtT46 mismatch");
        // claimed matches accrued
        assertEq(claimedAtT41, accruedAtT41, "claimedAtT41 and accruedAtT41 mismatch");

        // check view fn
        assertEq(user1Vault1ClaimableAtT41ViewFn, claimedAtT41, "view fn mismatch: T41");
        assertEq(user1Vault1ClaimableAtT46ViewFn, 0, "view fn mismatch: T46");

        // check token transfers
        assertEq(user1BalanceBefore + claimedAtT41, user1BalanceAfter, "token transfer amount mismatch");  
    }

    function testUser2_ClaimDistribution1_Vault1_T46() public {
        
        // rewards at t41
        uint256 accruedAtT41 = user2Vault1Account1_T41.accStakingRewards + user2Vault1Account1_T41.accNftStakingRewards + user2Vault1Account1_T41.accRealmPointsRewards;
        uint256 claimedAtT41 = user2Vault1Account1_T41.claimedStakingRewards + user2Vault1Account1_T41.claimedNftRewards + user2Vault1Account1_T41.claimedRealmPointsRewards + user2Vault1Account1_T41.claimedCreatorRewards; 
        uint256 claimableAtT41 = accruedAtT41 - claimedAtT41;

        // rewards at t46
        uint256 accruedAtT46 = user2Vault1Account1_T46.accStakingRewards + user2Vault1Account1_T46.accNftStakingRewards + user2Vault1Account1_T46.accRealmPointsRewards;
        uint256 claimedAtT46 = user2Vault1Account1_T46.claimedStakingRewards + user2Vault1Account1_T46.claimedNftRewards + user2Vault1Account1_T46.claimedRealmPointsRewards + user2Vault1Account1_T46.claimedCreatorRewards; 
        uint256 claimableAtT46 = accruedAtT46 - claimedAtT46;

        // check claimed does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(claimedAtT41, claimedAtT46, "claimedAtT41<>claimedAtT46 mismatch");
        // check accrued does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(accruedAtT41, accruedAtT46, "accruedAtT41<>accruedAtT46 mismatch");
        // claimed matches accrued
        assertEq(claimedAtT41, accruedAtT41, "claimedAtT41<>accruedAtT41 mismatch");

        // check view fn
        assertEq(user2Vault1ClaimableAtT41ViewFn, claimedAtT41, "view fn mismatch: T41");
        assertEq(user2Vault1ClaimableAtT46ViewFn, 0, "view fn mismatch: T46");

        // check token transfers
        assertEq(user2BalanceBefore + claimedAtT41, user2BalanceAfter, "token transfer amount mismatch");  
    }

    // sanity check: should be 0
    function testUser2_ClaimDistribution1_Vault2_T46() public {
        
        // rewards at t41
        uint256 accruedAtT41 = user2Vault2Account1_T41.accStakingRewards + user2Vault2Account1_T41.accNftStakingRewards + user2Vault2Account1_T41.accRealmPointsRewards + vault2Account1_T41.accCreatorRewards;
        uint256 claimedAtT41 = user2Vault2Account1_T41.claimedStakingRewards + user2Vault2Account1_T41.claimedNftRewards + user2Vault2Account1_T41.claimedRealmPointsRewards + user2Vault2Account1_T41.claimedCreatorRewards; 
        uint256 claimableAtT41 = accruedAtT41 - claimedAtT41;

        // rewards at t46
        uint256 accruedAtT46 = user2Vault2Account1_T46.accStakingRewards + user2Vault2Account1_T46.accNftStakingRewards + user2Vault2Account1_T46.accRealmPointsRewards + vault2Account1_T46.accCreatorRewards;
        uint256 claimedAtT46 = user2Vault2Account1_T46.claimedStakingRewards + user2Vault2Account1_T46.claimedNftRewards + user2Vault2Account1_T46.claimedRealmPointsRewards + user2Vault2Account1_T46.claimedCreatorRewards; 
        uint256 claimableAtT46 = accruedAtT46 - claimedAtT46;

        assertEq(claimedAtT41, 0, "claimedAtT41<>0 mismatch");
        assertEq(accruedAtT41, 0, "accruedAtT41<>0 mismatch");

        // check claimed does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(claimedAtT41, claimedAtT46, "claimedAtT41<>claimedAtT46 mismatch");
        // check accrued does not change from 41 to 46:  no further rewards accrued after D1 ended
        assertEq(accruedAtT41, accruedAtT46, "accruedAtT41<>accruedAtT46 mismatch");
        // claimed matches accrued
        assertEq(claimedAtT41, accruedAtT41, "claimedAtT41<>accruedAtT41 mismatch");

        // check view fn
        assertEq(pool.getClaimableRewards(user2, vaultId2, 1), 0, "view fn mismatch: T46");
    }

// ---- state transition: pop distribution ----

    function testCannotPopDistribution0_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionId.selector);
            pool.popEndedDistribution(0);
        vm.stopPrank();
    }

    function testUserCannotPopEndedDistribution_T46p() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.popEndedDistribution(1);
        vm.stopPrank();
    }

    function testCannotPopNonExistentDistribution_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.NonExistentDistribution.selector);
            pool.popEndedDistribution(100);
        vm.stopPrank();
    }

    function testCanPopEndedDistribution_T46p() public {
        // Check before popping
        uint256 beforePopping = pool.getActiveDistributionsLength();
        assertEq(beforePopping, 2);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionPopped(1);
            pool.popEndedDistribution(1);
        vm.stopPrank();

        // Check after popping
        uint256 afterPopping = pool.getActiveDistributionsLength();
        assertEq(afterPopping, 1);
        assertEq(beforePopping - afterPopping, 1);
        
        // Verify the remaining distribution is distribution 0
        uint256 remainingDistribution = pool.activeDistributions(0);
        DataTypes.Distribution memory distribution = getDistribution(remainingDistribution);
        assertEq(distribution.distributionId, 0);
    }
}

abstract contract StateT46p_PopDistribution is StateT46_UpdateEndedDistribution {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(operator);
            pool.popEndedDistribution(1);
        vm.stopPrank();
    }
}

contract PoolT46p_PopDistributionTest is StateT46p_PopDistribution {

    function testCannotPopPoppedDistribution_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionNotFound.selector);
            pool.popEndedDistribution(1);
        vm.stopPrank();
    }

    // ---- state transition: test changing rewardsVault ----
    function testCanSetRewardsVaultIfNoActiveTokenDistribution() public {

        // deploy new rewardsVault
        RewardsVaultV1 rewardsVault2 = new RewardsVaultV1(owner, monitor, owner, address(pool));

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit RewardsVaultSet(address(rewardsVault), address(rewardsVault2));
            pool.setRewardsVault(address(rewardsVault2));
        vm.stopPrank();

        // Verify new vault is set
        assertEq(address(pool.REWARDS_VAULT()), address(rewardsVault2));
    }
}

