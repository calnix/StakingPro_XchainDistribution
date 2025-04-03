// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import "../../src/EvmVault.sol";

contract EVMVaultTest is Test {

    EVMVault public evmVault;

    function setUp() public override {
        super.setUp();

        evmVault = new EVMVault(address(0), address(0), address(0), address(0));
    }
    
    
}