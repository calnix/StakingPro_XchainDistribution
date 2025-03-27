// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT51.t.sol";

abstract contract StateT56p_Paused is StateT51_BothVaultsFeesUpdated {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(56);

        vm.startPrank(monitor);
            pool.pause();
        vm.stopPrank();
    }
}

contract StateT56p_PausedTest is StateT56p_Paused {

    function testUserCannotUnpausePool() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, pool.DEFAULT_ADMIN_ROLE()));
            pool.unpause();
        vm.stopPrank();
    }
    
    function testAdminCanUnpausePool() public {
        vm.startPrank(owner);
            pool.unpause();
        vm.stopPrank();

        assertEq(pool.paused(), false, "pool not unpaused");
    }

    function testAdminCanFreezePool() public {
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true);
            emit PoolFrozen(block.timestamp);
            pool.freeze();
        vm.stopPrank();

        assertEq(pool.isFrozen(), 1, "pool not frozen");
    }


    function testCannotCreateVaultWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.createVault(user1NftsArray, 1000, 1000, 1000);
    }

    function testCannotStakeTokensWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.stakeTokens(vaultId1, 1000);
    }
    
    function testCannotStakeNftsWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.stakeNfts(vaultId1, user1NftsArray);
    }
    
    function testCannotStakeRPWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.stakeRP(vaultId1, 1000, block.timestamp + 1, bytes(""));
    }

    function testCannotMigrateRpWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.migrateRealmPoints(vaultId1, vaultId2, 1000);
    }

    function testCannotUnstakeWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.unstake(vaultId1, 1000, new uint256[](0));
    }

    function testCannotClaimRewardsWhenPaused() public {
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.claimRewards(vaultId1, 0);
    }
}

abstract contract StateT56p_Frozen is StateT56p_Paused {

    function setUp() public virtual override {
        super.setUp();  

        vm.startPrank(owner);
            pool.freeze();
        vm.stopPrank();
    }
}

contract StateT56p_FrozenTest is StateT56p_Frozen {

    function testAdminCannotUnpausePool() public {
        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(Errors.IsFrozen.selector));
            pool.unpause();
        vm.stopPrank();
    }
    

    function testUserCanEmergencyExit() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;

        // Get initial state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        DataTypes.User memory userBefore = pool.getUser(user1, vaultId1);
        // token balance before
        uint256 userTokensBefore = mocaToken.balanceOf(user1);
        
        // Expect token transfer and NFT registry calls
        vm.expectCall(address(mocaToken), abi.encodeCall(IERC20.transfer, (user1, userBefore.stakedTokens)));
        vm.expectCall(address(nftRegistry), abi.encodeCall(INftRegistry.recordUnstake, (user1, vaultBefore.creationTokenIds, vaultId1)));
        
        vm.startPrank(user1);
            vm.expectEmit(true, true, true, true);
            emit NftsExited(user1, vaultId1, vaultBefore.creationTokenIds);

            vm.expectEmit(true, true, true, true);
            emit TokensExited(user1, vaultIds, userBefore.stakedTokens);

            pool.emergencyExit(vaultIds, user1);
        vm.stopPrank();

        // Get final state
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        DataTypes.User memory userAfter = pool.getUser(user1, vaultId1);

        // token balance after
        uint256 userTokensAfter = mocaToken.balanceOf(user1);
        assertEq(userTokensAfter, userTokensBefore + userBefore.stakedTokens, "tokens not returned to user");

        // Verify vault changes
        assertEq(vaultAfter.stakedTokens, vaultBefore.stakedTokens - userBefore.stakedTokens, "vault tokens not decremented");
        assertEq(vaultAfter.stakedNfts, vaultBefore.stakedNfts - userBefore.tokenIds.length, "vault nfts not decremented");

        // Verify user changes
        assertEq(userAfter.stakedTokens, 0, "user tokens not zeroed");
        assertEq(userAfter.tokenIds.length, 0, "user nfts not zeroed");

        // Verify token transfer
        assertEq(userTokensAfter, userTokensBefore + userBefore.stakedTokens, "tokens not returned to user");

        // Verify NFT registry state
        for(uint256 i; i < vaultBefore.creationTokenIds.length; ++i) {
            (address nftOwner, bytes32 stakedVaultId) = nftRegistry.nfts(vaultBefore.creationTokenIds[i]);
            assertEq(nftOwner, user1, "nft owner mismatch");
            assertEq(stakedVaultId, bytes32(0), "nft vault id not cleared");
        }
    }
}

