// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

/**
    T46p: new vault gets nothing

    - new vault created
    - end distribution 1
    - go into maintenance
    - call updateAllUserAccounts()

    For a vault that starts after a distribution ends, updateAllUserAccounts() reverts.
 */

abstract contract StateT41_EndDistribution is StateT41_User2StakesToVault2 {

    bytes32 public newVaultId;

    function setUp() public virtual override {
        super.setUp();

        // create new vault
        vm.startPrank(owner);
            // no nft limit
            pool.updateCreationNfts(0);
            
            pool.createVault(new uint256[](0), 0, 0, 0);
            newVaultId = generateVaultId(block.number - 1, owner);
        vm.stopPrank();

        // end distribution 1
        vm.startPrank(operator);
            pool.endDistributionManually(1);
        vm.stopPrank();

        bytes32[] memory vaultIds = new bytes32[](3);
            vaultIds[0] = vaultId1;
            vaultIds[1] = vaultId2;
            vaultIds[2] = newVaultId;

        // go into maintenance
        vm.startPrank(owner);
            pool.enableMaintenance();

            // update distributions
            pool.updateActiveDistributions();

            // update all vault accounts
            pool.updateAllVaultAccounts(vaultIds, 0);
            pool.updateAllVaultAccounts(vaultIds, 1);
        vm.stopPrank();
    }
}

contract StateT41_EndDistributionTest is StateT41_EndDistribution {

    // check for: if(distribution.endTime > 0) { if(vault.startTime >= distribution.endTime) continue; }
    function testNewVaultGetsNothing_UpdateAllVaultAccounts_D1_T46p() public {
        uint256 distributionId = 1;

        // Check that newVault does not get any rewards and vaultAccount.index is still 0
        DataTypes.Vault memory newVault = pool.getVault(newVaultId);
        DataTypes.VaultAccount memory vaultAccount = getVaultAccount(newVaultId, distributionId);

        assertEq(vaultAccount.index, 0, "VaultAccount index should be 0 for new vault");
        assertEq(vaultAccount.nftIndex, 0, "New vault should not have any nftIndex");
        assertEq(vaultAccount.rpIndex, 0, "New vault should not have any rpIndex");

        assertEq(vaultAccount.totalAccRewards, 0, "New vault should not get any rewards");
    }

    // check for: if(distribution.endTime > 0) { if(vault.startTime >= distribution.endTime) revert Errors.NotEligibleForRewards(); }
    function testNewVaultReverts_UpdateAllUserAccounts_D1_T46p() public {
        uint256 distributionId = 1;

        address[] memory userAddresses = new address[](2);
            userAddresses[0] = user1;
            userAddresses[1] = user2;

        // update user accounts for new vault: should revert
        vm.startPrank(operator);
            vm.expectRevert(Errors.NotEligibleForRewards.selector);
            pool.updateAllUserAccounts(distributionId, newVaultId, userAddresses);
        vm.stopPrank();
    }

}