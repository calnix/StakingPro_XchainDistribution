// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import "./../../../src/EvmVault.sol";
import "./../../utils/TestingHarness.sol";

abstract contract State_DeployEVMVault is Test, TestingHarness {

    EVMVault public evmVault;

    function setUp() public virtual override {
        super.setUp();

        // evmVault
        vm.startPrank(owner);
            evmVault = new EVMVault(dstEid, address(lzMock), owner, monitor, depositor);
            evmVault.setPeer(dstEid, bytes32(uint256(uint160(address(rewardsVault)))));
        vm.stopPrank();
    }
}

contract State_DeployEVMVault_Test is State_DeployEVMVault {

    function test_deploy() public {

        // Check constructor assignments
        assertEq(evmVault.dstEid(), dstEid);
        assertEq(address(evmVault.endpoint()), address(lzMock));
        assertEq(evmVault.owner(), owner);
        
        // Check role assignments
        assertTrue(evmVault.hasRole(evmVault.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(evmVault.hasRole(evmVault.MONITOR_ROLE(), monitor));
        assertTrue(evmVault.hasRole(evmVault.MONEY_MANAGER_ROLE(), depositor));
    }

    function test_UserCannotDeposit() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 100 ether;
        address from = user1;
        uint256 distributionId = 1;
        
        // Expect revert when a random user tries to deposit
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user1,
                evmVault.MONEY_MANAGER_ROLE()
            )
        );
        evmVault.deposit(token, amount, from, distributionId);
        vm.stopPrank();
    }

    function test_CannotDeposit_InvalidTokenAddress() public {
        // Setup
        address token = address(0);
        uint256 amount = 100 ether;
        address from = depositor;
        uint256 distributionId = 1;

        // Expect revert when a random user tries to deposit
        vm.startPrank(depositor);
            vm.expectRevert(Errors.InvalidTokenAddress.selector);
            evmVault.deposit(token, amount, from, distributionId);
        vm.stopPrank();
    }

    function test_CannotDeposit_InvalidDistributionId() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 100 ether;
        address from = depositor;
        uint256 distributionId = 0;

        // Expect revert when a random user tries to deposit
        vm.startPrank(depositor);
            vm.expectRevert(Errors.InvalidDistributionId.selector);
            evmVault.deposit(token, amount, from, distributionId);
        vm.stopPrank();
    }

    function test_MoneyManagerCanDeposit() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 100 ether;
        address from = depositor;
        uint256 distributionId = 1;
        
        // Mint tokens depositor
        rewardsToken1.mint(depositor, amount);
        
        // Initial state check
        (uint256 totalDepositedBefore, , ) = evmVault.tokens(token);
        assertEq(totalDepositedBefore, 0);
        assertEq(rewardsToken1.balanceOf(address(evmVault)), 0);

        // deposit
        vm.startPrank(depositor);
            rewardsToken1.approve(address(evmVault), amount);

            // Expect the Deposit event to be emitted
            vm.expectEmit(true, true, true, true);
            emit Deposit(token, from, amount, distributionId);

            evmVault.deposit(token, amount, from, distributionId);
        vm.stopPrank();
        
        // Verify deposit was successful
        (uint256 totalDepositedAfter, , ) = evmVault.tokens(token);
        assertEq(totalDepositedAfter, amount);
        assertEq(rewardsToken1.balanceOf(address(evmVault)), amount);
    }

}

abstract contract State_DepositEVMVault is State_DeployEVMVault {

    function setUp() public virtual override {
        super.setUp();

        uint256 amount = 100 ether;

        // mint tokens to depositor
        rewardsToken1.mint(depositor, amount);

        // deposit
        vm.startPrank(depositor);
            rewardsToken1.approve(address(evmVault), amount);
            evmVault.deposit(address(rewardsToken1), amount, depositor, 1);
        vm.stopPrank();
    }
}

contract State_DepositEVMVault_Test is State_DepositEVMVault {

    function test_LzReceive_NotPaused_SufficientBalance() public {
        // Origin struct and other required parameters for lzReceive
        Origin memory origin = Origin({
            srcEid: dstEid,      // Example source chain ID
            sender: bytes32(uint256(uint160(address(rewardsVault)))),  // Example sender address converted to bytes32
            nonce: 1                // Example nonce
        });
        bytes32 guid = bytes32(uint256(0x1));  // Example GUID
        address executor = address(this);
        bytes memory extraData = "";


        // encode payload
        bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
        uint256 amount = 10 ether;
        address receiver = user1;
        bytes memory message = abi.encode(tokenAddress, amount, receiver);

        // Check balances and mappings before lzReceive
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceBefore = rewardsToken1.balanceOf(receiver);
        (,uint256 totalPaidOutBefore,) = evmVault.tokens(address(rewardsToken1));
        uint256 paidOutBefore = evmVault.paidOut(receiver, address(rewardsToken1));
        
        // call lzReceive
        vm.startPrank(address(lzMock));
            vm.expectEmit(true, true, true, true);
            emit PayRewards(address(rewardsToken1), receiver, amount);

            evmVault.lzReceive(origin, guid, message, executor, extraData);
        vm.stopPrank();

        
        // Check balances and mappings after lzReceive
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceAfter = rewardsToken1.balanceOf(receiver);
        (,uint256 totalPaidOutAfter,) = evmVault.tokens(address(rewardsToken1));
        uint256 paidOutAfter = evmVault.paidOut(receiver, address(rewardsToken1));
        
        // Verify token transfer
        assertEq(vaultBalanceAfter, vaultBalanceBefore - amount, "Vault balance should decrease by amount");
        assertEq(receiverBalanceAfter, receiverBalanceBefore + amount, "Receiver balance should increase by amount");
        
        // Verify mappings updated
        assertEq(totalPaidOutAfter, totalPaidOutBefore + amount, "totalPaidOut should increase by amount");
        assertEq(paidOutAfter, paidOutBefore + amount, "paidOut should increase by amount");
    }

    function test_LzReceive_NotPaused_InsufficientBalance() public {

        // Origin struct and other required parameters for lzReceive
        Origin memory origin = Origin({
            srcEid: dstEid,      // Example source chain ID
            sender: bytes32(uint256(uint160(address(rewardsVault)))),  // Example sender address converted to bytes32
            nonce: 1                // Example nonce
        });
        bytes32 guid = bytes32(uint256(0x1));  // Example GUID
        address executor = address(this);
        bytes memory extraData = "";


        // encode payload
        bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
        uint256 amount = 10_000 ether;
        address receiver = user1;
        bytes memory message = abi.encode(tokenAddress, amount, receiver);

        // Check balances and mappings before lzReceive
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceBefore = rewardsToken1.balanceOf(receiver);
        (,uint256 totalPaidOutBefore,) = evmVault.tokens(address(rewardsToken1));
        uint256 paidOutBefore = evmVault.paidOut(receiver, address(rewardsToken1));


        // maxPossiblePayout is totalDeposited
        (uint256 totalDeposited, ,) = evmVault.tokens(address(rewardsToken1));

        // call lzReceive
        vm.startPrank(address(lzMock));
            // Check for both PayRewards and UnclaimedRewards events
            vm.expectEmit(true, true, true, true);
            emit PayRewards(address(rewardsToken1), receiver, totalDeposited);
            
            vm.expectEmit(true, true, true, true);
            emit UnclaimedRewards(address(rewardsToken1), receiver, amount - totalDeposited);

            evmVault.lzReceive(origin, guid, message, executor, extraData);
        vm.stopPrank();

        
        // Check balances and mappings after lzReceive
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceAfter = rewardsToken1.balanceOf(receiver);
        (,uint256 totalPaidOutAfter,) = evmVault.tokens(address(rewardsToken1));
        uint256 paidOutAfter = evmVault.paidOut(receiver, address(rewardsToken1));

        
        // Verify token transfer
        assertEq(vaultBalanceAfter, vaultBalanceBefore - totalDeposited, "Vault balance should decrease by amount");
        assertEq(receiverBalanceAfter, receiverBalanceBefore + totalDeposited, "Receiver balance should increase by amount");
        
        // Verify mappings updated
        assertEq(totalPaidOutAfter, totalPaidOutBefore + totalDeposited, "totalPaidOut should increase by amount");
        assertEq(paidOutAfter, paidOutBefore + totalDeposited, "paidOut should increase by amount");

        // amount > totalDeposited
        assertGt(amount, totalDeposited, "amount should be more than totalDeposited");
    }

    function test_CannotCollectUnclaimedRewards_NoUnclaimable() public {
        // Setup
        address token = address(rewardsToken1);

        vm.startPrank(user1);
            vm.expectRevert(Errors.NoUnclaimedRewards.selector);
            evmVault.collectUnclaimedRewards(token);
        vm.stopPrank();
    }

    function test_UserCannotWithdraw() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 10 ether;
        address to = user1;
        uint256 distributionId = 1;

        // Expect revert when a random user tries to withdraw
        vm.startPrank(user1);
            vm.expectRevert(
                abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, evmVault.MONEY_MANAGER_ROLE())
            );
            evmVault.withdraw(token, amount, to, distributionId);
        vm.stopPrank();
    }

    function test_MoneyManagerCannotWithdraw_InsufficientBalance() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 10_000 ether;
        address to = depositor;
        uint256 distributionId = 1; 

        vm.startPrank(depositor);
            vm.expectRevert(Errors.InsufficientBalance.selector);
            evmVault.withdraw(token, amount, to, distributionId);
        vm.stopPrank();
    }
    
    function test_MoneyManagerCanWithdraw() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 100 ether;
        address to = depositor;
        uint256 distributionId = 1;
        
        // Check initial state
        (uint256 totalDepositedBefore, , ) = evmVault.tokens(token);
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceBefore = rewardsToken1.balanceOf(to);
        
        // Expect the Withdraw event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Withdraw(token, to, amount, distributionId);
        
        // withdraw
        vm.startPrank(depositor);
            evmVault.withdraw(token, amount, to, distributionId);
        vm.stopPrank();
        
        // Check state after withdrawal
        (uint256 totalDepositedAfter, , ) = evmVault.tokens(token);
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceAfter = rewardsToken1.balanceOf(to);
        
        // Verify withdraw was successful
        assertEq(totalDepositedAfter, totalDepositedBefore - amount, "Total deposited should decrease by amount");
        assertEq(vaultBalanceAfter, vaultBalanceBefore - amount, "Vault balance should decrease by amount");
        assertEq(receiverBalanceAfter, receiverBalanceBefore + amount, "Receiver balance should increase by amount");
    }


    function test_MonitorCanPause() public {
        // Check initial state
        assertFalse(evmVault.paused(), "Vault should not be paused initially");
        
        // Pause the vault
        vm.startPrank(monitor);
            evmVault.pause();
        vm.stopPrank();
        
        // Check state after pausing
        assertTrue(evmVault.paused(), "Vault should be paused after calling pause");
    }
}

abstract contract State_PauseEVMVault is State_DepositEVMVault {

    function setUp() public virtual override {
        super.setUp();
        
        // Pause the vault
        vm.startPrank(monitor);
            evmVault.pause();
        vm.stopPrank();
    }
}

contract State_PauseEVMVault_Test is State_PauseEVMVault {

    function test_CannotWithdraw_Paused() public {
        // Setup    
        address token = address(rewardsToken1);
        uint256 amount = 10 ether;
        address to = depositor;
        uint256 distributionId = 1;

        vm.startPrank(depositor);
            vm.expectRevert(Pausable.EnforcedPause.selector);
            evmVault.withdraw(token, amount, to, distributionId);
        vm.stopPrank();
    }

    function test_CannotDeposit_Paused() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 10 ether;
        address from = depositor;
        uint256 distributionId = 1;

        vm.startPrank(depositor);
            vm.expectRevert(Pausable.EnforcedPause.selector);
            evmVault.deposit(token, amount, from, distributionId);
        vm.stopPrank();
    }

    function test_LzReceive_Paused() public {
        // Origin struct and other required parameters for lzReceive
        Origin memory origin = Origin({
            srcEid: dstEid,      // Example source chain ID
            sender: bytes32(uint256(uint160(address(rewardsVault)))),  // Example sender address converted to bytes32
            nonce: 1                // Example nonce
        });
        bytes32 guid = bytes32(uint256(0x1));  // Example GUID
        address executor = address(this);
        bytes memory extraData = "";


        // encode payload
        bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
        uint256 amount = 10 ether;
        address receiver = user1;
        bytes memory message = abi.encode(tokenAddress, amount, receiver);

        // token balance before
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceBefore = rewardsToken1.balanceOf(receiver);
        
        // unclaimable before
        uint256 unclaimableBefore = evmVault.unclaimable(receiver, address(rewardsToken1));
        (,,uint256 totalUnclaimableBefore) = evmVault.tokens(address(rewardsToken1));
        
        vm.startPrank(address(lzMock));
            vm.expectEmit(true, true, true, true);
            emit UnclaimedRewards(address(rewardsToken1), receiver, amount);

            evmVault.lzReceive(origin, guid, message, executor, extraData);
        vm.stopPrank();

        
        // token balance after
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceAfter = rewardsToken1.balanceOf(receiver);

        // unclaimable after
        (,,uint256 totalUnclaimableAfter) = evmVault.tokens(address(rewardsToken1));
        uint256 unclaimableAfter = evmVault.unclaimable(receiver, address(rewardsToken1));

        
        // Verify no token transfer occurred (contract is paused)
        assertEq(vaultBalanceAfter, vaultBalanceBefore, "Vault balance should remain unchanged");
        assertEq(receiverBalanceAfter, receiverBalanceBefore, "Receiver balance should remain unchanged");
        
        // Verify unclaimable mappings were updated instead
        assertEq(unclaimableAfter, unclaimableBefore + amount, "unclaimable should increase by amount");
        assertEq(totalUnclaimableAfter, totalUnclaimableBefore + amount, "totalUnclaimable should increase by amount");
    }
}

abstract contract State_UnclaimedDueToPause is State_PauseEVMVault {

    function setUp() public virtual override {
        super.setUp();


        // Origin struct and other required parameters for lzReceive
        Origin memory origin = Origin({
            srcEid: dstEid,      // Example source chain ID
            sender: bytes32(uint256(uint160(address(rewardsVault)))),  // Example sender address converted to bytes32
            nonce: 1                // Example nonce
        });
        bytes32 guid = bytes32(uint256(0x1));  // Example GUID
        address executor = address(this);
        bytes memory extraData = "";

        // encode payload
        bytes32 tokenAddress = bytes32(uint256(uint160(address(rewardsToken1))));
        uint256 amount = 10 ether;
        address receiver = user1;
        bytes memory message = abi.encode(tokenAddress, amount, receiver);
        
        vm.startPrank(address(lzMock));
            evmVault.lzReceive(origin, guid, message, executor, extraData);
        vm.stopPrank();  
         
    }
}

contract State_UnclaimedDueToPause_Test is State_UnclaimedDueToPause {

    function test_OwnerCanExit() public {

        // Check token balances before exit
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 ownerBalanceBefore = rewardsToken1.balanceOf(owner);
        
        // Check state before exit
        assertTrue(evmVault.paused(), "Contract should be paused before test");

        // Exit
        vm.startPrank(owner);
            evmVault.exit(address(rewardsToken1));
        vm.stopPrank();

        // Check token balances after exit
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 ownerBalanceAfter = rewardsToken1.balanceOf(owner);
        
        // Verify tokens were transferred
        assertEq(vaultBalanceAfter, 0, "Vault balance should be zero after exit");
        assertEq(ownerBalanceAfter, ownerBalanceBefore + vaultBalanceBefore, "Owner should receive all tokens from vault");
    }
        

    function test_OwnerCanUnpause() public {
        
        // Check state before unpause
        assertTrue(evmVault.paused(), "Contract should be paused before test");
        
        vm.startPrank(owner);
            evmVault.unpause();
        vm.stopPrank();
        
        // Check state after unpause
        assertFalse(evmVault.paused(), "Contract should be unpaused after test");
    }

}

abstract contract State_CollectUnclaimedRewards is State_UnclaimedDueToPause {

    function setUp() public virtual override {
        super.setUp();

        // Unpause with owner
        vm.startPrank(owner);
            evmVault.unpause();
        vm.stopPrank();
    }
}

contract State_CollectUnclaimedRewards_Test is State_CollectUnclaimedRewards {


    function test_CannotCollectUnclaimedRewards_InvalidTokenAddress() public {
        // Setup
        address token = address(0);

        vm.startPrank(user1);
            vm.expectRevert(Errors.InvalidTokenAddress.selector);
            evmVault.collectUnclaimedRewards(token);
        vm.stopPrank();
    }

    function test_CanCollectUnclaimedRewards() public {
        // Setup
        address token = address(rewardsToken1);
        uint256 amount = 10 ether;
        address receiver = user1;

        // token balance before
        uint256 vaultBalanceBefore = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceBefore = rewardsToken1.balanceOf(receiver);

        // Check state before
        (,uint256 totalPaidOutBefore, uint256 totalUnclaimableBefore) = evmVault.tokens(token);
        uint256 unclaimableBefore = evmVault.unclaimable(receiver, token);
        uint256 paidOutBefore = evmVault.paidOut(receiver, token);

        // Check unclaimable before
        assertEq(unclaimableBefore, amount, "unclaimable should be equal to amount");
        assertEq(totalUnclaimableBefore, amount, "totalUnclaimable should be equal to amount");


        vm.startPrank(receiver);
            vm.expectEmit(true, true, true, true);
            emit CollectUnclaimedRewards(token, receiver, amount);

            evmVault.collectUnclaimedRewards(token);
        vm.stopPrank();


        // token balance after
        uint256 vaultBalanceAfter = rewardsToken1.balanceOf(address(evmVault));
        uint256 receiverBalanceAfter = rewardsToken1.balanceOf(receiver);
        
        // Check state after 
        (,uint256 totalPaidOutAfter, uint256 totalUnclaimableAfter) = evmVault.tokens(token);
        uint256 unclaimableAfter = evmVault.unclaimable(receiver, token);
        uint256 paidOutAfter = evmVault.paidOut(receiver, token);

        // Check unclaimable after 
        assertEq(unclaimableAfter, 0, "unclaimable should be 0");
        assertEq(totalUnclaimableAfter, 0, "totalUnclaimable should be 0");

        // check paidOut after 
        assertEq(totalPaidOutAfter, totalPaidOutBefore + amount, "totalPaidOut should increase by amount");
        assertEq(paidOutAfter, paidOutBefore + amount, "paidOut should increase by amount");

        // token balance after
        assertEq(vaultBalanceAfter, vaultBalanceBefore - amount, "vault balance should decrease by amount");
        assertEq(receiverBalanceAfter, receiverBalanceBefore + amount, "receiver balance should increase by amount");
    }
}

