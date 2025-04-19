// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import "../utils/TestingHarness.sol";
import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

/**
    requires pool to be deployed first
 */

abstract contract StateDeploy is TestingHarness {    

    function setUp() public virtual override {
        super.setUp();
    }
}

contract StateDeployTest is StateDeploy {

    function testConstructor() public {
        
        // check roles
        assertEq(rewardsVault.hasRole(rewardsVault.DEFAULT_ADMIN_ROLE(), owner), true);
        assertEq(rewardsVault.hasRole(Constants.POOL_ROLE, address(pool)), true);
        assertEq(rewardsVault.hasRole(Constants.MONITOR_ROLE, monitor), true);
        assertEq(rewardsVault.hasRole(Constants.MONEY_MANAGER_ROLE, depositor), true);
    }

    function testCannotSetupDistributionAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.POOL_ROLE
            )
        );
        rewardsVault.setupDistribution(1, 30184, bytes32(uint256(uint160(address(rewardsToken1)))), 100 ether);
        vm.stopPrank();
    }

    function testCannotUpdateDistributionAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.POOL_ROLE
            )
        );
        rewardsVault.updateDistribution(1, 100 ether);
        vm.stopPrank();
    }

    function testCannotEndDistributionAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.POOL_ROLE
            )
        );
        rewardsVault.endDistribution(1, 100 ether);
        vm.stopPrank();
    }

    function testCannotPayRewardsAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.POOL_ROLE
            )
        );
        rewardsVault.payRewards(1, 100 ether, user2);
        vm.stopPrank();
    }

    function testCannotDepositAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.MONEY_MANAGER_ROLE
            )
        );
        rewardsVault.deposit(1, 100 ether, user2);
        vm.stopPrank();
    }
    
    function testCannotWithdrawAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.MONEY_MANAGER_ROLE
            )
        );
        rewardsVault.withdraw(1, 100 ether, user2);
        vm.stopPrank();
    }

    function testCannotPauseAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                Constants.MONITOR_ROLE
            )
        );
        rewardsVault.pause();
        vm.stopPrank();
    }

    function testAddressToBytes32() public {
        // Test converting address to bytes32
        address testAddr = address(0x1234567890123456789012345678901234567890);
        bytes32 expectedBytes = bytes32(uint256(uint160(testAddr)));
        
        bytes32 result = rewardsVault.addressToBytes32(testAddr);
        assertEq(result, expectedBytes, "addressToBytes32 conversion failed");
    }

    function testBytes32ToAddress() public {
        // Test converting bytes32 to address
        address expectedAddr = address(0x1234567890123456789012345678901234567890);
        bytes32 testBytes = bytes32(uint256(uint160(expectedAddr)));
        
        address result = rewardsVault.bytes32ToAddress(testBytes);
        assertEq(result, expectedAddr, "bytes32ToAddress conversion failed");
    }

    function testRoundTripConversion() public {
        // Test converting address -> bytes32 -> address
        address originalAddr = address(0x1234567890123456789012345678901234567890);
        
        bytes32 asBytes = rewardsVault.addressToBytes32(originalAddr);
        address roundTripped = rewardsVault.bytes32ToAddress(asBytes);
        
        assertEq(roundTripped, originalAddr, "Round trip conversion failed");
    }

    function testZeroAddressConversion() public {
        // Test with zero address
        address zeroAddr = address(0);
        bytes32 zeroBytes = bytes32(0);
        
        assertEq(rewardsVault.addressToBytes32(zeroAddr), zeroBytes, "Zero address to bytes32 failed");
        assertEq(rewardsVault.bytes32ToAddress(zeroBytes), zeroAddr, "Zero bytes32 to address failed");
    }

    // --------  set receiver tests --------

    function testCannotSetReceiverWithZeroEvmAddress() public {
        vm.startPrank(user1);
        
        vm.expectRevert(Errors.InvalidAddress.selector);
        rewardsVault.setReceiverEvm(address(0));
        
        vm.stopPrank();
    }

    function testCanSetReceiver() public {
        // Setup test data
        address evmAddress = address(0x1234567890123456789012345678901234567890);

        vm.startPrank(user1);
            // Expect event emission
            vm.expectEmit(true, true, true, true);
            emit EvmReceiverSet(user1, evmAddress);

            // Set receiver
            rewardsVault.setReceiverEvm(evmAddress);
        vm.stopPrank();

        // Verify storage update
        (address storedEvmAddress, bytes32 storedSolanaAddress) = rewardsVault.users(user1);
        assertEq(storedEvmAddress, evmAddress, "Incorrect EVM address stored");
        assertEq(storedSolanaAddress, bytes32(0), "Incorrect Solana address stored");
    }

}

abstract contract StatePaused is StateDeploy {

    function setUp() public virtual override {
        super.setUp();

        vm.prank(monitor);
        rewardsVault.pause();
    }
}

contract StatePausedTest is StatePaused {

    function testCannotUnpauseAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                rewardsVault.DEFAULT_ADMIN_ROLE()
            )
        );
        rewardsVault.unpause();
        vm.stopPrank();
    }

    function testCannotSetReceiverWhenPaused() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.setReceiverEvm(address(0x1234567890123456789012345678901234567890));
        vm.stopPrank();
    }

    function testCannotUpdateDistributionWhenPaused() public {
        vm.startPrank(address(pool));
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.updateDistribution(1, 100 ether);
        vm.stopPrank();
    }   

    function testCannotEndDistributionWhenPaused() public {
        vm.startPrank(address(pool));
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.endDistribution(1, 100 ether);
        vm.stopPrank();
    }

    function testCannotPayRewardsWhenPaused() public {
        vm.startPrank(address(pool));
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.payRewards(1, 100 ether, user2);
        vm.stopPrank();
    }           

    function testCannotDepositWhenPaused() public {
        vm.startPrank(depositor);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.deposit(1, 100 ether, user2);
        vm.stopPrank(); 
    }

    function testCannotWithdrawWhenPaused() public {
        vm.startPrank(depositor);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.withdraw(1, 100 ether, user2); 
        vm.stopPrank();
    }

    function testCannotPauseWhenPaused() public {
        vm.startPrank(monitor);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        rewardsVault.pause();
        vm.stopPrank();
    }

    function testCannotUnpauseWhenPaused() public {
        vm.startPrank(monitor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                monitor,
                rewardsVault.DEFAULT_ADMIN_ROLE()
            )
        );
        rewardsVault.unpause();
        vm.stopPrank();
    }

    function testCannotExitAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1, 
                rewardsVault.DEFAULT_ADMIN_ROLE()
            )
        );
        rewardsVault.exit(address(rewardsToken1));
        vm.stopPrank();
    }

}

abstract contract StateUnpaused is StatePaused {

    function setUp() public virtual override {
        super.setUp();

        // Change from monitor to owner since only admin can unpause
        vm.prank(owner);  
        rewardsVault.unpause();
    }
}   

contract StateUnpausedTest is StateUnpaused {

    function testCanSetReceiverWhenUnpaused() public {
        vm.startPrank(user1);
        rewardsVault.setReceiverEvm(address(0x1234567890123456789012345678901234567890));
        vm.stopPrank();
    }
}
