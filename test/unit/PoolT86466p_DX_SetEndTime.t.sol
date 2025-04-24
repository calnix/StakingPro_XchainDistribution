// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT86466.t.sol";

/**

Contract will end at 86471

    D0 has not endTime unless set by setEndTime
    D1 ends after contract endTime was set      | 172821 (> 86471)
    D2 ends before contract endTime was set     | 86470  (< 86471)
    D3 ended but not popped; before contract endTime was set
    
    what about D created after contract endTime was set?
*/

abstract contract StateT86466_SetupD2D4 is StateT86466_User2UnstakedFromVault2 {

    uint256 public contractEndTime = 86471;

    function setUp() public virtual override {
        super.setUp();

        // create D2
        uint256 distributionId = 2;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = contractEndTime - 1;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        
        vm.startPrank(operator);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        // create D3    
        distributionId = 3;
        distributionStartTime = block.timestamp;
        distributionEndTime = contractEndTime + 100;
        emissionPerSecond = 1 ether;
        tokenPrecision = 1E18;
        tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));

        vm.startPrank(operator);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        // end D3
        vm.startPrank(operator);
            pool.endDistribution(3);
        vm.stopPrank();
    }
}

contract StateT86466_SetupD2D4_Test is StateT86466_SetupD2D4 {

    function test_D0_HasNoEndTime() public {
        // get D0
        DataTypes.Distribution memory distribution = getDistribution(0);

        // D0 endTime is 0
        assertEq(distribution.endTime, 0);
        assertEq(distribution.manuallyEnded, 0);
    }

    function test_D1_EndTimeAfterContractEndTime() public {
        // get D1
        DataTypes.Distribution memory distribution = getDistribution(1);

        // D1 endTime is 172821
        assertEq(distribution.endTime, 172821);
        assertGt(distribution.endTime, contractEndTime);

        assertEq(distribution.manuallyEnded, 0);
    }

    function test_D2_EndTimeBeforeContractEndTime() public {
        // get D2
        DataTypes.Distribution memory distribution = getDistribution(2);

        // D2 ends at 86470 (< 86471)
        assertLt(distribution.endTime, contractEndTime);
        assertEq(distribution.endTime, contractEndTime - 1);
        
        assertEq(distribution.manuallyEnded, 0);
    }

    function test_D3_EndedButNotPopped() public {
        // get D3
        DataTypes.Distribution memory distribution = getDistribution(3);

        // Assert D3 was ended but not popped
        assertEq(distribution.manuallyEnded, 1, "D3 should be marked as manually ended");
        assertEq(pool.getActiveDistributionsLength(), 4, "4 Ele in activeDistributions: D0,D1,D2,D3");

        // check if D3 is in activeDistributions
        uint256 numActiveDistributions = pool.getActiveDistributionsLength();
        bool foundD3 = false;
        
            // Cycle through activeDistributions array to find D3
            for (uint256 i; i < numActiveDistributions; ++i) {
                uint256 distributionId = pool.activeDistributions(i);
                if (distributionId == 3) {
                    foundD3 = true;
                    break;
                }
            }
        
        // Assert D3 is found in the activeDistributions array
        assertTrue(foundD3, "D3 should be in the activeDistributions array");
    }
}


abstract contract StateT86466_SetEndTime is StateT86466_SetupD2D4 {

    function setUp() public virtual override {
        super.setUp();

    
        // set endTime
        vm.startPrank(operator);
            pool.setEndTime(contractEndTime);
        vm.stopPrank();    
    }
}   

contract StateT86466_SetEndTime_Test is StateT86466_SetEndTime {

    function test_D0_ContractEndTimeSet() public {
        // get D0
        DataTypes.Distribution memory distribution = getDistribution(0);

        // D0 endTime is 0
        assertEq(distribution.endTime, contractEndTime);
    }

    function test_D1_ContractEndTimeSet() public {
        // get D1
        DataTypes.Distribution memory distribution = getDistribution(1);

        // D1 endTime is 172821
        assertEq(distribution.endTime, contractEndTime);
    }

    function test_D2_ContractEndTimeSet() public {
        // get D2
        DataTypes.Distribution memory distribution = getDistribution(2);

        // D2 endTime is 86470
        assertEq(distribution.endTime, contractEndTime - 1);
    }

    function test_D3_ContractEndTimeSet() public {
        // get D3
        DataTypes.Distribution memory distribution = getDistribution(3);

        // D3 endTime is 86466
        assertEq(distribution.endTime, 86466);
        assertLt(distribution.endTime, contractEndTime);

    }
}

