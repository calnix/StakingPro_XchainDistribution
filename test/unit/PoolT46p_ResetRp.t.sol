// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

    /**    
        1. enableMaintenance
        2. updateActiveDistributions -- all active distributions
        3. updateAllVaultAccounts -- all vaults w/ rp
        4. updateAllUserAccounts -- book rp related fees before resetting
        5. resetRealmPoints
        6. incrementSeason
        7. disableMaintenance
     */

abstract contract StateT46p_ResetRp_UpdateDistributions is StateT41_User2StakesToVault2 {

    function setUp() public virtual override {
        super.setUp();

        // set t46p
        vm.warp(46);

        // vaults
        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;

        vm.startPrank(owner);
            pool.enableMaintenance();
            pool.updateActiveDistributions();

        vm.stopPrank();
    }
}

// time is frozen at T46 - distribution state saved
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
    }

    // transition fn
    function test_TimeIsFrozen() public {
        // vaultAccount state should be the same regardless when it is updated, as distributions are frozen
        
        // ---- D0: VAULTID 1 ----

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


    //user1+vault1
    DataTypes.UserAccount user1Vault1Account0_T51;
    DataTypes.UserAccount user1Vault1Account1_T51;
    //user2+vault1
    DataTypes.UserAccount user2Vault1Account0_T51;
    DataTypes.UserAccount user2Vault1Account1_T51;
    //user1+vault2
    DataTypes.UserAccount user1Vault2Account0_T51;
    DataTypes.UserAccount user1Vault2Account1_T51;
    //user2+vault2
    DataTypes.UserAccount user2Vault2Account0_T51;
    DataTypes.UserAccount user2Vault2Account1_T51;


    function setUp() public virtual override {
        super.setUp();

        // STORE userAccounts at T46
        user1Vault1Account0_T46 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T46 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T46 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T46 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T46 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T46 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T46 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T46 = getUserAccount(user2, vaultId2, 1);

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

        // STORE userAccounts at T51
        user1Vault1Account0_T51 = getUserAccount(user1, vaultId1, 0);
        user1Vault1Account1_T51 = getUserAccount(user1, vaultId1, 1);
        user2Vault1Account0_T51 = getUserAccount(user2, vaultId1, 0);
        user2Vault1Account1_T51 = getUserAccount(user2, vaultId1, 1);
        user1Vault2Account0_T51 = getUserAccount(user1, vaultId2, 0);
        user1Vault2Account1_T51 = getUserAccount(user1, vaultId2, 1);
        user2Vault2Account0_T51 = getUserAccount(user2, vaultId2, 0);
        user2Vault2Account1_T51 = getUserAccount(user2, vaultId2, 1);
    }
}

// vaults and users updated at T51
contract StateT51p_ResetRp_VaultsAndUsersUpdated_Test is StateT51p_ResetRp_VaultsAndUsersUpdated {

    // ---------------- distribution 0 ----------------

    // --------------- d0:vault1:users --------------- 

/*        function testUser1_ForVault1Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 0);  
            
            //--- user1+vault1 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user1Rp;
            uint256 stakedTokens = user1Moca;
            uint256 numOfNfts = 0; 

            // check indices match vault@t51
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // check accumulated rewards
                uint256 prevUserIndex = user1Vault1Account0_T46.index;
                uint256 prevNftIndex = user1Vault1Account0_T46.nftIndex;
                uint256 prevRpIndex = user1Vault1Account0_T46.rpIndex;
                uint256 prevAccStakingRewards = user1Vault1Account0_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user1Vault1Account0_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user1Vault1Account0_T46.accRealmPointsRewards;

                // Calculate expected rewards for user1's staked tokens 
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
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 0);
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

        // IGNORING USER2 - SHOULD BE THE SAME AS USER1

    // --------------- d0:vault2:user2 ---------------

        // user1 does not have any assets in vault2
        function testUser1_ForVault2Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user1+vault2
            uint256 stakedRP = 0;
            uint256 stakedTokens = 0;
            uint256 numOfNfts = 0; 

            // should show 0 for all values
            
            assertEq(userAccount.index, 0, "userIndex mismatch");
            assertEq(userAccount.nftIndex, 0, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, 0, "rpIndex mismatch");

            assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
            assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
            assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

            assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
            assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
            assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
            assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

            //--------------------------------

            // view fn: user1 gets their share of total rewards
            uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId2, 0);          
            uint256 expectedClaimableRewards = 0;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

        function testUser2_ForVault2Account0_T51() public {
            DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId2, 0);
            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 0);

            //--- user2+vault2 last updated at t46: consider the emissions from t46-t51
            uint256 stakedRP = user2Rp/2;
            uint256 stakedTokens = user2Moca/2; 
            uint256 numOfNfts = 2; 

            // Check indices match vault@t46
            assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
            assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
            assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

            // Check accumulated rewards
                uint256 prevUserIndex = user2Vault2Account0_T46.index;
                uint256 prevNftIndex = user2Vault2Account0_T46.nftIndex;
                uint256 prevRpIndex = user2Vault2Account0_T46.rpIndex;
                uint256 prevAccStakingRewards = user2Vault2Account0_T46.accStakingRewards;
                uint256 prevAccNftStakingRewards = user2Vault2Account0_T46.accNftStakingRewards;
                uint256 prevAccRealmPointsRewards = user2Vault2Account0_T46.accRealmPointsRewards;


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
            uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 0);
            
            uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
            if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

            assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
        }

        // updated at T51; lastUpdated at T46
        function testVault1Account1_T51() public {
            DataTypes.Distribution memory distribution = getDistribution(1);
            DataTypes.Vault memory vault = pool.getVault(vaultId1);

            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);        

            /** T46 - T51
                stakedTokens: user1Moca + user2Moca/2
                stakedRp: user1Rp + user2Rp/2 
                stakedNfts: 2
            */
/*
            // vault assets: T46-T51
            uint256 stakedRp = user1Rp + user2Rp/2;  
            uint256 stakedTokens = user1Moca + user2Moca/2;
            uint256 stakedNfts = 2;
            // prev. vault index
            uint256 prevVaultIndex = vault1Account1_T46.index;
            // boosted tokens
            uint256 boostedTokens = vault1_T46.boostedStakedTokens;
            uint256 poolBoostedTokens = vault1_T46.boostedStakedTokens + vault2_T46.boostedStakedTokens; 

            // -------------- check indices --------------

                // calc. newly accrued rewards       
                uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

                // newly accrued fees since last update: based on newlyAccRewards
                uint256 newlyAccCreatorFee = newlyAccRewards * vault1_T46.creatorFeeFactor / 10_000;
                uint256 newlyAccTotalNftFee = newlyAccRewards * vault1_T46.nftFeeFactor / 10_000;         
                uint256 newlyAccRealmPointsFee = newlyAccRewards * vault1_T46.realmPointsFeeFactor / 10_000;
                
                // latest indices
                uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault1Account1_T46.nftIndex;     
                uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault1Account1_T46.rpIndex;

            // Check indices match distribution
            assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
            assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
            assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
        
            // -------------- check accumulated rewards --------------

                // calc. accumulated rewards
                uint256 totalAccRewards = newlyAccRewards + vault1Account1_T46.totalAccRewards;
                // calc. accumulated fees
                uint256 latestAccCreatorFee = newlyAccCreatorFee + vault1Account1_T46.accCreatorRewards;
                uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault1Account1_T46.accNftStakingRewards;
                uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault1Account1_T46.accRealmPointsRewards;

            // Check accumulated rewards
            assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
            assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
            assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
            assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");

            // -------------- check rewardsAccPerUnitStaked --------------

                // rewardsAccPerUnitStaked: for moca stakers
                uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
                uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault1Account1_T46.rewardsAccPerUnitStaked;

            // Check rewardsAccPerUnitStaked
            assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

            // Check totalClaimedRewards
            assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
        }

        // updated at T51; lastUpdated at T46
        function testVault2Account1_T51() public {
            DataTypes.Distribution memory distribution = getDistribution(1);
            DataTypes.Vault memory vault = pool.getVault(vaultId2);

            DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

            // vault assets: T46-T51
            uint256 stakedRp = user2Rp/2;  
            uint256 stakedTokens = user2Moca/2;
            uint256 stakedNfts = 2;
            // prev. vault index
            uint256 prevVaultIndex = vault2Account1_T46.index;
            // boosted tokens
            uint256 boostedTokens = vault2_T46.boostedStakedTokens;
            uint256 poolBoostedTokens = vault1_T46.boostedStakedTokens + vault2_T46.boostedStakedTokens; 

            // -------------- check indices --------------

                // calc. newly accrued rewards       
                uint256 newlyAccRewards = calculateRewards(boostedTokens, distribution.index, prevVaultIndex, 1E18); 

                // newly accrued fees since last update: based on newlyAccRewards
                uint256 newlyAccCreatorFee = newlyAccRewards * vault2_T46.creatorFeeFactor / 10_000;
                uint256 newlyAccTotalNftFee = newlyAccRewards * vault2_T46.nftFeeFactor / 10_000;         
                uint256 newlyAccRealmPointsFee = newlyAccRewards * vault2_T46.realmPointsFeeFactor / 10_000;
                
                // latest indices
                uint256 latestNftIndex = (newlyAccTotalNftFee / stakedNfts) + vault2Account1_T46.nftIndex;     
                uint256 latestRpIndex = (newlyAccRealmPointsFee * 1E18 / stakedRp) + vault2Account1_T46.rpIndex;

            // Check indices match distribution at t41
            assertEq(vaultAccount.index, distribution.index, "vaultAccount index mismatch");
            assertEq(vaultAccount.nftIndex, latestNftIndex, "vaultAccount nftIndex mismatch");
            assertEq(vaultAccount.rpIndex, latestRpIndex, "vaultAccount rpIndex mismatch");
            
            // -------------- check accumulated rewards --------------

                // calc. accumulated rewards
                uint256 totalAccRewards = newlyAccRewards + vault2Account1_T46.totalAccRewards;
                // calc. accumulated fees
                uint256 latestAccCreatorFee = newlyAccCreatorFee + vault2Account1_T46.accCreatorRewards;
                uint256 latestAccTotalNftFee = newlyAccTotalNftFee + vault2Account1_T46.accNftStakingRewards;
                uint256 latestAccRealmPointsFee = newlyAccRealmPointsFee + vault2Account1_T46.accRealmPointsRewards;

            assertEq(vaultAccount.totalAccRewards, totalAccRewards, "totalAccRewards mismatch");
            assertEq(vaultAccount.accCreatorRewards, latestAccCreatorFee, "accCreatorRewards mismatch");
            assertEq(vaultAccount.accNftStakingRewards, latestAccTotalNftFee, "accNftStakingRewards mismatch"); 
            assertEq(vaultAccount.accRealmPointsRewards, latestAccRealmPointsFee, "accRealmPointsRewards mismatch");
            
            // -------------- check rewardsAccPerUnitStaked --------------

                // rewardsAccPerUnitStaked: for moca stakers
                uint256 latestAccRewardsLessOfFees = newlyAccRewards - newlyAccCreatorFee - newlyAccTotalNftFee - newlyAccRealmPointsFee;
                uint256 expectedRewardsAccPerUnitStaked = (latestAccRewardsLessOfFees * 1E18 / stakedTokens) + vault2Account1_T46.rewardsAccPerUnitStaked;

            assertEq(vaultAccount.rewardsAccPerUnitStaked, expectedRewardsAccPerUnitStaked, "rewardsAccPerUnitStaked mismatch");

            // Check totalClaimedRewards
            assertEq(vaultAccount.totalClaimedRewards, 0, "totalClaimedRewards mismatch");
        }
    // ---------------- distribution 1 ----------------

        //    function testDistribution1_T51() public {
        //    function testVault1Account1_T51() public {
        //    function testVault2Account1_T51() public {
/*
    // --------------- d1:vault1:users ---------------
            
            // updated at T51; lastUpdated at T46
            function testUser1_ForVault1Account1_T51() public {
                DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId1, 1);
                DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);  
                
                //--- user1+vault1 last updated at t46: consider the emissions from t46-t51
                uint256 stakedRP = user1Rp;
                uint256 stakedTokens = user1Moca;
                uint256 numOfNfts = 0; 

                // check indices match vault@t46
                assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
                assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
                assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

                // check accumulated rewards
                    uint256 prevUserIndex = user1Vault1Account1_T46.index;
                    uint256 prevNftIndex = user1Vault1Account1_T46.nftIndex;
                    uint256 prevRpIndex = user1Vault1Account1_T46.rpIndex;
                    uint256 prevAccStakingRewards = user1Vault1Account1_T46.accStakingRewards;
                    uint256 prevAccNftStakingRewards = user1Vault1Account1_T46.accNftStakingRewards;
                    uint256 prevAccRealmPointsRewards = user1Vault1Account1_T46.accRealmPointsRewards;

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
                uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId1, 1);
                
                uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
                if (user1 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

                assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
            }

            // stale: user2's account was last updated at t36
            /*function testUser2_ForVault1Account1_T51() public {
                DataTypes.UserAccount memory userAccount = getUserAccount(user2, vaultId1, 1);
                DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId1, 1);

                //--- user2+vault1: last updated at t41
                uint256 stakedRP = user2Rp/2;
                uint256 stakedTokens = user2Moca/2; 
                uint256 numOfNfts = 2; 

                // Check indices match vault@t46
                assertEq(userAccount.index, vaultAccount.rewardsAccPerUnitStaked, "userIndex mismatch");
                assertEq(userAccount.nftIndex, vaultAccount.nftIndex, "nftIndex mismatch");
                assertEq(userAccount.rpIndex, vaultAccount.rpIndex, "rpIndex mismatch");

                // Check accumulated rewards

                    // Calculate expected rewards for user2's staked tokens 
                    uint256 prevUserIndex = user2Account1_T41.index;
                    uint256 prevAccStakingRewards = user2Account1_T41.accStakingRewards;
                    uint256 latestAccStakingRewards = calculateRewards(stakedTokens, vaultAccount.rewardsAccPerUnitStaked, prevUserIndex, 1E18) + prevAccStakingRewards;     

                    // Calculate expected rewards for nft staking
                    uint256 prevAccNftStakingRewards = user2Account1_T41.accNftStakingRewards;
                    uint256 latestAccNftStakingRewards = ((vaultAccount.nftIndex - user2Account1_T41.nftIndex) * numOfNfts) + prevAccNftStakingRewards; 
                    // Calculate expected rewards for rp staking
                    uint256 prevRpIndex = user2Account1_T41.rpIndex;
                    uint256 prevAccRealmPointsRewards = user2Account1_T41.accRealmPointsRewards;
                    uint256 latestAccRealmPointsRewards = calculateRewards(stakedRP, vaultAccount.rpIndex, prevRpIndex, 1E18) + prevAccRealmPointsRewards;

                assertEq(userAccount.accStakingRewards, latestAccStakingRewards, "accStakingRewards mismatch"); 
                assertEq(userAccount.accNftStakingRewards, latestAccNftStakingRewards, "accNftStakingRewards mismatch");
                assertEq(userAccount.accRealmPointsRewards, latestAccRealmPointsRewards, "accRealmPointsRewards mismatch");

                // Check claimed rewards: staking power cannot be claimed
                assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
                assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
                assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
                assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");   //user 2 did not create vault1

                
                //--------------------------------
                
                // view fn: user1 gets their share of total rewards
                uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId1, 1);
                
                uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
                if (user2 == pool.getVault(vaultId1).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

                assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
            }*/
/*            
    // --------------- d1:vault2:users ---------------

            // user1 does not have any assets in vault2
            function testUser1_ForVault2Account1_T51() public {
                DataTypes.UserAccount memory userAccount = getUserAccount(user1, vaultId2, 1);
                DataTypes.VaultAccount memory vaultAccount = getVaultAccount(vaultId2, 1);

                //--- user1+vault2
                uint256 stakedRP = 0;
                uint256 stakedTokens = 0;
                uint256 numOfNfts = 0; 

                // should show 0 for all values
                
                assertEq(userAccount.index, 0, "userIndex mismatch");
                assertEq(userAccount.nftIndex, 0, "nftIndex mismatch");
                assertEq(userAccount.rpIndex, 0, "rpIndex mismatch");

                assertEq(userAccount.accStakingRewards, 0, "accStakingRewards mismatch"); 
                assertEq(userAccount.accNftStakingRewards, 0, "accNftStakingRewards mismatch");
                assertEq(userAccount.accRealmPointsRewards, 0, "accRealmPointsRewards mismatch");

                assertEq(userAccount.claimedStakingRewards, 0, "claimedStakingRewards mismatch");
                assertEq(userAccount.claimedNftRewards, 0, "claimedNftRewards mismatch");
                assertEq(userAccount.claimedRealmPointsRewards, 0, "claimedRealmPointsRewards mismatch");
                assertEq(userAccount.claimedCreatorRewards, 0, "claimedCreatorRewards mismatch");

                //--------------------------------
                
                // view fn: user1 gets their share of total rewards
                uint256 claimableRewards = pool.getClaimableRewards(user1, vaultId2, 1);           
                assertEq(claimableRewards, 0, "claimableRewards mismatch"); 
            }

            function testUser2_ForVault2Account1_T51() public {
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
                uint256 claimableRewards = pool.getClaimableRewards(user2, vaultId2, 1);
                
                uint256 expectedClaimableRewards = latestAccStakingRewards + latestAccNftStakingRewards + latestAccRealmPointsRewards;
                if (user2 == pool.getVault(vaultId2).creator) expectedClaimableRewards += vaultAccount.accCreatorRewards;

                assertEq(claimableRewards, expectedClaimableRewards, "claimableRewards mismatch"); 
            }
        */
    // --------------- state transition  ---------------

    // --------------- reset rp ---------------
    function testResetBaseRealmPoints_T51() public {
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
        
        // Check global base realm points are decremented
        assertEq(afterTotalStakedRP, beforeTotalStakedRP - beforeUser1RP, "totalStakedRealmPoints mismatch");
        

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


    function testCanResetBoostedRp_T51() public {
        // Assert global base RP values are 0
        assertEq(pool.totalStakedRealmPoints(), 0, "totalStakedRealmPoints should be 0");
        
        bytes32[] memory vaultIds = new bytes32[](2);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;
            
        // reset boosted rp
        vm.startPrank(owner);
            pool.resetBoostedRealmPoints(vaultIds);
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

        bytes32[] memory vaultIds = new bytes32[](2);
        vaultIds[0] = vaultId1;
        vaultIds[1] = vaultId2;
        

        vm.startPrank(owner);
            pool.resetBoostedRealmPoints(vaultIds);
        vm.stopPrank();
    }
}

contract StateT51p_ResetRp_ResetBoostedRp_Test is StateT51p_ResetRp_ResetBoostedRp {

    // transition
    function testCanIncrementRpAfterResetRp() public {
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

abstract contract StateT51p_ResetRp_IncrementSeason is StateT51p_ResetRp_ResetBoostedRp_Test {

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
        uint256 nonce = 1;
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

    function testCanStakeRpWithCurrentSeasonSignature() public {
        // Create a signature with the current season
        uint256 expiry = block.timestamp + 1 days;
        uint256 currentSeason = pool.CURRENT_SEASON();
        uint256 nonce = 1;
        bytes memory signature = generateSignature(user1, vaultId1, user1Rp/2, expiry, currentSeason, nonce);

        // Get initial state
        DataTypes.Vault memory vaultBefore = pool.getVault(vaultId1);
        uint256 initialStakedPoints = vaultBefore.stakedRealmPoints;

        // Calculate boosted amount
        uint256 boostedAmount = (user1Rp/2 * vaultBefore.totalBoostFactor) / 10000;

        // Expect event with boosted amount
        vm.expectEmit(true, true, true, true);
        emit StakedRealmPoints(user1, vaultId1, user1Rp/2, boostedAmount);

        // Stake realm points with current season signature
        vm.startPrank(user1);
            pool.stakeRealmPoints(vaultId1, user1Rp/2, expiry, signature);
        vm.stopPrank();

        // Verify state changes
        DataTypes.Vault memory vaultAfter = pool.getVault(vaultId1);
        assertEq(vaultAfter.stakedRealmPoints, initialStakedPoints + user1Rp/2, "Staked realm points should increase");
        assertEq(vaultAfter.boostedRealmPoints, boostedAmount, "Boosted realm points should match calculated amount");
        
        // Assert global RP values updated correctly
        assertEq(pool.totalStakedRealmPoints(), user1Rp/2, "totalStakedRealmPoints should match staked amount");
        assertEq(pool.totalBoostedRealmPoints(), boostedAmount, "totalBoostedRealmPoints should match boosted amount");
    }
}
