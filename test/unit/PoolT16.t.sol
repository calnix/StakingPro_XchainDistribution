// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT11.t.sol";

abstract contract StateT16_BothUsersStakeAgain is StateT11_Distribution1Created {
    
    // for reference
    DataTypes.Distribution distribution0_T16;
    DataTypes.Distribution distribution1_T16;
    DataTypes.VaultAccount vault1Account0_T16;
    DataTypes.VaultAccount vault1Account1_T16;
    DataTypes.UserAccount user1Account0_T16;
    DataTypes.UserAccount user2Account0_T16;

    function setUp() public virtual override {
        super.setUp();

        // T16   
        vm.warp(16);
 
        // User1 stakes remaining assets
        vm.startPrank(user1);
        
            // Stake remaining tokens
            mocaToken.approve(address(pool), user1Moca/2);
            pool.stakeTokens(vaultId1, user1Moca/2);
            
            // Stake remaining RP
            uint256 expiry = block.timestamp + 1 days;
            uint256 nonce = 1;
            bytes memory signature = generateSignature(user1, vaultId1, user1Rp/2, expiry, nonce);
            pool.stakeRP(vaultId1, user1Rp/2, expiry, signature);

        vm.stopPrank();

        // User2 stakes remaining assets
        vm.startPrank(user2);
        
            // Stake remaining tokens
            mocaToken.approve(address(pool), user2Moca/2);
            pool.stakeTokens(vaultId1, user2Moca/2);

            // Stake 2 more nfts
            uint256[] memory nftsToStake = new uint256[](2); 
            nftsToStake[0] = user2NftsArray[2];
            nftsToStake[1] = user2NftsArray[3];
            pool.stakeNfts(vaultId1, nftsToStake);
            
            // Stake remaining RP
            expiry = block.timestamp + 1 days;
            nonce = 1;
            signature = generateSignature(user2, vaultId1, user2Rp/2, expiry, nonce);
            pool.stakeRP(vaultId1, user2Rp/2, expiry, signature);

        vm.stopPrank();

        // save state
        distribution0_T16 = getDistribution(0);
        distribution1_T16 = getDistribution(1);
        vault1Account0_T16 = getVaultAccount(vaultId1, 0);
        vault1Account1_T16 = getVaultAccount(vaultId1, 1);
        user1Account0_T16 = getUserAccount(user1, vaultId1, 0);
        user2Account0_T16 = getUserAccount(user2, vaultId1, 0);
    }
}

//note: 2 distributions created
contract StateT16_BothUsersStakeAgainTest is StateT16_BothUsersStakeAgain {

    //TODO: testPool_t16

    function testVault1_T16() public {
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
        assertEq(vault.stakedTokens, user1Moca + user2Moca);
        assertEq(vault.stakedNfts, 4);
        assertEq(vault.stakedRealmPoints, user1Rp + user2Rp);

        // Verify boosted balances
        uint256 expectedBoostFactor = 10_000 + (vault.stakedNfts * pool.NFT_MULTIPLIER());
        assertEq(vault.totalBoostFactor, expectedBoostFactor);
        assertEq(vault.boostedRealmPoints, (vault.stakedRealmPoints * vault.totalBoostFactor) / 10_000);
        assertEq(vault.boostedStakedTokens, (vault.stakedTokens * vault.totalBoostFactor) / 10_000);
    }

    function testUser1_T16() public {
        DataTypes.User memory user = pool.getUser(user1, vaultId1);

        // nfts        
        assertEq(user.tokenIds.length, 0);

        // tokens
        assertEq(user.stakedTokens, user1Moca);

        // realm points
        assertEq(user.stakedRealmPoints, user1Rp);
    }

    function testUser2_T16() public {
        DataTypes.User memory user = pool.getUser(user2, vaultId1);

        // nfts        
        assertEq(user.tokenIds.length, 4);
        assertEq(user.tokenIds[0], user2NftsArray[0]);
        assertEq(user.tokenIds[1], user2NftsArray[1]); 
        assertEq(user.tokenIds[2], user2NftsArray[2]);
        assertEq(user.tokenIds[3], user2NftsArray[3]);

        // tokens
        assertEq(user.stakedTokens, user2Moca);

        // realm points
        assertEq(user.stakedRealmPoints, user2Rp);
    }

// ---------------- distribution 0 ----------------

    function testDistribution0_T16() public {

        DataTypes.Distribution memory distribution = getDistribution(0);

        // static
        assertEq(distribution.distributionId, 0);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 0);
        assertEq(distribution.startTime, 1);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        
        
        /** index calc:
            - prev. index: 0.02e18 [t6]
            - totalEmitted: 10e18 SP
            - totalRpStaked: (250 + 500) [t6-t16]
            - totalBoostFactor: 1000 * 2 / PRECISION_BASE = 20% [20/100]
            - totalBoostedRP: (250 + 500) * 1.2 = 900e18
            index = 0.02e18 + [10e18 SP / 900e18 RP]
                  = 0.02e18 + 1.111...111e16
                  = 0.031111e18
            both users had staked half their RP balances from t6-t16
         */

        uint256 totalRpStaked = user1Rp/2 + user2Rp/2;
        uint256 numOfNftsStaked = 2;                            // user2: 2nfts staked for t6-t16
        uint256 boostedAmount = (totalRpStaked * (numOfNftsStaked * pool.NFT_MULTIPLIER()) / pool.PRECISION_BASE());
        uint256 totalBoostedRp = totalRpStaked + boostedAmount;

        uint256 indexDelta = 10 ether * 1E18 / totalBoostedRp;
        uint256 expectedIndex = 0.02E18 + indexDelta;
        console.log("expectedIndex", expectedIndex);
        assertEq(expectedIndex, 31111111111111111); // 3.111e16
        
        // dynamic
        assertEq(distribution.index, expectedIndex);
        assertEq(distribution.totalEmitted, 15 ether);
        assertEq(distribution.lastUpdateTimeStamp, 16);
    }

    function testVault1Account0_T16() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T6 - T16
            stakedTokens: user1 1/2 + user 2 1/2
            stakedRp: user1 1/2 + user 2 1/2
            stakedNfts: 2
         */

        // cal. newly accrued rewards
        uint256 prevVaultIndex = 0.02e18;
        uint256 boostedBalance = (user1Rp/2 + user2Rp/2) * 120/100;    // user 2 stakes 2 nfts at t6-t16
        uint256 newlyAccRewards = calculateRewards(boostedBalance, distribution0_T16.index, prevVaultIndex, 1E18);
        // eval. rounding error
        uint256 newlyAccRewardsExpected = 10 ether;                   // ignores rounding 
        assertApproxEqAbs(newlyAccRewards, newlyAccRewardsExpected, 100);

        // newly accrued fees since last update: based on newlyAccRewards
        uint256 newlyAccCreatorFee = newlyAccRewards * 1000 / 10_000;
        uint256 newlyAccTotalNftFee = newlyAccRewards * 1000 / 10_000;         // 2 nfts staked frm t6-t16
        uint256 newlyAccRealmPointsFee = newlyAccRewards * 1000 / 10_000;
        
        // latest indices
        uint256 latestNftIndex = (newlyAccTotalNftFee / 2) + vault1Account0_T6.nftIndex;     // 2 nfts staked frm t6-t16
        uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / (user1Rp/2 + user2Rp/2)) + vault1Account0_T6.rpIndex;

        // check indices
        assertEq(vaultAccount.index, distribution.index); // must match distribution index
        assertEq(vaultAccount.nftIndex, latestNftIndex);
        assertEq(vaultAccount.rpIndex, latestRpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = newlyAccRewards + vault1Account0_T6.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T6.accCreatorRewards;
        uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T6.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T6.accRealmPointsRewards;

        // heck accumulated rewards + fees
        assertEq(vaultAccount.totalAccRewards, totalAccRewards);
        assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / (user1Moca/2 + user2Moca/2)) + vault1Account0_T6.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 

        // totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    function testUser1_ForVault1Account0_T16() public {

        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user 1 last updated at t1

        // Check indices match vault
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Calculate expected rewards for user1's staked tokens
        uint256 latestAccStakingRewards = calculateRewards(user1Moca/2, vaultAccount.rewardsAccPerUnitStaked, user1Account0_T6.index, 1E18) + user1Account0_T6.accStakingRewards;      
        // Calculate expected rewards for nft staking
        uint256 latestAccNftStakingRewards = 0; // 0 nfts staked
        // Calculate expected rewards for rp staking
        uint256 latestAccRealmPointsRewards = calculateRewards(user1Rp/2, vaultAccount.rpIndex, user1Account0_T6.rpIndex, 1E18) + user1Account0_T6.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, latestAccStakingRewards); 
        assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards);
        assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //--------------------------------
        
        // view fn: user1 gets their share of total rewards
        uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
        
        uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
        if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        assertEq(claimableRewards, expectedClaimableRewards); 
    }

    function testUser2_ForVault1Account0_T16() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 0);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);

        //--- user2 last updated at t6: consider the emissions from t6-t16

        // Check indices match vault@t16
        assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked);
        assertEq(userAccount.nftIndex, vaultAccount.nftIndex);
        assertEq(userAccount.rpIndex, vaultAccount.rpIndex);

        // Calculate expected rewards for user1's staked tokens
        uint256 latestAccStakingRewards = calculateRewards(user2Moca/2, vaultAccount.rewardsAccPerUnitStaked, user2Account0_T6.index, 1E18) + user2Account0_T6.accStakingRewards;      
        // Calculate expected rewards for nft staking
        uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account0_T6.nftIndex) * 2) + user2Account0_T6.accNftStakingRewards; // 2 nfts staked
        // Calculate expected rewards for rp staking
        uint256 latestAccRealmPointsRewards = calculateRewards(user2Rp/2, vaultAccount.rpIndex, user2Account0_T6.rpIndex, 1E18) + user2Account0_T6.accRealmPointsRewards;

        // Check accumulated rewards
        assertEq(userAccount.accStakingRewards, latestAccStakingRewards); 
        assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards);
        assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards);

        // Check claimed rewards
        assertEq(userAccount.claimedStakingRewards, 0);
        assertEq(userAccount.claimedNftRewards, 0);
        assertEq(userAccount.claimedRealmPointsRewards, 0);
        assertEq(userAccount.claimedCreatorRewards, 0);
        
        //--------------------------------
        
        // view fn: user2 gets their share of total rewards
        uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 0);
        
        uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
        if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

        assertEq(claimableRewards, expectedClaimableRewards); 
    }

// ---------------- distribution 1 ----------------
    
    // distribution 1 not yet started
    function testDistribution1_T16() public {
        // Check all Distribution struct fields
        DataTypes.Distribution memory distribution = getDistribution(1);
        
        // static
        assertEq(distribution.distributionId, 1);
        assertEq(distribution.TOKEN_PRECISION, 1e18); 
        assertEq(distribution.endTime, 21 + 2 days);
        assertEq(distribution.startTime, 21);
        assertEq(distribution.emissionPerSecond, 1 ether);
        assertEq(distribution.manuallyEnded, 0);        

        // dynamic
        assertEq(distribution.index, 0);
        assertEq(distribution.totalEmitted, 0);
        assertEq(distribution.lastUpdateTimeStamp, 21);
    }

    function testVault1Account1_T16() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
        
        // Check indices match distribution
        assertEq(vaultAccount.index, distribution.index);
        assertEq(vaultAccount.nftIndex, 0);
        assertEq(vaultAccount.rpIndex, 0);

        // Check accumulated rewards
        assertEq(vaultAccount.totalAccRewards, 0);
        assertEq(vaultAccount.accCreatorRewards, 0);
        assertEq(vaultAccount.accNftStakingRewards, 0); 
        assertEq(vaultAccount.accRealmPointsRewards, 0);

        // Check rewards per unit staked
        assertEq(vaultAccount.rewardsAccPerUnitStaked, 0);

        // Check claimed rewards
        assertEq(vaultAccount.totalClaimedRewards, 0);
    }

    function testUser1_ForVault1Account1_T16() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
        
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
    }

    function testUser2_ForVault1Account1_T16() public {
        DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);
        
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
    }    

// ---------------- others ----------------

    function testCannotClaimFromDistributionNotStarted_T16() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Errors.DistributionNotStarted.selector));
        pool.claimRewards(vaultId1, 1);
    }

    function testNonOperatorCannotUpdateCreationNfts(uint256 newAmount) public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, pool.OPERATOR_ROLE()));
            pool.updateCreationNfts(newAmount);
        vm.stopPrank();
    }

    // operator updates CREATION_NFTS_REQUIRED
    function testUpdateCreationNfts(uint256 newAmount) public {
        vm.startPrank(operator);
            vm.expectEmit(true, true, false, false);
            emit CreationNftRequiredUpdated(pool.CREATION_NFTS_REQUIRED(), newAmount);
            pool.updateCreationNfts(newAmount);
        vm.stopPrank();
    
        assertEq(pool.CREATION_NFTS_REQUIRED(), newAmount);
    }

}
