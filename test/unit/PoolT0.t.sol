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

    function testCanUpdateActiveDistributionsWhenNotStarted() public {
        // Check initial value
        uint256 initialMaxActive = pool.maxActiveAllowed();
        uint256 newMaxActive = 1;
        assertNotEq(initialMaxActive, newMaxActive);

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MaximumActiveDistributionsUpdated(newMaxActive);
            
            pool.updateMaxActiveDistributions(newMaxActive);
        vm.stopPrank();
        
        // Check value was updated
        uint256 updatedMaxActive = pool.maxActiveAllowed();
        assertEq(updatedMaxActive, newMaxActive);
    }

// ------ state transition ------
    function testOperatorCanSetupDistribution() public {
        vm.prank(operator);
        
        // staking power
            uint256 distributionId = 0;
            uint256 distributionStartTime = 1;
            uint256 distributionEndTime;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            uint32 dstEid = 0;
            bytes32 tokenAddress = 0x00;
        pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);        
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
}