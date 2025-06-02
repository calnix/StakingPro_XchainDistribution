// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../unit/PoolT21.t.sol";

/** T26
    1. T26: Setup new distribution D2
    2. T31: Check claimable rewards [hotwire distribution updates by entering maintenance mode]
    3. T36: Users claim current rewards
    4. T36: End and Pop all active distributions, DX [cannot switch rewards vault if there are active distributions]
    5. T36: Switch rewards vault
    6. T36: Grant POOL ROLE to some EOA
    7. T36: Setup old distribution D1 [bypassing all checks]
    8. T36: Deposit remainder of rewards for D1
    9. T36: Users claim old distribution remainder [same behaviour expected for D2]
 */

abstract contract StateT26_D2Created is StateT21_CreationNftsUpdated {

    uint256 public distributionId = 2;
    uint256 public distributionStartTime;
    uint256 public distributionEndTime;
    uint256 public emissionPerSecond;
    uint256 public tokenPrecision;
    bytes32 public tokenAddress;
    uint256 public totalRequired;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(26);
        
        // d2 params
        distributionStartTime = block.timestamp;
        distributionEndTime = distributionStartTime + 2 days;
        emissionPerSecond = 1 ether;
        tokenPrecision = 1E18;
        tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken2));

        vm.startPrank(operator);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        totalRequired = (distributionEndTime - distributionStartTime) * emissionPerSecond;

        // mint rewards
        vm.startPrank(depositor);
            rewardsToken2.mint(depositor, totalRequired);
            rewardsToken2.approve(address(rewardsVault), totalRequired);
            rewardsVault.deposit(distributionId, totalRequired, depositor);
        vm.stopPrank();
    }
}

contract StateT26_D2CreatedTest is StateT26_D2Created {

    function test_D2Created() public {

        DataTypes.Distribution memory distribution = getDistribution(2);

        assertEq(distribution.distributionId, 2);
        assertEq(distribution.startTime, block.timestamp);
        assertEq(distribution.endTime, block.timestamp + 2 days);
        assertEq(distribution.emissionPerSecond, 1 ether);
    }   
}

abstract contract StateT31_CheckClaimableRewards is StateT26_D2Created {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(31);

        bytes32[] memory vaultIds = new bytes32[](2);
        vaultIds[0] = vaultId1;

        // update distributions
        vm.startPrank(operator);
            pool.enableMaintenance();
            pool.updateActiveDistributions();
            pool.disableMaintenance();
        vm.stopPrank();
        
        // update vaults
        vm.startPrank(cronJob);
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
            pool.updateAllVaultAccounts(vaultIds, 2);
        vm.stopPrank();
    }
}

contract StateT31_CheckClaimableRewardsTest is StateT31_CheckClaimableRewards {

    // only bother checking user2's rewards
    function test_CheckClaimableRewards_D1_Vault1_User2() public {
        uint256 distributionId = 1;
        bytes32 vaultId = vaultId1;
        
        // get from mapping & helper fn
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        DataTypes.Distribution memory updatedDistribution = pool.getUpdatedDistribution(distributionId);
        assertEq(updatedDistribution.totalEmitted, distribution.totalEmitted);
        assertEq(updatedDistribution.totalEmitted, 10 ether);

        // get from mapping & helper fn 
        (DataTypes.VaultAccount memory vaultAccount, ) = pool.getUpdatedVaultAccount(vaultId, distributionId);
        DataTypes.VaultAccount memory updatedVaultAccount = getVaultAccount(vaultId, distributionId);
        assertApproxEqAbs(vaultAccount.totalAccRewards, 9999999999999999990, 1);
        assertEq(vaultAccount.totalAccRewards, updatedVaultAccount.totalAccRewards);


        // user2's expected rewards | based on staking moca tokens
        uint256 expectedMocaTokenStakingRewards 
            = (vaultAccount.rewardsAccPerUnitStaked * user2Moca) / 1E18;

        // check that user2's vault1 account accrued rewards; > 0
        (DataTypes.UserAccount memory userAccount, , ) = pool.getUpdatedUserAccount(user2, vaultId, distributionId);
        assertEq(userAccount.accStakingRewards, expectedMocaTokenStakingRewards, "userAccount.accStakingRewards does not match expected value");
    }

    function test_CheckClaimableRewards_D2_Vault1_User2() public {
        uint256 distributionId = 2;
        bytes32 vaultId = vaultId1;

        // distribution
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        DataTypes.Distribution memory updatedDistribution = pool.getUpdatedDistribution(distributionId);
        assertEq(updatedDistribution.totalEmitted, distribution.totalEmitted);
        assertEq(updatedDistribution.totalEmitted, 5 ether);

        // vault account
        (DataTypes.VaultAccount memory vaultAccount, ) = pool.getUpdatedVaultAccount(vaultId, distributionId);
        DataTypes.VaultAccount memory updatedVaultAccount = getVaultAccount(vaultId, distributionId);
        assertApproxEqAbs(vaultAccount.totalAccRewards, 4999999999999999890, 10);
        assertEq(vaultAccount.totalAccRewards, updatedVaultAccount.totalAccRewards);


        // user2's expected rewards | based on staking moca tokens
        uint256 expectedMocaTokenStakingRewards 
            = (vaultAccount.rewardsAccPerUnitStaked * user2Moca) / 1E18;

        // check that user2's vault1 account accrued rewards; > 0
        (DataTypes.UserAccount memory userAccount, , ) = pool.getUpdatedUserAccount(user2, vaultId, distributionId);
        assertEq(userAccount.accStakingRewards, expectedMocaTokenStakingRewards, "userAccount.accStakingRewards does not match expected value");
        assertEq(userAccount.accStakingRewards, 2333333333333333200);
    }

    // CANNOT SWITCH REWARDS VAULT: active distributions
    function testCannotSwitchRewardsVault() public {
        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(Errors.ActiveTokenDistributions.selector));
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();
    }
}

// claim, warp, end distributions
abstract contract StateT36_EndAllActiveDistributions is StateT31_CheckClaimableRewards {

    function setUp() public virtual override {
        super.setUp();

        // user claims rewards at T31
        vm.startPrank(user1);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId1, 2);
        vm.stopPrank();
        vm.startPrank(user2);
            pool.claimRewards(vaultId1, 1);
            pool.claimRewards(vaultId1, 2);
        vm.stopPrank();

        // 5 more ticks of emissions -> users have claimable rewards; BUT NOT CLAIMED
        vm.warp(36);

        // 1. grant operator role to operator
        // done in testing harness

        // 2. Operator ends distribution manually
        vm.startPrank(operator);
            pool.endDistributionManually(1);
            pool.endDistributionManually(2);
        vm.stopPrank();

        bytes32[] memory vaultIds = new bytes32[](1);
        vaultIds[0] = vaultId1;

        // 3. CronJob updates vault accounts
        vm.startPrank(cronJob);
            pool.updateAllVaultAccounts(vaultIds, 1);
            pool.updateAllVaultAccounts(vaultIds, 2);
        vm.stopPrank();

        // 4. Operator pops ended distribution
        vm.startPrank(operator);
            pool.popEndedDistribution(1);
            pool.popEndedDistribution(2);
        vm.stopPrank();

        // 5. Operator renounceRole role on self [for ease of testing, ignore this step]
        //vm.startPrank(operator);
        //    pool.renounceRole(Constants.OPERATOR_ROLE, operator);
        //vm.stopPrank();
    }
}

contract StateT36_EndAllActiveDistributionsTest is StateT36_EndAllActiveDistributions {

    function test_EndAllActiveDistributions() public {
        // only D0 active
        assertEq(pool.getActiveDistributionsLength(), 1);
    }
    
    function testCanSwitchRewardsVault() public {
        vm.startPrank(owner);
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();

        assertEq(address(pool.REWARDS_VAULT()), address(rewardsVaultV2));
    }
}

abstract contract StateT36_SwitchRewardsVault is StateT36_EndAllActiveDistributions {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();
    }
}

contract StateT36_SwitchRewardsVaultTest is StateT36_SwitchRewardsVault {

    function test_NewRewardsVaultIsSet() public {
        // check that new rewards vault is set
        assertEq(address(pool.REWARDS_VAULT()), address(rewardsVaultV2));

        // check that old rewards vault is not set
        assertNotEq(address(pool.REWARDS_VAULT()), address(rewardsVault));
    }

    function test_BypassUpdateOfNewRewardsVault_OldDistributions() public {
        // grant POOL ROLE to some other address
        vm.startPrank(owner);
            rewardsVaultV2.grantRole(Constants.POOL_ROLE, deployer);
        vm.stopPrank();

        // CALC. TOTAL REQUIRED
        uint256 distributionId = 1;
        uint256 distributionStartTime = 21;
        uint256 distributionEndTime = 21 + 2 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 2 days * emissionPerSecond;

        // update distribution
        vm.startPrank(deployer);
            rewardsVaultV2.setupDistribution(distributionId, dstEid, tokenAddress, totalRequired);
        vm.stopPrank();

        // deposit remainder of rewards
        uint256 remainder = totalRequired - 10 ether;
        vm.startPrank(depositor);
            rewardsToken1.mint(depositor, remainder);
            rewardsToken1.approve(address(rewardsVaultV2), remainder);
            rewardsVaultV2.deposit(distributionId, remainder, depositor);
        vm.stopPrank();
    }
}


// note: when bypassing to setup old distribution, none of the input checks would be applied
abstract contract StateT36_ClaimOldDistributionRemainder is StateT36_SwitchRewardsVault {
    /**
        We setup the old distribution on the new rewardsVault contract,
        then deposit only the portion of rewards deemed emitted, but not claimed.

        This allows users to claim their rewards under the old distributionId.

        However, we do not use this avenue to have the distribution continue.
        Rather, we setup a new distributionId to distribute the remaining unemitted rewards.
        This is to ensure no edge case issues with totalRequired, etc.

        Hence the complexity of process detailed below.
     */

    function setUp() public virtual override {
        super.setUp();
         
        // users had claimable from T26 - T31
        (,,uint256 totalRequiredAfterEnded,uint256 totalClaimedAfterEnded,) = rewardsVault.distributions(2);
        uint256 emittedButNotClaimed = totalRequiredAfterEnded - totalClaimedAfterEnded;
        // delta of 723 from expectation: 5 ether for 5 seconds 
        assertEq(emittedButNotClaimed, 5 ether + 723);
        
        // future emissions calc based on paper math
        uint256 futureEmissions = rewardsToken2.balanceOf(address(rewardsVault)) - emittedButNotClaimed;

        // 1. pause old rewards vault, then exit tokens. transfer to depositor
        vm.startPrank(owner);
            rewardsVault.pause();
            rewardsVault.exit(address(rewardsToken2));
            //rewardsToken2.transfer(depositor, futureEmissions);
        vm.stopPrank();

        // 2. grant POOL_ROLE to self 
        // 3. setup old distribution on new vault: to allow users to claim emitted rewards [we are not continuing the distribution; only claiming emitted]
        vm.startPrank(owner);
            rewardsVaultV2.grantRole(Constants.POOL_ROLE, owner);

            rewardsVaultV2.setupDistribution(distributionId, dstEid, tokenAddress, emittedButNotClaimed);
        
            rewardsToken2.approve(address(rewardsVaultV2), emittedButNotClaimed);
            rewardsVaultV2.deposit(distributionId, emittedButNotClaimed, owner);

            rewardsVaultV2.revokeRole(Constants.POOL_ROLE, owner);
        vm.stopPrank();

        // 4. create new distribution for remainder of rewards - through stakingPro
        // all params remain the same except, id and startTime - look to distribute emissions only
        uint256 newDistributionId = 3;
        uint256 newDistributionStartTime = block.timestamp;
        vm.startPrank(operator);
            pool.setupDistribution(newDistributionId, newDistributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();

        (,,uint256 newTotalRequired,,) = rewardsVaultV2.distributions(3);
        assertEq(futureEmissions - newTotalRequired, 0);

        // 5. deposit remainder of rewards into new distribution [easier for owner to do this instead of transferring to depositor]
        vm.startPrank(owner);
            rewardsToken2.approve(address(rewardsVaultV2), newTotalRequired);
            rewardsVaultV2.deposit(newDistributionId, newTotalRequired, owner);
        vm.stopPrank();
    }
}

contract StateT36_ClaimOldDistributionRemainderTest is StateT36_ClaimOldDistributionRemainder {
    
    // D1 was not setup on new RewardsVault; users cannot claim previously emitted+unclaimed rewards
    function test_CannotClaimOldDistributionIfNotSetup_D1() public {
        uint256 distributionId = 1;
        bytes32 vaultId = vaultId1;

        // Claim rewards
        vm.startPrank(user2);
            vm.expectRevert(Errors.InsufficientBalance.selector);
            pool.claimRewards(vaultId, distributionId);
        vm.stopPrank();
    }

    function test_CanClaimOldDistributionRemainder_D2() public {
        uint256 distributionId = 2;
        bytes32 vaultId = vaultId1;
        
        // Check initial balances
        uint256 initialBalance = rewardsToken2.balanceOf(user2);
        uint256 initialVaultBalance = rewardsToken2.balanceOf(address(rewardsVaultV2));
        
        // Get user account before claiming
        (DataTypes.UserAccount memory userAccountBefore, , ) = pool.getUpdatedUserAccount(user2, vaultId, distributionId);
        
        // Calculate expected rewards
        uint256 totalAccruedRewards = userAccountBefore.accStakingRewards + userAccountBefore.accNftStakingRewards + userAccountBefore.accRealmPointsRewards; 
        uint256 totalClaimedRewards = userAccountBefore.claimedStakingRewards + userAccountBefore.claimedNftRewards + userAccountBefore.claimedRealmPointsRewards;
        uint256 expectedRewards = totalAccruedRewards - totalClaimedRewards;
        console.log("expectedRewards", expectedRewards);

        // Claim rewards
        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit RewardsClaimed(distributionId, vaultId, user2, expectedRewards);
            
            pool.claimRewards(vaultId, distributionId);
        vm.stopPrank();
        
        // Check balances after claiming
        uint256 finalBalance = rewardsToken2.balanceOf(user2);
        uint256 finalVaultBalance = rewardsToken2.balanceOf(address(rewardsVaultV2));
        
        // check token transfers
        assertEq(finalBalance, initialBalance + expectedRewards, "User balance should increase by claimed rewards");
        assertEq(finalVaultBalance, initialVaultBalance - expectedRewards, "Vault balance should decrease by claimed rewards");
        
        // Get user account after claiming
        DataTypes.UserAccount memory userAccountAfter = getUserAccount(user2, vaultId, distributionId);
        
        // check that claimed rewards are updated
        uint256 totalClaimedRewardsAfter = userAccountAfter.claimedStakingRewards + userAccountAfter.claimedNftRewards + userAccountAfter.claimedRealmPointsRewards;
        assertEq(totalClaimedRewardsAfter, totalClaimedRewards + expectedRewards, "Claimed rewards should be updated");
    }

    function test_CanClaimNewDistribution_D3() public {
        // for emissions to occur
        vm.warp(block.timestamp + 1);

        uint256 distributionId = 3;
        bytes32 vaultId = vaultId1;

        // Check initial balances
        uint256 initialBalance = rewardsToken2.balanceOf(user2);
        uint256 initialVaultBalance = rewardsToken2.balanceOf(address(rewardsVaultV2));

        // Get user account before claiming
        (DataTypes.UserAccount memory userAccountBefore, , ) = pool.getUpdatedUserAccount(user2, vaultId, distributionId);

        // Calculate expected rewards
        uint256 totalAccruedRewards = userAccountBefore.accStakingRewards + userAccountBefore.accNftStakingRewards + userAccountBefore.accRealmPointsRewards; 
        uint256 totalClaimedRewards = userAccountBefore.claimedStakingRewards + userAccountBefore.claimedNftRewards + userAccountBefore.claimedRealmPointsRewards;
        uint256 expectedRewards = totalAccruedRewards - totalClaimedRewards;

        // Claim rewards
        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit RewardsClaimed(distributionId, vaultId, user2, expectedRewards);

            pool.claimRewards(vaultId, distributionId);
        vm.stopPrank();

        // Check balances after claiming
        uint256 finalBalance = rewardsToken2.balanceOf(user2);
        uint256 finalVaultBalance = rewardsToken2.balanceOf(address(rewardsVaultV2));
        
        // check token transfers
        assertEq(finalBalance, initialBalance + expectedRewards, "User balance should increase by claimed rewards");
        assertEq(finalVaultBalance, initialVaultBalance - expectedRewards, "Vault balance should decrease by claimed rewards");

        // Get user account after claiming
        DataTypes.UserAccount memory userAccountAfter = getUserAccount(user2, vaultId, distributionId);
        
        // check that claimed rewards are updated
        uint256 totalClaimedRewardsAfter = userAccountAfter.claimedStakingRewards + userAccountAfter.claimedNftRewards + userAccountAfter.claimedRealmPointsRewards;
        assertEq(totalClaimedRewardsAfter, totalClaimedRewards + expectedRewards, "Claimed rewards should be updated");
    }

    function test_DistributionWasMigratedCorrectly_D2D3() public {
        // Get D2 values from old vault
        (,,uint256 oldD2TotalRequired, uint256 oldD2TotalClaimed, uint256 oldD2TotalDeposited) = rewardsVault.distributions(2);

        // Get D2 and D3 values from new vault
        (,,uint256 newD2TotalRequired, uint256 newD2TotalClaimed, uint256 newD2TotalDeposited) = rewardsVaultV2.distributions(2);
        (,,uint256 newD3TotalRequired, uint256 newD3TotalClaimed, uint256 newD3TotalDeposited) = rewardsVaultV2.distributions(3);
        
        // get total emitted w/ rewards vault v1
        (,,,,,,uint256 poolTotalEmitted,,uint256 manuallyEnded) = pool.distributions(2);
        assertEq(manuallyEnded, 1);

        // 1. pool emitted should match old D2 totalRequired -> this is set to match as per endDistributionManually
        // 2. pool emitted, less what had been claimed on old rewards vault, should be equal to new D2 totalRequired 
        // this ensures new D2 was setup correctly to ONLY emit emitted+unclaimed
        assertEq(poolTotalEmitted, oldD2TotalRequired);
        assertEq(poolTotalEmitted - oldD2TotalClaimed, newD2TotalRequired, "new D2 totalRequired incorrect");

        // get future emissions of old D2: started T26 & ended T36; meant to end T26 + 2Days
        uint256 futureDuration = distributionEndTime - 36;
        uint256 futureEmissions = futureDuration * emissionPerSecond;

        // check D3 setup correctly
        assertEq(newD3TotalRequired, futureEmissions, "D3 should be setup to emit futureEmissions");
    }
}

