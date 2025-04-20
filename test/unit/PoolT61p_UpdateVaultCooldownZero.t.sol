// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT56.t.sol";

abstract contract StateT61_Vault2CooldownActivated_UpdatedCooldown is StateT56_UsersClaimRewardsFromBothVaults {

    // for reference
    DataTypes.Vault vault1_T61; 
    DataTypes.Vault vault2_T61;

    DataTypes.Distribution distribution0_T61;
    DataTypes.Distribution distribution1_T61;
    //vault1
    DataTypes.VaultAccount vault1Account0_T61;
    DataTypes.VaultAccount vault1Account1_T61;
    //vault2
    DataTypes.VaultAccount vault2Account0_T61;
    DataTypes.VaultAccount vault2Account1_T61;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T61;
    DataTypes.UserAccount user1Vault1Account1_T61;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T61;
    DataTypes.UserAccount user2Vault1Account1_T61;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T61;
    DataTypes.UserAccount user1Vault2Account1_T61;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T61;
    DataTypes.UserAccount user2Vault2Account1_T61;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(61);
        
        vm.startPrank(operator);
            pool.updateVaultCooldown(0);
        vm.stopPrank();

        // save state
        vault1_T61 = pool.getVault(vaultId1);
        vault2_T61 = pool.getVault(vaultId2);
        
        distribution0_T61 = getDistribution(0); 
        distribution1_T61 = getDistribution(1);

        vault1Account0_T61 = getVaultAccount(vaultId1, 0);
        vault1Account1_T61 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T61 = getVaultAccount(vaultId2, 0);
        vault2Account1_T61 = getVaultAccount(vaultId2, 1);

        user1Vault1Account0_T61 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T61 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T61 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T61 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T61 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T61 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T61 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T61 = getUserAccount(user2, vaultId2, 1);
    }
}



contract StateT61p_UpdateVaultCooldownTest is StateT61_Vault2CooldownActivated_UpdatedCooldown {

    function testVault2EndedOnActivateCooldown_T61p() public {
        // global state: before
        uint256 poolTotalNftsBefore = pool.totalStakedNfts();
        uint256 poolTotalCreationNftsBefore = pool.totalCreationNfts();
        uint256 poolTotalRpBefore = pool.totalStakedRealmPoints();
        uint256 poolTotalTokensBefore = pool.totalStakedTokens();
        uint256 poolTotalBoostedRpBefore = pool.totalBoostedRealmPoints();
        uint256 poolTotalBoostedTokensBefore = pool.totalBoostedStakedTokens();
       
        // vault state: before
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId2);
        assertEq(vaultBefore.endTime, 0, "Vault2 endTime not 0");
        assertEq(vaultBefore.removed, 0, "Vault2 removed not 0");


        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit VaultCooldownActivated(vaultId2, block.timestamp);

            vm.expectEmit(true, true, true, true);
            emit VaultEnded(vaultId2);
            pool.activateCooldown(vaultId2);
        vm.stopPrank();


        //global state: after
        uint256 poolTotalNftsAfter = pool.totalStakedNfts();
        uint256 poolTotalCreationNftsAfter = pool.totalCreationNfts();
        uint256 poolTotalRpAfter = pool.totalStakedRealmPoints();
        uint256 poolTotalTokensAfter = pool.totalStakedTokens();
        uint256 poolTotalBoostedRpAfter = pool.totalBoostedRealmPoints();
        uint256 poolTotalBoostedTokensAfter = pool.totalBoostedStakedTokens();
        
        //get vault2: after
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId2);

        //check global state changes
        assertEq(poolTotalNftsBefore - vaultBefore.stakedNfts, poolTotalNftsAfter, "totalStakedNfts mismatch");
        assertEq(poolTotalCreationNftsBefore - vaultBefore.creationTokenIds.length, poolTotalCreationNftsAfter, "totalCreationNfts mismatch");
        assertEq(poolTotalRpBefore - vaultBefore.stakedRealmPoints, poolTotalRpAfter, "totalStakedRealmPoints mismatch");
        assertEq(poolTotalTokensBefore - vaultBefore.stakedTokens, poolTotalTokensAfter, "totalStakedTokens mismatch");
        assertEq(poolTotalBoostedRpBefore - vaultBefore.boostedRealmPoints, poolTotalBoostedRpAfter, "totalBoostedRealmPoints mismatch");
        assertEq(poolTotalBoostedTokensBefore - vaultBefore.boostedStakedTokens, poolTotalBoostedTokensAfter, "totalBoostedStakedTokens mismatch");

        // check vault state changes
        assertEq(vaultAfter.removed, 1, "Vault2 not ended");
        assertEq(vaultAfter.endTime, block.timestamp, "Vault endTime not updated to NOW");

    }
}


abstract contract StateT61p_Vault2CooldownActivated_VaultIsRemovedImmediately is StateT61_Vault2CooldownActivated_UpdatedCooldown {

    function setUp() public virtual override {
        super.setUp();

        //vm.warp(61 + 5);

        vm.startPrank(user2);            
            pool.activateCooldown(vaultId2);
        vm.stopPrank();
    }
}

contract StateT61p_Vault2CooldownActivated_VaultIsRemovedImmediately_Test is StateT61p_Vault2CooldownActivated_VaultIsRemovedImmediately {

    function testUser2UnstakeAfterVault2EndedDoesNotDecrementGlobalState() public {

        // global state: before
        uint256 poolTotalNftsBefore = pool.totalStakedNfts();
        uint256 poolTotalCreationNftsBefore = pool.totalCreationNfts();
        uint256 poolTotalRpBefore = pool.totalStakedRealmPoints();
        uint256 poolTotalTokensBefore = pool.totalStakedTokens();
        uint256 poolTotalBoostedRpBefore = pool.totalBoostedRealmPoints();
        uint256 poolTotalBoostedTokensBefore = pool.totalBoostedStakedTokens();

        // vault state: before
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId2);
        assertEq(vaultBefore.removed, 1, "Vault2 not ended");

        // user account: before
        DataTypes.User memory user2Vault2Assets = pool.getUser(user2, vaultId2);

        vm.startPrank(user2);
            pool.unstake(vaultId2, user2Vault2Assets.stakedTokens, user2Vault2Assets.tokenIds);
        vm.stopPrank();

        //global state: after
        uint256 poolTotalNftsAfter = pool.totalStakedNfts();
        uint256 poolTotalCreationNftsAfter = pool.totalCreationNfts();
        uint256 poolTotalRpAfter = pool.totalStakedRealmPoints();
        uint256 poolTotalTokensAfter = pool.totalStakedTokens();
        uint256 poolTotalBoostedRpAfter = pool.totalBoostedRealmPoints();
        uint256 poolTotalBoostedTokensAfter = pool.totalBoostedStakedTokens();

        //get vault2: after
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId2);

        //check global state: no changes
        assertEq(poolTotalNftsBefore, poolTotalNftsAfter, "totalStakedNfts mismatch");
        assertEq(poolTotalCreationNftsBefore, poolTotalCreationNftsAfter, "totalCreationNfts mismatch");
        assertEq(poolTotalRpBefore, poolTotalRpAfter, "totalStakedRealmPoints mismatch");
        assertEq(poolTotalTokensBefore, poolTotalTokensAfter, "totalStakedTokens mismatch");
        assertEq(poolTotalBoostedRpBefore, poolTotalBoostedRpAfter, "totalBoostedRealmPoints mismatch");
        assertEq(poolTotalBoostedTokensBefore, poolTotalBoostedTokensAfter, "totalBoostedStakedTokens mismatch");

        //check vault state: decrementation of assets
        assertEq(vaultAfter.stakedNfts, vaultBefore.stakedNfts - user2Vault2Assets.tokenIds.length, "stakedNfts mismatch");
        assertEq(vaultAfter.stakedTokens, vaultBefore.stakedTokens - user2Vault2Assets.stakedTokens, "stakedTokens mismatch");
        
        // check boosted assets: 0 since all nfts are unstaked
        assertEq(vaultAfter.totalBoostFactor, 10_000, "totalBoostFactor mismatch"); 
        assertEq(vaultAfter.boostedStakedTokens, 0, "boostedStakedTokens mismatch");
    }

    function testUser2MigrateRpToVault1DoesNotDecrementGlobalState() public {

        // global state: before
        uint256 poolTotalRpBefore = pool.totalStakedRealmPoints();
        uint256 poolTotalBoostedRpBefore = pool.totalBoostedRealmPoints();

        // vault states: before
        DataTypes.Vault memory vault1Before = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2Before = pool.getVault(vaultId2);

        // user accounts: before
        DataTypes.User memory user2Vault1Before = pool.getUser(user2, vaultId1);
        DataTypes.User memory user2Vault2Before = pool.getUser(user2, vaultId2);
        uint256 rpToMigrate = user2Vault2Before.stakedRealmPoints;

        vm.startPrank(user2);
            pool.migrateRealmPoints(vaultId2, vaultId1, rpToMigrate);
        vm.stopPrank();

        // global state: after
        uint256 poolTotalRpAfter = pool.totalStakedRealmPoints();
        uint256 poolTotalBoostedRpAfter = pool.totalBoostedRealmPoints();

        // vault states: after
        DataTypes.Vault memory vault1After = pool.getVault(vaultId1);
        DataTypes.Vault memory vault2After = pool.getVault(vaultId2);

        // user accounts: after
        DataTypes.User memory user2Vault1After = pool.getUser(user2, vaultId1);
        DataTypes.User memory user2Vault2After = pool.getUser(user2, vaultId2);

        // check global state: no changes
        uint256 totalBoostedDelta = (rpToMigrate * vault2Before.totalBoostFactor) / 10_000;
        assertEq(poolTotalRpBefore, poolTotalRpAfter, "totalStakedRealmPoints mismatch");
        assertEq(poolTotalBoostedRpBefore + totalBoostedDelta, poolTotalBoostedRpAfter, "totalBoostedRealmPoints mismatch");

        // check vault states: rp moved correctly
        assertEq(vault1After.stakedRealmPoints, vault1Before.stakedRealmPoints + rpToMigrate, "vault1 stakedRealmPoints mismatch");
        assertEq(vault2After.stakedRealmPoints, vault2Before.stakedRealmPoints - rpToMigrate, "vault2 stakedRealmPoints mismatch");

        // check user accounts: rp moved correctly
        assertEq(user2Vault1After.stakedRealmPoints, user2Vault1Before.stakedRealmPoints + rpToMigrate, "user2 vault1 stakedRealmPoints mismatch");
        assertEq(user2Vault2After.stakedRealmPoints, user2Vault2Before.stakedRealmPoints - rpToMigrate, "user2 vault2 stakedRealmPoints mismatch");
    }
}