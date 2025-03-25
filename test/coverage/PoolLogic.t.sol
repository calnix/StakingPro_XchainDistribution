// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../utils/TestingHarness.sol";

abstract contract PoolLogicFunctions is TestingHarness {

    function setUp() public override {
        super.setUp();

    }
}

contract PoolLogicFunctionsTest is PoolLogicFunctions {

    function testCacheRevertsIfVaultDoesNotExist() public {
        vm.warp(startTime + 1);
        bytes32 vaultId = bytes32(uint256(1));
        vm.expectRevert(abi.encodeWithSelector(Errors.NonExistentVault.selector, vaultId));
        pool.stakeTokens(vaultId, 1000);
    }
}
