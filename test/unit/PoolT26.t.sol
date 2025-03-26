// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT21.t.sol";

//note: creation nfts updated at t21 | distribution_1 starts at t21
abstract contract StateT26_User2CreatesVault2 is StateT21_CreationNftsUpdated {

    bytes32 vaultId2;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(26);

        // user2 creates vault
        vm.startPrank(user2);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = user2NftsArray[4];    //5th nft
            uint256 nftFeeFactor = 1000;
            uint256 creatorFeeFactor = 500;
            uint256 realmPointsFeeFactor = 500;

            pool.createVault(tokenIds, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();       

        vaultId2 = generateVaultId(block.number - 1, user2);
    }
}

contract StateT26_User2CreatesVault2Test is StateT26_User2CreatesVault2 {

    /** 
        creating a vault does not update state of existing distributions, vaults or users.
        so all state data related to these entities should be the same as in StateT16

        for sanity, we check that state is stale.
     */
    
    // ---------------- stale checks: should be as per T16 ----------------
        function testUser1_T26() public {
            DataTypes.User memory user = pool.getUser(user1, vaultId1);

            // nfts        
            assertEq(user.tokenIds.length, 0);

            // tokens
            assertEq(user.stakedTokens, user1Moca);

            // realm points
            assertEq(user.stakedRealmPoints, user1Rp);
        }

        function testUser2_T26() public {
            DataTypes.User memory user = pool.getUser(user2, vaultId1);

            // nfts        
            assertEq(user.tokenIds.length, 4);
            assertEq(user.tokenIds[0], user2NftsArray[0]);
            assertEq(user.tokenIds[1], user2NftsArray[1]); 
            assertEq(user.tokenIds[2], user2NftsArray[2]);
            assertEq(user.tokenIds[3], user2NftsArray[3]);

            // tokens
            assertEq(user.stakedTokens, user2Moca);

            // realm points
            assertEq(user.stakedRealmPoints, user2Rp);
        }

        // ---------------- distribution 0 ----------------

        function testDistribution0_T26() public {

            DataTypes.Distribution memory distribution = getDistribution(0);

            // static
            assertEq(distribution.distributionId, 0);
            assertEq(distribution.TOKEN_PRECISION, 1e18); 
            assertEq(distribution.endTime, 0);
            assertEq(distribution.startTime, 1);
            assertEq(distribution.emissionPerSecond, 1 ether);
            assertEq(distribution.manuallyEnded, 0);        
            
            /** index calc:
                - prev. index: 0.02e18 [t6]
                - totalEmitted: 10e18 SP
                - totalRpStaked: (250 + 500) [t6-t16]
                - totalBoostFactor: 1000 * 2 / PRECISION_BASE = 20% [20/100]
                - totalBoostedRP: (250 + 500) * 1.2 = 900e18
                index = 0.02e18 + [10e18 SP / 900e18 RP]
                    = 0.02e18 + 1.111...111e16
                    = 0.031111e18
                both users had staked half their RP balances from t6-t16
            */

            uint256 totalRpStaked = user1Rp/2 + user2Rp/2;
            uint256 numOfNftsStaked = 2;                            // user2: 2nfts staked for t6-t16
            uint256 boostedAmount = (totalRpStaked * (numOfNftsStaked * pool.NFT_MULTIPLIER()) / pool.PRECISION_BASE());
            uint256 totalBoostedRp = totalRpStaked + boostedAmount;

            uint256 indexDelta = 10 ether * 1E18 / totalBoostedRp;
            uint256 expectedIndex = 0.02E18 + indexDelta;
            console.log("expectedIndex", expectedIndex);
            assertEq(expectedIndex, 31111111111111111); // 3.111e16
            
            // dynamic
            assertEq(distribution.index, expectedIndex);
            assertEq(distribution.totalEmitted, 15 ether);
            assertEq(distribution.lastUpdateTimeStamp, 16);
        }

        function testVault1Account0_T26() public {
            DataTypes.Distribution memory distribution = getDistribution(0);
            DataTypes.Vault memory vault = pool.getVault(vaultId1);

            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
            
            /** T6 - T16
                stakedTokens: user1 1/2 + user 2 1/2
                stakedRp: user1 1/2 + user 2 1/2
                stakedNfts: 2
            */

            // cal. newly accrued rewards
            uint256 prevVaultIndex = 0.02e18;
            uint256 boostedBalance = (user1Rp/2 + user2Rp/2) * 120/100;    // user 2 stakes 2 nfts at t6-t16
            uint256 newlyAccRewards = calculateRewards(boostedBalance, distribution0_T16.index, prevVaultIndex, 1E18);
            // eval. rounding error
            uint256 newlyAccRewardsExpected = 10 ether;                   // ignores rounding 
            assertApproxEqAbs(newlyAccRewards, newlyAccRewardsExpected, 100);

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * 1000 / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * 1000 / 10_000;         // 2 nfts staked frm t6-t16
            uint256 newlyAccRealmPointsFee = newlyAccRewards * 1000 / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / 2) + vault1Account0_T6.nftIndex;     // 2 nfts staked frm t6-t16
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / (user1Rp/2 + user2Rp/2)) + vault1Account0_T6.rpIndex;

            // check indices
            assertEq(vaultAccount.index, distribution.index); // must match distribution index
            assertEq(vaultAccount.nftIndex, latestNftIndex);
            assertEq(vaultAccount.rpIndex, latestRpIndex);    

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account0_T6.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T6.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T6.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T6.accRealmPointsRewards;

            // heck accumulated rewards + fees
            assertEq(vaultAccount.totalAccRewards, totalAccRewards);
            assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
            assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
            assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / (user1Moca/2 + user2Moca/2)) + vault1Account0_T6.rewardsAccPerUnitStaked;

            // rewardsAccPerUnitStaked
            assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

            // totalClaimedRewards
            assertEq(vaultAccount.totalClaimedRewards, 0);
        }
        
        function testUser1_ForVault1Account0_T26() public {

            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

            //--- user 1 last updated at t1

            // Check indices match vault
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

            // Calculate expected rewards for user1's staked tokens
            uint256 latestAccStakingRewards = calculateRewards(user1Moca/2, vaultAccount.rewardsAccPerUnitStaked, user1Account0_T6.index, 1E18) + user1Account0_T6.accStakingRewards;      
            // Calculate expected rewards for nft staking
            uint256 latestAccNftStakingRewards = 0; // 0 nfts staked
            // Calculate expected rewards for rp staking
            uint256 latestAccRealmPointsRewards = calculateRewards(user1Rp/2, vaultAccount.rpIndex, user1Account0_T6.rpIndex, 1E18) + user1Account0_T6.accRealmPointsRewards;

            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards);
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards);

            // Check claimed rewards
            assertEq(userAccount.claimedStakingRewards, 0);
            assertEq(userAccount.claimedNftRewards, 0);
            assertEq(userAccount.claimedRealmPointsRewards, 0);
            assertEq(userAccount.claimedCreatorRewards, 0);
            
            //--------------------------------
            /* note: update expectedClaimableRewards to include pending rewards

                // view fn: user1 gets their share of total rewards
                uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
                
                uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
                if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

                // book pending
                expectedClaimableRewards += 

                assertEq(claimableRewards, expectedClaimableRewards); 
            */
        }

        function testUser2_ForVault1Account0_T26() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

            //--- user2 last updated at t6: consider the emissions from t6-t16

            // Check indices match vault@t16
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

            // Calculate expected rewards for user1's staked tokens
            uint256 latestAccStakingRewards = calculateRewards(user2Moca/2, vaultAccount.rewardsAccPerUnitStaked, user2Account0_T6.index, 1E18) + user2Account0_T6.accStakingRewards;      
            // Calculate expected rewards for nft staking
            uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T6.nftIndex) * 2) + user2Account0_T6.accNftStakingRewards; // 2 nfts staked
            // Calculate expected rewards for rp staking
            uint256 latestAccRealmPointsRewards = calculateRewards(user2Rp/2, vaultAccount.rpIndex, user2Account0_T6.rpIndex, 1E18) + user2Account0_T6.accRealmPointsRewards;

            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards);
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards);

            // Check claimed rewards
            assertEq(userAccount.claimedStakingRewards, 0);
            assertEq(userAccount.claimedNftRewards, 0);
            assertEq(userAccount.claimedRealmPointsRewards, 0);
            assertEq(userAccount.claimedCreatorRewards, 0);
            
            //--------------------------------
            /* note: update expectedClaimableRewards to include pending rewards
            
            // view fn: user2 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 0);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

                assertEq(claimableRewards, expectedClaimableRewards); 
            */
        }

        // ---------------- distribution 1 ----------------
        
        // distribution 1 started@T21: state not updated
        function testDistribution1_T26() public {
            // Check all Distribution struct fields
            DataTypes.Distribution memory distribution = getDistribution(1);
            
            // static
            assertEq(distribution.distributionId, 1);
            assertEq(distribution.TOKEN_PRECISION, 1e18); 
            assertEq(distribution.endTime, 21 + 2 days);
            assertEq(distribution.startTime, 21);
            assertEq(distribution.emissionPerSecond, 1 ether);
            assertEq(distribution.manuallyEnded, 0);        

            // dynamic
            assertEq(distribution.index, 0);
            assertEq(distribution.totalEmitted, 0);
            assertEq(distribution.lastUpdateTimeStamp, 21);
        }

        function testVault1Account1_T26() public {
            DataTypes.Distribution memory distribution = getDistribution(1);
            DataTypes.Vault memory vault = pool.getVault(vaultId1);

            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
            
            // Check indices match distribution
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

        function testUser1_ForVault1Account1_T26() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
            
            // Check indices match vault    
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, 0);
            assertEq(userAccount.accNftStakingRewards, 0);
            assertEq(userAccount.accRealmPointsRewards, 0);

            // Check claimed rewards
            assertEq(userAccount.claimedStakingRewards, 0);
            assertEq(userAccount.claimedNftRewards, 0);
            assertEq(userAccount.claimedRealmPointsRewards, 0);
            assertEq(userAccount.claimedCreatorRewards, 0);
        }

        function testUser2_ForVault1Account1_T26() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
            
            // Check indices match vault
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

            // Check accumulated rewards    
            assertEq(userAccount.accStakingRewards, 0);
            assertEq(userAccount.accNftStakingRewards, 0);
            assertEq(userAccount.accRealmPointsRewards, 0);

            // Check claimed rewards
            assertEq(userAccount.claimedStakingRewards, 0);
            assertEq(userAccount.claimedNftRewards, 0);
            assertEq(userAccount.claimedRealmPointsRewards, 0);
            assertEq(userAccount.claimedCreatorRewards, 0);
        }   

    // ---------------- stale checks: ended -------------------------------- //

    // ---------- vault2 checks: vault struct populated; accounts empty ---------

    //note: pool.totalCreationNfts should be updated
    function testPool_T26() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);

        // Check total creation NFTs
        assertEq(pool.totalCreationNfts(), 6);
        assertEq(pool.totalCreationNfts(), vault1.creationTokenIds.length + vault2.creationTokenIds.length);

        // Check total staked assets
        assertEq(pool.totalStakedNfts(), 4); // user2's 4 staked NFTs
        assertEq(pool.totalStakedTokens(), user1Moca + user2Moca);
        assertEq(pool.totalStakedRealmPoints(), user1Rp + user2Rp);

        // Check boosted balances
        uint256 expectedBoostFactor = 10_000 + (4 * nftMultiplier); // Base + 4 NFTs from user2
        uint256 expectedBoostedRealmPoints = ((user1Rp + user2Rp) * expectedBoostFactor) / 10_000;
        uint256 expectedBoostedStakedTokens = ((user1Moca + user2Moca) * expectedBoostFactor) / 10_000;

        assertEq(pool.totalBoostedRealmPoints(), expectedBoostedRealmPoints);
        assertEq(pool.totalBoostedStakedTokens(), expectedBoostedStakedTokens);
    }

    function testVault2_T26() public {
        DataTypes.Vault memory vault = pool.getVault(vaultId2);
        
        // Base vault data
        assertEq(vault.creator, user2);
        // Verify creation NFTs
        assertEq(vault.creationTokenIds.length, 1);
        assertEq(vault.creationTokenIds[0], user2NftsArray[4]);

        assertEq(vault.startTime, 26);
        assertEq(vault.endTime, 0);
        assertEq(vault.removed, 0);
        
        // Verify fees
        assertEq(vault.nftFeeFactor, 1000);
        assertEq(vault.creatorFeeFactor, 500);
        assertEq(vault.realmPointsFeeFactor, 500);
        
        // Verify staked assets
        assertEq(vault.stakedTokens, 0);
        assertEq(vault.stakedNfts, 0);
        assertEq(vault.stakedRealmPoints, 0);

        // Verify boosted balances
        assertEq(vault.totalBoostFactor, pool.PRECISION_BASE());
        assertEq(vault.boostedRealmPoints, 0);
        assertEq(vault.boostedStakedTokens, 0);
    }

    function testVault2Account0_T26() public {
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);
        
        // Check indices
        assertEq(vaultAccount.index, 0);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0);
        assertEq(vaultAccount.accRealmPointsRewards, 0);

        // Check per unit rewards and total claimed
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    function testVault2Account1_T26() public {
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);
        
        // Check indices
        assertEq(vaultAccount.index, 0);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0);
        assertEq(vaultAccount.accRealmPointsRewards, 0);

        // Check per unit rewards and total claimed
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

// state transition

    function testCannotMigrateRpFromNonExistentVault_T26() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, bytes32(uint256(1))));
            pool.migrateRealmPoints(bytes32(uint256(1)), vaultId2, 1000);
        vm.stopPrank();
    }

    function testCannotMigrateRpToNonExistentVault_T26() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, bytes32(uint256(1))));
            pool.migrateRealmPoints(vaultId1, bytes32(uint256(1)), 1000);
        vm.stopPrank();
    }

    function testCannotMigrateZeroRp_T26() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.migrateRealmPoints(vaultId1, vaultId2, 0);
        vm.stopPrank();
    }

    function testCannotMigrateRpToSameVault_T26() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidVaultId.selector);
            pool.migrateRealmPoints(vaultId1, vaultId1, 1000);
        vm.stopPrank();
    }
    
    function testCannotMigrateRpWhenNothingStakedInFrom_T26() public {
        vm.startPrank(user3);
            vm.expectRevert(abi.encodeWithSelector(Errors.InsufficientRealmPoints.selector, 0));
            pool.migrateRealmPoints(vaultId1, vaultId2, 1000);
        vm.stopPrank();
    }   

    function testCannotMigrateMoreThanStakedRp_T26() public {
        vm.startPrank(user2);
            vm.expectRevert(abi.encodeWithSelector(Errors.InsufficientRealmPoints.selector, user2Rp));
            pool.migrateRealmPoints(vaultId1, vaultId2, user2Rp + 1 ether);
        vm.stopPrank();
    }

    function testUser2MigrateRp() public {
        
        // get initial values
        uint256 poolBoostedRpBefore = pool.totalBoostedRealmPoints();
        uint256 poolTotalRpBefore = pool.totalStakedRealmPoints();
        DataTypes.Vault memory vault1Before = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2Before = pool.getVault(vaultId2);
        DataTypes.User memory user2VaultOneBefore = pool.getUser(user2, vaultId1);
        DataTypes.User memory user2VaultTwoBefore = pool.getUser(user2, vaultId2);

        // user2 migrates half their RP from vault1 to vault2
        vm.startPrank(user2);
            uint256 amount = user2Rp/2;
            // check event
            vm.expectEmit(true, true, true, true);
            emit RealmPointsMigrated(user2, vaultId1, vaultId2, amount);
            pool.migrateRealmPoints(vaultId1, vaultId2, amount);
        vm.stopPrank();
        
        // --------- VAULT1 CHECKS: before & after migration ---------

        // check vault1 (old vault) balances
        DataTypes.Vault memory vault1After = pool.getVault(vaultId1);
        
        // Base RP checks for vault1
        assertEq(vault1After.stakedRealmPoints, vault1Before.stakedRealmPoints - amount, "Vault1 base RP not reduced correctly");
        // Boosted RP checks for vault1
        uint256 expectedVault1BoostFactor = pool.PRECISION_BASE() + (vault1After.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedVault1BoostedRp = (vault1After.stakedRealmPoints * expectedVault1BoostFactor) / pool.PRECISION_BASE();
        assertEq(vault1After.boostedRealmPoints, expectedVault1BoostedRp, "Vault1 boosted RP not reduced correctly");

        // --------- VAULT2 CHECKS: before & after migration ---------

        // check vault2 (new vault) balances
        DataTypes.Vault memory vault2After = pool.getVault(vaultId2);
        
        // Base RP checks for vault2
        assertEq(vault2After.stakedRealmPoints, vault2Before.stakedRealmPoints + amount, "Vault2 base RP not increased correctly");
        // Boosted RP checks for vault2
        uint256 expectedVault2BoostFactor = pool.PRECISION_BASE() + (vault2After.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedVault2BoostedRp = (vault2After.stakedRealmPoints * expectedVault2BoostFactor) / pool.PRECISION_BASE();
        assertEq(vault2After.boostedRealmPoints, expectedVault2BoostedRp, "Vault2 boosted RP not increased correctly");

        // --------- POOL CHECKS: before & after migration ---------

        // check pool totals
        assertEq(pool.totalStakedRealmPoints(), poolTotalRpBefore, "Pool total RP should not change");
        assertEq(pool.totalBoostedRealmPoints(), expectedVault1BoostedRp + expectedVault2BoostedRp, "Pool total boosted RP incorrect");

        // --------- USER-VAULT BALANCES CHECKS: before & after migration ---------

        // check user balances for vault1
        DataTypes.User memory user2VaultOneAfter = pool.getUser(user2, vaultId1);
        assertEq(user2VaultOneAfter.stakedRealmPoints, user2VaultOneBefore.stakedRealmPoints - amount, "User2 vault1 RP not reduced correctly");

        // check user balances for vault2
        DataTypes.User memory user2VaultTwoAfter = pool.getUser(user2, vaultId2);
        assertEq(user2VaultTwoAfter.stakedRealmPoints, user2VaultTwoBefore.stakedRealmPoints + amount, "User2 vault2 RP not increased correctly");


        // ----- MISC: OTHER CHECKS -----
        
        // Other vault1 checks
        assertEq(vault1After.stakedNfts, vault1Before.stakedNfts, "Vault1 NFTs should not change");
        assertEq(vault1After.stakedTokens, vault1Before.stakedTokens, "Vault1 tokens should not change");
        assertEq(vault1After.totalBoostFactor, expectedVault1BoostFactor, "Vault1 boost factor incorrect");
        assertEq(vault1After.boostedStakedTokens, (vault1After.stakedTokens * expectedVault1BoostFactor) / pool.PRECISION_BASE(), "Vault1 boosted tokens incorrect");

        // Other vault2 checks
        assertEq(vault2After.stakedNfts, vault2Before.stakedNfts, "Vault2 NFTs should not change");
        assertEq(vault2After.stakedTokens, vault2Before.stakedTokens, "Vault2 tokens should not change");
        assertEq(vault2After.totalBoostFactor, expectedVault2BoostFactor, "Vault2 boost factor incorrect");
        assertEq(vault2After.boostedStakedTokens, (vault2After.stakedTokens * expectedVault2BoostFactor) / pool.PRECISION_BASE(), "Vault2 boosted tokens incorrect");
    }

}