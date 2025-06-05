// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "../unit/PoolT6.t.sol";
import "../mocks/ERC20VariableDecimal.sol";

/**
    D1 will serve as a placeholder for the distribution that will be created.
    - token precision set to 1E30
    - modify the token precision accordingly
 */
abstract contract StateT11_SimulatedBoostedBalances is StateT6_User2StakeAssetsToVault1 {
    using stdStorage for StdStorage;

    // sample values: boosted balances
    uint256 public totalBoostedStakedTokens = 1337 ether;

    function setUp() public virtual override {
        super.setUp();

        // update storage for totalBoostedStakedTokens
        stdstore
            .target(address(pool))
            .sig(pool.totalBoostedStakedTokens.selector)
            .checked_write(totalBoostedStakedTokens);
        
        // create vault - if needed
        vm.startPrank(user3);
            pool.createVault(user3NftsArray, 100, 100, 100);
        vm.stopPrank();

        // do the necessary staking for simulation

    }
}

contract StateT11_SimulatedBoostedBalancesTest is StateT11_SimulatedBoostedBalances {

    function test_Recreate() public {
        assertEq(pool.totalBoostedStakedTokens(), totalBoostedStakedTokens);
    }
}


abstract contract StateT11_DistributionXCreated is StateT11_SimulatedBoostedBalances {

    ERC20VariableDecimal public variableDecimalsToken;
    uint8 public decimals = 30;
    
    uint256 public distributionId = 1;
    uint256 public distributionStartTime;
    uint256 public distributionEndTime;
    uint256 public emissionPerSecond;
    uint256 public tokenPrecision = 10**decimals;
    bytes32 public tokenAddress;
    uint256 public totalRequired;

    function setUp() public virtual override {
        super.setUp();

        // T11   
        vm.warp(11);

        // create token with 30 decimals
        variableDecimalsToken = new ERC20VariableDecimal("Variable Decimals Token", "VDT", decimals);

        // d1 params
        distributionStartTime = block.timestamp;
        distributionEndTime = distributionStartTime + 2 days;
        emissionPerSecond = 1 ether;
        tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken2));

        // operator sets up distribution
        vm.startPrank(operator);

            // create distribution 1
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );
        vm.stopPrank();

       
        // depositor mints, approves, deposits
        vm.startPrank(depositor);
            rewardsToken1.mint(depositor, totalRequired);
            rewardsToken1.approve(address(rewardsVault), totalRequired);
            rewardsVault.deposit(distributionId, totalRequired, depositor);
        vm.stopPrank();
    }
}

