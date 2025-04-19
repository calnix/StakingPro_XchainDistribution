// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT16.t.sol";


//note: creation nfts updated at t21 | distribution_1 starts at t21
abstract contract StateT21_CreationNftsUpdated is StateT16_BothUsersStakeAgain {

    // for reference
    DataTypes.Distribution distribution0_T21;
    DataTypes.Distribution distribution1_T21;

    DataTypes.VaultAccount vault1Account0_T21;
    DataTypes.VaultAccount vault1Account1_T21;

    DataTypes.UserAccount user1Account0_T21;
    DataTypes.UserAccount user2Account0_T21;

    function setUp() public virtual override {
        super.setUp();

        // T16   
        vm.warp(21);
    
        // operator updates CREATION_NFTS_REQUIRED
        vm.startPrank(operator);
            pool.updateCreationNfts(1);
        vm.stopPrank();

        // save state
        distribution0_T21 = getDistribution(0);
        distribution1_T21 = getDistribution(1);
        vault1Account0_T21 = getVaultAccount(vaultId1, 0);
        vault1Account1_T21 = getVaultAccount(vaultId1, 1);
        user1Account0_T21 = getUserAccount(user1, vaultId1, 0);
        user2Account0_T21 = getUserAccount(user2, vaultId1, 0);
    }
}

contract StateT21_CreationNftsUpdatedTest is StateT21_CreationNftsUpdated {
    
    /**
     NOTE: distribution 1 started
     but no state update done for vaults, users, distributions

     todo: view fns calculate the correct pending rewards
     */
    
    function testUser2CannotReuseCreationNfts() public {
        vm.startPrank(user2);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = user2NftsArray[0];  

            vm.expectRevert(abi.encodeWithSelector(NftRegistry.NftIsStaked.selector));
            pool.createVault(tokenIds, 1000, 500, 500);
        vm.stopPrank();
    }

    // can create vault w/ update limit
    function testUser2CreatesVault() public {
        bytes32 vaultId2 = generateVaultId(block.number - 1, user2);

        // user2 creates vault
        vm.startPrank(user2);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = user2NftsArray[4];    //5th nft
            uint256 nftFeeFactor = 1000;
            uint256 creatorFeeFactor = 500;
            uint256 realmPointsFeeFactor = 500;
            
            vm.expectEmit(true, true, true, true);
            emit VaultCreated(vaultId2, user2, creatorFeeFactor, nftFeeFactor, realmPointsFeeFactor);

            pool.createVault(tokenIds, creatorFeeFactor, nftFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();
        // check vault
        DataTypes.Vault memory vault = pool.getVault(vaultId2);
        
        // creator
        assertEq(vault.creator, user2);
        
        // creation nfts
        assertEq(vault.creationTokenIds.length, 1);
        assertEq(vault.creationTokenIds[0], user2NftsArray[4]);
        
        // timing
        assertEq(vault.startTime, 21);
        assertEq(vault.endTime, 0);
        assertEq(vault.removed, 0);
        
        // fees
        assertEq(vault.nftFeeFactor, nftFeeFactor);
        assertEq(vault.creatorFeeFactor, creatorFeeFactor);
        assertEq(vault.realmPointsFeeFactor, realmPointsFeeFactor);
        
        // staked assets (should be 0 initially)
        assertEq(vault.stakedNfts, 0);
        assertEq(vault.stakedTokens, 0); 
        assertEq(vault.stakedRealmPoints, 0);
        
        // boost factors (should start at base precision)
        assertEq(vault.totalBoostFactor, Constants.PRECISION_BASE);
        assertEq(vault.boostedRealmPoints, 0);
        assertEq(vault.boostedStakedTokens, 0);
    }
}