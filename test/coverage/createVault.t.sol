// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../utils/TestingHarness.sol";

abstract contract PoolNoActiveDistributions is TestingHarness {

    StakingPro public otherPool;

    function setUp() public override {
        super.setUp();

        otherPool = new StakingPro(
            address(nftRegistry),
            address(mocaToken), 
            startTime,
            nftMultiplier,
            creationNftsRequired,
            vaultCoolDownDuration,
            owner,
            monitor,
            operator,
            storedSigner,
            "StakingPro",
            "1");
    }
}


contract PoolNoActiveDistributionsTest is PoolNoActiveDistributions {

    function testCannotCreateVaultWhenNoActiveDistributions() public {
        vm.expectRevert(Errors.NoActiveDistributions.selector);
        pool.createVault(user1NftsArray, 1000, 1000, 1000);
    }
}
