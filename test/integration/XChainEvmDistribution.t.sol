// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../unit/PoolT6.t.sol";
import "./../../src/EvmVault.sol";

abstract contract StateT6Extension_OnHomeChain_SwitchToRewardsVaultV2 is StateT6_User2StakeAssetsToVault1 {

    uint32 public remoteDstEid;

    function setUp() public virtual override {
        super.setUp();

        remoteDstEid = dstEid + 1; 

        // switch to rewardsVaultV2 + setPeers
        vm.startPrank(owner);
            pool.setRewardsVault(address(rewardsVaultV2));
            rewardsVaultV2.setPeer(remoteDstEid, rewardsVaultV2.addressToBytes32(address(lzMock)));
        vm.stopPrank();
    }
}

abstract contract StateT6Extension_OnDstChain_DeployEvmVault is StateT6Extension_OnHomeChain_SwitchToRewardsVaultV2 {

    EVMVault public evmVault;

    function setUp() public virtual override {
        super.setUp();

        // deploy EVM vault on dstChain 
        evmVault = new EVMVault(address(lzMock), owner, monitor, depositor);
    }
}

abstract contract StateT11_OnHomeChain_CreateD1AsRemoteDistribution is StateT6Extension_OnDstChain_DeployEvmVault {

    // distribution params
    uint256 public distributionId;
    uint256 public distributionStartTime;
    uint256 public distributionEndTime;
    uint256 public emissionPerSecond;
    uint256 public tokenPrecision;
    bytes32 public tokenAddress;
    uint256 public totalRequired;

    function setUp() public virtual override {
        super.setUp();

        // T11   
        vm.warp(11);

        // distribution params
        distributionId = 1;
        distributionStartTime = block.timestamp;
        distributionEndTime = distributionStartTime + 2 days;
        emissionPerSecond = 1 ether;
        tokenPrecision = 1E18;
        tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken3));
        totalRequired = 2 days * emissionPerSecond;

        // operator sets up distribution
        vm.startPrank(operator);

            // create distribution 1
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                remoteDstEid, tokenAddress
            );
        vm.stopPrank();
    }
}


contract StateT11_OnHomeChain_CreateD1AsRemoteDistributionTest is StateT11_OnHomeChain_CreateD1AsRemoteDistribution {

    function test_D1AsRemoteDistribution() public {

        // check distribution is created on pool
        (
            uint256 distributionId_OnPool, 
            uint256 TOKEN_PRECISION_OnPool,
            uint256 endTime_OnPool,
            uint256 startTime_OnPool, 
            uint256 emissionPerSecond_OnPool, 
            uint256 index_OnPool, 
            uint256 totalEmitted_OnPool, 
            uint256 lastUpdateTimeStamp_OnPool, 
            uint256 manuallyEnded_OnPool
        ) = pool.distributions(1);

        assertEq(distributionId_OnPool, distributionId);
        assertEq(TOKEN_PRECISION_OnPool, tokenPrecision);
        assertEq(endTime_OnPool, distributionEndTime);
        assertEq(startTime_OnPool, distributionStartTime);
        assertEq(emissionPerSecond_OnPool, emissionPerSecond);
        assertEq(index_OnPool, 0);
        assertEq(totalEmitted_OnPool, 0);
        assertEq(lastUpdateTimeStamp_OnPool, distributionStartTime);
        assertEq(manuallyEnded_OnPool, 0);

        // check distribution is created on rewardsVaultV2
        (
            uint32 dstEid_OnRV, 
            bytes32 tokenAddress_OnRV, 
            uint256 totalRequired_OnRV, 
            uint256 totalClaimed_OnRV, 
            uint256 totalDeposited_OnRV
        ) = rewardsVaultV2.distributions(1);

        assertEq(dstEid_OnRV, remoteDstEid);
        assertEq(tokenAddress_OnRV, tokenAddress);
        assertEq(totalRequired_OnRV, totalRequired);
        assertEq(totalClaimed_OnRV, 0); 
        assertEq(totalDeposited_OnRV, 0);
    }
}

abstract contract StateT11_OnDstChain_DepositRewardsToEvmVault is StateT11_OnHomeChain_CreateD1AsRemoteDistribution {

    function setUp() public virtual override {
        super.setUp();

        // deposit rewards to evm vault
        // only deposit half of the total required
        vm.startPrank(depositor);
            rewardsToken3.mint(depositor, totalRequired);
            rewardsToken3.approve(address(evmVault), totalRequired);
            evmVault.deposit(address(rewardsToken3), totalRequired/2, depositor, distributionId);
        vm.stopPrank();        
    }
}

contract StateT11_OnDstChain_DepositRewardsToEvmVaultTest is StateT11_OnDstChain_DepositRewardsToEvmVault {

    function test_DepositRewardsToEvmVault_DstChain() public {

        // check evm vault has deposits 

        (uint256 totalDeposited, uint256 totalPaidOut, uint256 totalUnclaimable) = evmVault.tokens(address(rewardsToken3));

        assertEq(totalDeposited, totalRequired/2);
        assertEq(totalPaidOut, 0);
        assertEq(totalUnclaimable, 0);
    }

    function test_UserCannotClaimXchainRewards_RewardsNotYetDeposited() public {

        vm.warp(distributionStartTime + 5);

        uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, distributionId);
        assertGt(claimableRewards, 0);

        // check user cannot claim rewards
        vm.startPrank(user1);
            vm.expectRevert(Errors.InsufficientBalance.selector);
            pool.claimRewards(vaultId1, distributionId);
        vm.stopPrank();
    }
}

abstract contract StateT11_OnDstChain_UpdateRemoteBalance is StateT11_OnDstChain_DepositRewardsToEvmVault {

    function setUp() public virtual override {
        super.setUp();

        // on home: isDeposit = 1
        vm.startPrank(depositor);
            rewardsVaultV2.updateRemoteBalance(distributionId, totalRequired/2, 1);
        vm.stopPrank();
    }
}

//note: users should be call claimRewards() now that updateRemoteBalance() has been used to update the available balance
contract StateT11_OnDstChain_UpdateRemoteBalanceTest is StateT11_OnDstChain_UpdateRemoteBalance {

    // checks that rewards are claimable after updateRemoteBalance() has been called - home chain
    function test_UserCanClaimXchainRewards_RewardsDeposited() public {
        // set user1 balance to 0.1 ether
        vm.deal(user1, 0.1 ether);
        
        // allow for 5 ticks of emission
        vm.warp(distributionStartTime + 5);

        // Get balances before claim
        (
            , 
            , 
            uint256 totalRequiredBefore, 
            uint256 totalClaimedBefore, 
            uint256 totalDepositedBefore
        ) = rewardsVaultV2.distributions(1);

        uint256 paidOutBefore = rewardsVaultV2.paidOut(user1, rewardsVaultV2.addressToBytes32(user1), distributionId);
        
        // Calculate expected claimable rewards
        uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, distributionId);
        assertGt(claimableRewards, 0, "Should have claimable rewards");

        // Claim rewards
        vm.startPrank(user1);
            vm.expectEmit(true, true, true, true);
            emit RewardsClaimed(distributionId, vaultId1, user1, claimableRewards);
            pool.claimRewards{value: 0.1 ether}(vaultId1, distributionId);
        vm.stopPrank();

        // Get balances after claim
        (
            , 
            , 
            uint256 totalRequiredAfter, 
            uint256 totalClaimedAfter, 
            uint256 totalDepositedAfter
        ) = rewardsVaultV2.distributions(1);
        
        uint256 paidOutAfter = rewardsVaultV2.paidOut(user1, rewardsVaultV2.addressToBytes32(user1), distributionId);

        // check rewardsVaultV2.distributions
        assertEq(totalRequiredAfter, totalRequiredBefore);
        assertEq(totalClaimedAfter, totalClaimedBefore + claimableRewards);
        assertEq(totalDepositedAfter, totalDepositedBefore);

        // check rewardsVaultV2.paidOut
        assertEq(paidOutAfter, paidOutBefore + claimableRewards);
    }
}