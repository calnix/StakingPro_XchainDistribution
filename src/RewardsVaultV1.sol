// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Events.sol";
import "./Errors.sol";
import "./Constants.sol";

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// this is just a container. all calcs and tracking is on staking contract
contract RewardsVaultV1 is Pausable, AccessControl {
    using SafeERC20 for IERC20;

    // structs
    struct Distribution {
        uint32 dstEid;           // LZ eid: proxy for chainId
        bytes32 tokenAddress;    // token address encoded as bytes32

        uint256 totalRequired;   // updated by pool: for reference wrt deposit/withdraw
        uint256 totalClaimed;
        uint256 totalDeposited;
    }

    struct UserAddresses {
        address evmAddress;     
        bytes32 solanaAddress;        
    }

//-------------------------------mappings--------------------------------------------
    
    mapping(address user => UserAddresses userAddresses) public users;
    mapping(uint256 distributionId => Distribution distribution) public distributions;
    // track payouts to addresses across distributions
    mapping(address staker => mapping(bytes32 receiver => mapping(uint256 distributionId => uint256 amount))) public paidOut;
        
//------- constructor ----------------------------------------------------------
    constructor(address moneyManager, address monitor, address owner, address pool) {

        // sanity checks
        if(moneyManager == address(0)) revert Errors.InvalidAddress();
        if(monitor == address(0)) revert Errors.InvalidAddress();
        if(owner == address(0)) revert Errors.InvalidAddress();
        if(pool == address(0)) revert Errors.InvalidAddress();

        // access control
        _grantRole(DEFAULT_ADMIN_ROLE, owner);                  // default admin role for all roles
        _grantRole(Constants.MONITOR_ROLE, owner);              // default admin role for all roles
        _grantRole(Constants.MONEY_MANAGER_ROLE, owner);

        _grantRole(Constants.POOL_ROLE, pool);                        // pool contract
        _grantRole(Constants.MONITOR_ROLE, monitor);                  // risk monitoring script
        _grantRole(Constants.MONEY_MANAGER_ROLE, moneyManager);
    }

//------- external functions -----------------------------------------------------
    
    /**
     * @notice Sets the receiver address for the user
     * @dev Only callable when the contract is not paused
     * @param evmAddress The EVM address of the user
     */
    function setReceiverEvm(address evmAddress) external virtual whenNotPaused {
        if(evmAddress == address(0)) revert Errors.InvalidAddress();

        users[msg.sender].evmAddress = evmAddress;

        emit EvmReceiverSet(msg.sender, evmAddress);
    }

    /*//////////////////////////////////////////////////////////////
                              POOL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up a new distribution for tracking rewards
     * @dev Only callable by POOL_ROLE. Distribution ID 0 is reserved for staking power.
     * @param distributionId Unique identifier for this distribution
     * @param dstEid LayerZero endpoint ID for the destination chain (0 for local chain)
     * @param tokenAddress The token address for this distribution encoded as bytes32
     */
    function setupDistribution(uint256 distributionId, uint32 dstEid, bytes32 tokenAddress, uint256 totalRequired) external virtual whenNotPaused onlyRole(Constants.POOL_ROLE) {
        // POOL ensures that:
        //  distributionId is > 0
        //  tokenAddress is not BYTES32(0)
        //  dstEid is > 0

        Distribution memory distribution = distributions[distributionId];
            distribution.dstEid = dstEid;
            distribution.tokenAddress = tokenAddress;
            distribution.totalRequired = totalRequired;
        
        // update
        distributions[distributionId] = distribution;

        emit DistributionCreated(distributionId, dstEid, tokenAddress);
    }

    /**
     * @notice Updates the total required for a distribution
     * @dev Only callable by pool
     * @param distributionId The ID of the distribution to update
     * @param newTotalRequired The new total required amount
     */
    function updateDistribution(uint256 distributionId, uint256 newTotalRequired) external virtual whenNotPaused onlyRole(Constants.POOL_ROLE) {
        Distribution storage distributionPointer = distributions[distributionId];
        distributionPointer.totalRequired = newTotalRequired;
        emit DistributionUpdated(distributionId, newTotalRequired);
    }

    /**
     * @notice Ends a distribution immediately
     * @dev Only callable by pool
     * @param distributionId The ID of the distribution to end
     */
    function endDistribution(uint256 distributionId, uint256 totalEmitted) external virtual whenNotPaused onlyRole(Constants.POOL_ROLE) {
        Distribution storage distributionPointer = distributions[distributionId];
        distributionPointer.totalRequired = totalEmitted;
        emit DistributionEnded(distributionId, totalEmitted);
    }

    /**
     * @notice Transfers rewards to users, handling both local and cross-chain distributions
     * @dev Only callable by the Staking Pool contract. Handles three cases:
     *      1. Local transfers using direct ERC20 transfer
     *      2. Solana transfers using LayerZero messaging
     *      3. Other EVM chain transfers using LayerZero messaging
     * @param distributionId The ID of the distribution to pay rewards from
     * @param staker Address of staker
     * @param amount Reward amount (expressed in the token's precision)
     */
    function payRewards(uint256 distributionId, uint256 amount, address staker) external payable virtual whenNotPaused onlyRole(Constants.POOL_ROLE) {
        if(msg.value > 0) revert Errors.PayableBlocked();

        // get distribution + user
        Distribution memory distribution = distributions[distributionId];
        UserAddresses memory user = users[staker];

        // check balance
        uint256 balance = distribution.totalDeposited - distribution.totalClaimed;
        if(balance < amount) revert Errors.InsufficientBalance();

        // update claimed
        distribution.totalClaimed += amount;

        // get receiver + token addresses
        address receiver = user.evmAddress == address(0) ? staker : user.evmAddress;
        address token = bytes32ToAddress(distribution.tokenAddress);

        // update storage
        distributions[distributionId] = distribution;
        paidOut[staker][addressToBytes32(receiver)][distributionId] += amount;
    
        emit PayRewards(distributionId, staker, receiver, amount);
 
        // transfer
        IERC20(token).safeTransfer(receiver, amount); 
    }

    /*//////////////////////////////////////////////////////////////
                              MONEY_MANAGER
    //////////////////////////////////////////////////////////////*/

    /** 
     * @notice Deposits rewards into the vault for a specific distribution
     * @dev Only callable by accounts with MONEY_MANAGER_ROLE. Distribution ID 0 is reserved for staking power.
     * @param distributionId The ID of the distribution to deposit rewards for
     * @param amount Amount of rewards to deposit (in wei)
     * @param from Address from which rewards will be pulled
     */
    function deposit(uint256 distributionId, uint256 amount, address from) external whenNotPaused onlyRole(Constants.MONEY_MANAGER_ROLE) {
        if(distributionId == 0) revert Errors.InvalidDistributionId();
        if(from == address(0)) revert Errors.InvalidAddress();
        if(amount == 0) revert Errors.InvalidAmount();
        
        // sanity checks
        Distribution memory distribution = distributions[distributionId];
        // distribution must be setup
        if(distribution.tokenAddress == bytes32(0)) revert Errors.DistributionNotSetup();
        // incorrect distribution Id: only local deposits
        if(distribution.dstEid != Constants.LOCAL_EID) revert Errors.CallDepositOnRemote();
                
        // revert if token address is 0
        address token = bytes32ToAddress(distribution.tokenAddress);
        if(token == address(0)) revert Errors.InvalidTokenAddress();

        // sanity check: will revert if address is not a token contract on local
        IERC20(token).balanceOf(address(this));
        
        // check if excess: allow for partial deposits
        if(distribution.totalRequired < distribution.totalDeposited + amount) revert Errors.ExcessiveDeposit();
        
        // update + storage
        distribution.totalDeposited += amount;
        distributions[distributionId] = distribution;

        // local: transfer from sender
        IERC20(token).safeTransferFrom(from, address(this), amount);

        emit Deposit(distributionId, distribution.dstEid, from, amount);
    }
    
    /**
     * @notice Withdraws rewards from the vault for a specific distribution
     * @dev Only callable by accounts with MONEY_MANAGER_ROLE. Distribution ID 0 is reserved for staking power.
     * @dev Withdrawal allowed based on balance; onus on caller to check and maintain sufficient balances.
     * @param distributionId The ID of the distribution to withdraw rewards from
     * @param withdrawAmount Amount of rewards to withdraw (in wei)
     * @param to Address to which rewards will be sent
     */
    function withdraw(uint256 distributionId, uint256 withdrawAmount, address to) external whenNotPaused onlyRole(Constants.MONEY_MANAGER_ROLE) {
        if(distributionId == 0) revert Errors.InvalidDistributionId();
        if(to == address(0)) revert Errors.InvalidAddress();
        if(withdrawAmount == 0) revert Errors.InvalidAmount();

        // check 
        Distribution memory distribution = distributions[distributionId];
        if(distribution.tokenAddress == bytes32(0)) revert Errors.DistributionNotSetup();

        // check if sufficient balance
        uint256 balance = distribution.totalDeposited - distribution.totalClaimed;
        if(balance < withdrawAmount) revert Errors.InsufficientBalance();

        // decrement
        distribution.totalDeposited -= withdrawAmount;
        
        // sanity check: totalDeposited must be >= totalRequired
        if(distribution.totalDeposited < distribution.totalRequired) revert Errors.InsufficientDeposit();

        // update storage
        distributions[distributionId] = distribution;

        // local: transfer to receiver
        address token = bytes32ToAddress(distribution.tokenAddress);
        IERC20(token).safeTransfer(to, withdrawAmount);

        emit Withdraw(distributionId, distribution.dstEid, to, withdrawAmount);
    }

//------------------------------- risk -------------------------------------------------------

    /**
     * @notice Pause pool. Cannot pause once frozen
     */
    function pause() external whenNotPaused onlyRole(Constants.MONITOR_ROLE) {
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


//------------------------------- pure ---------------------------------


    function addressToBytes32(address addr) public pure returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice Converts a bytes32 value to an Ethereum address
     * @dev Used for cross-chain messaging where addresses are encoded as bytes32
     * @param bytes32_ The bytes32 value to convert to an address
     * @return The Ethereum address decoded from the bytes32 value
     */
    function bytes32ToAddress(bytes32 bytes32_) public pure returns(address) {
        uint256 value = uint256(bytes32_);

        // copied from OZ's SafeCast library
        if (value > type(uint160).max) {
            revert Errors.SafeCastOverflowedUintDowncast();
        }
        
        return address(uint160(value));
    }


} 
    



/**
    Setup a distribution
    - deposit required into here
    - setUpDistribution on pool
    
    - should setUpDistri on pool sanity check tokenVault?
    - yes, cos we can have multiple distributions, for the same token.

    LAYERZERO
    - isSupportedEid: https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts
 */