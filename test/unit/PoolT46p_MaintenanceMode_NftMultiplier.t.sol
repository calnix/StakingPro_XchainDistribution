// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

abstract contract StateT46p_MaintenanceMode is StateT41_User2StakesToVault2 {

    function setUp() public virtual override {
        super.setUp();

        /**
            user 2 staked assets in vault2 at T41
         */

        vm.warp(46);

        vm.startPrank(operator);
            pool.enableMaintenance();
        vm.stopPrank();
    }
}

contract StateT46p_MaintenanceModeTest is StateT46p_MaintenanceMode {
    
    function testPool_InMaintenanceMode() public {
        assertEq(pool.isUnderMaintenance(), 1);
    }

// ---- users fns ---- 

    function testCannotCreateVaultWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.createVault(user1NftsArray, 1000, 1000, 1000);
        vm.stopPrank();
    }

    function testCannotStakeTokensWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.stakeTokens(vaultId1, 1000);
        vm.stopPrank();
    }

    function testCannotStakeNftsWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.stakeNfts(vaultId1, user1NftsArray);
        vm.stopPrank();
    }

    function testCannotStakeRPWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.stakeRealmPoints(vaultId1, 1000, block.timestamp + 1, bytes(""));
        vm.stopPrank();
    }

    function testCannotMigrateRpWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.migrateRealmPoints(vaultId1, vaultId2, 1000);
        vm.stopPrank();
    }

    function testCannotUnstakeWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.unstake(vaultId1, 1000, new uint256[](0));
        vm.stopPrank();
    }

    function testCannotClaimRewardsWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.claimRewards(vaultId1, 0);
        vm.stopPrank();
    }

    function testCannotUpdateVaultFeesWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.updateVaultFees(vaultId1, 1000, 1000, 1000);
        vm.stopPrank();
    }

    function testCannotActivateCooldownWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.activateCooldown(vaultId1);
        vm.stopPrank();
    }

    function testCannotEndVaultWhenInMaintenanceMode() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InMaintenance.selector);

            bytes32[] memory vaultIds = new bytes32[](1);
            vaultIds[0] = vaultId1;
        
            pool.endVaults(vaultIds);
        
        vm.stopPrank();
    }

// ---- operator fns ----
    function testCannotStakeOnBehalfWhenInMaintenanceMode() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.stakeOnBehalfOf(new bytes32[](1), new address[](1), new uint256[](1));
        vm.stopPrank();
    }

    function testCanSetEndTimeWhenInMaintenanceMode() public {
        // Check initial end time
        assertEq(pool.endTime(), 0);

        uint256 newEndTime = block.timestamp + 1;
        
        vm.startPrank(operator);
            pool.setEndTime(newEndTime);
        vm.stopPrank();

        assertEq(pool.endTime(), newEndTime);
    }

    function testCanSetRewardsVaultWhenInMaintenanceMode() public {

        // assume stakingPro only has 1 active distribution: D0
        vm.startPrank(operator);
            pool.endDistributionManually(1);
            pool.popEndedDistribution(1);
        vm.stopPrank();

        assertEq(pool.getActiveDistributionsLength(), 1);
        
        // now that there is only 1 active distribution, we can set the rewards vault
        address initialRewardsVault = address(pool.REWARDS_VAULT());
        address newRewardsVault = address(123);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit RewardsVaultSet(initialRewardsVault, newRewardsVault);
            pool.setRewardsVault(newRewardsVault);
        vm.stopPrank();

        assertEq(address(pool.REWARDS_VAULT()), newRewardsVault);
        assertNotEq(initialRewardsVault, newRewardsVault);
    }

    function testCanUpdateActiveDistributionsWhenInMaintenanceMode() public {
        // Get current
        uint256 currentActive = pool.getActiveDistributionsLength();
        uint256 newMaxActive = currentActive + 1;
        
        vm.startPrank(operator);
            pool.updateMaxActiveDistributions(newMaxActive);
        vm.stopPrank();

        assertEq(pool.MAX_ACTIVE_DISTRIBUTIONS(), newMaxActive);
    }

    function testCanUpdateMaximumFeeFactorWhenInMaintenanceMode() public {
        uint256 initialMaxFeeFactor = pool.MAXIMUM_FEE_FACTOR();
        uint256 newMaxFeeFactor = initialMaxFeeFactor + 1;

        vm.startPrank(operator);
            pool.updateMaximumFeeFactor(newMaxFeeFactor);
        vm.stopPrank();

        assertEq(pool.MAXIMUM_FEE_FACTOR(), newMaxFeeFactor);
    }

    function testCanUpdateMinimumRealmPointsWhenInMaintenanceMode() public {
        uint256 initialMinRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
        uint256 newMinRealmPoints = initialMinRealmPoints + 1;

        vm.startPrank(operator);
            pool.updateMinimumRealmPoints(newMinRealmPoints);
        vm.stopPrank();

        assertEq(pool.MINIMUM_REALMPOINTS_REQUIRED(), newMinRealmPoints);
    }

    function testCanUpdateNftMultiplierWhenInMaintenanceMode() public {
        uint256 initialNftMultiplier = pool.NFT_MULTIPLIER();
        uint256 newNftMultiplier = initialNftMultiplier + 1;
        
        vm.startPrank(operator);
            pool.updateNftMultiplier(newNftMultiplier);
        vm.stopPrank();

        assertEq(pool.NFT_MULTIPLIER(), newNftMultiplier);
    }

    function testCanUpdateCreationNftsWhenInMaintenanceMode() public {
        uint256 initialCreationNfts = pool.CREATION_NFTS_REQUIRED();
        uint256 newCreationNfts = initialCreationNfts + 1;

        vm.startPrank(operator);
            pool.updateCreationNfts(newCreationNfts);
    }

    function testCanUpdateVaultCooldownWhenInMaintenanceMode() public {
        uint256 initialVaultCooldown = pool.VAULT_COOLDOWN_DURATION();
        uint256 newVaultCooldown = initialVaultCooldown + 1;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit VaultCooldownDurationUpdated(initialVaultCooldown, newVaultCooldown);
            pool.updateVaultCooldown(newVaultCooldown);
        vm.stopPrank();

        assertEq(pool.VAULT_COOLDOWN_DURATION(), newVaultCooldown);
        assertNotEq(initialVaultCooldown, newVaultCooldown);
    }

    function testCanSetupDistributionWhenInMaintenanceMode() public {
        uint256 distributionId = 2;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 1000;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = bytes32(uint256(0x123));
        
        // Check state before
        uint256 activeDistributionsLengthBefore = pool.getActiveDistributionsLength();
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionCreated(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        // Check state after
        uint256 activeDistributionsLengthAfter = pool.getActiveDistributionsLength();
        assertEq(activeDistributionsLengthAfter, activeDistributionsLengthBefore + 1);

        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        assertEq(distribution.distributionId, distributionId);
        assertEq(distribution.startTime, distributionStartTime);
        assertEq(distribution.endTime, distributionEndTime);
        assertEq(distribution.emissionPerSecond, emissionPerSecond);
        assertEq(distribution.TOKEN_PRECISION, tokenPrecision);
    }

    function testCanUpdateDistributionWhenInMaintenanceMode() public {
        uint256 distributionId = 0;
        uint256 newEmissionPerSecond = 2 ether;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionPerSecond);

            pool.updateDistribution(distributionId, 0, 0, newEmissionPerSecond);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertNotEq(distributionBefore.emissionPerSecond, distributionAfter.emissionPerSecond);
    }

    function testCanEndDistributionWhenInMaintenanceMode() public {
        uint256 distributionId = 1;

        // Get distribution before end
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);

        // Get updated distribution
        DataTypes.Distribution memory updatedDistribution = pool.getUpdatedDistribution(distributionId);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionEnded(distributionId, block.timestamp, updatedDistribution.totalEmitted);

            pool.endDistributionManually(distributionId);
        vm.stopPrank();

        // Get distribution after end
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);

        assertEq(distributionAfter.endTime, block.timestamp);
        assertEq(distributionAfter.totalEmitted, updatedDistribution.totalEmitted);
    }

    function testCanPopEndedDistributionWhenInMaintenanceMode() public {
        uint256 distributionId = 1;

        // end distribution
        vm.startPrank(operator);
            pool.endDistributionManually(distributionId);
        vm.stopPrank();

        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        assertEq(distributionBefore.endTime, block.timestamp);
        assertEq(distributionBefore.manuallyEnded, 1);
        assertEq(pool.getActiveDistributionsLength(), 2);

        // pop distribution
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionPopped(distributionId);
            pool.popEndedDistribution(distributionId);
        vm.stopPrank();

        // verify distribution was popped
        assertEq(pool.getActiveDistributionsLength(), 1);
    }

    function testOperatorCannotEnableMaintenanceWhenAlreadyInMaintenance_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InMaintenance.selector);
            pool.enableMaintenance();
        vm.stopPrank();
    }


// ---- state transition ----

    function testOperatorCanUpdateDistributions() public {
        
        // check distributions before
        DataTypes.Distribution memory distribution0Before = getDistribution(0);
        DataTypes.Distribution memory distribution1Before = getDistribution(1);
        
        uint256[] memory distributionIds = new uint256[](2);
            distributionIds[0] = 0;
            distributionIds[1] = 1;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionsUpdated(distributionIds);

            pool.updateActiveDistributions();
        vm.stopPrank();

        // check distributions after
        DataTypes.Distribution memory distribution0After = getDistribution(0);
        DataTypes.Distribution memory distribution1After = getDistribution(1);

        // verify distributions were updated
        assertEq(distribution0Before.lastUpdateTimeStamp, 41);
        assertEq(distribution1Before.lastUpdateTimeStamp, 41);
        assertEq(distribution0After.lastUpdateTimeStamp, 46);
        assertEq(distribution1After.lastUpdateTimeStamp, 46);
    }
}


abstract contract StateT46p_MaintenanceMode_UpdateDistributions is StateT46p_MaintenanceMode {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(operator);
            pool.updateActiveDistributions();
        vm.stopPrank();
    }
}

contract StateT46p_MaintenanceMode_UpdateDistributionsTest is StateT46p_MaintenanceMode_UpdateDistributions {

    function testUserCannotUpdateAllVaultAccounts() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidCaller.selector);
            pool.updateAllVaultAccounts(new bytes32[](1), 0);
        vm.stopPrank();
    }

    function testCRONJOBCannotUpdateAllVaultAccountsInMaintenance() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;

        vm.startPrank(cronJob);
            vm.expectRevert(Errors.InvalidCaller.selector);
            pool.updateAllVaultAccounts(vaultIds, 0);
        vm.stopPrank();
    }

    function testUpdateAllVaultAccounts_InvalidArray() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidArray.selector);
            pool.updateAllVaultAccounts(new bytes32[](0), 0);
        vm.stopPrank();
    }

    // if(distribution.index == vaultAccount_.index) continue;
    function testUpdateAllVaultAccounts_Skip_AccountAlreadyUpdated() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;

        uint256 distributionId = 0;

        //update vault
        vm.startPrank(operator);
            pool.updateAllVaultAccounts(vaultIds, distributionId);
        vm.stopPrank();

        // update again: should skip. VaultAccountUpdated will not be emitted
        vm.startPrank(operator);
            
            vm.record();
            
            pool.updateAllVaultAccounts(vaultIds, distributionId);
        vm.stopPrank();

        // check storage r/w calls
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(pool));

        // expect no writes
        assertEq(writes.length, 0);
    }

    function testUpdateAllVaultAccounts_Skip_VaultRemoved() public {
        uint256 distributionId = 0;

        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;
        
        // setup: end vault
            // exit maintenance
            vm.startPrank(operator);
                pool.disableMaintenance();
            vm.stopPrank();

            // activateCooldown
            vm.startPrank(user1);
                pool.activateCooldown(vaultId1);
            vm.stopPrank();

            // get vault before
            DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);

            vm.warp(vaultBefore.endTime);

            //end vault
            vm.startPrank(operator);
                pool.endVaults(vaultIds);
            vm.stopPrank();

            // get vault after
            DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);

            // verify vault was removed
            assertEq(vaultAfter.removed, 1);

        // update again: should skip
        vm.startPrank(operator);
            pool.enableMaintenance();

            vm.record();
            pool.updateAllVaultAccounts(vaultIds, distributionId);
        vm.stopPrank();

        // check storage r/w calls
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(pool));

        // expect no writes
        assertEq(writes.length, 0);
    }

    function testUpdateAllVaultAccounts_Skip_ZeroBoostedBalance() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;

        uint256 distributionId = 0;
        
        // get user1's vault assets
        DataTypes.User memory user1Before = pool.getUser(user1, vaultId1);
        DataTypes.User memory user2Before = pool.getUser(user2, vaultId1);

        // disable maintenance: to allow unstaking
        vm.startPrank(operator);
            pool.disableMaintenance();
        vm.stopPrank();

        // unstake all tokens: user1
        vm.startPrank(user1);
            pool.unstake(vaultId1, user1Before.stakedTokens, new uint256[](0));
        vm.stopPrank();        

        // unstake all tokens: user2
        vm.startPrank(user2);
            pool.unstake(vaultId1, user2Before.stakedTokens, new uint256[](0));
        vm.stopPrank();

        // get user1's account after
        DataTypes.User memory user1After = pool.getUser(user1, vaultId1);
        DataTypes.User memory user2After = pool.getUser(user2, vaultId1);
        assertEq(user1After.stakedTokens, 0);
        assertEq(user2After.stakedTokens, 0);

        // update vault
        vm.startPrank(operator);
            pool.enableMaintenance();

            vm.record();
            pool.updateAllVaultAccounts(vaultIds, distributionId);
        vm.stopPrank();

        // check storage r/w calls
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(pool));

        // expect no writes
        assertEq(writes.length, 0);
    }


    function testOperatorCanUpdateAllVaultAccounts() public {
        // check vaults before
        DataTypes.VaultAccount memory vault1Before = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2Before = getVaultAccount(vaultId2, 1);

        bytes32[] memory vaultIds = new bytes32[](2);
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;
            
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit VaultAccountsUpdated(vaultIds);
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
        vm.stopPrank();

        // check vaults after
        DataTypes.VaultAccount memory vault1After = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2After = getVaultAccount(vaultId2, 1);

        // verify vaults were updated
        assertGt(vault1After.index, vault1Before.index);
        assertGt(vault2After.index, vault2Before.index);
    }
}


abstract contract StateT46p_MaintenanceMode_VaultAccountsUpdated is StateT46p_MaintenanceMode_UpdateDistributions {

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

        vm.startPrank(operator);
            bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
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


contract StateT46p_MaintenanceMode_VaultAccountsUpdatedTest is StateT46p_MaintenanceMode_VaultAccountsUpdated {

    // updated at T46; lastUpdated at T36
    function testVault1Account1_T46_MaintenanceMode() public {
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

    function testVault2Account1_T46_MaintenanceMode() public {
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
    
    // repeated call of updateAllVaultAccounts is immaterial; as long as distributions remain unchanged
    function testRepeatedCallOfUpdateAllVaultAccountsIsImmaterial() public {
        // check vaults before
        DataTypes.VaultAccount memory vault1Account0Before = getVaultAccount(vaultId1, 0);
        DataTypes.VaultAccount memory vault2Account0Before = getVaultAccount(vaultId2, 0);
        DataTypes.VaultAccount memory vault1Account1Before = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2Account1Before = getVaultAccount(vaultId2, 1);
        
        bytes32[] memory vaultIds = new bytes32[](2);
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;

        // advance time
        vm.warp(block.timestamp + 100);

        // repeat call
        vm.startPrank(operator);
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
        vm.stopPrank();

        // check vaults after
        DataTypes.VaultAccount memory vault1Account0After = getVaultAccount(vaultId1, 0);
        DataTypes.VaultAccount memory vault2Account0After = getVaultAccount(vaultId2, 0);
        DataTypes.VaultAccount memory vault1Account1After = getVaultAccount(vaultId1, 1);
        DataTypes.VaultAccount memory vault2Account1After = getVaultAccount(vaultId2, 1);
        
        // verify vaults are unchanged
        assertEq(vault1Account0After.index, vault1Account0Before.index, "vault1Account0 index mismatch");
        assertEq(vault2Account0After.index, vault2Account0Before.index, "vault2Account0 index mismatch");
        assertEq(vault1Account1After.index, vault1Account1Before.index, "vault1Account1 index mismatch");
        assertEq(vault2Account1After.index, vault2Account1Before.index, "vault2Account1 index mismatch");
        // sanity check: totalAccRewards
        assertEq(vault1Account0After.totalAccRewards, vault1Account0Before.totalAccRewards, "vault1Account0 totalAccRewards mismatch");
        assertEq(vault2Account0After.totalAccRewards, vault2Account0Before.totalAccRewards, "vault2Account0 totalAccRewards mismatch");
        assertEq(vault1Account1After.totalAccRewards, vault1Account1Before.totalAccRewards, "vault1Account1 totalAccRewards mismatch");
        assertEq(vault2Account1After.totalAccRewards, vault2Account1Before.totalAccRewards, "vault2Account1 totalAccRewards mismatch");
    }

    function testUserCannotUpdateNftMultiplier_T46p() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.updateNftMultiplier(100);
        vm.stopPrank();
    }

    function testCannotSetNftMultiplierToZero_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidMultiplier.selector);
            pool.updateNftMultiplier(0);
        vm.stopPrank();
    }

    // transition
    function testCanUpdateNftMultiplierWhenInMaintenanceMode_T46p() public {
        uint256 oldNftMultiplier = pool.NFT_MULTIPLIER();
        uint256 newNftMultiplier = oldNftMultiplier * 2;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit NftMultiplierUpdated(oldNftMultiplier, newNftMultiplier);
            pool.updateNftMultiplier(newNftMultiplier);
        vm.stopPrank();

        assertEq(newNftMultiplier, pool.NFT_MULTIPLIER());
    }
}


abstract contract StateT46p_MaintenanceMode_NftMultiplierUpdated is StateT46p_MaintenanceMode_VaultAccountsUpdated {

    uint256 oldNftMultiplier;
    uint256 newNftMultiplier;

    function setUp() public virtual override {
        super.setUp();

        oldNftMultiplier = pool.NFT_MULTIPLIER();
        newNftMultiplier = oldNftMultiplier * 2;

        vm.startPrank(operator);
            pool.updateNftMultiplier(newNftMultiplier);
        vm.stopPrank();
    }
}

contract StateT46p_MaintenanceMode_NftMultiplierUpdatedTest is StateT46p_MaintenanceMode_NftMultiplierUpdated {

    function testNftMultiplierUpdated() public {
        assertEq(pool.NFT_MULTIPLIER(), newNftMultiplier, "nft multiplier not updated");
    }

    function testUserCannotUpdateBoostedBalances_T46p() public {
        bytes32[] memory vaultIds = new bytes32[](2);   
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;

        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.updateBoostedBalances(vaultIds);
        vm.stopPrank();
    }

    function testUpdateBoostedBalances_InvalidArray_T46p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidArray.selector);
            pool.updateBoostedBalances(new bytes32[](0));
        vm.stopPrank();
    }

    function testUpdateBoostedBalances_NonExistentVault_T46p() public {
        bytes32[] memory vaultIds = new bytes32[](2);   
        vaultIds[0] = generateVaultId(10, user1);
        
        vm.startPrank(operator);
            vm.expectPartialRevert(Errors.NonExistentVault.selector);
            pool.updateBoostedBalances(vaultIds);
        vm.stopPrank();
    }

    //oldMultiplier: 1000, newMultiplier: 2000
    function testOperatorCanUpdateBoostedBalances_T46p() public {
        bytes32[] memory vaultIds = new bytes32[](2);   
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;

        // Check boosted values before
        DataTypes.Vault memory vault1Before = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2Before = pool.getVault(vaultId2);
        uint256 totalBoostedRpBefore = pool.totalBoostedRealmPoints();
        uint256 totalBoostedTokensBefore = pool.totalBoostedStakedTokens();

        assertEq(vault1Before.totalBoostFactor, 12_000, "vault1 boost factor not initialized correctly");
        assertEq(vault2Before.totalBoostFactor, 12_000, "vault2 boost factor not initialized correctly");

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit BoostedBalancesUpdated(vaultIds);
            pool.updateBoostedBalances(vaultIds);
        vm.stopPrank();

        // Check boosted values after
        DataTypes.Vault memory vault1After = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2After = pool.getVault(vaultId2);
        uint256 totalBoostedRpAfter = pool.totalBoostedRealmPoints();
        uint256 totalBoostedTokensAfter = pool.totalBoostedStakedTokens();

        // check new totalBoostFactor
        uint256 expectedBoostFactor = (2 * 2000) + 10_000; // 2 nfts staked in each vault
        assertEq(vault1After.totalBoostFactor, expectedBoostFactor, "vault1 boost factor not updated correctly");   //14_000
        assertEq(vault2After.totalBoostFactor, expectedBoostFactor, "vault2 boost factor not updated correctly");

        // Verify boosted values were updated
        assertEq(vault1After.boostedRealmPoints, vault1Before.stakedRealmPoints * expectedBoostFactor / 10_000, "vault1 boosted realm points not updated correctly");
        assertEq(vault1After.boostedStakedTokens, vault1Before.stakedTokens * expectedBoostFactor / 10_000, "vault1 boosted staked tokens not updated correctly");

        assertEq(vault2After.boostedRealmPoints, vault2Before.stakedRealmPoints * expectedBoostFactor / 10_000, "vault2 boosted realm points not updated correctly");
        assertEq(vault2After.boostedStakedTokens, vault2Before.stakedTokens * expectedBoostFactor / 10_000, "vault2 boosted staked tokens not updated correctly");

        assertEq(totalBoostedRpAfter, vault1After.boostedRealmPoints + vault2After.boostedRealmPoints, "total boosted realm points not updated correctly");
        assertEq(totalBoostedTokensAfter, vault1After.boostedStakedTokens + vault2After.boostedStakedTokens, "total boosted staked tokens not updated correctly");
    }
    
}


abstract contract StateT46p_MaintenanceMode_UpdateBoostedBalances is StateT46p_MaintenanceMode_NftMultiplierUpdated {

    function setUp() public virtual override {
        super.setUp();

        bytes32[] memory vaultIds = new bytes32[](2);   
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;

        vm.startPrank(operator);
            pool.updateBoostedBalances(vaultIds);
        vm.stopPrank();
    }
}


contract StateT46p_MaintenanceMode_UpdateBoostedBalancesTest is StateT46p_MaintenanceMode_UpdateBoostedBalances {

    function testRepeatedCallOfUpdateBoostedBalancesIsImmaterial_T46p() public {
        bytes32[] memory vaultIds = new bytes32[](2);   
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;

        // Get values before the repeated call
        DataTypes.Vault memory vault1Before = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2Before = pool.getVault(vaultId2);
        uint256 totalBoostedRpBefore = pool.totalBoostedRealmPoints();
        uint256 totalBoostedTokensBefore = pool.totalBoostedStakedTokens();

        vm.startPrank(operator);
            pool.updateBoostedBalances(vaultIds);
        vm.stopPrank();

        // Get values after the repeated call
        DataTypes.Vault memory vault1After = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2After = pool.getVault(vaultId2);
        uint256 totalBoostedRpAfter = pool.totalBoostedRealmPoints();
        uint256 totalBoostedTokensAfter = pool.totalBoostedStakedTokens();

        // Verify that vault boosted values did not change
        assertEq(vault1After.boostedRealmPoints, vault1Before.boostedRealmPoints, "vault1 boosted realm points should not change");
        assertEq(vault1After.boostedStakedTokens, vault1Before.boostedStakedTokens, "vault1 boosted staked tokens should not change");
        assertEq(vault2After.boostedRealmPoints, vault2Before.boostedRealmPoints, "vault2 boosted realm points should not change");
        assertEq(vault2After.boostedStakedTokens, vault2Before.boostedStakedTokens, "vault2 boosted staked tokens should not change");

        // Verify that global boosted values did not change
        assertEq(totalBoostedRpAfter, totalBoostedRpBefore, "total boosted realm points should not change");
        assertEq(totalBoostedTokensAfter, totalBoostedTokensBefore, "total boosted staked tokens should not change");
    }

    function testUserCannotDisableMaintenanceMode_T46p() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.disableMaintenance();
        vm.stopPrank();
    }

    function testOperatorCanDisableMaintenanceMode_T46p() public {
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaintenanceDisabled(block.timestamp);
            pool.disableMaintenance();
        vm.stopPrank();
        assertEq(pool.isUnderMaintenance(), 0, "maintenance not disabled");
    }
}

abstract contract StateT46p_MaintenanceMode_DisableMaintenance is StateT46p_MaintenanceMode_UpdateBoostedBalances {

    function setUp() public virtual override {
        super.setUp();
        
        vm.warp(51);

        vm.startPrank(operator);
            pool.disableMaintenance();
        vm.stopPrank();
    }
}

contract StateT46p_MaintenanceMode_DisableMaintenanceTest is StateT46p_MaintenanceMode_DisableMaintenance {

    function testOperatorCannotDisableMaintenanceIfNotUnderMaintenance() public {
        vm.startPrank(operator);
            vm.expectRevert(abi.encodeWithSelector(Errors.NotInMaintenance.selector));
            pool.disableMaintenance();
        vm.stopPrank();
    }   

    function test_TimeIsNotLostInMaintenanceMode() public {
        // 1. maintenance mode entered at T46
        // 2. distributions updated at T46 
        // 3. maintenance mode exited at T51
        // 4. next state update occurs at T56 
        // we show that the 5s of time, T46 - T51, is not lost
        // users will get rewards accounting for emissions from T46 - T56

        // get state before 
        DataTypes.Distribution memory distribution_before = getDistribution(1);
        DataTypes.VaultAccount memory vault1Account_before = getVaultAccount(vaultId1, 1);


        vm.warp(56);

        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        // Get distribution state after update
        DataTypes.Distribution memory distribution_after = getDistribution(1);
        DataTypes.VaultAccount memory vault1Account_after = getVaultAccount(vaultId1, 1);
        
        // Calculate expected index increment for 10 seconds of emissions
        uint256 expectedEmitted = 10 * distribution_before.emissionPerSecond;    
        uint256 expectedIndexIncrement = expectedEmitted * 1E18 / pool.totalBoostedStakedTokens();
        uint256 expectedIndex = distribution_before.index + expectedIndexIncrement;

        // Verify distribution state
        assertEq(distribution_after.index, expectedIndex, "distribution index mismatch");
        assertEq(distribution_after.totalEmitted, distribution_before.totalEmitted + expectedEmitted, "distribution total emitted mismatch");
        assertEq(distribution_after.lastUpdateTimeStamp, 56, "distribution last update timestamp mismatch");

        // Verify vault1 accrued rewards during maintenance mode
        assertEq(vault1Account_after.index, expectedIndex, "vault1 index mismatch");
        assertGt(vault1Account_after.totalAccRewards, vault1Account_before.totalAccRewards, "vault1 total rewards did not increase");
    }
}

