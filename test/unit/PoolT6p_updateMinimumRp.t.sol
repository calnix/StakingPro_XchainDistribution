// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT1.t.sol";

abstract contract StateT6_User2StakeAssetsToVault1_LowerMinimumRp is StateT1_User1StakeAssetsToVault1 {

    function setUp() public virtual override {
        super.setUp();

        // T6   
        vm.warp(6);
 
        // lower minimum realm points
        vm.startPrank(operator);
            uint256 oldMinimumRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
            uint256 newMinimumRealmPoints = oldMinimumRealmPoints/2;
            pool.updateMinimumRealmPoints(newMinimumRealmPoints);
        vm.stopPrank();
    }
}


contract StateT6_User2StakeAssetsToVault1_LowerMinimumRpTest is StateT6_User2StakeAssetsToVault1_LowerMinimumRp {

    function testUser2CannotStakeRpExceedingNewMinimum() public {
        uint256 rpToStake = pool.MINIMUM_REALMPOINTS_REQUIRED() - 1;

        vm.startPrank(user2);
            uint256 expiry = block.timestamp + 1 days;
            uint256 nonce = 0;
            bytes memory signature = generateSignature(user2, vaultId1, rpToStake, expiry, nonce);
            
            vm.expectRevert(abi.encodeWithSelector(Errors.MinimumRealmPointsRequired.selector));
            pool.stakeRealmPoints(vaultId1, rpToStake, expiry, signature);
        vm.stopPrank();
    }

    function testUser2CanStakeRpAsPerNewMinimum() public {
        // Get vault before
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        // Get user before
        DataTypes.User memory user2Before = pool.getUser(user2, vaultId1);
        assertEq(user2Before.stakedRealmPoints, 0);
        
        uint256 rpToStake = pool.MINIMUM_REALMPOINTS_REQUIRED();

        vm.startPrank(user2);
            uint256 expiry = block.timestamp + 1 days;
            uint256 nonce = 0;  
            bytes memory signature = generateSignature(user2, vaultId1, rpToStake, expiry, nonce);
            pool.stakeRealmPoints(vaultId1, rpToStake, expiry, signature);
        vm.stopPrank();


        // Check user vault assets
        DataTypes.User memory user2After = pool.getUser(user2, vaultId1);
        assertEq(user2After.stakedRealmPoints, rpToStake);
        
        // Check vault assets changed correctly
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedRealmPoints, vaultBefore.stakedRealmPoints + rpToStake);
        assertEq(vaultAfter.boostedRealmPoints, vaultBefore.boostedRealmPoints + rpToStake);
    }
}


abstract contract StateT6_User2StakeAssetsToVault1_HigherMinimumRp is StateT1_User1StakeAssetsToVault1 {

    // for reference
    DataTypes.Vault vault1_T6; 
    // d0
    DataTypes.Distribution distribution0_T6;
    // vault1
    DataTypes.VaultAccount vault1Account0_T6;
    // users+vault1
    DataTypes.UserAccount user1Vault1Account0_T6;
    DataTypes.UserAccount user2Vault1Account0_T6;
    // users vault assets for vault1
    DataTypes.User user1Vault1Assets_T6;
    DataTypes.User user2Vault1Assets_T6;


    function setUp() public virtual override {
        super.setUp();

        // T6   
        vm.warp(6);
 
        // lower minimum realm points
        vm.startPrank(operator);
            uint256 oldMinimumRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
            uint256 newMinimumRealmPoints = oldMinimumRealmPoints*2;
            pool.updateMinimumRealmPoints(newMinimumRealmPoints);
        vm.stopPrank();

        // save state
        vault1_T6 = pool.getVault(vaultId1);
        distribution0_T6 = getDistribution(0);
        vault1Account0_T6 = getVaultAccount(vaultId1, 0);
        user1Vault1Account0_T6 = getUserAccount(user1, vaultId1, 0);
        user2Vault1Account0_T6 = getUserAccount(user2, vaultId1, 0);

        user1Vault1Assets_T6 = pool.getUser(user1, vaultId1);
        user2Vault1Assets_T6 = pool.getUser(user2, vaultId1);
    }
}


contract StateT6_User2StakeAssetsToVault1_HigherMinimumRpTest is StateT6_User2StakeAssetsToVault1_HigherMinimumRp {

    function testUser2CannotStakeRpExceedingNewMinimum() public {
        uint256 rpToStake = pool.MINIMUM_REALMPOINTS_REQUIRED() - 1;

        vm.startPrank(user2);
            uint256 expiry = block.timestamp + 1 days;
            uint256 nonce = 0;
            bytes memory signature = generateSignature(user2, vaultId1, rpToStake, expiry, nonce);
            
            vm.expectRevert(abi.encodeWithSelector(Errors.MinimumRealmPointsRequired.selector));
            pool.stakeRealmPoints(vaultId1, rpToStake, expiry, signature);
        vm.stopPrank();
    }

    function testUser2CanStakeRpAsPerNewMinimum() public {
        // check vault before
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        // check user before
        DataTypes.User memory user2Before = pool.getUser(user2, vaultId1);
        assertEq(user2Before.stakedRealmPoints, 0);
        
        uint256 rpToStake = pool.MINIMUM_REALMPOINTS_REQUIRED();

        vm.startPrank(user2);
            uint256 expiry = block.timestamp + 1 days;
            uint256 nonce = 0;  
            bytes memory signature = generateSignature(user2, vaultId1, rpToStake, expiry, nonce);
            pool.stakeRealmPoints(vaultId1, rpToStake, expiry, signature);
        vm.stopPrank();

        // check user after
        DataTypes.User memory user2After = pool.getUser(user2, vaultId1);
        assertEq(user2After.stakedRealmPoints, rpToStake);
        
        // check vault after
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedRealmPoints, vaultBefore.stakedRealmPoints + rpToStake);
        assertEq(vaultAfter.boostedRealmPoints, vaultBefore.boostedRealmPoints + rpToStake);
    }
}


