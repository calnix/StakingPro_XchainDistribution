// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Events.sol";
import "./Errors.sol";

// OZ
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { SafeERC20, IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable2Step, Ownable } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

// LZ
import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract EVMVault is OApp, Pausable, Ownable2Step, AccessControl {
    using SafeERC20 for IERC20;

    // the eid of the destination chain
    uint32 public immutable dstEid;
    
    // roles
    bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");                // only pause  
    bytes32 public constant MONEY_MANAGER_ROLE = keccak256("MONEY_MANAGER_ROLE");    // withdraw/deposit

    // Track token balances and activity
    struct TokenInfo {
        uint256 totalDeposited;     // Total amount deposited
        uint256 totalPaidOut;       // Total amount paid out as rewards
        uint256 totalUnclaimable;   // Total amount unclaimable due to insufficient balance
    }

    // Token address => TokenInfo
    mapping(address token => TokenInfo tokenInfo) public tokens;
    // Track rewards paid out to each user for each token
    mapping(address user => mapping(address token => uint256 amount)) public paidOut;
    // Track rewards unclaimable due to insufficient balance
    mapping(address user => mapping(address token => uint256 amount)) public unclaimable;
    
    constructor(uint32 dstEid_, address endpoint, address owner, address monitor, address moneyManager) OApp(endpoint, owner) Ownable(owner) {
        dstEid = dstEid_;

        // access control
        _grantRole(DEFAULT_ADMIN_ROLE, owner);              // default admin role for all roles
        
        _grantRole(MONITOR_ROLE, monitor);                  // risk monitoring script
        _grantRole(MONEY_MANAGER_ROLE, moneyManager);
    }

    /**
     * @notice Allows users to collect previously unclaimable rewards for a specific token
     * @param token The address of the token to collect unclaimable rewards for
     */
    function collectUnclaimedRewards(address token) external whenNotPaused {
        if(token == address(0)) revert Errors.InvalidTokenAddress();

        uint256 unclaimableAmount = unclaimable[msg.sender][token];
        if(unclaimableAmount == 0) revert Errors.NoUnclaimedRewards();
        
        // check balance
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amountToPay = balance < unclaimableAmount ? balance : unclaimableAmount;

        // update storage
        tokens[token].totalUnclaimable -= amountToPay;
        unclaimable[msg.sender][token] -= amountToPay;
        
        tokens[token].totalPaidOut += amountToPay;
        paidOut[msg.sender][token] += amountToPay;

        emit CollectUnclaimedRewards(token, msg.sender, amountToPay);

        // transfer what we can pay
        IERC20(token).safeTransfer(msg.sender, amountToPay);
    }

//------------------------------- DEPOSIT/WITHDRAW -------------------------------

    /** Process deposits and withdrawals

        Deposit [or totalRequired increases]:
            1. deposit here.
            2. update on home, via `updatedDistribution` on StakingPro

        user cannot claimRewards prematurely.
        claimRewards txns revert until sufficient balance is available on remote chain.
        
        Withdraw [or totalRequired decreases]:
            1. reduce on home, via `updatedDistribution` on StakingPro 
            2. then withdraw on remote
        
        Incoming claimRewards calls will be immediately treated on the update, as StakingPro and RewardsVault are updated.
        This prevents invalid claimRewards txns from going x-chain.

        However:
        there could be claimRewards txns in mid-flight, that were initiated just before step 1.
        due to the latency of cross-chain calls, these txns would `fail`; users would have token balances stored as 'unclaimable'.

        To avoid this issue:
         - allow some downtime between steps 1 and 2, to ensure all mid-flight claimRewards txns have time to complete.
         - once they are, proceed with step 2.

        If withdraw is immediately done step 1, some users may have their claimRewards txns 'fail'.
        - these would be perceived as legitimate txns are they were initiated on home, before step 1 occured. 
        - users will have token balances stored as 'unclaimable'
        - as their claimRewards txns were in mid-flight, when the totalRequired was updated.
        
        To avoid this, user can call `collectUnclaimedRewards` to claim their rewards.
    */

    /** Note: Refer to process comment block above for more details.
     * @notice Deposits tokens into the vault
     * @dev Caller is expected to reference Distribution.totalRequired on the RewardsVault
     * @param token The address of the token being deposited
     * @param amount The amount of tokens to deposit
     * @param from The address the tokens are being deposited from
     * @param distributionId The ID of the distribution these tokens are for
     */
    function deposit(address token, uint256 amount, address from, uint256 distributionId) external whenNotPaused onlyRole(MONEY_MANAGER_ROLE) {
        if(token == address(0)) revert Errors.InvalidTokenAddress();
        if(distributionId == 0) revert Errors.InvalidDistributionId();
        
        // update distribution
        tokens[token].totalDeposited += amount;

        emit Deposit(token, from, amount, distributionId);

        // transfer from sender
        IERC20(token).safeTransferFrom(from, address(this), amount);
    }
    
    /** Note: Refer to process comment block above for more details.
     * @notice Withdraws tokens from the vault
     * @dev Caller is expected to reference Distribution.totalRequired on the RewardsVault
     * @param token The address of the token being withdrawn
     * @param amount The amount of tokens to withdraw
     * @param to The address the tokens are being withdrawn to
     * @param distributionId The ID of the distribution these tokens are for
     */
    function withdraw(address token, uint256 amount, address to, uint256 distributionId) external whenNotPaused onlyRole(MONEY_MANAGER_ROLE) {
        if(token == address(0)) revert Errors.InvalidTokenAddress();

        // check balance
        if(tokens[token].totalDeposited < amount) revert Errors.InsufficientBalance();

        // update
        tokens[token].totalDeposited -= amount;

        emit Withdraw(token, to, amount, distributionId);  

        // transfer to receiver
        IERC20(token).safeTransfer(to, amount);
    }

//------------------------------- LAYERZERO --------------------------------------

    /** 
     * @dev Override of _lzReceive internal fn in OAppReceiver.sol. The public fn lzReceive, handles param validation.
     * @param payload message payload being received
     * @custom:anon-param origin A struct containing information about where the packet came from.
     * @custom:anon-param guid: A global unique identifier for tracking the packet.
     * @custom:anon-param executor: Executor address as specified by the OApp.
     * @custom:anon-param options: Any extra data or options to trigger on receipt.
     */
    function _lzReceive(Origin calldata /*origin*/, bytes32 /*guid*/, bytes calldata payload, address /*executor*/, bytes calldata /*options*/) internal override {

        (bytes32 tokenAddress, uint256 amount, address receiver) = abi.decode(payload, (bytes32, uint256, address));

        // convert bytes32 to address
        address token = address(uint160(uint256(tokenAddress)));

        // if paused, increment unclaimable, do not transfer
        // crucial to prevent _lzReceive from reverting
        if(paused()) {

            unclaimable[receiver][token] += amount;
            tokens[token].totalUnclaimable += amount;
            emit UnclaimedRewards(token, receiver, amount);

        } else {
            
            uint256 balance = IERC20(token).balanceOf(address(this));

            // insufficient balance: send remaining balance
            if(balance < amount) {
                
                uint256 unclaimableAmount = amount - balance;

                // update storage
                unclaimable[receiver][token] += unclaimableAmount;
                tokens[token].totalUnclaimable += unclaimableAmount;

                tokens[token].totalPaidOut += balance;
                paidOut[receiver][token] += balance;
                

                emit PayRewards(token, receiver, balance);
                emit UnclaimedRewards(token, receiver, unclaimableAmount);

                IERC20(token).safeTransfer(receiver, balance);

            } else { // full amount available, transfer it all

                tokens[token].totalPaidOut += amount;
                paidOut[receiver][token] += amount;

                emit PayRewards(token, receiver, amount);

                IERC20(token).safeTransfer(receiver, amount);
            }
        }
    }

//------------------------------- OWNABLE2STEP -----------------------------------

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override(Ownable, Ownable2Step) onlyOwner {
        Ownable2Step.transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }

//------------------------------- risk -------------------------------------------------------

    /**
     * @notice Pause pool. Cannot pause once frozen
     */
    function pause() external whenNotPaused onlyRole(MONITOR_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause pool. Cannot unpause once frozen
     */
    function unpause() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Allows the DEFAULT_ADMIN_ROLE to exfil any ERC20 tokens from the contract
     * @dev Only callable when the contract is paused
     * @param token Token address 
     */
    function exit(address token) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}