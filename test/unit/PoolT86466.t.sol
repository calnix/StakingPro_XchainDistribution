// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT86461.t.sol";
 
/**

 5s  delta to check if rewards accrued properly after vault 2 ended
 are rewards accrued to vault2 if it is ended?
 are rewards accrued to vault2 beyond endTime - yes. but no choice

 */

// 66+1day
abstract contract StateT86466_User2UnstakedFromVault2 is StateT86461_Vault2Ended {

    function setUp() public virtual override {
        super.setUp();

        // 66 + 1 day
        vm.warp(66 + 86400);

        // User2 unstakes from vault2
        vm.startPrank(user2);
            DataTypes.User memory initialUser = pool.getUser(user2, vaultId2);
            pool.unstake(vaultId2, initialUser.stakedTokens, initialUser.tokenIds);
        vm.stopPrank();
    }
}

// test that ended vault does not accrue rewards after endTime
contract StateT86466_User2UnstakedFromVault2Test is StateT86466_User2UnstakedFromVault2 {

    // only d1
    function testUser2ClaimRewardsFromVault2() public {
        // get initial rewards token balances
        uint256 initialUserBalance = rewardsToken1.balanceOf(user2);
        uint256 initialRewardsVaultBalance = rewardsToken1.balanceOf(address(rewardsVault));

        // get initial claimable rewards
        uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);

        // claim rewards
        vm.startPrank(user2);
            pool.claimRewards(vaultId2, 1);
        vm.stopPrank();

        // Check final token balances
        assertEq(rewardsToken1.balanceOf(user2), initialUserBalance + claimableRewards, "User rewardsToken1 balance not increased by claimed rewards");
        assertEq(rewardsToken1.balanceOf(address(rewardsVault)), initialRewardsVaultBalance - claimableRewards, "Pool rewardsToken1 balance not decreased by claimed rewards");

        // Check no more rewards claimable
        assertEq(pool.getClaimableRewards(user2, vaultId2, 1), 0, "Distribution 1 still has claimable rewards");

        // check that what as claimed is the same as what was claimable in T86461: i.e. vault did not accrued rewards after endTime
        uint256 claimableAtT86461 = vault2Account1_T86461.totalAccRewards - vault2Account1_T86461.totalClaimedRewards;
        assertApproxEqAbs(claimableRewards, claimableAtT86461, 1676, "Claimed rewards do not match expected amount from T86461");   
    }

    function testUserCannotSetEndTime() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.setEndTime(block.timestamp + 1);
        vm.stopPrank();
    }

    function testCannotSetZeroEndTime() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.setEndTime(0);
        vm.stopPrank();
    }

    function testCannotSetEndTimeInPast() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.setEndTime(block.timestamp - 1);
        vm.stopPrank();
    }

    function testCannotSetEndTimeMultipleTimes() public {
        vm.startPrank(operator);
            // Set first end time
            uint256 firstEndTime = block.timestamp + 5;
            pool.setEndTime(firstEndTime);
            assertEq(pool.endTime(), firstEndTime);

            // Set second end time
            uint256 secondEndTime = block.timestamp + 10; 
            vm.expectRevert(Errors.EndTimeAlreadySet.selector);
            pool.setEndTime(secondEndTime);
        vm.stopPrank();
    }

    function testCanUpdateD1EndTimeWithinContractEndTime_T86466() public {
        // set end Time
        vm.startPrank(operator);
            pool.setEndTime(block.timestamp + 10);
        vm.stopPrank();

        uint256 distributionId = 1;
        uint256 newEndTime = block.timestamp + 2;
                
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);

        // can update D1 endTime within contract endTime
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, newEndTime, distributionBefore.emissionPerSecond);

            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();

        // get distribution after
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify endTime was updated
        assertEq(distributionAfter.endTime, newEndTime);

        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
    }

    // transition
    function testSetContractEndTime() public {
        // get initial endTime
        uint256 initialEndTime = pool.endTime();
        assertEq(initialEndTime, 0);

        // get initial distribution endTimes
        uint256[] memory initialDistributionEndTimes = new uint256[](pool.getActiveDistributionsLength());
        for(uint256 i; i < pool.getActiveDistributionsLength(); ++i) {
            DataTypes.Distribution memory distribution = getDistribution(i);
            initialDistributionEndTimes[i] = distribution.endTime;
        }

        uint256 newEndTime = block.timestamp + 5;
        
        // set new endTime
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit StakingEndTimeSet(newEndTime);
            pool.setEndTime(newEndTime);
        vm.stopPrank();

        // check that endTime is set
        assertEq(pool.endTime(), newEndTime);

        // check that distribution endTimes are updated
        for(uint256 i; i < pool.getActiveDistributionsLength(); ++i) {
            DataTypes.Distribution memory distribution = getDistribution(i);

            assertEq(distribution.endTime, newEndTime, "Distribution endTime not updated");
        }
    }

}
