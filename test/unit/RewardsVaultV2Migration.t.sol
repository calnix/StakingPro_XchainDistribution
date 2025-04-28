// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT21.t.sol";

/** T26
    - D1 started at T21
    - create D2 at T26
 */

abstract contract StateT26_D2Created is StateT21_CreationNftsUpdated {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(26);

        // create D2
        uint256 distributionId = 2;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = distributionStartTime + 2 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken2));

        vm.startPrank(operator);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
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
        
        // update distributions and vaults
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
    }

    // CANNOT SWITCH REWARDS VAULT: active distributions
    function testCannotSwitchRewardsVault() public {
        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(Errors.ActiveTokenDistributions.selector));
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();
    }
}

abstract contract StateT31_EndAllActiveDistributions is StateT31_CheckClaimableRewards {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(operator);
            pool.endDistributionManually(1);
            pool.endDistributionManually(2);
            pool.popEndedDistribution(1);
            pool.popEndedDistribution(2);
        vm.stopPrank();
    }
}

contract StateT31_EndAllActiveDistributionsTest is StateT31_EndAllActiveDistributions {

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

abstract contract StateT31_SwitchRewardsVault is StateT31_EndAllActiveDistributions {

    //address oldRewardsVault = address(pool.REWARDS_VAULT());

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);
            pool.setRewardsVault(address(rewardsVaultV2));
        vm.stopPrank();
    }
}

contract StateT31_SwitchRewardsVaultTest is StateT31_SwitchRewardsVault {

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

abstract contract StateT31_ClaimOldDistributionRemainder is StateT31_SwitchRewardsVault {

    function setUp() public virtual override {
        super.setUp();

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

contract StateT31_ClaimOldDistributionRemainderTest is StateT31_ClaimOldDistributionRemainder {

    function test_ClaimOldDistributionRemainder() public {
        uint256 distributionId = 1;
        
        // Check initial balances
        uint256 initialBalance = rewardsToken1.balanceOf(user2);
        uint256 initialVaultBalance = rewardsToken1.balanceOf(address(rewardsVaultV2));
        
        // Get user account before claiming
        DataTypes.UserAccount memory userAccountBefore = getUserAccount(user2, vaultId1, distributionId);
        
        // Calculate expected rewards
        uint256 expectedRewards = 6333333333333332596; // This should be calculated based on actual accrued rewards
        
        // Claim rewards
        vm.startPrank(user2);
            vm.expectEmit(true, true, true, true);
            emit RewardsClaimed(distributionId, vaultId1, user2, expectedRewards);
            
            pool.claimRewards(vaultId1, distributionId);
        vm.stopPrank();
        
        // Check balances after claiming
        uint256 finalBalance = rewardsToken1.balanceOf(user2);
        uint256 finalVaultBalance = rewardsToken1.balanceOf(address(rewardsVaultV2));
        
        // Get user account after claiming
        DataTypes.UserAccount memory userAccountAfter = getUserAccount(user2, vaultId1, distributionId);
        
        // Verify rewards were claimed correctly
        assertEq(finalBalance, initialBalance + expectedRewards, "User balance should increase by claimed rewards");
        assertEq(finalVaultBalance, initialVaultBalance - expectedRewards, "Vault balance should decrease by claimed rewards");
        assertEq(userAccountAfter.claimedStakingRewards, userAccountBefore.claimedStakingRewards + expectedRewards, "Claimed rewards should be updated");
    }
}

