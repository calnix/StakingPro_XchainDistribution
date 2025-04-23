// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import "../utils/TestingHarness.sol";


abstract contract StateT0_Deploy is TestingHarness {    

    function setUp() public virtual override {
        super.setUp();
    }
}

contract StateT0_DeployTest is StateT0_Deploy {

    function testConstructor() public {
        assertEq(address(pool.NFT_REGISTRY()), address(nftRegistry));
        assertEq(address(pool.STAKED_TOKEN()), address(mocaToken));

        assertEq(pool.startTime(), startTime);

        assertEq(pool.NFT_MULTIPLIER(), nftMultiplier);
        assertEq(pool.CREATION_NFTS_REQUIRED(), creationNftsRequired);
        assertEq(pool.MINIMUM_REALMPOINTS_REQUIRED(), 250 ether);
        assertEq(pool.VAULT_COOLDOWN_DURATION(), vaultCoolDownDuration);
        assertEq(pool.STORED_SIGNER(), storedSigner);

        // CHECK ROLES
        assertEq(pool.hasRole(pool.DEFAULT_ADMIN_ROLE(), owner), true);
        assertEq(pool.hasRole(Constants.OPERATOR_ROLE, owner), true);
        assertEq(pool.hasRole(Constants.MONITOR_ROLE, owner), true);

        assertEq(pool.hasRole(Constants.MONITOR_ROLE, monitor), true);
        assertEq(pool.hasRole(Constants.OPERATOR_ROLE, operator), true);
    }
    
// ------ user fns ------

    function testCannotCreateVaultWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);

        uint256 nftFeeFactor = 1000;
        uint256 creatorFeeFactor = 1000;
        uint256 realmPointsFeeFactor = 1000;
        pool.createVault(user1NftsArray, creatorFeeFactor, nftFeeFactor, realmPointsFeeFactor);
    }

    function testCannotStakeTokensWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.stakeTokens(bytes32(uint256(1)), 1000);
    }

    function testCannotStakeNftsWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.stakeNfts(bytes32(uint256(1)), user1NftsArray);
    }
    
    function testCannotStakeRpWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.stakeRealmPoints(bytes32(uint256(1)), 1000, block.timestamp + 1, bytes(""));
    }

    function testCannotMigrateRpWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.migrateRealmPoints(bytes32(uint256(1)), bytes32(uint256(2)), 1000);
    }

    function testCannotUnstakeWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.unstake(bytes32(uint256(1)), 1000, new uint256[](0));
    }

    function testCannotClaimRewardsWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.claimRewards(bytes32(uint256(1)), 0);
    }

    function testCannotUpdateVaultFeesWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.updateVaultFees(bytes32(uint256(1)), 1000, 1000, 1000);
    }

    function testCannotActivateCooldownWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.activateCooldown(bytes32(uint256(1)));
    }

    function testCannotEndVaultWhenNotStarted() public {
        vm.prank(user1);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.endVaults(new bytes32[](1));
    }

    function testUserCannotSetRewardsVault() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.setRewardsVault(address(123));
        vm.stopPrank();
    }

// ------ operator fns ------

    function testCannotStakeOnBehalfWhenNotStarted() public {
        vm.prank(operator);

        vm.expectRevert(Errors.NotStarted.selector);
        pool.stakeOnBehalfOf(new bytes32[](1), new address[](1), new uint256[](1));
    }

    function testCanSetEndTimeWhenNotStarted() public {
        // Check initial end time
        assertEq(pool.endTime(), 0);
        
        uint256 newEndTime = block.timestamp + 1;
        
        vm.prank(operator);
        pool.setEndTime(newEndTime);
        
        // Check end time was updated
        assertEq(pool.endTime(), newEndTime);
    }
    
    function testCannotSetZeroAddressAsRewardsVault() public {
        vm.prank(operator);
        vm.expectRevert(Errors.InvalidAddress.selector);
        pool.setRewardsVault(address(0));
    }

    function testCanSetRewardsVaultWhenNotStarted() public {
        // Check initial rewards vault
        address initialRewardsVault = address(pool.REWARDS_VAULT());
        address newRewardsVault = address(123);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit RewardsVaultSet(initialRewardsVault, newRewardsVault);

            pool.setRewardsVault(newRewardsVault);
        vm.stopPrank();
        
        // Check rewards vault was updated
        address updatedRewardsVault = address(pool.REWARDS_VAULT());
        assertEq(updatedRewardsVault, newRewardsVault);
        assertNotEq(initialRewardsVault, updatedRewardsVault);
    }

    function testCanUpdateMaxActiveDistributionsWhenNotStarted() public {
        // Check initial value
        uint256 initialMaxActive = pool.MAX_ACTIVE_DISTRIBUTIONS();
        uint256 newMaxActive = 1;
        assertNotEq(initialMaxActive, newMaxActive);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaximumActiveDistributionsUpdated(newMaxActive);
            
            pool.updateMaxActiveDistributions(newMaxActive);
        vm.stopPrank();
        
        // Check value was updated
        uint256 updatedMaxActive = pool.MAX_ACTIVE_DISTRIBUTIONS();
        assertEq(updatedMaxActive, newMaxActive);
    }

    function testCanUpdateMaximumFeeFactorWhenNotStarted() public {
        // Check initial value
        uint256 initialMaxFeeFactor = pool.MAXIMUM_FEE_FACTOR();
        uint256 newMaxFeeFactor = 1000;
        assertNotEq(initialMaxFeeFactor, newMaxFeeFactor);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaximumFeeFactorUpdated(initialMaxFeeFactor, newMaxFeeFactor);
            pool.updateMaximumFeeFactor(newMaxFeeFactor);
        vm.stopPrank();

        // Check value was updated
        uint256 updatedMaxFeeFactor = pool.MAXIMUM_FEE_FACTOR();
        assertEq(updatedMaxFeeFactor, newMaxFeeFactor);
        assertNotEq(initialMaxFeeFactor, updatedMaxFeeFactor);
    }

    function testCanUpdateMinimumRealmPointsWhenNotStarted() public {
        uint256 initialMinRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
        uint256 newMinRealmPoints = initialMinRealmPoints + 1;
        assertNotEq(initialMinRealmPoints, newMinRealmPoints);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MinimumRealmPointsUpdated(initialMinRealmPoints, newMinRealmPoints);
            pool.updateMinimumRealmPoints(newMinRealmPoints);
        vm.stopPrank();

        assertEq(pool.MINIMUM_REALMPOINTS_REQUIRED(), newMinRealmPoints);
        assertNotEq(initialMinRealmPoints, pool.MINIMUM_REALMPOINTS_REQUIRED());
    }

    function testCanUpdateCreationNftsWhenNotStarted() public {
        uint256 initialCreationNfts = pool.CREATION_NFTS_REQUIRED();
        uint256 newCreationNfts = initialCreationNfts + 1;
        assertNotEq(initialCreationNfts, newCreationNfts);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit CreationNftRequiredUpdated(initialCreationNfts, newCreationNfts);
            pool.updateCreationNfts(newCreationNfts);
        vm.stopPrank();

        assertEq(pool.CREATION_NFTS_REQUIRED(), newCreationNfts);
    }

    function testCanUpdateVaultCooldownWhenNotStarted() public {
        uint256 initialVaultCooldown = pool.VAULT_COOLDOWN_DURATION();
        uint256 newVaultCooldown = initialVaultCooldown + 1;
        assertNotEq(initialVaultCooldown, newVaultCooldown);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit VaultCooldownDurationUpdated(initialVaultCooldown, newVaultCooldown);
            pool.updateVaultCooldown(newVaultCooldown);
        vm.stopPrank();

        assertEq(pool.VAULT_COOLDOWN_DURATION(), newVaultCooldown);
    }

    function testCanEnableMaintenanceWhenNotStarted() public {
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaintenanceEnabled(block.timestamp);

            pool.enableMaintenance();
        vm.stopPrank();

        assertEq(pool.isUnderMaintenance(), 1);
    }

    function testCanDisableMaintenanceWhenNotStarted() public {

        vm.startPrank(operator);
            pool.enableMaintenance();
        vm.stopPrank();

        assertEq(pool.isUnderMaintenance(), 1);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaintenanceDisabled(block.timestamp);

            pool.disableMaintenance();
        vm.stopPrank();

        assertEq(pool.isUnderMaintenance(), 0);
    }

    function testCanUpdateActiveDistributionsWhenNotStarted() public {
        vm.startPrank(operator);
            pool.enableMaintenance();
            pool.updateActiveDistributions();
        vm.stopPrank();
    }

    function testCanUpdateAllVaultAccountsWhenNotStarted() public {
        bytes32[] memory vaultIds = new bytes32[](1);
        uint256 distributionId = 0;

        vm.startPrank(cronJob);
            pool.updateAllVaultAccounts(vaultIds, distributionId);
        vm.stopPrank();
    }

    function testCanUpdateNftMultiplierWhenNotStarted() public {
        uint256 initialNftMultiplier = pool.NFT_MULTIPLIER();
        uint256 newNftMultiplier = initialNftMultiplier + 1;
        assertNotEq(initialNftMultiplier, newNftMultiplier);


        
        vm.startPrank(operator);
            pool.enableMaintenance();

            vm.expectEmit(true, true, true, true);
            emit NftMultiplierUpdated(initialNftMultiplier, newNftMultiplier);
            
            pool.updateNftMultiplier(newNftMultiplier);
        vm.stopPrank();
        
        assertEq(pool.NFT_MULTIPLIER(), newNftMultiplier);
        assertNotEq(initialNftMultiplier, pool.NFT_MULTIPLIER());
    }
    
// ------ state transition:StateT0_DeployAndSetupStakingPower ------

    function testUserCannotSetupDistribution_T0() public {
        uint256 distributionId = 0;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testFirstDistributionMustBeD0_T0() public {
        uint256 distributionId = 1;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionId.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testCannotSetupDistributionWithZeroTokenPrecision_T0() public {
        uint256 distributionId = 0;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 0;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.ZeroTokenPrecision.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }
    
    function testCannotSetupDistributionWithZeroEmissionRate_T0() public {
        uint256 distributionId = 0;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime;
        uint256 emissionPerSecond = 0;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.ZeroEmissionRate.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testCannotSetupDistributionWithRebasedEmissionRateZero_T0() public {
        uint256 distributionId = 0;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime = 0;
        uint256 emissionPerSecond = 1;
        uint256 tokenPrecision = 1E19;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.RebasedEmissionRateIsZero.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testOperatorCanSetupDistributionWhenNotStarted_T0() public {
        uint256 distributionId = 0;
        uint256 distributionStartTime = 1;
        uint256 distributionEndTime = 0;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;
        
        // Check state before
        assertEq(pool.getActiveDistributionsLength(), 0);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionCreated(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
        
        // Check state after
        assertEq(pool.getActiveDistributionsLength(), 1);
        
        DataTypes.Distribution memory distribution = getDistribution(distributionId);
        assertEq(distribution.distributionId, distributionId);
        assertEq(distribution.startTime, distributionStartTime);
        assertEq(distribution.endTime, distributionEndTime);
        assertEq(distribution.emissionPerSecond, emissionPerSecond);
        assertEq(distribution.TOKEN_PRECISION, tokenPrecision);
    }

}

abstract contract StateT0_DeployAndSetupStakingPower is StateT0_Deploy {

    function setUp() public virtual override {
        super.setUp();

        vm.prank(operator);
        
        // staking power
            uint256 distributionId = 0;
            uint256 distributionStartTime = 1;
            uint256 distributionEndTime;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            uint32 dstEid = 3141;
            bytes32 tokenAddress = 0x00;
        pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);        
    }
}

// TODO
contract StateT0_DeployAndSetupStakingPowerTest is StateT0_DeployAndSetupStakingPower {
    /**
        - test setupDistribution
        - test updateDistribution
        stuff you can can w/ distribvution, but before setup
    */

    function testCannotUpdateDistributionWithNullInputs_T0() public {
        uint256 distributionId = 0;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionParameters.selector);
            pool.updateDistribution(distributionId, 0, 0, 0);
        vm.stopPrank();
    }


    function testCannotUpdateDistributionToStartBeforeContractStartTime_T0() public {
        uint256 distributionId = 0;
        uint256 newDistributionStartTime = 0;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionParameters.selector);
            pool.updateDistribution(distributionId, newDistributionStartTime, 0, 0);
        vm.stopPrank();
    }

    function testCanUpdateDistributionWhenContractNotStarted_T0() public {
        // staking power
        uint256 distributionId = 0;
        DataTypes.Distribution memory distributionBefore = getDistribution(distributionId);
        
        // update distribution
        uint256 newDistributionStartTime = distributionBefore.startTime + 1;
        
        // Check state before
        assertEq(distributionBefore.startTime, 1);
        assertEq(distributionBefore.endTime, 0);
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionUpdated(distributionId, newDistributionStartTime, distributionBefore.endTime, distributionBefore.emissionPerSecond);

            pool.updateDistribution(distributionId, newDistributionStartTime, 0, 0);
        vm.stopPrank();
        
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        
        // Check state after
        assertEq(distributionAfter.startTime, newDistributionStartTime);
        assertEq(distributionAfter.endTime, distributionBefore.endTime);
        assertEq(distributionAfter.emissionPerSecond, distributionBefore.emissionPerSecond);
    }

    function testCanEndDistributionWhenNotStarted() public {
            // Setup a distribution first
            uint256 distributionId = 1;
            uint256 distributionStartTime = block.timestamp + 100;
            uint256 distributionEndTime = distributionStartTime + 1000;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
            
            vm.startPrank(operator);
                vm.expectEmit(true, true, true, true);
                emit DistributionCreated(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision);

                pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
            vm.stopPrank();

            // assert distribution was setup
            DataTypes.Distribution memory distribution = getDistribution(distributionId);
            assertEq(distribution.distributionId, distributionId);
            assertEq(distribution.startTime, distributionStartTime);
            assertEq(distribution.endTime, distributionEndTime);
            assertEq(distribution.lastUpdateTimeStamp, distributionStartTime);
            assertEq(distribution.emissionPerSecond, emissionPerSecond);
            assertEq(distribution.TOKEN_PRECISION, tokenPrecision);
            assertEq(distribution.manuallyEnded, 0);
        

        // End the distribution 
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit DistributionEnded(distributionId, block.timestamp, distribution.totalEmitted);

            pool.endDistribution(distributionId);
        vm.stopPrank();

        // assert distribution was ended
        DataTypes.Distribution memory distributionAfter = getDistribution(distributionId);
        assertEq(distributionAfter.endTime, block.timestamp, "Distribution end time should be set to current block timestamp");
        //assertEq(distributionAfter.lastUpdateTimeStamp, block.timestamp, "Last update timestamp should be set to current block timestamp");
        assertEq(distributionAfter.totalEmitted, 0, "Total emitted should be zero for distribution that never started");
        assertEq(distributionAfter.manuallyEnded, 1, "Distribution should be marked as manually ended");
    }
    
    function testCanPopEndedDistributionWhenNotStarted() public {
            // Setup a distribution first
            uint256 distributionId = 1;
            uint256 distributionStartTime = block.timestamp + 1;
            uint256 distributionEndTime = distributionStartTime + 1000;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
            
            vm.startPrank(operator);
                vm.expectEmit(true, true, true, true);
                emit DistributionCreated(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision);

                pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
            vm.stopPrank();

            assertEq(pool.getActiveDistributionsLength(), 2);

            // assert distribution was setup
            DataTypes.Distribution memory distribution = getDistribution(distributionId);
            assertEq(distribution.distributionId, distributionId);
            assertEq(distribution.startTime, distributionStartTime);
            assertEq(distribution.endTime, distributionEndTime);
            assertEq(distribution.lastUpdateTimeStamp, distributionStartTime);
            assertEq(distribution.emissionPerSecond, emissionPerSecond);
            assertEq(distribution.TOKEN_PRECISION, tokenPrecision);
            assertEq(distribution.manuallyEnded, 0);
        
        vm.warp(distributionStartTime); 

        vm.startPrank(operator);
            vm.expectRevert(Errors.DistributionNotEnded.selector);
            pool.popEndedDistribution(distributionId);
        vm.stopPrank();

        // assert distribution was popped
        assertEq(pool.getActiveDistributionsLength(), 1);
    }

    function testCanUpdateNftMultiplierWhenNotStarted() public {
        vm.startPrank(operator);
            pool.enableMaintenance();
            pool.updateNftMultiplier(100);
        vm.stopPrank();
    }

    function testCanUpdateBoostedBalancesWhenNotStarted() public {
        
        vm.startPrank(operator);
            pool.enableMaintenance();

            vm.expectRevert(Errors.InvalidArray.selector);
            pool.updateBoostedBalances(new bytes32[](0));
        vm.stopPrank();
    }
}