// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT1.t.sol";

abstract contract StateT6_User2StakeAssetsToVault1 is StateT1_User1StakeAssetsToVault1 {

    // for reference
    DataTypes.Distribution distribution0_T6;
    DataTypes.VaultAccount vault1Account0_T6;
    DataTypes.UserAccount user1Account0_T6;
    DataTypes.UserAccount user2Account0_T6;

    function setUp() public virtual override {
        super.setUp();

        // T6   
        vm.warp(6);
 
        vm.startPrank(user2);
        
        // User2 stakes half their tokens
        mocaToken.approve(address(pool), user2Moca/2);
        pool.stakeTokens(vaultId1, user2Moca/2);

        // User2 stakes 2 nfts
        uint256[] memory nftsToStake = new uint256[](2); 
        nftsToStake[0] = user2NftsArray[0];
        nftsToStake[1] = user2NftsArray[1];
        pool.stakeNfts(vaultId1, nftsToStake);
        
        // User2 stakes half their RP
        uint256 expiry = block.timestamp + 1 days;
        uint256 nonce = 0;
        bytes memory signature = generateSignature(user2, vaultId1, user2Rp/2, expiry, pool.CURRENT_SEASON(), nonce);
        pool.stakeRealmPoints(vaultId1, user2Rp/2, expiry, signature);

        vm.stopPrank();

        // save state
        distribution0_T6 = getDistribution(0);
        vault1Account0_T6 = getVaultAccount(vaultId1, 0);
        user1Account0_T6 = getUserAccount(user1, vaultId1, 0);
        user2Account0_T6 = getUserAccount(user2, vaultId1, 0);
    }
}


//note: 5 seconds delta. 5 ether of staking power emitted @1ether/second
contract StateT6_User2StakeAssetsToVault1Test is StateT6_User2StakeAssetsToVault1 {

    function testUserCannotStakeSameNftsTwice() public {
        uint256[] memory nftsToStake = new uint256[](2); 
        nftsToStake[0] = user2NftsArray[0];
        nftsToStake[1] = user2NftsArray[1];

        vm.startPrank(user2);
            vm.expectRevert();
            pool.stakeNfts(vaultId1, nftsToStake);
        vm.stopPrank();
    }

    function testUserCannotStakeRpTwiceWithSameNonce() public {
        // User2 stakes half their RP
        uint256 expiry = block.timestamp + 1 days;
        uint256 nonce = 0;
        bytes memory signature = generateSignature(user2, vaultId1, user2Rp/2, expiry, pool.CURRENT_SEASON(), nonce);

        vm.startPrank(user2);
            vm.expectRevert(Errors.InvalidSignature.selector);
            pool.stakeRealmPoints(vaultId1, user2Rp/2, expiry, signature);
        vm.stopPrank();
    }

// ---------------- distribution 0 ----------------

    function testPool_T6() public {

        // Check total staked assets
        assertEq(pool.totalCreationNfts(), user1NftsArray.length);
        assertEq(pool.totalStakedNfts(), 2); // user2's 2 staked NFTs
        assertEq(pool.totalStakedTokens(), user1Moca/2 + user2Moca/2);
        assertEq(pool.totalStakedRealmPoints(), user1Rp/2 + user2Rp/2);

        // Check boosted balances
        uint256 expectedBoostFactor = 10_000 + (2 * nftMultiplier); // Base + 2 NFTs from user2
        uint256 expectedBoostedRealmPoints = ((user1Rp/2 + user2Rp/2) * expectedBoostFactor) / 10_000;
        uint256 expectedBoostedStakedTokens = ((user1Moca/2 + user2Moca/2) * expectedBoostFactor) / 10_000;

        assertEq(pool.totalBoostedRealmPoints(), expectedBoostedRealmPoints);
        assertEq(pool.totalBoostedStakedTokens(), expectedBoostedStakedTokens);
    }

    function testDistribution0_T6() public {
        DataTypes.Distribution memory distribution = getDistribution(0);

        /** index calc.
            totalStakedRp = user1Rp/2 = 250 RP
            totalEmitted = 5 SP
            index = 5 SP / 250 RP = 0.02 * 1E18
         */
        uint256 expectedIndex = 0.02 * 1E18;

        assertEq(distribution.index, expectedIndex);
        assertEq(distribution.lastUpdateTimeStamp, 6);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.endTime, 0);
    }

    function testVault1_T6() public {
        DataTypes.Vault memory vault = pool.getVault(vaultId1);
        
        // Base vault data
        assertEq(vault.creator, user1);
        assertEq(vault.startTime, startTime);
        assertEq(vault.endTime, 0);
        assertEq(vault.removed, 0);
        assertEq(vault.nftFeeFactor, 1000);
        assertEq(vault.creatorFeeFactor, 1000);
        assertEq(vault.realmPointsFeeFactor, 1000);
        
        // Verify creation NFTs
        assertEq(vault.creationTokenIds.length, user1NftsArray.length);
        for(uint i = 0; i < user1NftsArray.length; i++) {
            assertEq(vault.creationTokenIds[i], user1NftsArray[i]);
        }

        // Verify staked assets
        assertEq(vault.stakedTokens, user1Moca/2 + user2Moca/2);
        assertEq(vault.stakedNfts, 2);
        assertEq(vault.stakedRealmPoints, user1Rp/2 + user2Rp/2);

        // Verify boosted balances
        uint256 expectedBoostFactor = 10_000 + (2 * nftMultiplier);
        assertEq(vault.totalBoostFactor, expectedBoostFactor);
        assertEq(vault.boostedRealmPoints, (vault.stakedRealmPoints * vault.totalBoostFactor) / 10_000);
        assertEq(vault.boostedStakedTokens, (vault.stakedTokens * vault.totalBoostFactor) / 10_000);
    }

    function testVault1Account0_T6() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** index calc:
            totalStakedRp = user1Rp/2 = 250 RP
            totalEmitted = 5 SP
            index = 5 SP / 250 RP = 0.02 * 1E18

            vault1 fees:
                uint256 nftFeeFactor = 1000;
                uint256 creatorFeeFactor = 1000; 
                uint256 realmPointsFeeFactor = 1000;
            totalFees = 30% of total rewards [3000/10000 = 30/100]
         */
        uint256 totalAccRewards = 5 ether;
        uint256 expectedIndex = distribution.index;
        // expected fees
        uint256 expectedAccCreatorFee = totalAccRewards * 1000 / 10_000;
        uint256 expectedAccTotalNftFee = 0;                                     // 0 nfts staked frm t1-6
        uint256 expectedAccRealmPointsFee = totalAccRewards * 1000 / 10_000;

        // expected indices
        uint256 expectedNftIndex = 0;      // 0 nfts staked frm t1-6
        uint256 expectedRpIndex = expectedAccRealmPointsFee * 1E18 / (user1Rp/2);     // 250 RP staked

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 totalRewardsLessOfFees = totalAccRewards - (expectedAccCreatorFee + expectedAccTotalNftFee + expectedAccRealmPointsFee);
        uint256 expectedRewardsAccPerUnitStaked = totalRewardsLessOfFees * 1E18 / (user1Moca/2);

        // Check indices
        assertEq(vaultAccount.index, expectedIndex); // must match distribution index
        assertEq(vaultAccount.nftIndex, expectedNftIndex); 
        assertEq(vaultAccount.rpIndex, expectedRpIndex);   

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, expectedAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, expectedAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, expectedAccRealmPointsFee); 

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    function testUser1_T6() public {
        DataTypes.User memory user = pool.getUser(user1, vaultId1);

        // nfts        
        assertEq(user.tokenIds.length, 0);

        // tokens
        assertEq(user.stakedTokens, user1Moca/2);

        // realm points
        assertEq(user.stakedRealmPoints, user1Rp/2);
    }

    function testUser1AccountForVault1_T6() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user 1 not updated. since he took no action at t6

        // Check indices
        assertEq(userAccount.index, 0);
        assertEq(userAccount.nftIndex, 0);
        assertEq(userAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0);
        assertEq(userAccount.accNftStakingRewards, 0);
        assertEq(userAccount.accRealmPointsRewards, 0);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //--------------------------------
        
        // view fn: user1 gets all emitted rewards so far
        uint256 rewards = pool.getClaimableRewards(user1, vaultId1, 0);
        assertEq(rewards, vaultAccount.totalAccRewards);
    }

    function testUser2_T6() public {
        DataTypes.User memory user = pool.getUser(user2, vaultId1);

        // tokens
        assertEq(user.stakedTokens, user2Moca/2);

        // nfts
        assertEq(user.tokenIds.length, 2);
        assertEq(user.tokenIds[0], user2NftsArray[0]);
        assertEq(user.tokenIds[1], user2NftsArray[1]);
        
        // realm points
        assertEq(user.stakedRealmPoints, user2Rp/2);
    }

    function testUser2AccountForVault1_T6() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user 2 has no rewards since just staked at t6

        // Check indices match vault 
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, 0);
        assertEq(userAccount.accNftStakingRewards, 0);
        assertEq(userAccount.accRealmPointsRewards, 0);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //--------------------------------
        
        // view fn: user2 gets all emitted rewards so far
        uint256 rewards = pool.getClaimableRewards(user2, vaultId1, 0);
        assertEq(rewards, 0);
    }

// ---------------- state transition: PoolT11.t.sol ----------------

    function testCannotSetupDistributionExceedsMaxActiveDistributions_T6() public {
        // distribution params
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 1 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = bytes32(uint256(0x123));

        uint256 maxActiveDistributions = pool.MAX_ACTIVE_DISTRIBUTIONS();
            
        // setup distributions until maximum is hit
        vm.startPrank(operator);
        
        // already have distribution 0 active from setup
        for (uint256 i = 1; i <= maxActiveDistributions; ++i) {

            if (i == maxActiveDistributions) {
                // The last iteration would exceed the maximum
                vm.expectRevert(Errors.MaxActiveDistributions.selector);
            }
            
            pool.setupDistribution(
                i, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision, 
                dstEid, 
                tokenAddress
            );
        }
        
        vm.stopPrank();
    }

    // distributionStartTime < startTime
    function testCannotSetupDistributionStartTimeBeforeContractStartTime_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp - 1;
        uint256 distributionEndTime = block.timestamp + 1 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionStartTime.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    // startTime > endTime
    function testCannotSetupTokenDistributionStartTimeGreaterThanEndTime_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp - 1;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;


        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDistributionEndTime.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }   

    function testCannotSetupTokenDistributionWithInvalidDstEid_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 1 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;
        uint32 dstEid_ = 0;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidDstEid.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid_, tokenAddress);
        vm.stopPrank();
    }

    function testCannotSetupTokenDistributionWithInvalidTokenAddress_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 1 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = 0x00;

        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidTokenAddress.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }   

    function testCannotSetupTokenDistributionIfEmissionPerSecondRebasedIsZero_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp;
        uint256 distributionEndTime = block.timestamp + 1 days;
        uint256 emissionPerSecond = 1;
        uint256 tokenPrecision = 1E19;
        bytes32 tokenAddress = 0x00;
        
        vm.startPrank(operator);
            vm.expectRevert(Errors.RebasedEmissionRateIsZero.selector);
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }


    function testUserCannotSetupDistribution_T6() public {
        // distribution params  
        uint256 distributionId = 1;
        uint256 distributionStartTime = 21;
        uint256 distributionEndTime = 21 + 2 days;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 2 days * emissionPerSecond;

        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.setupDistribution(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision, dstEid, tokenAddress);
        vm.stopPrank();
    }

    function testOperatorCanSetupDistribution_T6() public {
        // operator sets up distribution
        vm.startPrank(operator);

            // distribution params
            uint256 distributionId = 1;
            uint256 distributionStartTime = 21;
            uint256 distributionEndTime = 21 + 2 days;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
            uint256 totalRequired = 2 days * emissionPerSecond;

            // check rewards vault call
            vm.expectCall(
                address(rewardsVault),
                abi.encodeCall(rewardsVault.setupDistribution, (distributionId, dstEid, tokenAddress, totalRequired))
            );

            vm.expectEmit(true, true, true, true);
            emit DistributionCreated(
                distributionId,
                distributionStartTime,
                distributionEndTime,
                emissionPerSecond,
                tokenPrecision
            );

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

        // check active distributions length increased
        assertEq(pool.getActiveDistributionsLength(), distributionId + 1);

        // verify distribution params were set correctly in rewardsVault
        (
            uint32 storedDstEid,
            bytes32 storedTokenAddress,
            uint256 storedTotalRequired,
            uint256 totalClaimed,
            uint256 totalDeposited
        ) = rewardsVault.distributions(distributionId);

        assertEq(storedDstEid, dstEid);
        assertEq(storedTokenAddress, tokenAddress);
        assertEq(storedTotalRequired, totalRequired);
        assertEq(totalClaimed, 0);
        assertEq(totalDeposited, 0);
    }

// ---------------- state transition: PoolT6p_updateMinimumRp.t.sol ----------------

    function testUserCannotUpdateMinimumRealmPoints_T6() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, Constants.OPERATOR_ROLE));
            pool.updateMinimumRealmPoints(1000);
        vm.stopPrank();
    }

    function testCannotSetMinimumRealmPointsToZero_T6() public {
        vm.startPrank(operator);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.updateMinimumRealmPoints(0);
        vm.stopPrank();
    }

    function testOperatorCanUpdateMinimumRealmPoints_T6() public {
        // Get initial value
        uint256 initialMinRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
        uint256 newMinRealmPoints = initialMinRealmPoints + 1;
        
        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MinimumRealmPointsUpdated(initialMinRealmPoints, newMinRealmPoints);
            pool.updateMinimumRealmPoints(newMinRealmPoints);
        vm.stopPrank();
        
        // Check value was updated
        uint256 updatedMinRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
        assertEq(updatedMinRealmPoints, newMinRealmPoints);
        assertNotEq(initialMinRealmPoints, updatedMinRealmPoints);
    }
}
