// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT11.t.sol";


// Distribution 0 started at T11
// Distribution 1 only starts at T21
abstract contract StateT16p_UpdateDistributionNotStarted is StateT11_Distribution1Created {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(16);
    }
}


contract StateT16p_UpdateDistributionNotStartedTest is StateT16p_UpdateDistributionNotStarted {

// ---------------- updateDistribution: generic checks ----------------
    
    function testCannotUpdateNonExistentDistribution_T16p() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.NonExistentDistribution.selector);
            pool.updateDistribution(5, block.timestamp, block.timestamp + 1, 1 ether);
        vm.stopPrank();
    }
    
    function testCannotUpdateEndedDistribution_T16p() public {
        // update to force D1 to end
        vm.startPrank(operator);
            pool.endDistribution(1);
        vm.stopPrank();

        // try to update
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionEnded.selector);
            pool.updateDistribution(1, block.timestamp, block.timestamp + 1, 1 ether);
        vm.stopPrank();
    }

// ---------------- updateDistribution: startTime modification ----------------
    
    // cannot update if started
    function test_StartTimeModification_CannotUpdateIfStarted_T16p() public {
        uint256 distributionId = 0;
        uint256 newStartTime = block.timestamp + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }

    // new startTime must be greater than current
    function test_StartTimeModification_NewStartTimeMustBeGreaterThanCurrent_T16p() public {
        uint256 distributionId = 1;
        uint256 newStartTime = block.timestamp - 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidStartTime.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }
    
    // can update if not started
    function test_StartTimeModification_CanUpdateStartTimeIfNotStarted_T16p() public {
        uint256 distributionId = 1;
        uint256 newStartTime = block.timestamp + 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (distributionBefore.endTime - newStartTime) * distributionBefore.emissionPerSecond;
        
        vm.startPrank(operator);
            // Check for event emission
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newStartTime, distributionBefore.endTime, distributionBefore.emissionPerSecond);
            
            // Expect call to rewards vault with the new total required
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.updateDistribution, (distributionId, expectedTotalRequired))
            );
            
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify the start time was updated
        assertEq(distributionAfter.startTime, newStartTime);
        
        // Verify other parameters remain unchanged
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
    }


// ---------------- updateDistribution: endTime modification ----------------

    function test_EndTimeModification_CannotUpdateEndTimeIfD0_T16p() public {
        uint256 distributionId = 0;
        uint256 newEndTime = block.timestamp + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.CannotEndStakingPowerDistribution.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }
    
    // cannot be in the past
    function test_EndTimeModification_CannotUpdateEndTimeIfInPast_T16p() public {
        uint256 distributionId = 1;
        uint256 newEndTime = block.timestamp - 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionEndTime.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }
    
    // If only endTime is being updated, ensure it's after existing startTime
    function test_EndTimeModification_CannotUpdateEndTimeIfAfterStartTime_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        uint256 newEndTime = distribution.startTime - 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionEndTime.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }
    
    // If both times are being updated, ensure end is after start
    function test_EndTimeModification_CannotUpdateBothTimesIfEndBeforeStart_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        uint256 newStartTime = distribution.endTime + 1;
        uint256 newEndTime = distribution.startTime - 1;
    
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionEndTime.selector);
            pool.updateDistribution(distributionId, newStartTime, newEndTime, 0);
        vm.stopPrank();
    }

    // only endTime: can update if endTime is after startTime
    function test_EndTimeModification_CanUpdateEndTimeIfAfterStartTime_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        uint256 newEndTime = distribution.startTime + 1;

        vm.startPrank(operator);
            // Check for event emission
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distribution.startTime, newEndTime, distribution.emissionPerSecond);
            
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank(); 
    }   
    
    
    // update both start and end time: can update if endTime is after startTime
    function test_EndTimeModification_CanUpdateBothTimesIfEndAfterStart_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        uint256 newStartTime = distribution.startTime + 1;
        uint256 newEndTime = distribution.endTime + 1;  

        vm.startPrank(operator);
            // Check for event emission
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newStartTime, newEndTime, distribution.emissionPerSecond);
            
            pool.updateDistribution(distributionId, newStartTime, newEndTime, 0);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify the start and end times were updated
        assertEq(distributionAfter.startTime, newStartTime);
        assertEq(distributionAfter.endTime, newEndTime);
    }

// ---------------- updateDistribution: emissionPerSecond modification ----------------
/*
    function test_EmissionRateModification_CannotUpdateEmissionPerSecondToBeZero_T16p() public {
        uint256 distributionId = 0;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEmissionPerSecond = 0;

        vm.startPrank(operator);
            pool.updateDistribution(distributionId, 0, 0, newEmissionPerSecond);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify emission rate was not changed
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
        assertNotEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
    }*/
    
    // lower emission rate
    function test_EmissionRateModification_LowerEmissionRate_T16p() public {
        uint256 distributionId = 0;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        // Set new emission rate lower than original
        uint256 newEmissionPerSecond = distributionBefore.emissionPerSecond / 2;
        
        vm.startPrank(operator);
            // Check for event emission
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, block.timestamp, distributionBefore.endTime, newEmissionPerSecond);
            
            // For distribution 0, we don't expect a call to rewards vault
            pool.updateDistribution(distributionId, 0, 0, newEmissionPerSecond);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify emission rate was changed
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertNotEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
        
        // For distribution 0 (staking power), no call to rewards vault is made
        // as it's handled in the if(distributionId > 0) condition in updateDistribution
    }

    // higher emission rate
    function test_EmissionRateModification_HigherEmissionRate_T16p() public {
        uint256 distributionId = 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        // Set new emission rate higher than original
        uint256 newEmissionPerSecond = distributionBefore.emissionPerSecond * 2;
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (distributionBefore.endTime - distributionBefore.startTime) * newEmissionPerSecond;

        vm.startPrank(operator);
            // Check for event emission
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionPerSecond);
            
            // Expect call to rewards vault with the new total required
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.updateDistribution, (distributionId, expectedTotalRequired))
            );
            
            pool.updateDistribution(distributionId, 0, 0, newEmissionPerSecond);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify emission rate was changed
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertNotEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
    }

// ---------------- updateDistribution: multiple updates ----------------

    // 1. update startTime, endTime
    // 2. update startTime, emissionPerSecond
    // 3. update endTime, emissionPerSecond
    // 4. update startTime, endTime, emissionPerSecond

    // 1. update startTime, endTime
    function testCanUpdateStartTimeAndEndTimeD1_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        
        uint256 newStartTime = distribution.startTime + 1;
        uint256 newEndTime = distribution.endTime + 1;
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (newEndTime - newStartTime) * distribution.emissionPerSecond;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newStartTime, newEndTime, distribution.emissionPerSecond);
            
            // Expect call to rewards vault with the new total required
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.updateDistribution, (distributionId, expectedTotalRequired))
            );
            
            pool.updateDistribution(distributionId, newStartTime, newEndTime, 0);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify the start and end times were updated
        assertEq(distributionAfter.startTime, newStartTime);
        assertEq(distributionAfter.endTime, newEndTime);
        assertEq(distributionAfter.emissionPerSecond, distribution.emissionPerSecond);
    }

    // 2. update startTime, emissionPerSecond
    function testCanUpdateStartTimeAndEmissionPerSecondD1_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        
        uint256 newStartTime = distribution.startTime + 1;
        uint256 newEmissionPerSecond = distribution.emissionPerSecond * 2;
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (distribution.endTime - newStartTime) * newEmissionPerSecond;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newStartTime, distribution.endTime, newEmissionPerSecond);
            
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.updateDistribution, (distributionId, expectedTotalRequired))
            );
            
            pool.updateDistribution(distributionId, newStartTime, distribution.endTime, newEmissionPerSecond);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify the start time and emission rate were updated
        assertEq(distributionAfter.startTime, newStartTime);
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertEq(distributionAfter.endTime, distribution.endTime);  
    }

    // 3. update endTime, emissionPerSecond
    function testCanUpdateEndTimeAndEmissionPerSecondD1_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        
        uint256 newEndTime = distribution.endTime + 1;
        uint256 newEmissionPerSecond = distribution.emissionPerSecond * 2;
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (newEndTime - distribution.startTime) * newEmissionPerSecond;   
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distribution.startTime, newEndTime, newEmissionPerSecond);
            
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.updateDistribution, (distributionId, expectedTotalRequired))
            );
            
            pool.updateDistribution(distributionId, distribution.startTime, newEndTime, newEmissionPerSecond);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify the end time and emission rate were updated
        assertEq(distributionAfter.endTime, newEndTime);
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertEq(distributionAfter.startTime, distribution.startTime);
    }

    // 4. update startTime, endTime, emissionPerSecond
    function testCanUpdateAllFieldsD1_T16p() public {
        uint256 distributionId = 1;
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        
        // D1: starts at T21
        assertEq(distribution.startTime, 21);
        assertEq(distribution.endTime, 172821);
        assertEq(distribution.lastUpdateTimeStamp, 21);

        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        uint256 newStartTime = distribution.startTime - 1;
        uint256 newEndTime = distribution.endTime + 10;
        uint256 newEmissionPerSecond = distribution.emissionPerSecond * 2;
        
        // Calculate expected total required for the entire distribution period
        uint256 expectedTotalRequired = (newEndTime - newStartTime) * newEmissionPerSecond;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newStartTime, newEndTime, newEmissionPerSecond);
           
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true, address(rewardsVault));
            emit DistributionUpdated(distributionId, expectedTotalRequired);
            
            pool.updateDistribution(distributionId, newStartTime, newEndTime, newEmissionPerSecond);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify all fields were updated
        assertEq(distributionAfter.startTime, newStartTime);
        assertEq(distributionAfter.endTime, newEndTime);
        assertEq(distributionAfter.emissionPerSecond, newEmissionPerSecond);
        assertEq(distributionAfter.lastUpdateTimeStamp, newStartTime);

        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);
    }

}

// note: then go to UpdateDistributionStarted
// note: then go to UpdateDistributionIfContractEndTimeSet