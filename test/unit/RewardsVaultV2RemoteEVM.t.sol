// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT6.t.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";              

abstract contract StateT11_Distribution1CreatedAsRemote_RewardsVaultV2 is StateT6_User2StakeAssetsToVault1 {

    uint32 public dstEidArbitrum = 30110;   // arb mainnet eid
    uint256 public distributionId = 1;
    uint256 public distributionStartTime = 11;
    uint256 public distributionEndTime = 11 + 2 days;
    uint256 public emissionPerSecond = 1 ether;
    uint256 public tokenPrecision = 1E18;
    bytes32 public tokenAddress;
    uint256 public totalRequired = 2 days * emissionPerSecond;  

    function setUp() public virtual override  {
        super.setUp();

        // T11   
        vm.warp(11);

        // set rewards vault   
        vm.startPrank(operator);
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();

        // set peer: dummy evmVault address
        vm.startPrank(owner);            
            rewardsVaultV2.setPeer(dstEidArbitrum, bytes32(uint256(uint160(address(1)))));
        vm.stopPrank();

        // set token address in bytes32 format
        tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));

        // operator sets up distribution
        vm.startPrank(operator);
            // create distribution 1 as remote distribution
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEidArbitrum, tokenAddress
            );
        vm.stopPrank();
    }
}

// d1 is remote
// test that d1 has been setup correctly on rewards vaultV2
contract StateT11_Distribution1CreatedAsRemote_RewardsVaultV2Test is StateT11_Distribution1CreatedAsRemote_RewardsVaultV2 {
    using stdStorage for StdStorage;

    function test_Distribution1CreatedOnRewardsVaultV2() public {

        RewardsVaultV1.Distribution memory d1 = getDistributionFromRewardsVaultV2(1);

        // check that d1 has been setup correctly on rewards vaultV2
        assertEq(d1.dstEid, dstEidArbitrum);
        assertEq(d1.tokenAddress, rewardsVault.addressToBytes32(address(rewardsToken1)));
        assertEq(d1.totalRequired, totalRequired);
    }

    // d1 is remote, so depositor cannot deposit on rewards vaultV2
    function testDepositorCannotDepositOnRewardsVaultV2() public {
        vm.startPrank(depositor);
            vm.expectRevert(abi.encodeWithSelector(Errors.CallDepositOnRemote.selector));
            rewardsVaultV2.deposit(1, 100 ether, depositor);
        vm.stopPrank();
    }

    function testStorageEditOfDeposits() public {
        // check initial totalDeposited
        RewardsVaultV1.Distribution memory d1Before = getDistributionFromRewardsVaultV2(1);
        assertEq(d1Before.totalDeposited, 0);

        // d1.totalDeposited = totalRequired
        stdstore  
            .enable_packed_slots()
            .target(address(rewardsVaultV2))
            .sig("distributions(uint256)")
            .with_key(uint256(1))
            .depth(4)   // 5th slot is totalDeposited
            .checked_write(totalRequired);

        RewardsVaultV1.Distribution memory d1After = getDistributionFromRewardsVaultV2(1);
        assertEq(d1After.totalDeposited, totalRequired);
    }
}


// storage edit: reflect that d1 was deposited on evm vault
abstract contract StateT11_Distribution1DepositedOnEvmVault is StateT11_Distribution1CreatedAsRemote_RewardsVaultV2 {
    using stdStorage for StdStorage;

    function setUp() public virtual override {
        super.setUp();

        // d1.totalDeposited = totalRequired
        stdstore  
            .enable_packed_slots()
            .target(address(rewardsVaultV2))
            .sig("distributions(uint256)")
            .with_key(uint256(1))
            .depth(4)   // 5th slot is totalDeposited
            .checked_write(totalRequired);

        // move forward by 5 seconds: 5e18 emitted
        vm.warp(11 + 5);

    }
}

contract StateT11_Distribution1DepositedOnEvmVaultTest is StateT11_Distribution1DepositedOnEvmVault {

    function test_Distribution1Deposited_RemoteEvm() public {
        RewardsVaultV1.Distribution memory d1 = getDistributionFromRewardsVaultV2(1);
        assertEq(d1.totalDeposited, totalRequired);
    }

    // test user can claim if remote evm token rewards
    function test_User2CanClaimRewards_RemoteEvm() public {
        // check distribution data before
        RewardsVaultV1.Distribution memory d1Before = getDistributionFromRewardsVaultV2(1);
        assertEq(d1Before.totalClaimed, 0);

        // check paidOut before
        assertEq(rewardsVaultV2.paidOut(user2, bytes32(uint256(uint160(user2))), 1), 0);

        // user2 has 0.1 ether
        vm.deal(user2, 0.1 ether);

        vm.startPrank(user2);
            // expect emit
            vm.expectEmit(true, true, true, true);
            emit PayRewards(1, user2, user2, 3166666666666666294);
            pool.claimRewards{value: 0.1 ether}(vaultId1, 1);
        vm.stopPrank();

        // check distribution data after
        RewardsVaultV1.Distribution memory d1After = getDistributionFromRewardsVaultV2(1);
        assertEq(d1After.totalClaimed, 3166666666666666294);

        // check paidOut after
        assertEq(rewardsVaultV2.paidOut(user2, bytes32(uint256(uint160(user2))), 1), 3166666666666666294);
    }
}



/**


    TEST : payRewards()
    - evm
    - local
    - solana

 */

