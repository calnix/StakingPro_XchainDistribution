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

    function testCanRepeatSetEndTimeBeforeContractEnded() public {
        // Get initial end time
        uint256 initialEndTime = pool.endTime();
        uint256 newEndTime = block.timestamp + 1000;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit StakingEndTimeSet(newEndTime);
            pool.setEndTime(newEndTime); 
        vm.stopPrank();
        
        // Check end time was updated
        assertEq(pool.endTime(), newEndTime);
        assertNotEq(initialEndTime, pool.endTime());
    }

    function testCannotSetEndTimeInPast() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.setEndTime(block.timestamp - 1);
        vm.stopPrank();
    }

    // endTime < startTime
    function testCannotSetupDistributionWithStartTimeExceedingEndTime_T86471() public {
        // distribution params  
        uint256 distributionId = 2;
        uint256 distributionStartTime = pool.endTime(); // 
        uint256 distributionEndTime = pool.endTime() - 1;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionEndTime.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testCannotSetupDistributionWithEndTimeExceedingContractEndTime_T86471() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = pool.endTime() + 2;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testCannotUpdateDistributionWithEndTimeExceedingContractEndTime_T86471() public {
        uint256 distributionId = 1;

        // get distribution
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        // new endTime
        uint256 newEndTime = pool.endTime() + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidEndTime.selector);
            pool.updateDistribution(distributionId, 0, newEndTime, 0);
        vm.stopPrank();
    }

    function testCannotUpdateDistributionWithStartTimeExceedingContractEndTime_T86471() public {
        uint256 distributionId = 1;

        // get distribution
        DataTypes.Distribution memory distribution = getDistribution(distributionId);

        // new startTime
        uint256 newStartTime = pool.endTime() + 1;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidStartTime.selector);
            pool.updateDistribution(distributionId, newStartTime, 0, 0);
        vm.stopPrank();
    }
    
}