// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT6.t.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";              

abstract contract StateT11_Distribution1CreatedAsLocal_RewardsVaultV2 is StateT6_User2StakeAssetsToVault1 {

    uint32 public dstEidLocal = 30184;   // base mainnet eid
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
            rewardsVaultV2.setPeer(dstEidLocal, bytes32(uint256(uint160(address(1)))));
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
                dstEidLocal, tokenAddress
            );
        vm.stopPrank();
    }
}

// d1 is local
// test that d1 has been setup correctly on rewards vaultV2
contract StateT11_Distribution1CreatedAsLocal_RewardsVaultV2Test is StateT11_Distribution1CreatedAsLocal_RewardsVaultV2 {
    using stdStorage for StdStorage;

    function test_Distribution1CreatedOnRewardsVaultV2() public {

        RewardsVaultV1.Distribution memory d1 = getDistributionFromRewardsVaultV2(1);

        // check that d1 has been setup correctly on rewards vaultV2
        assertEq(d1.dstEid, dstEidLocal);
        assertEq(d1.tokenAddress, rewardsVault.addressToBytes32(address(rewardsToken1)));
        assertEq(d1.totalRequired, totalRequired);
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
abstract contract StateT11_Distribution1DepositedOnLocalVault is StateT11_Distribution1CreatedAsLocal_RewardsVaultV2 {
    using stdStorage for StdStorage;

    function setUp() public virtual override {
        super.setUp();

        // deposit
        vm.startPrank(depositor);
            rewardsToken1.mint(depositor, totalRequired);
            rewardsToken1.approve(address(rewardsVaultV2), totalRequired);
            rewardsVaultV2.deposit(1, totalRequired, depositor);
        vm.stopPrank();

        // move forward by 5 seconds: 5e18 emitted
        vm.warp(11 + 5);
    }
}

contract StateT11_Distribution1DepositedOnLocalVaultTest is StateT11_Distribution1DepositedOnLocalVault {

    function test_Distribution1Deposited_Local() public {
        RewardsVaultV1.Distribution memory d1 = getDistributionFromRewardsVaultV2(1);
        assertEq(d1.totalDeposited, totalRequired);
    }

    function test_PayRewardsRevertsOnMsgValue() public {
        // user2 has 0.1 ether
        vm.deal(user2, 0.1 ether);

        vm.startPrank(user2);
            vm.expectRevert(Errors.PayableBlocked.selector);
            pool.claimRewards{value: 0.1 ether}(vaultId1, 1);
        vm.stopPrank();
    }

    // test user can claim if remote evm token rewards
    function test_User2CanClaimRewards_Local() public {
        // check distribution data before
        RewardsVaultV1.Distribution memory d1Before = getDistributionFromRewardsVaultV2(1);
        assertEq(d1Before.totalClaimed, 0);
        // check paidOut before
        assertEq(rewardsVaultV2.paidOut(user2, bytes32(uint256(uint160(user2))), 1), 0);

        // check token balance before
        uint256 balanceBefore = rewardsToken1.balanceOf(user2);

        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit PayRewards(1, user2, user2, 3166666666666666294);
            vm.expectCall(
                address(rewardsToken1),
                abi.encodeCall(IERC20.transfer, (user2, 3166666666666666294))
            );
            pool.claimRewards(vaultId1, 1);
        vm.stopPrank();

        // check distribution data after
        RewardsVaultV1.Distribution memory d1After = getDistributionFromRewardsVaultV2(1);
        assertEq(d1After.totalClaimed, 3166666666666666294);
        // check paidOut after
        assertEq(rewardsVaultV2.paidOut(user2, bytes32(uint256(uint160(user2))), 1), 3166666666666666294);

        // check token balance after
        uint256 balanceAfter = rewardsToken1.balanceOf(user2);
        assertEq(balanceAfter - balanceBefore, 3166666666666666294);
    }
}
