// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT0.t.sol";

abstract contract StateT1_Started is StateT0_DeployAndSetupStakingPower {

    function setUp() public virtual override {
        super.setUp();

        //T1
        vm.warp(pool.startTime());
    }
}

contract StateT1_StartedTest is StateT1_Started {

    function testCannotStakeNftsToNonexistentVault() public {
        vm.prank(user2);
        bytes32 nonexistentVaultId = bytes32(uint256(1));
        uint256[] memory nftsToStake = new uint256[](1);
        nftsToStake[0] = user2NftsArray[0];

        vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, nonexistentVaultId));
        pool.stakeNfts(nonexistentVaultId, nftsToStake);
    }

    function testCannotStakeTokensToNonexistentVault() public {
        vm.prank(user2);
        bytes32 nonexistentVaultId = bytes32(uint256(1));
        uint256 amount = 100 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, nonexistentVaultId));
        pool.stakeTokens(nonexistentVaultId, amount);
    }

    function testCreateVault() public {
        vm.prank(user1);

            uint256 nftFeeFactor = 1000;
            uint256 creatorFeeFactor = 1000; 
            uint256 realmPointsFeeFactor = 1000;
            
        // Get vault ID before creating vault
        bytes32 expectedVaultId = generateVaultId(block.number - 1, user1);
        
        vm.expectEmit(true, true, true, true);
        emit VaultCreated(expectedVaultId, user1, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        
        pool.createVault(user1NftsArray, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        
        // Verify vault was created correctly
        DataTypes.Vault memory vault = pool.getVault(expectedVaultId);
        
        // Check creator and fee factors
        assertEq(vault.creator, user1, "Incorrect vault owner");
        assertEq(vault.nftFeeFactor, nftFeeFactor, "Incorrect NFT fee factor");
        assertEq(vault.creatorFeeFactor, creatorFeeFactor, "Incorrect creator fee factor");
        assertEq(vault.realmPointsFeeFactor, realmPointsFeeFactor, "Incorrect realm points fee factor");

        // Check creation NFTs array
        assertEq(vault.creationTokenIds.length, user1NftsArray.length, "Incorrect number of creation NFTs");
        for(uint i = 0; i < user1NftsArray.length; i++) {
            assertEq(vault.creationTokenIds[i], user1NftsArray[i], "Incorrect creation NFT ID");
        }

        // Check timestamps and status
        assertEq(vault.startTime, block.timestamp, "Incorrect start time");
        assertEq(vault.endTime, 0, "End time should be 0");
        assertEq(vault.removed, 0, "Vault should not be removed");

        // Check staking balances
        assertEq(vault.stakedNfts, 0, "Should have no staked NFTs");
        assertEq(vault.stakedTokens, 0, "Should have no staked tokens");
        assertEq(vault.stakedRealmPoints, 0, "Should have no staked realm points");

        // Check boost factors
        assertEq(vault.totalBoostFactor, 10_000, "Should have no boost factor");
        assertEq(vault.boostedRealmPoints, 0, "Should have no boosted realm points");
        assertEq(vault.boostedStakedTokens, 0, "Should have no boosted staked tokens");

        // Verify NFTs are registered to vault
        for(uint256 i = 0; i < user1NftsArray.length; i++) {
            (, bytes32 registeredVaultId) = nftRegistry.nfts(user1NftsArray[i]);
            assertEq(registeredVaultId, expectedVaultId, "NFT not registered to vault correctly");
        }
    }
}

// TODO
abstract contract StateT1_CreateVault1 is StateT1_Started {

    bytes32 public vaultId1 = 0x8fbe8a20f950b11703e51f11dee9f00d9fa0ebd091cc4f695909e860e994944b;

    function setUp() public virtual override {
        super.setUp();
        
        vm.startPrank(user1);

        uint256 nftFeeFactor = 1000;
        uint256 creatorFeeFactor = 1000; 
        uint256 realmPointsFeeFactor = 1000;

        pool.createVault(user1NftsArray, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();
    }
}

contract StateT1_CreateVault1Test is StateT1_CreateVault1 {

    function testCannotCreateVaultInvalidCreationNfts() public {
        vm.prank(user1);

        uint256[] memory invalidCreationNfts = new uint256[](1);
        invalidCreationNfts[0] = 1;

        vm.expectRevert(Errors.InvalidCreationNfts.selector);
        pool.createVault(invalidCreationNfts, 1000, 1000, 1000);
    }
    
    function testCannotCreateVaultWithOthersNfts() public {
        vm.prank(user2);

        vm.expectRevert();
        pool.createVault(user1NftsArray, 1000, 1000, 1000);
    }

    function testCannotCreateVaultWithInvalidFeeFactors() public {
        vm.prank(user1);

        vm.expectRevert(Errors.MaximumFeeFactorExceeded.selector);
        pool.createVault(user1NftsArray, 10000, 10000, 10000);
    }

    function testCannotCreateAnotherVaultWithLockedNfts() public {
        vm.prank(user1);
        vm.expectRevert();
        pool.createVault(user1NftsArray, 1000, 1000, 1000);
    }

    function testCannotStakeZeroTokens() public {
        vm.startPrank(user2);
        mocaToken.approve(address(pool), type(uint256).max);

        vm.expectRevert(Errors.InvalidAmount.selector);
        pool.stakeTokens(vaultId1, 0);
        vm.stopPrank();
    }

    function testCannotStakeZeroNfts() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidAmount.selector);
            pool.stakeNfts(vaultId1, new uint256[](0));
        vm.stopPrank();
    }

    function testCannotStakeRpExpiredSignature() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.SignatureExpired.selector);
            pool.stakeRP(vaultId1, 1000, block.timestamp - 1, bytes(""));
        vm.stopPrank();
    }

    function testCannotStakeRpLessThanMinimumRealmPoints() public {
        vm.startPrank(user1);
            vm.expectRevert(Errors.MinimumRpRequired.selector);
            pool.stakeRP(vaultId1, 1000, block.timestamp + 1, bytes(""));
        vm.stopPrank();
    }

    function testCannotStakeRpInvalidSignature() public {
        // Pack the struct data
        bytes32 structHash = keccak256(
            abi.encode(
                pool.TYPEHASH(),
                user1,
                vaultId1,
                1000 ether,
                block.timestamp + 1,
                1
            )
        );
        
        // Get the digest using the contract's domain separator
        bytes32 digest = pool.hashTypedDataV4(structHash);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(1), digest);
        // format
        bytes memory invalidSignature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidSignature.selector);
            pool.stakeRP(vaultId1, 1000 ether, block.timestamp + 1, invalidSignature);
        vm.stopPrank();
    }

    function testVault1CreatedCorrectly() public {
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
        assertEq(vault.stakedTokens, 0);
        assertEq(vault.stakedNfts, 0);
        assertEq(vault.stakedRealmPoints, 0);

        // Verify boosted balances
        assertEq(vault.totalBoostFactor, 10_000);
        assertEq(vault.boostedRealmPoints, 0);
        assertEq(vault.boostedStakedTokens, 0);
    }

    function testCanStakeTokens() public {
        // Setup
        vm.startPrank(user2);
        uint256 stakeAmount = 100 ether;
        mocaToken.approve(address(pool), stakeAmount);

        // Get initial state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        uint256 initialStakedTokens = vaultBefore.stakedTokens;
        uint256 userBalanceBefore = mocaToken.balanceOf(user2);

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit StakedTokens(user2, vaultId1, stakeAmount);

        // Stake tokens
        pool.stakeTokens(vaultId1, stakeAmount);

        // Verify state changes
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedTokens, initialStakedTokens + stakeAmount);
        assertEq(mocaToken.balanceOf(user2), userBalanceBefore - stakeAmount);
        assertEq(mocaToken.balanceOf(address(pool)), stakeAmount);
        vm.stopPrank();
    }

    function testCanStakeNfts() public {
        // Setup
        uint256[] memory nftsToStake = new uint256[](1);
        nftsToStake[0] = user2NftsArray[0];  // This should be 5 based on setup

        // Get initial state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        uint256 initialStakedNfts = vaultBefore.stakedNfts;

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit StakedNfts(user2, vaultId1, nftsToStake);

        // Stake NFTs
        vm.prank(user2);
        pool.stakeNfts(vaultId1, nftsToStake);

        // Verify state changes
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedNfts, initialStakedNfts + nftsToStake.length);
        
        // Verify NFT ownership using nfts mapping
        (, bytes32 registeredVaultId) = nftRegistry.nfts(nftsToStake[0]);
        assertEq(registeredVaultId, vaultId1, "NFT not registered to vault correctly");
        vm.stopPrank();
    }

    function testCanStakeRealmPoints() public {
        // Generate signature for realm points staking
        uint256 realmPointsAmount = 1000 ether;
        uint256 expiry = block.timestamp + 1 days;
        uint256 nonce = 0;
        bytes memory signature = generateSignature(user2, vaultId1, realmPointsAmount, expiry, nonce);


        // Get initial state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        uint256 initialStakedPoints = vaultBefore.stakedRealmPoints;

        // Calculate boosted amount
        uint256 boostedAmount = (realmPointsAmount * vaultBefore.totalBoostFactor) / 10000;

        // Expect event with boosted amount
        vm.expectEmit(true, true, true, true);
        emit StakedRealmPoints(user2, vaultId1, realmPointsAmount, boostedAmount);

        // Stake realm points
        vm.prank(user2);
        pool.stakeRP(vaultId1, realmPointsAmount, expiry, signature);

        // Verify state changes
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedRealmPoints, initialStakedPoints + realmPointsAmount);
        assertEq(vaultAfter.boostedRealmPoints, boostedAmount);
    }
}


abstract contract StateT1_User1StakeAssetsToVault1 is StateT1_CreateVault1 {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(user1);

        // User1 stakes half their tokens
        mocaToken.approve(address(pool), user1Moca/2);
        pool.stakeTokens(vaultId1, user1Moca/2);

        // User1 stakes half their RP
        uint256 expiry = block.timestamp + 1 days;
        uint256 nonce = 0;
        bytes memory signature = generateSignature(user1, vaultId1, user1Rp/2, expiry, nonce);
        pool.stakeRP(vaultId1, user1Rp/2, expiry, signature);

        vm.stopPrank();
    }
}

// accounts only exist for distribution 0
contract StateT1_User1StakeAssetsToVault1Test is StateT1_User1StakeAssetsToVault1 {

    function testPool_T1() public {
        
        // Check total staked assets
        assertEq(pool.totalCreationNfts(), 5);
        assertEq(pool.totalStakedNfts(), 0); // No NFTs staked yet
        assertEq(pool.totalStakedTokens(), user1Moca/2);
        assertEq(pool.totalStakedRealmPoints(), user1Rp/2);

        // Check boosted balances
        uint256 expectedBoostFactor = 10_000; // Just base factor since no NFTs staked
        uint256 expectedBoostedRealmPoints = (user1Rp/2 * expectedBoostFactor) / 10_000;
        uint256 expectedBoostedStakedTokens = (user1Moca/2 * expectedBoostFactor) / 10_000;

        assertEq(pool.totalBoostedRealmPoints(), expectedBoostedRealmPoints);
        assertEq(pool.totalBoostedStakedTokens(), expectedBoostedStakedTokens);
    }

    function testVault1_T1() public {
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
        assertEq(vault.stakedTokens, user1Moca/2);
        assertEq(vault.stakedNfts, 0);
        assertEq(vault.stakedRealmPoints, user1Rp/2);

        // Verify boosted balances
        assertEq(vault.totalBoostFactor, 10_000);
        assertEq(vault.boostedRealmPoints, (vault.stakedRealmPoints * vault.totalBoostFactor) / 10_000);
        assertEq(vault.boostedStakedTokens, (vault.stakedTokens * vault.totalBoostFactor) / 10_000);
    }

    function testVault1Account0_T1() public {
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        // Check indices
        assertEq(vaultAccount.index, 0);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0);
        assertEq(vaultAccount.accRealmPointsRewards, 0);
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    function testUser1_T1() public {
        DataTypes.User memory user = pool.getUser(user1, vaultId1);

        // nfts        
        assertEq(user.tokenIds.length, 0);

        // tokens
        assertEq(user.stakedTokens, user1Moca/2);

        // realm points
        assertEq(user.stakedRealmPoints, user1Rp/2);
    }

    function testUser1AccountForVault1_T1() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);

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
    }

    function testCannotStakeAssignedNfts() public {
        vm.startPrank(user1);
            vm.expectRevert();
            pool.stakeNfts(vaultId1, user1NftsArray);
        vm.stopPrank();
    }

    function testCannotStakeNotOwnedNfts() public {
        vm.startPrank(user1);
            vm.expectRevert();
            pool.stakeNfts(vaultId1, user2NftsArray);
        vm.stopPrank();
    }

    // transition fn: parallel test
    function testOperatorCanUpdateMinimumRealmPoints() public {
        // lower minimum realm points
        uint256 originalMinimumRealmPoints = pool.MINIMUM_REALMPOINTS_REQUIRED();
        uint256 newMinimumRealmPoints = originalMinimumRealmPoints/2;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MinimumRealmPointsUpdated(originalMinimumRealmPoints, newMinimumRealmPoints);
            pool.updateMinimumRealmPoints(newMinimumRealmPoints);
        vm.stopPrank();

        assertEq(pool.MINIMUM_REALMPOINTS_REQUIRED(), newMinimumRealmPoints);

        // increase minimum realm points
        uint256 newerMinimumRealmPoints = originalMinimumRealmPoints*2;

        vm.startPrank(operator);
            vm.expectEmit(true, true, true, true);
            emit MinimumRealmPointsUpdated(newMinimumRealmPoints, newerMinimumRealmPoints);
            pool.updateMinimumRealmPoints(newerMinimumRealmPoints);
        vm.stopPrank();

        assertEq(pool.MINIMUM_REALMPOINTS_REQUIRED(), newerMinimumRealmPoints);
    }
}