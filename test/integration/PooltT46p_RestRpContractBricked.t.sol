// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT46p_ResetRp.t.sol";

/**
    Only vault1 is reset, vault2 is not reset
    Then proceed to call updateActiveDistributions
    This simulates a scenario where the contract is bricked
    The only solution is to redeploy the contract
 */

abstract contract StateT51p_ResetRp_PartialReset is StateT51p_ResetRp_VaultsAndUsersUpdated {
    
    DataTypes.VaultAccount[2] public updatedVaultAccounts_D0_T51;
    DataTypes.VaultAccount[2] public updatedVaultAccounts_D0_T56;
    
    function setUp() public virtual override {
        super.setUp();

        // userAddresses
        address[] memory userAddresses = new address[](2);
        userAddresses[0] = user1;
        userAddresses[1] = user2;

        // reset rp
        vm.startPrank(owner);
            // partial reset
            pool.resetBaseRealmPoints(vaultId1, userAddresses);
            //pool.resetBaseRealmPoints(vaultId2, userAddresses);
            //pool.resetTotalBoostedRealmPoints();

            // incorrect midway update
            pool.updateActiveDistributions();

            // continue as per normal
            // pool.incrementSeason(); // cannot increment season as RP was partially reset
            pool.disableMaintenance();
        vm.stopPrank();

        // store vault accounts at T51
        (updatedVaultAccounts_D0_T51[0], ) = pool.getUpdatedVaultAccount(vaultId1, 0);
        (updatedVaultAccounts_D0_T51[1], ) = pool.getUpdatedVaultAccount(vaultId2, 0);

        // advance time to allow for emissions
        vm.warp(block.timestamp + 5);

        // store vault accounts at T56
        (updatedVaultAccounts_D0_T56[0], ) = pool.getUpdatedVaultAccount(vaultId1, 0);
        (updatedVaultAccounts_D0_T56[1], ) = pool.getUpdatedVaultAccount(vaultId2, 0);
    }
}



// vault1 had its RP reset and will earn no emissions from D0
// however, vault2 will continue to earn emissions from D0
// this reflects the fact that the contract is bricked
contract StateT51p_ResetRp_PartialReset_Test is StateT51p_ResetRp_PartialReset {

    function test_ContractBricked_MustRedeploy() public {
        DataTypes.Distribution memory d0 = pool.getUpdatedDistribution(0);

        // ..... Check vault1's D0 account remains unchanged between T51 and T56 .....
        // vault index are incremented as expected
        assertEq(updatedVaultAccounts_D0_T56[0].index, d0.index, "Vault1 index should match D0 index at T56");
        assertGt(updatedVaultAccounts_D0_T56[0].index, updatedVaultAccounts_D0_T51[0].index, "Vault1 index should increase between T51 and T56");
        // nft and rp indexes are unchanged
        assertEq(updatedVaultAccounts_D0_T56[0].nftIndex, updatedVaultAccounts_D0_T51[0].nftIndex, "Vault1 NFT index should not change");
        assertEq(updatedVaultAccounts_D0_T56[0].rpIndex, updatedVaultAccounts_D0_T51[0].rpIndex, "Vault1 RP index should not change");
        // rewards are equal as no emissions were earned
        assertEq(updatedVaultAccounts_D0_T51[0].totalAccRewards, updatedVaultAccounts_D0_T56[0].totalAccRewards, "Vault1 should not earn rewards");
        assertEq(updatedVaultAccounts_D0_T51[0].accCreatorRewards, updatedVaultAccounts_D0_T56[0].accCreatorRewards, "Vault1 should not earn creator rewards");
        assertEq(updatedVaultAccounts_D0_T51[0].accNftStakingRewards, updatedVaultAccounts_D0_T56[0].accNftStakingRewards, "Vault1 should not earn NFT rewards");
        assertEq(updatedVaultAccounts_D0_T51[0].accRealmPointsRewards, updatedVaultAccounts_D0_T56[0].accRealmPointsRewards, "Vault1 should not earn RP rewards");

        

        // ..... Check vault2's D0 account earns all emissions between T51 and T56 .....
            // indexes
            assertEq(updatedVaultAccounts_D0_T56[1].index, d0.index, "Vault2 index should match D0 index at T56");
            assertGt(updatedVaultAccounts_D0_T56[1].index, updatedVaultAccounts_D0_T51[1].index, "Vault2 index should increase between T51 and T56");
            
            assertGt(updatedVaultAccounts_D0_T56[1].nftIndex, updatedVaultAccounts_D0_T51[1].nftIndex, "Vault2 NFT index should not change");
            assertGt(updatedVaultAccounts_D0_T56[1].rpIndex, updatedVaultAccounts_D0_T51[1].rpIndex, "Vault2 RP index should increase between T51 and T56");

        assertGt(updatedVaultAccounts_D0_T56[1].totalAccRewards, updatedVaultAccounts_D0_T51[1].totalAccRewards, "Vault2 should earn total rewards");
        assertGt(updatedVaultAccounts_D0_T56[1].accCreatorRewards, updatedVaultAccounts_D0_T51[1].accCreatorRewards, "Vault2 should earn creator rewards");
        assertGt(updatedVaultAccounts_D0_T56[1].accNftStakingRewards, updatedVaultAccounts_D0_T51[1].accNftStakingRewards, "Vault2 should earn NFT rewards");
        assertGt(updatedVaultAccounts_D0_T56[1].accRealmPointsRewards, updatedVaultAccounts_D0_T51[1].accRealmPointsRewards, "Vault2 should earn RP rewards");
    }
}

