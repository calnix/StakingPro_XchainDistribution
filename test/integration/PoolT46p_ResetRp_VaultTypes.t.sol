// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../unit/PoolT41.t.sol";

    /**    
        1. enableMaintenance
        2. updateActiveDistributions -- all active distributions
        3. updateAllVaultAccounts -- all vaults w/ rp
        4. updateAllUserAccounts -- book rp related fees before resetting
        5. resetRealmPoints
            5.1 offchain script to check all vaults and users rp balances as sanity check, before proceeding to next onchain step
        6. incrementSeason
        7. disableMaintenance
    */

    /**
        other vault types
        1: ended [removed == 1]
        2: in cooldown [endTime > 0]
    */

abstract contract StateT46p_ResetRp_VaultTypes_Ended is StateT41_User2StakesToVault2 {

    function setUp() public virtual override {
        super.setUp();

        //1. lower vault cooldown
        vm.startPrank(owner);
            pool.updateVaultCooldown(1);
        vm.stopPrank();

        //2. end vault 1
        vm.startPrank(user1);
            pool.activateCooldown(vaultId1);
            
            // forward to end vault
            vm.warp(41 + 1);

            // end vault
            bytes32[] memory vaultIds = new bytes32[](1);
            vaultIds[0] = vaultId1;
            pool.endVaults(vaultIds);
        vm.stopPrank();

        //3. increase vault cooldown
        vm.startPrank(owner);
            pool.updateVaultCooldown(1 days);
        vm.stopPrank();    

        //4. activate cooldown vault 2
        vm.startPrank(user2);
            pool.activateCooldown(vaultId2);
        vm.stopPrank();

        vm.warp(46);
    }

}

abstract contract StateT46p_ResetRp_UpdateDistributions is StateT46p_ResetRp_VaultTypes_Ended {
    
    DataTypes.Vault vault1_T46; 
    DataTypes.Vault vault2_T46;
    DataTypes.Distribution distribution0_T46;
    DataTypes.Distribution distribution1_T46;

    function setUp() public virtual override {
        super.setUp();

        // set t46
        vm.warp(46);

        // vaults
        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;

        vm.startPrank(owner);
            pool.enableMaintenance();
            pool.updateActiveDistributions();
        vm.stopPrank();

        // store updated distributions at T46
        vault1_T46 = pool.getVault(vaultId1);
        vault2_T46 = pool.getVault(vaultId2);
        distribution0_T46 = getDistribution(0); 
        distribution1_T46 = getDistribution(1);
    }
}

//note: time is frozen at T46 - distribution state saved
contract StateT46p_ResetRp_UpdateDistributions_Test is StateT46p_ResetRp_UpdateDistributions {

    DataTypes.VaultAccount[2] public updatedVaultAccounts_D0_T46;
    DataTypes.VaultAccount[2] public updatedVaultAccounts_D0_T51;

    DataTypes.VaultAccount[2] public updatedVaultAccounts_D1_T46;
    DataTypes.VaultAccount[2] public updatedVaultAccounts_D1_T51;

    function test_updateVaultAccounts_T46() public {
        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;

        // update all vault accounts
        vm.startPrank(owner);
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
        vm.stopPrank();

        // STORE vaultAccounts at T46
        updatedVaultAccounts_D0_T46[0] = getVaultAccount(vaultId1, 0);
        updatedVaultAccounts_D0_T46[1] = getVaultAccount(vaultId2, 0);
        updatedVaultAccounts_D1_T46[0] = getVaultAccount(vaultId1, 1);
        updatedVaultAccounts_D1_T46[1] = getVaultAccount(vaultId2, 1);
    }

    function test_updateVaultAccounts_T51() public {
        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;

        vm.warp(51);

        // update all vault accounts
        vm.startPrank(owner);
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
        vm.stopPrank();
        
        // STORE vaultAccounts at T51
        updatedVaultAccounts_D0_T51[0] = getVaultAccount(vaultId1, 0);
        updatedVaultAccounts_D0_T51[1] = getVaultAccount(vaultId2, 0);
        updatedVaultAccounts_D1_T51[0] = getVaultAccount(vaultId1, 1);
        updatedVaultAccounts_D1_T51[1] = getVaultAccount(vaultId2, 1);
    }

    // transition fn
    function test_TimeIsFrozen() public {
        
        // update vaultAccounts at different times
        test_updateVaultAccounts_T46();
        test_updateVaultAccounts_T51();

        // vaultAccount state should be the same regardless when it is updated, as distributions are frozen
        // ---- D0: VAULTID 1 ----
        console.log("D0: VAULTID 1 | ENDED AT T42");
        
            // indexes
            assertEq(updatedVaultAccounts_D0_T46[0].index, updatedVaultAccounts_D0_T51[0].index);
            assertEq(updatedVaultAccounts_D0_T46[0].nftIndex, updatedVaultAccounts_D0_T51[0].nftIndex);
            assertEq(updatedVaultAccounts_D0_T46[0].rpIndex, updatedVaultAccounts_D0_T51[0].rpIndex);
            // rewards
            assertEq(updatedVaultAccounts_D0_T46[0].totalAccRewards, updatedVaultAccounts_D0_T51[0].totalAccRewards);
            assertEq(updatedVaultAccounts_D0_T46[0].accCreatorRewards, updatedVaultAccounts_D0_T51[0].accCreatorRewards);
            assertEq(updatedVaultAccounts_D0_T46[0].accNftStakingRewards, updatedVaultAccounts_D0_T51[0].accNftStakingRewards);
            assertEq(updatedVaultAccounts_D0_T46[0].accRealmPointsRewards, updatedVaultAccounts_D0_T51[0].accRealmPointsRewards);
            // rewards per unit staked
            assertEq(updatedVaultAccounts_D0_T46[0].rewardsAccPerUnitStaked, updatedVaultAccounts_D0_T51[0].rewardsAccPerUnitStaked);       
            // claimed rewards
            assertEq(updatedVaultAccounts_D0_T46[0].totalClaimedRewards, updatedVaultAccounts_D0_T51[0].totalClaimedRewards);

        // ---- D0: VAULTID 2 ----
        console.log("D0: VAULTID 2");
        
            // indexes
            assertEq(updatedVaultAccounts_D0_T46[1].index, updatedVaultAccounts_D0_T51[1].index);
            assertEq(updatedVaultAccounts_D0_T46[1].nftIndex, updatedVaultAccounts_D0_T51[1].nftIndex);
            assertEq(updatedVaultAccounts_D0_T46[1].rpIndex, updatedVaultAccounts_D0_T51[1].rpIndex);
            // rewards
            assertEq(updatedVaultAccounts_D0_T46[1].totalAccRewards, updatedVaultAccounts_D0_T51[1].totalAccRewards);
            assertEq(updatedVaultAccounts_D0_T46[1].accCreatorRewards, updatedVaultAccounts_D0_T51[1].accCreatorRewards);
            assertEq(updatedVaultAccounts_D0_T46[1].accNftStakingRewards, updatedVaultAccounts_D0_T51[1].accNftStakingRewards);
            assertEq(updatedVaultAccounts_D0_T46[1].accRealmPointsRewards, updatedVaultAccounts_D0_T51[1].accRealmPointsRewards);
            // rewards per unit staked
            assertEq(updatedVaultAccounts_D0_T46[1].rewardsAccPerUnitStaked, updatedVaultAccounts_D0_T51[1].rewardsAccPerUnitStaked);
            // claimed rewards
            assertEq(updatedVaultAccounts_D0_T46[1].totalClaimedRewards, updatedVaultAccounts_D0_T51[1].totalClaimedRewards);
        
        // ---- D1: VAULTID 1 ----
        console.log("D1: VAULTID 1");
        
            // indexes
            assertEq(updatedVaultAccounts_D1_T46[0].index, updatedVaultAccounts_D1_T51[0].index);
            assertEq(updatedVaultAccounts_D1_T46[0].nftIndex, updatedVaultAccounts_D1_T51[0].nftIndex);
            assertEq(updatedVaultAccounts_D1_T46[0].rpIndex, updatedVaultAccounts_D1_T51[0].rpIndex);
            // rewards
            assertEq(updatedVaultAccounts_D1_T46[0].totalAccRewards, updatedVaultAccounts_D1_T51[0].totalAccRewards);
            assertEq(updatedVaultAccounts_D1_T46[0].accCreatorRewards, updatedVaultAccounts_D1_T51[0].accCreatorRewards);
            assertEq(updatedVaultAccounts_D1_T46[0].accNftStakingRewards, updatedVaultAccounts_D1_T51[0].accNftStakingRewards);
            assertEq(updatedVaultAccounts_D1_T46[0].accRealmPointsRewards, updatedVaultAccounts_D1_T51[0].accRealmPointsRewards);
            // rewards per unit staked
            assertEq(updatedVaultAccounts_D1_T46[0].rewardsAccPerUnitStaked, updatedVaultAccounts_D1_T51[0].rewardsAccPerUnitStaked);
            // claimed rewards
            assertEq(updatedVaultAccounts_D1_T46[0].totalClaimedRewards, updatedVaultAccounts_D1_T51[0].totalClaimedRewards);

        // ---- D1: VAULTID 2 ----
        console.log("D1: VAULTID 2");
            // indexes
            assertEq(updatedVaultAccounts_D1_T46[1].index, updatedVaultAccounts_D1_T51[1].index);
            assertEq(updatedVaultAccounts_D1_T46[1].nftIndex, updatedVaultAccounts_D1_T51[1].nftIndex);
            assertEq(updatedVaultAccounts_D1_T46[1].rpIndex, updatedVaultAccounts_D1_T51[1].rpIndex);
            // rewards
            assertEq(updatedVaultAccounts_D1_T46[1].totalAccRewards, updatedVaultAccounts_D1_T51[1].totalAccRewards);
            assertEq(updatedVaultAccounts_D1_T46[1].accCreatorRewards, updatedVaultAccounts_D1_T51[1].accCreatorRewards);
            assertEq(updatedVaultAccounts_D1_T46[1].accNftStakingRewards, updatedVaultAccounts_D1_T51[1].accNftStakingRewards);
            assertEq(updatedVaultAccounts_D1_T46[1].accRealmPointsRewards, updatedVaultAccounts_D1_T51[1].accRealmPointsRewards);
            // rewards per unit staked
            assertEq(updatedVaultAccounts_D1_T46[1].rewardsAccPerUnitStaked, updatedVaultAccounts_D1_T51[1].rewardsAccPerUnitStaked);
            // claimed rewards
            assertEq(updatedVaultAccounts_D1_T46[1].totalClaimedRewards, updatedVaultAccounts_D1_T51[1].totalClaimedRewards);
    }   
}


abstract contract StateT51p_ResetRp_VaultsAndUsersUpdated is StateT46p_ResetRp_UpdateDistributions {
    
    // note: while data is captured at T51 - rewards are booked as per T46 [frozen state]
    // to reflect this accounts are labelled with T46
    //vault1
    DataTypes.VaultAccount vault1Account0_T46;
    DataTypes.VaultAccount vault1Account1_T46;
    //vault2
    DataTypes.VaultAccount vault2Account0_T46;
    DataTypes.VaultAccount vault2Account1_T46;
    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T46;
    DataTypes.UserAccount user1Vault1Account1_T46;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T46;
    DataTypes.UserAccount user2Vault1Account1_T46;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T46;
    DataTypes.UserAccount user1Vault2Account1_T46;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T46;
    DataTypes.UserAccount user2Vault2Account1_T46;


    function setUp() public virtual override {
        super.setUp();
        
        vm.warp(51);

        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;

        address[] memory userAddresses = new address[](2);
            userAddresses[0] = user1;
            userAddresses[1] = user2;

        vm.startPrank(operator);
            // all vaults for D0 & D1
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);

            // all user accounts for D0 + D1
            pool.updateAllUserAccounts(0, vaultId1, userAddresses);
            pool.updateAllUserAccounts(0, vaultId2, userAddresses);
            pool.updateAllUserAccounts(1, vaultId1, userAddresses);
            pool.updateAllUserAccounts(1, vaultId2, userAddresses);

        vm.stopPrank();

        // store UPDATED accounts [updated as T51, booked as per T46]
        vault1Account0_T46 = getVaultAccount(vaultId1, 0);
        vault1Account1_T46 = getVaultAccount(vaultId1, 1);  
        vault2Account0_T46 = getVaultAccount(vaultId2, 0);
        vault2Account1_T46 = getVaultAccount(vaultId2, 1);
        user1Vault1Account0_T46 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T46 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T46 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T46 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T46 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T46 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T46 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T46 = getUserAccount(user2, vaultId2, 1);
    }
}

// vaults and users updated at T51
contract StateT51p_ResetRp_VaultsAndUsersUpdated_Test is StateT51p_ResetRp_VaultsAndUsersUpdated {

    function testVault1_StateFrozenAtT46() public {
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        
        // Check base balances
        assertEq(vault1.stakedRealmPoints, user1Rp + user2Rp/2);
        assertEq(vault1.stakedTokens, user1Moca + user2Moca/2);
        assertEq(vault1.stakedNfts, 2);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault1.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault1.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault1.stakedTokens * boostFactor) / 10_000;
        
        assertEq(vault1.totalBoostFactor, 0);
        assertEq(vault1.boostedRealmPoints, 0);
        assertEq(vault1.boostedStakedTokens, 0);
    }

    function testVault2_StateFrozenAtT46() public {
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        
        // Check base balances
        assertEq(vault2.stakedRealmPoints, user2Rp/2);
        assertEq(vault2.stakedTokens, user2Moca/2);
        assertEq(vault2.stakedNfts, 2);

        // Check boosted values
        uint256 boostFactor = 10_000 + (vault2.stakedNfts * pool.NFT_MULTIPLIER());
        uint256 expectedBoostedRp = (vault2.stakedRealmPoints * boostFactor) / 10_000;
        uint256 expectedBoostedTokens = (vault2.stakedTokens * boostFactor) / 10_000;

        assertEq(vault2.totalBoostFactor, boostFactor);
        assertEq(vault2.boostedRealmPoints, expectedBoostedRp);
        assertEq(vault2.boostedStakedTokens, expectedBoostedTokens);
    }

// ---------------- distribution 0 ----------------


    // vault1 accounts updated at T46; lastUpdate at t36 
    function testVault1Account0_StateFrozenAtT46() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);
        
        /** T41 - T46
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */

        // vault assets 
        uint256 stakedRp = vault1_T41.stakedRealmPoints;  
        uint256 stakedTokens = vault1_T41.stakedTokens;
        uint256 stakedNfts = vault1_T41.stakedNfts;

        uint256 boostedRp = vault1_T41.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T41.boostedRealmPoints + vault2_T41.boostedRealmPoints;

        uint256 prevVaultIndex = vault1Account0_T41.index;

        // check indices

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedRp, distribution0_T46.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account0_T41.nftIndex;     // 4 nfts staked frm t31-t36
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account0_T41.rpIndex;

        // check indices
        assertLe(vaultAccount.index, distribution.index); // 46604501449702686 [4.66e16]
        assertLe(vaultAccount.nftIndex, latestNftIndex);       
        assertLe(vaultAccount.rpIndex, latestRpIndex);    

        // calc. accumulated rewards
        uint256 totalAccRewards = newlyAccRewards + vault1Account0_T41.totalAccRewards;
        // calc. accumulated fees
        uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account0_T41.accCreatorRewards;
        uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account0_T41.accNftStakingRewards;
        uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account0_T41.accRealmPointsRewards;

        // check accumulated rewards + fees
        assertLe(vaultAccount.totalAccRewards, totalAccRewards);
        assertLe(vaultAccount.accCreatorRewards, latestAccCreatorFee); 
        assertLe(vaultAccount.accNftStakingRewards, latestAccTotalNftFee); 
        assertLe(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee); 

        // rewardsAccPerUnitStaked: for moca stakers
        uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
        uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account0_T41.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked
        assertLe(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked); 
    }
    
    function testVault2Account0_StateFrozenAtT46() public {
        DataTypes.Distribution memory distribution = getDistribution(0);
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

        /** T41 - T42 (vault1 ends at T42)
            stakedTokens: user2Moca/2
            stakedRp: user2Rp/2
            stakedNfts: 2
         */

        // vault assets for t41-t42
        uint256 stakedRp = vault2_T41.stakedRealmPoints;  
        uint256 stakedTokens = vault2_T41.stakedTokens;
        uint256 stakedNfts = vault2_T41.stakedNfts;

        uint256 boostedRp = vault2_T41.boostedRealmPoints;
        uint256 poolBoostedRp = vault1_T41.boostedRealmPoints + vault2_T41.boostedRealmPoints;

        uint256 prevVaultIndex = vault2Account0_T41.index;

        // check indices

            // calc. newly accrued rewards - split between vault1 and vault2 for T41-T42 period | after that only vault2 earns     
            uint256 splitRewards = 1 ether;  
            uint256 newlyAccRewards = ((boostedRp * splitRewards) / poolBoostedRp) + ((46-42) * 1 ether);
            
            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T41.realmPointsFeeFactor / 10_000;

            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account0_T41.nftIndex;   
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account0_T41.rpIndex;

        // check indices - should only reflect updates until T42
        assertEq(vaultAccount.index, distribution.index);
        assertApproxEqAbs(vaultAccount.nftIndex, latestNftIndex, 36);       
        assertApproxEqAbs(vaultAccount.rpIndex, latestRpIndex, 1);  

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account0_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account0_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account0_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account0_T41.accRealmPointsRewards;

        // check accumulated rewards + fees - should only include rewards until T42
        assertApproxEqAbs(vaultAccount.totalAccRewards, totalAccRewards, 733);
        assertApproxEqAbs(vaultAccount.accCreatorRewards, latestAccCreatorFee, 36); 
        assertApproxEqAbs(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, 73); 
        assertApproxEqAbs(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, 36); 

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account0_T41.rewardsAccPerUnitStaked;

        // rewardsAccPerUnitStaked - should reflect only rewards until T42
        assertApproxEqAbs(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, 12); 

        // totalClaimedRewards: staking power cannot be claimed
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

    // --------------- d0:vault1:users --------------- 

        function testUser1_ForVault1Account0_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);  
            
            //--- user1+vault1 last updated at t36: consider the emissions from t36-t46
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account0_T41.index;
                uint256 prevNftIndex = user1Vault1Account0_T41.nftIndex;
                uint256 prevRpIndex = user1Vault1Account0_T41.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account0_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account0_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account0_T41.accRealmPointsRewards;

                // Calculate expected rewards for user2's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;
                
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch"); // 0
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");
        
            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state
        }

        // IGNORING USER2 - SHOULD BE THE SAME AS USER1

    // --------------- d0:vault2:users ---------------

        // user1 does not have any assets in vault2
        function testUser1_ForVault2Account0_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user1+vault2
            uint256 stakedRP = 0;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0; 

            // indexes should match btw user and vault accounts indicating update
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");
            
            // rewards should be 0 as user1 did not stake anything into vault2
            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

            // staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state

        }

        function testUser2_ForVault2Account0_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t31: consider the emissions from t31-t41
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account0_T41.index;
                uint256 prevNftIndex = user2Vault2Account0_T41.nftIndex;
                uint256 prevRpIndex = user2Vault2Account0_T41.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account0_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account0_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T41.accRealmPointsRewards;


                // Calculate expected rewards for user2's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;               
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: staking power cannot be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");    // user2: vault2 creator

            
            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state

        }

// ---------------- distribution 1 ----------------

    function testVault1Account1_StateFrozenAtT46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId1);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

        /** T41 - T46
            stakedTokens: user1Moca + user2Moca/2
            stakedRp: user1Rp + user2Rp/2 
            stakedNfts: 2
         */

        // vault assets: T41-T46
        uint256 stakedRp = user1Rp + user2Rp/2;  
        uint256 stakedTokens = user1Moca + user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault1Account1_T41.index;
        // boosted tokens
        uint256 boostedTokens = vault1_T41.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T41.boostedStakedTokens + vault2_T41.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T41.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T41.rpIndex;

        // Check indices match distribution
        assertLe(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertLe(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
        assertLe(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
    
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault1Account1_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T41.accRealmPointsRewards;

        // Check accumulated rewards
        assertLe(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
        assertLe(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
        assertLe(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
        assertLe(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T41.rewardsAccPerUnitStaked;

        // Check rewardsAccPerUnitStaked
        assertLe(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");
    }

    function testVault2Account1_StateFrozenAtT46() public {
        DataTypes.Distribution memory distribution = getDistribution(1);
        DataTypes.Vault memory vault = pool.getVault(vaultId2);

        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

        // vault assets: T41-T46
        uint256 stakedRp = user2Rp/2;  
        uint256 stakedTokens = user2Moca/2;
        uint256 stakedNfts = 2;
        // prev. vault index
        uint256 prevVaultIndex = vault2Account1_T41.index;
        // boosted tokens
        uint256 boostedTokens = vault2_T41.boostedStakedTokens;
        uint256 poolBoostedTokens = vault1_T41.boostedStakedTokens + vault2_T41.boostedStakedTokens; 

        // -------------- check indices --------------

            // calc. newly accrued rewards       
            uint256 splitRewards = 1 ether;  
            uint256 newlyAccRewards = ((boostedTokens * splitRewards) / poolBoostedTokens) + ((46-42) * 1 ether); 

            // newly accrued fees since last update: based on newlyAccRewards
            uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T41.creatorFeeFactor / 10_000;
            uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T41.nftFeeFactor / 10_000;         
            uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T41.realmPointsFeeFactor / 10_000;
            
            // latest indices
            uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account1_T41.nftIndex;     
            uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account1_T41.rpIndex;

        // Check indices match distribution at t41
        assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
        assertApproxEqAbs(vaultAccount.nftIndex, latestNftIndex, 36);
        assertApproxEqAbs(vaultAccount.rpIndex, latestRpIndex, 1);
        
        // -------------- check accumulated rewards --------------

            // calc. accumulated rewards
            uint256 totalAccRewards = newlyAccRewards + vault2Account1_T41.totalAccRewards;
            // calc. accumulated fees
            uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account1_T41.accCreatorRewards;
            uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account1_T41.accNftStakingRewards;
            uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account1_T41.accRealmPointsRewards;

        assertApproxEqAbs(vaultAccount.totalAccRewards, totalAccRewards, 733);
        assertApproxEqAbs(vaultAccount.accCreatorRewards, latestAccCreatorFee, 36);
        assertApproxEqAbs(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, 73); 
        assertApproxEqAbs(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, 36);
        
        // -------------- check rewardsAccPerUnitStaked --------------

            // rewardsAccPerUnitStaked: for moca stakers
            uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
            uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account1_T41.rewardsAccPerUnitStaked;

        assertApproxEqAbs(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, 12);

        // Check totalClaimedRewards
        assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
    }

    // --------------- d1:vault1:users ---------------
            
        function testUser1_ForVault1Account1_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);  
            
            //--- user1+vault1 last updated at t36: consider the emissions from t36-t46
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account1_T41.index;
                uint256 prevNftIndex = user1Vault1Account1_T41.nftIndex;
                uint256 prevRpIndex = user1Vault1Account1_T41.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account1_T41.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account1_T41.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account1_T41.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens 
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;
                
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch"); // 0
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");
        
            // Check claimed rewards: token rewards can be claimed
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");  //user1 is vault1 creator

            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state
        }

        // IGNORING USER2 - SHOULD BE THE SAME AS USER1


    // --------------- d1:vault2:users ---------------

        // user1 does not have any assets in vault2
        function testUser1_ForVault2Account1_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user1+vault2
            uint256 stakedRP = 0;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0; 

            // should show 0 for all values
            
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------
            
            // view fn: user1 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state

        }

        function testUser2_ForVault2Account1_StateFrozenAtT46() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 1);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            //--- user2+vault2 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2;
            uint256 numOfNfts = 2;

            // Check indices match vault@t51
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account1_T46.index;
                uint256 prevUserNftIndex = user2Vault2Account1_T46.nftIndex;
                uint256 prevUserRpIndex = user2Vault2Account1_T46.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account1_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account1_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account1_T46.accRealmPointsRewards;

                // Calculate expected rewards for user2's staked tokens
                uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;      
                // Calculate expected rewards for nft staking
                uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - prevUserNftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                // Calculate expected rewards for rp staking
                uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevUserRpIndex, 1E18) + prevAccRealmPointsRewards;
            
            // Check accumulated rewards
            assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch");
            assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

            // Check claimed rewards: token rewards are claimable
            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch"); // user2 is vault2 creator

            //--------------------------------
            
            // view fn: user2 gets their share of total rewards
            // cannot check view fns as they update distributions, overriding the frozen state

        }
        
// --------------- state transition: reset rp ---------------
    
    function testCannotResetTotalBoostedRp_BeforeResetRp() public {

        vm.startPrank(owner);
            vm.expectRevert(Errors.RpNotResetCorrectly.selector);
            pool.resetTotalBoostedRealmPoints();
        vm.stopPrank();
    }

    function testCannotIncrementSeason_BaseRpNotReset() public {
        vm.startPrank(owner);
            vm.expectRevert(Errors.RpNotResetCorrectly.selector);
            pool.incrementSeason();
        vm.stopPrank();
    }

    function testCannotResetBaseRealmPoints_InvalidArray() public {
        address[] memory userAddresses = new address[](0);

        vm.startPrank(owner);
            vm.expectRevert(Errors.InvalidArray.selector);
            pool.resetBaseRealmPoints(vaultId1, userAddresses);
        vm.stopPrank();
    }

    function testCannotResetBaseRealmPoints_NonExistentVault() public {
        bytes32 vaultId = bytes32(uint256(0));

        address[] memory userAddresses = new address[](1);
            userAddresses[0] = user1;

        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, vaultId));
            pool.resetBaseRealmPoints(vaultId, userAddresses);
        vm.stopPrank();
    }

    function testResetBaseRealmPoints_Vault1Ended() public {
        // Store before values
        uint256 beforeUser1RP = pool.getUser(user1, vaultId1).stakedRealmPoints;
        uint256 beforeUser1BoostedRP = beforeUser1RP * pool.getVault(vaultId1).totalBoostFactor / Constants.PRECISION_BASE;
        uint256 beforeVault1RP = pool.getVault(vaultId1).stakedRealmPoints;
        uint256 beforeVault1BoostedRP = pool.getVault(vaultId1).boostedRealmPoints;
        uint256 beforeTotalStakedRP = pool.totalStakedRealmPoints();
        uint256 beforeTotalBoostedRP = pool.totalBoostedRealmPoints();
        
        // Setup user addresses for reset
        address[] memory userAddresses = new address[](1);
            userAddresses[0] = user1;
        
        // Reset realm points
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true);
            emit BaseRealmPointsReset(vaultId1, userAddresses, beforeUser1RP);
        
            pool.resetBaseRealmPoints(vaultId1, userAddresses);
        vm.stopPrank();

        //Store After values
        uint256 afterUser1RP = pool.getUser(user1, vaultId1).stakedRealmPoints;
        uint256 afterVault1RP = pool.getVault(vaultId1).stakedRealmPoints;
        uint256 afterVault1BoostedRP = pool.getVault(vaultId1).boostedRealmPoints;
        uint256 afterTotalStakedRP = pool.totalStakedRealmPoints();
        uint256 afterTotalBoostedRP = pool.totalBoostedRealmPoints();

        
        // Check user values after reset
        assertEq(afterUser1RP, 0, "user1 stakedRP should be 0");

        // Check vault values after reset - only user1's RP should be decremented
        assertEq(afterVault1RP, beforeVault1RP - beforeUser1RP, "vault1 stakedRP should be decremented by user1's RP");
        
        // Check global base realm points are NOT decremented
        assertEq(afterTotalStakedRP, beforeTotalStakedRP, "totalStakedRealmPoints mismatch");
        

        // Check that boosted realm points are not affected
        assertEq(afterVault1BoostedRP, beforeVault1BoostedRP, "vault1 boostedStakedRP should be unchanged");
        assertEq(afterTotalBoostedRP, beforeTotalBoostedRP, "totalBoostedRealmPoints mismatch");
    }
}

abstract contract StateT51p_ResetRp_ResetBaseRp is StateT51p_ResetRp_VaultsAndUsersUpdated {

    function setUp() public virtual override {
        super.setUp();

        // userAddresses
        address[] memory userAddresses = new address[](2);
        userAddresses[0] = user1;
        userAddresses[1] = user2;

        // reset rp
        vm.startPrank(owner);
            pool.resetBaseRealmPoints(vaultId1, userAddresses);
            pool.resetBaseRealmPoints(vaultId2, userAddresses);
        vm.stopPrank();
    }
}

contract StateT51p_ResetRp_ResetBaseRp_Test is StateT51p_ResetRp_ResetBaseRp {

    function testCanIncrementSeason_IfGlobalRpZeroedOut() public {

        if(pool.totalStakedRealmPoints() == 0 && pool.totalBoostedRealmPoints() == 0) {
            uint256 beforeSeason = pool.CURRENT_SEASON();

            vm.startPrank(owner);
                vm.expectEmit(true, true, true, true);
                emit SeasonIncremented(beforeSeason + 1);

                pool.incrementSeason();
            vm.stopPrank();

            assertEq(pool.CURRENT_SEASON(), beforeSeason + 1, "Season should be incremented by 1");

        } else {
            vm.startPrank(owner);
                vm.expectRevert(Errors.RpNotResetCorrectly.selector);
                pool.incrementSeason();
            vm.stopPrank();
        }
    }

    // transition
    function testCanResetBoostedRp() public {
        // Assert global base RP values are 0
        assertEq(pool.totalStakedRealmPoints(), 0, "totalStakedRealmPoints should be 0");

        // totalBoostedRealmPoints may or may not be 0

        // reset boosted rp
        vm.startPrank(owner);
            pool.resetTotalBoostedRealmPoints();
        vm.stopPrank();

        // Check global boosted RP is 0
        assertEq(pool.totalBoostedRealmPoints(), 0, "totalBoostedRealmPoints should be 0");
        
        // Check individual vault boosted RP values are 0
        assertEq(pool.getVault(vaultId1).boostedRealmPoints, 0, "vault1 boostedRealmPoints should be 0");
        assertEq(pool.getVault(vaultId2).boostedRealmPoints, 0, "vault2 boostedRealmPoints should be 0");
    }

}


abstract contract StateT51p_ResetRp_ResetBoostedRp is StateT51p_ResetRp_ResetBaseRp {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);
            pool.resetTotalBoostedRealmPoints();
        vm.stopPrank();
    }
}

contract StateT51p_ResetRp_ResetBoostedRp_Test is StateT51p_ResetRp_ResetBoostedRp {

    // transition
    function testCanIncrementSeason() public {
        // Assert global RP values are 0
        assertEq(pool.totalStakedRealmPoints(), 0, "totalStakedRealmPoints should be 0");
        assertEq(pool.totalBoostedRealmPoints(), 0, "totalBoostedRealmPoints should be 0");
                
        // Store current season before incrementing
        uint256 beforeSeason = pool.CURRENT_SEASON();
        
        // Have owner increment season
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true);
            emit SeasonIncremented(beforeSeason + 1);
            
            pool.incrementSeason();
        vm.stopPrank();
        
        // Check that season was incremented correctly
        uint256 afterSeason = pool.CURRENT_SEASON();
        assertEq(afterSeason, beforeSeason + 1, "Season should be incremented by 1");
    }
}

abstract contract StateT51p_ResetRp_IncrementSeason is StateT51p_ResetRp_ResetBoostedRp {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);
            pool.incrementSeason();
            pool.disableMaintenance();
        vm.stopPrank();
    }
}

contract StateT51p_ResetRp_IncrementSeason_Test is StateT51p_ResetRp_IncrementSeason {

    // transition
    function testCannotStakeRpWithPriorSeasonSignature() public {
        // Create a signature from the previous season
        uint256 expiry = block.timestamp + 1 days;
        uint256 previousSeason = pool.CURRENT_SEASON() - 1;
        uint256 nonce = pool.userNonces(user1);
        bytes memory signature = generateSignature(user1, vaultId1, user1Rp/2, expiry, previousSeason, nonce);

        // Attempt to stake RP with signature from previous season - should revert
        vm.startPrank(user1);

            vm.expectRevert(Errors.InvalidSignature.selector);
            pool.stakeRealmPoints(vaultId1, user1Rp/2, expiry, signature);

        vm.stopPrank();
        
        // Assert global RP values remain 0
        assertEq(pool.totalStakedRealmPoints(), 0, "totalStakedRealmPoints should be 0");
        assertEq(pool.totalBoostedRealmPoints(), 0, "totalBoostedRealmPoints should be 0");
    }
}