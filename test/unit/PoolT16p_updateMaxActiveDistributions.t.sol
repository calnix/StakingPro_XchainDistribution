// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT11.t.sol";

abstract contract StateT16p_UpdateActiveDistributions is StateT11_Distribution1Created {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(16);
   
        vm.startPrank(operator);
            pool.updateMaxActiveDistributions(pool.getActiveDistributionsLength() + 1);
        vm.stopPrank();
    }
}

contract StateT16p_UpdateActiveDistributions_Test is StateT16p_UpdateActiveDistributions {

    function testCannotSetupDistributionBeyondMaxAllowed() public {
        vm.startPrank(operator);
            // distribution params
            uint256 distributionId = 2;
            uint256 distributionStartTime = 21;
            uint256 distributionEndTime = 21 + 2 days;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken2));

            // create distribution 2
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );

            // attempt to create distribution 3 - should revert
            distributionId = 3;
            tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken3));

            vm.expectRevert(abi.encodeWithSelector(Errors.MaxActiveDistributions.selector));
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );

        vm.stopPrank();
    }

    function testCanSetupDistributionWithinNewMax() public {
        vm.startPrank(operator);
            // distribution params
            uint256 distributionId = 2;
            uint256 distributionStartTime = 21;
            uint256 distributionEndTime = 21 + 2 days;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken2));

            // create distribution 2
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );
            
        vm.stopPrank();
    }
}
