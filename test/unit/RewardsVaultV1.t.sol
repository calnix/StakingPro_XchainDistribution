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

        // setup D0 so that we can test deposit on DX
        vm.prank(operator);
        
        // staking power
            uint256 distributionId = 0;
            uint256 distributionStartTime = block.timestamp + 1;
            uint256 emissionPerSecond = 1 ether;
            uint256 tokenPrecision = 1E18;
            bytes32 tokenAddress = 0x00;
        pool.setupDistribution(distributionId, distributionStartTime, 0, emissionPerSecond, tokenPrecision, 0, tokenAddress);        
    }
}

contract StateDeployTest is StateDeploy {
    using stdStorage for StdStorage;
    
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

// --------  deposit tests --------

    function testCannotDespositD0() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidDistributionId.selector);
        rewardsVault.deposit(0, 10 ether, depositor);
        vm.stopPrank();
    }

    function testCannotDepositFromZeroAddress() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidAddress.selector);
        rewardsVault.deposit(1, 10 ether, address(0));
        vm.stopPrank();
    }

    function testCannotDepositZeroAmount() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidAmount.selector);
        rewardsVault.deposit(1, 0, depositor);
        vm.stopPrank();
    }

    function testCannotDepositRemoteToken() public {
        // Setup remote distribution
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp + 1;
        uint256 distributionEndTime = block.timestamp + 11 seconds;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 10 ether;

        // Setup remote distribution on pool
        vm.startPrank(operator);
            pool.setupDistribution(
                distributionId,
                distributionStartTime,
                distributionEndTime,
                emissionPerSecond,
                tokenPrecision,
                (dstEid + 1), // Set as remote distribution
                tokenAddress
            );
        vm.stopPrank();

        // Attempt to deposit for remote distribution
        vm.startPrank(depositor);
            vm.expectRevert(Errors.CallDepositOnRemote.selector);
            rewardsVault.deposit(distributionId, totalRequired, depositor);
        vm.stopPrank();
    }

    function testCannotDepositForNonExistentDistribution() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.DistributionNotSetup.selector);
        rewardsVault.deposit(12, 10 ether, depositor);
        vm.stopPrank();
    }

/* note: cannot unit test InvalidTokenAddress() since it gets picked up first as DistributionNotSetup() 
    function testCannotDepositInvalidTokenAddress() public {
        // Setup distribution 
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp + 1;
        uint256 distributionEndTime = block.timestamp + 11 seconds;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 10 ether;

        // Setup distribution on pool
        vm.startPrank(operator);
            pool.setupDistribution(
                distributionId,
                distributionStartTime,
                distributionEndTime,
                emissionPerSecond,
                tokenPrecision,
                dstEid,
                tokenAddress
            );
        vm.stopPrank();

        // modify storage to make tokenAddress be 0 on rewardsVault
        stdstore
            .target(address(rewardsVault))
            .sig("distributions(uint256)")
            .with_key(1)
            .depth(1)   
            .checked_write(bytes32(0));

        // Attempt to deposit
        vm.startPrank(depositor);
            vm.expectRevert(Errors.InvalidTokenAddress.selector);
            rewardsVault.deposit(distributionId, totalRequired, depositor);
        vm.stopPrank();
    }
*/
    function testCanDeposit() public {
        // distribution params
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp + 1;
        uint256 distributionEndTime = block.timestamp + 11 seconds;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 10 ether;

        // operator sets up distribution
        vm.startPrank(operator);
            // create distribution 1
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );
        vm.stopPrank();

        // Check initial balances
        uint256 initialVaultBalance = rewardsToken1.balanceOf(address(rewardsVault));
        (,,,,uint256 initialTotalDeposited) = rewardsVault.distributions(1);

        // depositor mints, approves, deposits
        vm.startPrank(depositor);
            rewardsToken1.mint(depositor, totalRequired);
            rewardsToken1.approve(address(rewardsVault), totalRequired);

            // Expect event emission
            vm.expectEmit(true, true, true, true);
            emit Deposit(distributionId, dstEid, depositor, totalRequired);

            rewardsVault.deposit(distributionId, totalRequired, depositor);
        vm.stopPrank();

        // Check final balances
        uint256 finalVaultBalance = rewardsToken1.balanceOf(address(rewardsVault));
        (,,,,uint256 finalTotalDeposited) = rewardsVault.distributions(1);

        // Verify token transfers
        assertEq(finalVaultBalance, initialVaultBalance + totalRequired, "Vault balance should increase by deposit amount");
        // Verify storage update
        assertEq(finalTotalDeposited, initialTotalDeposited + totalRequired, "Total deposited should increase by deposit amount");
    }
    
}

abstract contract StateDeposit is StateDeploy {

    function setUp() public virtual override {
        super.setUp();

        // distribution params
        uint256 distributionId = 1;
        uint256 distributionStartTime = block.timestamp + 1;
        uint256 distributionEndTime = block.timestamp + 11 seconds;
        uint256 emissionPerSecond = 1 ether;
        uint256 tokenPrecision = 1E18;
        bytes32 tokenAddress = rewardsVault.addressToBytes32(address(rewardsToken1));
        uint256 totalRequired = 10 ether;

        // operator sets up distribution
        vm.startPrank(operator);

            // create distribution 1
            pool.setupDistribution(
                distributionId, 
                distributionStartTime, 
                distributionEndTime, 
                emissionPerSecond, 
                tokenPrecision,
                dstEid, tokenAddress
            );
        vm.stopPrank();

       
        // depositor mints, approves, deposits | partial deposit
        vm.startPrank(depositor);
            rewardsToken1.mint(depositor, totalRequired);
            rewardsToken1.approve(address(rewardsVault), totalRequired);
            rewardsVault.deposit(distributionId, totalRequired - 5 ether, depositor);
        vm.stopPrank();
    }
}

contract StateDepositTest is StateDeposit {

    function testCannotDepositInExcess() public {    
        vm.startPrank(depositor);
        vm.expectRevert(Errors.ExcessiveDeposit.selector);
        rewardsVault.deposit(1, 11 ether, depositor);
        vm.stopPrank();
    }

    function testDeposit() public {
        (,,,,uint256 totalDeposited) = rewardsVault.distributions(1);
        assertEq(totalDeposited, 5 ether);
    }

// --------  withdraw tests --------
    function testCannotWithdrawInvalidDistribution() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidDistributionId.selector);
        rewardsVault.withdraw(0, 10 ether, depositor);
        vm.stopPrank();
    }

    function testCannotWithdrawInvalidAddress() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidAddress.selector);
        rewardsVault.withdraw(1, 11 ether, address(0));
        vm.stopPrank();
    }

    function testCannotWithdrawZeroAmount() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InvalidAmount.selector);
        rewardsVault.withdraw(1, 0, depositor);
        vm.stopPrank();
    }

    function testCannotWithdrawDistributionNotSetup() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.DistributionNotSetup.selector);
        rewardsVault.withdraw(11, 10 ether, depositor);
        vm.stopPrank();
    }

    
    function testCannotWithdrawInsufficientBalance() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InsufficientBalance.selector);
        rewardsVault.withdraw(1, 200 ether, depositor);
        vm.stopPrank();
    }

    function testCannotWithdrawInsufficientDeposit() public {
        vm.startPrank(depositor);
        vm.expectRevert(Errors.InsufficientDeposit.selector);
        rewardsVault.withdraw(1, 3 ether, depositor);
        vm.stopPrank();
    }

    function testCannotWithdrawInsufficientDeposit_Overflow() public {
        vm.startPrank(depositor);
        vm.expectRevert();
        rewardsVault.withdraw(1, 20 ether, depositor);
        vm.stopPrank();
    }

    function testCanWithdrawIfDistributionHasSurplus() public {
        // Setup distribution with surplus
        uint256 distributionId = 1;
        uint256 newEndTime = block.timestamp + 2 seconds; // Reduced duration
        uint256 newTotalRequired = 3 ether; // Reduced total required

        // Update distribution through pool
        vm.startPrank(operator);
            pool.updateDistribution(distributionId, 0, newEndTime, 1 ether);
        vm.stopPrank();

        // Check initial balances
        uint256 initialVaultBalance = rewardsToken1.balanceOf(address(rewardsVault));
        uint256 initialDepositorBalance = rewardsToken1.balanceOf(depositor);

        // Withdraw surplus
        vm.startPrank(depositor);
            vm.expectEmit(true, true, true, true);
            emit Withdraw(distributionId, dstEid, depositor, 1 ether);
            
            rewardsVault.withdraw(distributionId, 1 ether, depositor);
        vm.stopPrank();

        // Verify balances
        assertEq(rewardsToken1.balanceOf(address(rewardsVault)), initialVaultBalance - 1 ether, "Incorrect vault balance after withdrawal");
        assertEq(rewardsToken1.balanceOf(depositor), initialDepositorBalance + 1 ether, "Incorrect depositor balance after withdrawal");
    } 
        
}

abstract contract StateWithdraw is StateDeposit {

    function setUp() public virtual override {
        super.setUp();        

        // Setup distribution with surplus
        uint256 distributionId = 1;
        uint256 newEndTime = block.timestamp + 2 seconds; // Reduced duration
        uint256 newTotalRequired = 3 ether; // Reduced total required

        // Update distribution through pool
        vm.startPrank(operator);
            pool.updateDistribution(distributionId, 0, newEndTime, 1 ether);
        vm.stopPrank();
    }
}

contract StateWithdrawTest is StateWithdraw {

    function testCanWithdraw() public {
        uint256 distributionId = 1;

        vm.startPrank(depositor);
            vm.expectEmit(true, true, true, true);
            emit Withdraw(distributionId, dstEid, depositor, 1 ether);

            rewardsVault.withdraw(distributionId, 1 ether, depositor);
        vm.stopPrank();
    }
}

abstract contract StatePaused is StateWithdraw {

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
    
    function testAdminCanExit() public {
        uint256 initialBalance = rewardsToken1.balanceOf(owner);
        uint256 vaultBalance = rewardsToken1.balanceOf(address(rewardsVault));
        
        vm.startPrank(owner);
        rewardsVault.exit(address(rewardsToken1));
        vm.stopPrank();

        assertEq(rewardsToken1.balanceOf(owner), initialBalance + vaultBalance, "Tokens not transferred correctly");
        assertEq(rewardsToken1.balanceOf(address(rewardsVault)), 0, "Vault balance not zeroed");
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
