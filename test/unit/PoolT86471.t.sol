// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT86466.t.sol";

abstract contract StateT86471_ContractEnded is StateT86466_User2UnstakedFromVault2 {
    function setUp() public virtual override {
        super.setUp();

        // set endTime: 86471
        vm.startPrank(operator);
            pool.setEndTime(86471);
        vm.stopPrank();

        vm.warp(pool.endTime() + 1);
    }
}   

contract StateT86471_ContractEndedTest is StateT86471_ContractEnded {

    function testCannotSetEndTimeAfterContractEnded() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.setEndTime(block.timestamp + 1); 
        vm.stopPrank();
    }

// ---- state tests ----
    function testCanUnstakeAfterContractEnded() public {
        // Get initial vault and user state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        DataTypes.User memory userBefore = pool.getUser(user1, vaultId1);

        uint256 unstakeAmount = 1000;

        vm.startPrank(user1);
            pool.unstake(vaultId1, unstakeAmount, new uint256[](0));
        vm.stopPrank();

        // Check vault state after unstake
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedTokens, vaultBefore.stakedTokens - unstakeAmount, "Vault staked tokens not reduced correctly");

        // Check user state after unstake
        DataTypes.User memory userAfter = pool.getUser(user1, vaultId1);
        assertEq(userAfter.stakedTokens, userBefore.stakedTokens - unstakeAmount, "User staked tokens not reduced correctly");
    }
    
    function testCanActivateCooldownAfterContractEnded() public {
        // Get initial vault state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        assertEq(vaultBefore.endTime, 0, "Vault end time should be 0");

        vm.startPrank(user1);
            pool.activateCooldown(vaultId1);
        vm.stopPrank();

        // Check vault state after cooldown activation
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.endTime, pool.endTime(), "Vault end time not set correctly");
        assertLe(vaultAfter.endTime, block.timestamp + pool.VAULT_COOLDOWN_DURATION(), "Vault end time should not exceed contract end time");
    }
    
    // now: 86472. contract ended at 86471. vault should end at 86471
    function testCanEndVaultsAfterContractEnded() public {
        // get initial vault state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);

        vm.startPrank(user1);
            pool.activateCooldown(vaultId1);

            bytes32[] memory vaultIds = new bytes32[](1);
            vaultIds[0] = vaultId1;
            pool.endVaults(vaultIds);
        vm.stopPrank();

        // check that vault endTime was set + removed
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        // vault end Time cannot exceed contract end time
        assertLt(vaultAfter.endTime, block.timestamp, "Vault endTime was not set to less than current timestamp");
        assertEq(vaultAfter.endTime, pool.endTime(), "Vault endTime was not set to contract end time");
        
        assertEq(vaultAfter.removed, 1, "Vault is not removed");
    }

    function testCanClaimRewardsAfterContractEnded() public {
        // get initial rewards token balances
        uint256 initialUserBalance = rewardsToken1.balanceOf(user1);
        uint256 initialRewardsVaultBalance = rewardsToken1.balanceOf(address(rewardsVault));

        // get initial claimable rewards
        uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 1);

        // claim rewards
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        // Check final token balances
        assertEq(rewardsToken1.balanceOf(user1), initialUserBalance + claimableRewards, "User rewardsToken1 balance not increased by claimed rewards");
        assertEq(rewardsToken1.balanceOf(address(rewardsVault)), initialRewardsVaultBalance - claimableRewards, "Pool rewardsToken1 balance not decreased by claimed rewards");

        // Check no more rewards claimable
        assertEq(pool.getClaimableRewards(user1, vaultId1, 1), 0, "Distribution 1 still has claimable rewards");
    }

// ---- users fns ----
    function testCannotCreateVaultAfterContractEnded() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = user3NftsArray[0];
        tokenIds[1] = user3NftsArray[1]; 
        tokenIds[2] = user3NftsArray[2];

        vm.startPrank(user3);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.createVault(tokenIds, 1000, 1000, 1000);
        vm.stopPrank();
    }

    function testCannotStakeTokensAfterContractEnded() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.stakeTokens(vaultId1, 1000);
        vm.stopPrank();
    }

    function testCannotStakeNftsAfterContractEnded() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = user3NftsArray[0];
        tokenIds[1] = user3NftsArray[1];

        vm.startPrank(user3);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.stakeNfts(vaultId1, tokenIds);
        vm.stopPrank();
    }

    function testCannotStakeRpAfterContractEnded() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.stakeRP(vaultId1, 1000, block.timestamp + 1, bytes(""));
        vm.stopPrank();
    }

    function testCannotMigrateRpAfterContractEnded() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.migrateRealmPoints(vaultId1, vaultId2, 250 ether);
        vm.stopPrank();
    }

    function testCannotUpdateVaultFeesAfterContractEnded() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.updateVaultFees(vaultId1, 1000, 1000, 1000);
        vm.stopPrank();
    }

// ---- operator fns ----
    function testCannotStakeOnBehalfAfterContractEnded() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.stakeOnBehalfOf(new bytes32[](1), new address[](1), new uint256[](1));
        vm.stopPrank();
    }

    function testCannotSetRewardsVaultAfterContractEnded() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.StakingEnded.selector);
            pool.setRewardsVault(address(123));
        vm.stopPrank();
    }


}   
