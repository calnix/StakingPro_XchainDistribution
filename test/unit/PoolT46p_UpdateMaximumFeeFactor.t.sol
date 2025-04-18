// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PoolT41.t.sol";

abstract contract StateT46p_UpdateMaximumFeeFactor is StateT41_User2StakesToVault2 {

    bytes32 vaultId3;

    function setUp() public virtual override {
        super.setUp();

        vm.warp(46);
        
        // update to 10%
        vm.startPrank(operator);
            pool.updateMaximumFeeFactor(1000);
        vm.stopPrank();

        vaultId3 = generateVaultId(block.number - 1, user3);
    }
}

contract StateT46p_UpdateMaximumFeeFactorTest is StateT46p_UpdateMaximumFeeFactor {

    function testUserCanCreateVaultWithNewFees() public {
        uint256[] memory creationNfts = new uint256[](1);
            creationNfts[0] = user3NftsArray[0];  

        vm.startPrank(user3);
            uint256 nftFeeFactor = 500;
            uint256 creatorFeeFactor = 300;
            uint256 realmPointsFeeFactor = 200;
            pool.createVault(creationNfts, creatorFeeFactor, nftFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();

        uint256 totalFeeFactor = nftFeeFactor + creatorFeeFactor + realmPointsFeeFactor;
        assertEq(totalFeeFactor, 1000, "totalFeeFactor mismatch");

        assertEq(pool.getVault(vaultId3).nftFeeFactor, nftFeeFactor, "nftFeeFactor mismatch");
        assertEq(pool.getVault(vaultId3).creatorFeeFactor, creatorFeeFactor, "creatorFeeFactor mismatch");
        assertEq(pool.getVault(vaultId3).realmPointsFeeFactor, realmPointsFeeFactor, "realmPointsFeeFactor mismatch");
    }

    function testUserCannotUpdateFeesOnExistingVaultDueToInsufficientBuffer() public {
        // get vault1's initial fee factors
        DataTypes.Vault memory vault1 = pool.getVault(vaultId1);
        uint256 totalFeeFactorBefore = vault1.nftFeeFactor + vault1.creatorFeeFactor + vault1.realmPointsFeeFactor;
        assertEq(totalFeeFactorBefore, 3000, "totalFeeFactorBefore mismatch");

        /** 
            Initial state:
             maximum fee factor = 5000
             nftFeeFactor = 1000
             creatorFeeFactor = 1000
             realmPointsFeeFactor = 1000
            Total = 3000

            After update:
             maximum fee factor = 1000 (reduced)
             nftFeeFactor = 1000 (unchanged)
             creatorFeeFactor = 0 (decreased by 1000)
             realmPointsFeeFactor = 1000 (unchanged)
            Total = 2000 > new maximum of 1000

            vault1 fees cannot be updated, as the new fees composition (2000) exceeds the new maximum fee factor (1000)
            this is acceptable, as the creator would be expected to end the vault, and start a new one with the new fees
         */

        vm.startPrank(user1);
            uint256 nftFeeFactor = 1000;
            uint256 creatorFeeFactor = 0;
            uint256 realmPointsFeeFactor = 1000;
            vm.expectRevert(abi.encodeWithSelector(Errors.MaximumFeeFactorExceeded.selector));
            pool.updateVaultFees(vaultId1, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();

    }

    function testUserCannotUpdateFeesOnVaultWithInvalidFees() public {
        vm.startPrank(user1);
            vm.expectRevert(abi.encodeWithSelector(Errors.MaximumFeeFactorExceeded.selector));
            pool.updateVaultFees(vaultId3, 1001, 1001, 1001);
        vm.stopPrank();
    }

    function testUserCanUpdateFeesOnVaultIfSufficientBuffer() public {
        // get vault2's initial fee factors
        DataTypes.Vault memory vault2 = pool.getVault(vaultId2);
        uint256 totalFeeFactorBefore = vault2.nftFeeFactor + vault2.creatorFeeFactor + vault2.realmPointsFeeFactor;
        assertEq(totalFeeFactorBefore, 2000, "totalFeeFactorBefore mismatch");

        // update to 20% from 50%
        vm.startPrank(operator);
            pool.updateMaximumFeeFactor(2000);
        vm.stopPrank();

        vm.startPrank(user2);
            uint256 nftFeeFactor = 1000 + vault2.creatorFeeFactor/4;
            uint256 creatorFeeFactor = 0;
            uint256 realmPointsFeeFactor = 500 + vault2.realmPointsFeeFactor/4;
            pool.updateVaultFees(vaultId2, nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
        vm.stopPrank();

        uint256 totalFeeFactor = nftFeeFactor + creatorFeeFactor + realmPointsFeeFactor;
        assertEq(totalFeeFactor, 1750, "totalFeeFactor mismatch");

        assertEq(pool.getVault(vaultId2).nftFeeFactor, nftFeeFactor, "nftFeeFactor mismatch");
        assertEq(pool.getVault(vaultId2).creatorFeeFactor, creatorFeeFactor, "creatorFeeFactor mismatch");
        assertEq(pool.getVault(vaultId2).realmPointsFeeFactor, realmPointsFeeFactor, "realmPointsFeeFactor mismatch");
    }
}
