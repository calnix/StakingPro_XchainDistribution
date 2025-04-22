// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT21.t.sol";


// note: update distribution started - D1
abstract contract StateT26p_UpdateDistributionStarted is StateT21_CreationNftsUpdated {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(26);
   
    }
}


contract StateT26p_UpdateDistributionStartedTest is StateT26p_UpdateDistributionStarted {

// ------- update distribution: D0 -------

    function testCannotUpdateD0StartTimeWhenStarted_T26p() public {
        uint256 distributionId = 0;
        uint256 newStartTime = 27;

        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }

    function testCannotUpdateD0EndTimeWhenStarted_T26p() public {
        uint256 distributionId = 0;
        uint256 newEndTime = 27;

        vm.startPrank(operator);
            vm.expectRevert(Errors.CannotEndStakingPowerDistribution.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }

    function testCanUpdateD0EmissionRateWhenStarted_T26p() public {
        uint256 distributionId = 0;
        uint256 newEmissionRate = 2 ether;
        
        // Check state before
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        assertEq(distributionBefore.emissionPerSecond, 1 ether);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionRate);
            pool.updateDistribution(distributionId, 0, 0, newEmissionRate);
        vm.stopPrank();

        // Check state after
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
    }

    function testCannotUpdateD0MultipleFieldsWhenStarted_T26p() public {
        uint256 distributionId = 0;
        uint256 newStartTime = 27;
        uint256 newEndTime = 28;
        uint256 newEmissionRate = 3 ether;

        //1. endTime + emissionRate
        vm.startPrank(operator);
            vm.expectRevert(Errors.CannotEndStakingPowerDistribution.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, newEmissionRate);
        vm.stopPrank(); 
        console.log("endTime + emissionRate");

        //2. startTime + endTime + emissionRate
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, newEndTime, newEmissionRate);
        vm.stopPrank(); 
        console.log("startTime + endTime + emissionRate");

        //3. startTime + emissionRate
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, newEmissionRate);
        vm.stopPrank(); 
        console.log("startTime + emissionRate");
        
        //4. startTime + endTime
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, newEndTime, 0);
        vm.stopPrank(); 
        console.log("startTime + endTime");
    }

        // All possible combinations have been tested:
        // 1. Only startTime - tested in testCannotUpdateD0StartTimeWhenStarted_T26p
        // 2. Only endTime - tested in testCannotUpdateD0EndTimeWhenStarted_T26p
        // 3. Only emissionRate - tested in testCanUpdateD0EmissionRateWhenStarted_T26p
        // 4. startTime + endTime - tested above
        // 5. startTime + emissionRate - tested above
        // 6. endTime + emissionRate - tested above
        // 7. startTime + endTime + emissionRate - tested above

// ------- update distribution: D1 -------

    function testCannotUpdateD1StartTimeWhenStarted_T26p() public {
        uint256 distributionId = 1;
        uint256 newStartTime = 27;

        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }

    // 10 seconds more than original end time | totalRequired increased
    function testCanExtendD1EndTimeWhenStarted_T26p() public {
        uint256 distributionId = 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEndTime = distributionBefore.endTime + 10; 
        
        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeLeft = newEndTime - distributionBefore.lastUpdateTimeStamp;
        uint256 expectedTotalRequired = (timeLeft * distributionBefore.emissionPerSecond) + distributionBefore.totalEmitted;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, newEndTime, distributionBefore.emissionPerSecond);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);
            
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
        
        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify the end time was updated
        assertEq(distributionAfter.endTime, newEndTime);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
        
        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);
        
        // Verify totalRequired was increased
        assertGt(totalRequiredAfter, totalRequiredBefore);
    }

    // 10 seconds less than original end time | totalRequired decreased
    function testCanShortenD1EndTimeWhenStarted_T26p() public {
        uint256 distributionId = 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEndTime = 172820; // 10 seconds less than original end time
        
        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeLeft = newEndTime - distributionBefore.lastUpdateTimeStamp;
        uint256 expectedTotalRequired = (timeLeft * distributionBefore.emissionPerSecond) + distributionBefore.totalEmitted;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, newEndTime, distributionBefore.emissionPerSecond);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);    
            
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);  
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify the end time was updated
        assertEq(distributionAfter.endTime, newEndTime);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
        
        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);

        // Verify totalRequired was decreased
        assertLt(totalRequiredAfter, totalRequiredBefore);
    }

    // emission rate increased | totalRequired increased
    function testCanIncreaseD1EmissionRateWhenStarted_T26p() public {
        uint256 distributionId = 1;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEmissionRate = distributionBefore.emissionPerSecond * 2;
        
        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeDeltaTillNow = block.timestamp - distributionBefore.lastUpdateTimeStamp;
        uint256 totalEmittedTillNow = distributionBefore.totalEmitted + (timeDeltaTillNow * distributionBefore.emissionPerSecond);
        
        uint256 timeLeft = distributionBefore.endTime - block.timestamp;
        uint256 expectedTotalRequired = (timeLeft * newEmissionRate) + totalEmittedTillNow;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionRate);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);
            
            pool.updateDistribution(distributionId, 0, 0, newEmissionRate);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify the emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
        
        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);

        // Verify totalRequired was increased
        assertGt(totalRequiredAfter, totalRequiredBefore);
    }

    // emission rate decreased | totalRequired decreased
    function testCanDecreaseD1EmissionRateWhenStarted_T26p() public {
        uint256 distributionId = 1;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEmissionRate = distributionBefore.emissionPerSecond / 2;
        
        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeDeltaTillNow = block.timestamp - distributionBefore.lastUpdateTimeStamp;
        uint256 totalEmittedTillNow = distributionBefore.totalEmitted + (timeDeltaTillNow * distributionBefore.emissionPerSecond);
        
        uint256 timeLeft = distributionBefore.endTime - block.timestamp;
        uint256 expectedTotalRequired = (timeLeft * newEmissionRate) + totalEmittedTillNow;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionRate);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);
            
            pool.updateDistribution(distributionId, 0, 0, newEmissionRate);
        vm.stopPrank();


        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);

        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify the emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
        
        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);

        // Verify totalRequired was decreased
        assertLt(totalRequiredAfter, totalRequiredBefore);
    }

    function testCanUpdateD1EndTimeAndEmissionRateWhenStarted_T26p() public {
        uint256 distributionId = 1;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEndTime = distributionBefore.endTime + 10;
        uint256 newEmissionRate = distributionBefore.emissionPerSecond + 1 ether;
        
        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeDeltaTillNow = block.timestamp - distributionBefore.lastUpdateTimeStamp;
        uint256 totalEmittedTillNow = distributionBefore.totalEmitted + (timeDeltaTillNow * distributionBefore.emissionPerSecond);
        
        uint256 timeLeft = newEndTime - block.timestamp;
        uint256 expectedTotalRequired = (timeLeft * newEmissionRate) + totalEmittedTillNow;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, newEndTime, newEmissionRate);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);
            
            pool.updateDistribution(distributionId, 0, newEndTime, newEmissionRate);
        vm.stopPrank();

        // Get distribution after update
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);
        
        // Verify the end time and emission rate were updated   
        assertEq(distributionAfter.endTime, newEndTime);
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        
        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
        assertNotEq(totalRequiredBefore, totalRequiredAfter);
    }

    // Any combination of startTime should revert
    function testCannotUpdateD1MultipleFieldsWhenStarted_T26p() public {
        uint256 distributionId = 1;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        // new params
        uint256 newStartTime = distributionBefore.startTime + 10;
        uint256 newEndTime = distributionBefore.endTime + 10;
        uint256 newEmissionRate = distributionBefore.emissionPerSecond + 1 ether;
                
        // 1. startTime + endTime + emissionRate
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, newEndTime, newEmissionRate);
        vm.stopPrank();

        // 2. startTime + endTime
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, newEndTime, 0);
        vm.stopPrank();

        // 3. startTime + emissionRate
        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionStarted.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, newEmissionRate);
        vm.stopPrank();
    }

}

