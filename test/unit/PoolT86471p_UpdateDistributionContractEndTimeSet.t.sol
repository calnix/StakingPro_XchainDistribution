// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT86466.t.sol";

abstract contract StateT86471_ContractSetEndTime is StateT86466_User2UnstakedFromVault2 {
    function setUp() public virtual override {
        super.setUp();

        // set endTime: 86471
        vm.startPrank(operator);
            pool.setEndTime(86471);
        vm.stopPrank();

    }
}   

contract StateT86471_ContractSetEndTimeTest is StateT86471_ContractSetEndTime {

    // if(newEndTime > endTime) revert Errors.InvalidEndTime();
    function testInvalidEndTimeVersusContractEndTime_T86471p() public {
        uint256 distributionId = 0;
        uint256 newEndTime = pool.endTime() + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }

    // if(newStartTime > endTime) revert Errors.InvalidStartTime();
    function testInvalidStartTimeVersusContractEndTime_T86471p() public {
        uint256 distributionId = 0;
        uint256 newStartTime = pool.endTime() + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidStartTime.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }

// ------- update distribution: D0 -------

    function testCannotUpdateD0EndTimeWithEndTimeSet_T86471p(uint256 newEndTime) public {
        newEndTime = bound(newEndTime, block.timestamp + 1, pool.endTime());

        uint256 distributionId = 0;

        // cannot update D0 endTime with endTime set
        vm.startPrank(operator);
            vm.expectRevert(Errors.CannotEndStakingPowerDistribution.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }

    function testCanUpdateD0EmissionRateWithEndTimeSet_T86471p() public {
        uint256 distributionId = 0;
        uint256 newEmissionRate = 3 ether;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);

        // can update D0 emissionRate with endTime set
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionRate);

            pool.updateDistribution(distributionId, 0, 0, newEmissionRate);
        vm.stopPrank();

        // get distribution after
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);

        // Verify emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        assertNotEq(distributionBefore.emissionPerSecond, distributionAfter.emissionPerSecond);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
    }

    function testCannotUpdateD0MultipleFieldsWithEndTimeSet_T86471p() public {
        uint256 newStartTime = block.timestamp + 1;
        uint256 newEndTime = pool.endTime();
        uint256 newEmissionRate = 3 ether;
        
        uint256 distributionId = 0;

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

// ------- update distribution: D1 -------


    function testCannotExtendD1EndTimeBeyondContractEndTime_T86471p() public {
        uint256 distributionId = 1;
        uint256 newEndTime = pool.endTime() + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }

    function testCanUpdateD1EndTimeWithinContractEndTime_T86471p() public {
        uint256 newEndTime = pool.endTime();
        
        uint256 distributionId = 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        assertNotEq(distributionBefore.endTime, newEndTime);

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

    function testCanUpdateD1EmissionRateWithEndTimeSet_T86471p() public {
        uint256 distributionId = 1;
        
        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        uint256 newEmissionRate = 3 ether;

        // Get the totalRequired before update
        (,, uint256 totalRequiredBefore,,) = rewardsVault.distributions(distributionId);
        
        // Calculate expected total required after update
        uint256 timeDeltaTillNow = block.timestamp - distributionBefore.lastUpdateTimeStamp;
        uint256 totalEmittedTillNow = distributionBefore.totalEmitted + (timeDeltaTillNow * distributionBefore.emissionPerSecond);
        
        uint256 timeLeft = distributionBefore.endTime - block.timestamp;
        uint256 expectedTotalRequired = (timeLeft * newEmissionRate) + totalEmittedTillNow;

        // can update D1 emissionRate with endTime set
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, distributionBefore.endTime, newEmissionRate);
            
            // Also expect the RewardsVault to emit its own event
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, expectedTotalRequired);

            pool.updateDistribution(distributionId, 0, 0, newEmissionRate);
        vm.stopPrank();

        // get distribution after
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Get the totalRequired after update
        (,, uint256 totalRequiredAfter,,) = rewardsVault.distributions(distributionId);

        // Verify emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        assertNotEq(distributionBefore.emissionPerSecond, distributionAfter.emissionPerSecond);

        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);    

        // Verify totalRequired was updated in the RewardsVault
        assertEq(totalRequiredAfter, expectedTotalRequired);
    }

    function testCanUpdateD1ValidEndTimeAndEmissionRate_T86471p() public {
        uint256 newEndTime = pool.endTime() - 1;
        uint256 newEmissionRate = 3 ether;

        uint256 distributionId = 1;

        // Get distribution before update
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);

        // can update D1 endTime and emissionRate
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, distributionBefore.startTime, newEndTime, newEmissionRate);
            pool.updateDistribution(distributionId, 0, newEndTime, newEmissionRate);
        vm.stopPrank();

        // get distribution after
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Verify endTime was updated
        assertEq(distributionAfter.endTime, newEndTime);
        assertNotEq(distributionBefore.endTime, distributionAfter.endTime);

        // Verify emission rate was updated
        assertEq(distributionAfter.emissionPerSecond, newEmissionRate);
        assertNotEq(distributionBefore.emissionPerSecond, distributionAfter.emissionPerSecond);
        
        // Verify other fields remain unchanged
        assertEq(distributionAfter.startTime, distributionBefore.startTime);
    }

       
        

}
