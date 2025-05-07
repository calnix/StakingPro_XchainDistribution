// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title StakingPro
 * @custom:version 1.0
 * @custom:author Calnix(@cal_nix)
 * @notice Multi-asset staking contract with X-chain distribution capabilities
 */

import './Events.sol';
import {Errors} from './Errors.sol';
import {DataTypes} from './DataTypes.sol';
import {PoolLogic} from "./PoolLogic.sol";
import {Constants} from "./Constants.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

// interfaces
import {INftRegistry} from "./interfaces/INftRegistry.sol";
import {IRewardsVault} from "./interfaces/IRewardsVault.sol";


contract StakingPro is EIP712, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    // external interfaces
    INftRegistry public immutable NFT_REGISTRY;
    IERC20 public immutable STAKED_TOKEN;  
    IRewardsVault public REWARDS_VAULT; 

    // pool states
    uint256 public isFrozen;
    uint256 public isUnderMaintenance;

    // duration
    uint256 public immutable startTime; 
    uint256 public endTime; 

    // staked assets
    uint256 public totalCreationNfts;
    uint256 public totalStakedNfts;     // disregards creation NFTs
    uint256 public totalStakedTokens;
    uint256 public totalStakedRealmPoints;

    // boosted balances
    uint256 public totalBoostedRealmPoints;
    uint256 public totalBoostedStakedTokens;

    // nft multiplier
    uint256 public NFT_MULTIPLIER;                     // 10% = 1000/10_000 = 1000/PRECISION_BASE 

    // vault params
    uint256 public MAXIMUM_FEE_FACTOR;
    uint256 public CREATION_NFTS_REQUIRED;
    uint256 public VAULT_COOLDOWN_DURATION;
    
    // signature params
    uint256 public SEASON;
    address public immutable STORED_SIGNER;                 
    uint256 public MINIMUM_REALMPOINTS_REQUIRED;

    // distributions
    uint256[] public activeDistributions;    // array stores key values for distributions mapping; includes not yet started distributions  
    uint256 public MAX_ACTIVE_DISTRIBUTIONS;

//-------------------------------mappings--------------------------------------------

    // vault base attributes
    mapping(bytes32 vaultId => DataTypes.Vault vault) public vaults;

    // staking power is distributionId:0 => tokenData{uint256 chainId:0, bytes32 tokenAddr: 0,...}
    mapping(uint256 distributionId => DataTypes.Distribution distribution) public distributions;

    // user's assets per vault
    mapping(address user => mapping(bytes32 vaultId => DataTypes.User userVaultAssets)) public users;

    // for independent reward distribution tracking              
    mapping(bytes32 vaultId => mapping(uint256 distributionId => DataTypes.VaultAccount vaultAccount)) public vaultAccounts;

    // rewards accrued per user, per distribution
    mapping(address user => mapping(bytes32 vaultId => mapping(uint256 distributionId => DataTypes.UserAccount userAccount))) public userAccounts;

    // nonces for preventing race conditions [ECDSA.sol::recover handles sig.mal]
    mapping(address user => uint256 nonce) public userNonces;

//-------------------------------constructor------------------------------------------

    constructor(
        address nftRegistry, address stakedToken, uint256 startTime_, 
        /*uint256 maxFeeFactor, uint256 minRpRequired,*/ uint256 nftMultiplier, 
        uint256 creationNftsRequired, uint256 vaultCoolDownDuration,
        address owner, address monitor, address operator,
        address storedSigner, string memory name, string memory version) payable EIP712(name, version) {

        // sanity check: addresses 
        if(owner == address(0)) revert Errors.InvalidAddress();
        if(monitor == address(0)) revert Errors.InvalidAddress();
        if(operator == address(0)) revert Errors.InvalidAddress();
        if(stakedToken == address(0)) revert Errors.InvalidAddress();

        // disable for 3rd-party use
        //if(storedSigner == address(0)) revert Errors.InvalidAddress();
        //if(nftRegistry == address(0)) revert Errors.InvalidAddress();

        // sanity check: startTime
        if(startTime_ < block.timestamp) revert Errors.InvalidStartTime();

        // sanity check: nftMultiplier [no multiplier: 10_000]
        if(nftMultiplier == 0) revert Errors.InvalidMultiplier();

        // interfaces: supporting contracts
        NFT_REGISTRY = INftRegistry(nftRegistry);       
        STAKED_TOKEN = IERC20(stakedToken);

        // set staking startTime 
        startTime = startTime_;

        // storage vars
        MAXIMUM_FEE_FACTOR = 5000;                  // 50%:5000
        MINIMUM_REALMPOINTS_REQUIRED = 250 ether;
        NFT_MULTIPLIER = nftMultiplier;
        CREATION_NFTS_REQUIRED = creationNftsRequired;
        VAULT_COOLDOWN_DURATION = vaultCoolDownDuration;
        STORED_SIGNER = storedSigner;
        
        // sane limit: modifiable
        MAX_ACTIVE_DISTRIBUTIONS = 15;

        // access control
        _grantRole(DEFAULT_ADMIN_ROLE, owner);  // default admin role for all roles
        _grantRole(Constants.OPERATOR_ROLE, owner);
        _grantRole(Constants.MONITOR_ROLE, owner);

        // monitor script: only calls pause
        _grantRole(Constants.MONITOR_ROLE, monitor);

        // operator
        _grantRole(Constants.OPERATOR_ROLE, operator);
    }


//------------------------------ external --------------------------------------------------

    /**
     * @notice Creates a new vault for staking assets by committing NFTs
     * @dev Creates a new vault with specified fee configuration and NFT commitments
     * @param tokenIds Array of NFT token IDs to commit for vault creation
     * @param nftFeeFactor Percentage of rewards allocated to NFT stakers (basis points)
     * @param creatorFeeFactor Percentage of rewards allocated to vault creator (basis points)
     * @param realmPointsFeeFactor Percentage of rewards allocated to realm points (basis points)
     * @custom:requirements
     * - Caller must own all NFTs being committed
     * - NFTs must not be already staked in another vault
     * - Number of NFTs must match CREATION_NFTS_REQUIRED
     * - Total fee factors must not exceed 50% (5000 basis points)
     * - Contract must not be paused and staking must have started
     */
    function createVault(uint256[] calldata tokenIds, uint256 creatorFeeFactor, uint256 nftFeeFactor, uint256 realmPointsFeeFactor) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        if(activeDistributions.length == 0) revert Errors.NoActiveDistributions();

        // must commit unstaked NFTs to create vaults: these do not count towards stakedNFTs
        uint256 incomingNfts = tokenIds.length;
        if(incomingNfts != CREATION_NFTS_REQUIRED) revert Errors.InvalidCreationNfts(); // incomingNfts can be 0, if CREATION_NFTS_REQUIRED == 0

        //note: MOCA stakers must receive at least 50% of rewards
        uint256 totalFeeFactor = nftFeeFactor + creatorFeeFactor + realmPointsFeeFactor;
        if(totalFeeFactor > MAXIMUM_FEE_FACTOR) revert Errors.MaximumFeeFactorExceeded();

        // vaultId generation
        bytes32 vaultId;
        {
            uint256 salt = block.number - 1;
            vaultId = _generateVaultId(salt, msg.sender);
            while (vaults[vaultId].creator != address(0)) vaultId = _generateVaultId(--salt, msg.sender);      // If vaultId exists, generate new random Id
        }

        // build vault
        DataTypes.Vault memory vault; 
            vault.creator = msg.sender;
            vault.startTime = block.timestamp; 

            // fees
            vault.nftFeeFactor = nftFeeFactor;
            vault.creatorFeeFactor = creatorFeeFactor;
            vault.realmPointsFeeFactor = realmPointsFeeFactor;
            
            // boost factor: Initialize to 100%, "1"
            vault.totalBoostFactor = Constants.PRECISION_BASE; 

        // If nfts are required
        if(incomingNfts > 0){

            // revert if any NFTs are not unassigned OR not owned by msg.sender
            NFT_REGISTRY.checkIfUnassignedAndOwned(msg.sender, tokenIds);
            // record NFT commitment on registry contract
            NFT_REGISTRY.recordStake(msg.sender, tokenIds, vaultId);    
            
            // update vault creationTokenIds: memory assignment
            vault.creationTokenIds = tokenIds;  
            
            // update global count: storage assignment
            totalCreationNfts += incomingNfts;    
        } 
        // else: no NFTs required; no need to assign creationTokenIds, increment global state, or interact w/ registry

        // update storage
        vaults[vaultId] = vault;

        emit VaultCreated(vaultId, msg.sender, creatorFeeFactor,  nftFeeFactor, realmPointsFeeFactor);
    }  

    /**
     * @notice Stakes tokens into a vault
     * @dev No staking limits on staking assets
     * @param vaultId The ID of the vault to stake into
     * @param amount The amount of tokens to stake
     */
    function stakeTokens(bytes32 vaultId, uint256 amount) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        if(amount == 0) revert Errors.InvalidAmount();
        
        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender;
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        uint256 incomingBoostedTokens 
            = PoolLogic.executeStakeTokens(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, 
                amount);

        // update storage: pool assets
        totalStakedTokens += amount;
        totalBoostedStakedTokens += incomingBoostedTokens;

        // emit
        emit StakedTokens(msg.sender, vaultId, amount);

        // grab MOCA
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);  
    }

    /**
     * @notice Stakes NFTs into a vault
     * @dev No staking limits on NFT assets. NFTs increase the boost factor for staked tokens and realm points.
     * @param vaultId The ID of the vault to stake NFTs into
     * @param tokenIds Array of NFT token IDs to stake
     */
    function stakeNfts(bytes32 vaultId, uint256[] calldata tokenIds) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        uint256 incomingNfts = tokenIds.length;
        if(incomingNfts == 0) revert Errors.InvalidAmount();

        // revert if any NFTs are not unassigned OR not owned by msg.sender
        NFT_REGISTRY.checkIfUnassignedAndOwned(msg.sender, tokenIds);

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender;
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        (
            uint256 incomingBoostedStakedTokens, 
            uint256 incomingBoostedRealmPoints
        ) 
            = PoolLogic.executeStakeNfts(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, 
                tokenIds, incomingNfts, NFT_MULTIPLIER);
          
        // update storage: pool assets 
        totalStakedNfts += incomingNfts;
        totalBoostedRealmPoints += incomingBoostedRealmPoints;
        totalBoostedStakedTokens += incomingBoostedStakedTokens;

        emit StakedNfts(msg.sender, vaultId, tokenIds);

        // record stake with registry
        NFT_REGISTRY.recordStake(msg.sender, tokenIds, vaultId);
    }

    /**
     * @notice Stakes realm points into a vault. 
     * @dev Requires a valid signature from the stored signer to authorize the staking
     * @param vaultId The ID of the vault to stake realm points into
     * @param amount The amount of realm points to stake
     * @param expiry The expiry timestamp of the signature
     * @param season The season of the signature
     * @param signature The signature to verify
     * @custom:requirements
     * - Amount must be at least MINIMUM_REALMPOINTS_REQUIRED
     * - Signature must not be expired or already executed
     * - Signature must be valid and from the stored signer
     * - Signature must be for the current season
     * - Contract must not be paused and staking must have started
     */
    function stakeRealmPoints(bytes32 vaultId, uint256 amount, uint256 expiry, uint256 season, bytes calldata signature) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        if(expiry < block.timestamp) revert Errors.SignatureExpired();
        if(amount < MINIMUM_REALMPOINTS_REQUIRED) revert Errors.MinimumRealmPointsRequired();

        // verify signature
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(Constants.TYPEHASH, msg.sender, vaultId, amount, expiry, season, userNonces[msg.sender])));
        
        address signer = ECDSA.recover(digest, signature);
        if(signer != STORED_SIGNER) revert Errors.InvalidSignature(); 

        // increment nonce
        ++userNonces[msg.sender];

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender;
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        uint256 incomingBoostedRealmPoints 
            = PoolLogic.executeStakeRealmPoints(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params,
                amount);

        // update storage: pool assets
        totalStakedRealmPoints += amount;
        totalBoostedRealmPoints += incomingBoostedRealmPoints;

        emit StakedRealmPoints(msg.sender, vaultId, amount, incomingBoostedRealmPoints);
    }

    /**
     * @notice Moves realm points from one vault to another. No minimum amount constraints.
     * @dev Updates accounting for both vaults and recalculates boosted amounts
     * @param oldVaultId The ID of the vault to move realm points from
     * @param newVaultId The ID of the vault to move realm points to
     * @param amount The amount of realm points to move
     */
    function migrateRealmPoints(bytes32 oldVaultId, bytes32 newVaultId, uint256 amount) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        if(amount == 0) revert Errors.InvalidAmount();
        if(oldVaultId == newVaultId) revert Errors.InvalidVaultId();

        DataTypes.UpdateAccountsIndexesParams memory oldVaultParams;
            oldVaultParams.user = msg.sender;
            oldVaultParams.vaultId = oldVaultId;
            oldVaultParams.totalBoostedRealmPoints = totalBoostedRealmPoints;
            oldVaultParams.totalBoostedStakedTokens = totalBoostedStakedTokens;

        DataTypes.UpdateAccountsIndexesParams memory newVaultParams;
            newVaultParams.user = msg.sender;
            newVaultParams.vaultId = newVaultId;
            newVaultParams.totalBoostedRealmPoints = oldVaultParams.totalBoostedRealmPoints;
            newVaultParams.totalBoostedStakedTokens = oldVaultParams.totalBoostedStakedTokens;

        (
            uint256 totalBoostedDelta,
            uint256 flag
        ) 
            = PoolLogic.executeMigrateRealmPoints(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, oldVaultParams, 
                newVaultParams, amount);
        
        // totalBoostedDelta == 0 if vault had been removed from circulation already
        if(totalBoostedDelta > 0) {
            // flag dictates addition/subtraction to global state
            if(flag == 1) {
                // newBoostedRealmPoints > oldBoostedRealmPoints
                totalBoostedRealmPoints += totalBoostedDelta;
            } else{
                // newBoostedRealmPoints < oldBoostedRealmPoints
                totalBoostedRealmPoints -= totalBoostedDelta;
            }
        }
    }

    /**
     * @notice Unstakes tokens and NFTs from a vault
     * @dev Updates accounting, transfers tokens, and records NFT unstaking
     * @param vaultId The ID of the vault to unstake from
     * @param amount The amount of tokens to unstake
     * @param tokenIds Array of NFT token IDs to unstake
     * @custom:revert Will revert w/o error if the tokenIds provided are not staked by the user
     */
    function unstake(bytes32 vaultId, uint256 amount, uint256[] calldata tokenIds) external virtual whenStarted whenNotPaused whenNotUnderMaintenance {
        if(amount == 0 && tokenIds.length == 0) revert Errors.InvalidAmount();

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender;
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        (
            uint256 isRemoved,
            uint256 totalBoostedTokensDelta,
            uint256 totalBoostedRealmPointsDelta
        ) 
            = PoolLogic.executeUnstake(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, 
                NFT_MULTIPLIER, amount, tokenIds);

        // decrement user's staked tokens and boosted staked tokens
        if(isRemoved == 0){

            if(amount > 0){

                // update global
                totalStakedTokens -= amount;
                totalBoostedStakedTokens -= totalBoostedTokensDelta;

                // return MOCA
                STAKED_TOKEN.safeTransfer(msg.sender, amount);
            }

            // update nfts
            uint256 numOfNftsToUnstake = tokenIds.length;
            if(numOfNftsToUnstake > 0){    
                
                // update global
                totalStakedNfts -= numOfNftsToUnstake;
                totalBoostedRealmPoints -= totalBoostedRealmPointsDelta;
                
                // decrement totalBoostedStakedTokens when only nfts are unstaked
                if(amount == 0) totalBoostedStakedTokens -= totalBoostedTokensDelta;
                
                // record unstake with registry
                NFT_REGISTRY.recordUnstake(msg.sender, tokenIds, vaultId);
            }

        } else{
            
            // vault.removed == 1: assets removed from circulation 
            
            // no need to update global state: only return staking assets
            if(amount > 0) STAKED_TOKEN.safeTransfer(msg.sender, amount);
            if(tokenIds.length > 0) NFT_REGISTRY.recordUnstake(msg.sender, tokenIds, vaultId);
        }
    }

    /**
     * @notice Claims all pending TOKEN rewards for a user from a specific vault and distribution
     * @param vaultId The ID of the vault to claim rewards from
     * @param distributionId The ID of the reward distribution to claim from
     * @dev Updates vault and user accounting across all active distributions before claiming
     * @dev Calculates and claims 4 types of rewards:
     *      1. Token staking rewards
     *      2. Realm Points staking rewards 
     *      3. NFT staking rewards
     *      4. Creator rewards (if caller is vault creator)
     * @dev Not applicable to distributionId:0 which is the staking power distribution
     */
    function claimRewards(bytes32 vaultId, uint256 distributionId) external payable virtual whenStarted whenNotPaused whenNotUnderMaintenance {   
        if(distributionId == 0) revert Errors.StakingPowerDistribution();

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender;   
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        uint256 totalUnclaimedRewardsInNative
         = PoolLogic.executeClaimRewards(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, 
            distributionId);

        // transfer rewards to user, from rewardsVault
        if(totalUnclaimedRewardsInNative > 0){
            emit RewardsClaimed(distributionId, vaultId, msg.sender, totalUnclaimedRewardsInNative);
            REWARDS_VAULT.payRewards{value: msg.value}(distributionId, totalUnclaimedRewardsInNative, msg.sender);
        } 
    }

    /**
     * @notice Updates the fee structure for a vault. Only the vault creator can update fees
     * @dev Creator can only decrease their creator fee factor (they may increase other fees by the same amount)
     * @dev Total of all fees cannot exceed maximum fee factor
     * @param vaultId The ID of the vault to update fees for
     * @param nftFeeFactor The new NFT fee factor factor
     * @param creatorFeeFactor The new creator fee factor
     * @param realmPointsFeeFactor The new realm points fee factor
     */
    function updateVaultFees(bytes32 vaultId, uint256 nftFeeFactor, uint256 creatorFeeFactor, uint256 realmPointsFeeFactor) external virtual whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance {
        // sanity check: new fee compositions cannot exceed max
        uint256 totalFeeFactor = nftFeeFactor + creatorFeeFactor + realmPointsFeeFactor;
        if(totalFeeFactor > MAXIMUM_FEE_FACTOR) revert Errors.MaximumFeeFactorExceeded();     //e.g.: 50% = 5000/10_000 = 5000/PRECISION_BASE

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender; 
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        PoolLogic.executeUpdateVaultFees(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, 
            nftFeeFactor, creatorFeeFactor, realmPointsFeeFactor);
    }

    /**
     * @notice Activates the cooldown period for a vault, after which it can be removed from circulation
     * @dev If VAULT_COOLDOWN_DURATION is 0, vault is removed immediately
     * @dev When vault is removed, all staked assets are removed from circulation and global totals are updated
     * @param vaultId The ID of the vault to activate cooldown
     */
    function activateCooldown(bytes32 vaultId) external virtual whenStarted whenNotPaused whenNotUnderMaintenance {

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = msg.sender; 
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        // only update storage for distributions, vaultAccounts, userAccounts
        DataTypes.Vault memory vault = PoolLogic.executeActivateCooldown(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params);

        uint256 vaultCoolDownDuration = VAULT_COOLDOWN_DURATION;

        // calc. vault endTime based on current cooldown duration
        uint256 endTimeBasedOnCooldown = block.timestamp + vaultCoolDownDuration;

        // take the shorter of endTimes, if contract endTime is set
        if(endTime > 0) {
            vault.endTime = endTimeBasedOnCooldown < endTime ? endTimeBasedOnCooldown : endTime;
        } else{
            vault.endTime = endTimeBasedOnCooldown;
        }   

        emit VaultCooldownActivated(vaultId, vault.endTime);

        // if cooldown duration is 0, or vault endTime has passed, remove vault from circulation immediately 
        // vault endTime could be passed if contract endTime is set and has passed
        if(vault.endTime <= block.timestamp) {  
            
            // decrement global state
            totalStakedNfts -= vault.stakedNfts;
            totalCreationNfts -= vault.creationTokenIds.length;
            totalStakedTokens -= vault.stakedTokens;
            totalStakedRealmPoints -= vault.stakedRealmPoints;
            totalBoostedStakedTokens -= vault.boostedStakedTokens;
            totalBoostedRealmPoints -= vault.boostedRealmPoints;

            // Mark vault as removed
            vault.removed = 1;

            // return creator NFTs
            NFT_REGISTRY.recordUnstake(vault.creator, vault.creationTokenIds, vaultId);
            delete vaults[vaultId].creationTokenIds;

            emit VaultEnded(vaultId);
        }

        // update storage
        vaults[vaultId] = vault;
    }

    /**
     * @notice Ends multiple vaults
     * @dev Removes all staked assets from circulation and updates global totals
     * @param vaultIds Array of vault IDs to end
     */
    function endVaults(bytes32[] calldata vaultIds) external virtual whenStarted whenNotPaused whenNotUnderMaintenance {
        uint256 numOfVaults = vaultIds.length;
        if(numOfVaults == 0) revert Errors.InvalidArray();
        
        DataTypes.UpdateAccountsIndexesParams memory params;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        (
            uint256 totalStakedNftsToRemove,
            uint256 totalCreationNftsToRemove,
            uint256 totalTokensToRemove, 
            uint256 totalRealmPointsToRemove, 
            uint256 totalBoostedTokensToRemove, 
            uint256 totalBoostedRealmPointsToRemove
        )   // updates all active distribution indexes, so that vaults' accounts can be updated in finality
            = PoolLogic.executeEndVaults(activeDistributions, vaults, distributions, vaultAccounts, params, 
                vaultIds, numOfVaults, NFT_REGISTRY);

        // Update global state
        totalStakedNfts -= totalStakedNftsToRemove;
        totalCreationNfts -= totalCreationNftsToRemove;
        totalStakedTokens -= totalTokensToRemove;
        totalStakedRealmPoints -= totalRealmPointsToRemove;
        totalBoostedStakedTokens -= totalBoostedTokensToRemove;
        totalBoostedRealmPoints -= totalBoostedRealmPointsToRemove;
    }

    
//------------------------------ Operator functions ------------------------------------------

    /**
     * @notice Stakes tokens on behalf of multiple users into multiple vaults
     * @param vaultIds Array of vault IDs to stake into
     * @param onBehalfOfs Array of addresses to stake on behalf of
     * @param amounts Array of token amounts to stake for each user
     */
    function stakeOnBehalfOf(bytes32[] calldata vaultIds, address[] calldata onBehalfOfs, uint256[] calldata amounts) external virtual 
        whenStartedAndNotEnded whenNotPaused whenNotUnderMaintenance onlyRole(Constants.CRON_JOB_ROLE) 
    {

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        (
            uint256 incomingTotalStakedTokens, 
            uint256 incomingTotalBoostedStakedTokens
        ) 
            = PoolLogic.executeStakeOnBehalfOf(activeDistributions, vaults, distributions, users, vaultAccounts, userAccounts, params, vaultIds, onBehalfOfs, amounts);

        // update storage: variables
        totalStakedTokens += incomingTotalStakedTokens;
        totalBoostedStakedTokens += incomingTotalBoostedStakedTokens;
        
        // grab MOCA: from msg.sender to this contract
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), incomingTotalStakedTokens);
    }

    /*//////////////////////////////////////////////////////////////
                            POOL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the end time for the staking pool
     * @param endTime_ The new end time for the staking pool
     */
    function setEndTime(uint256 endTime_) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(endTime > 0) revert Errors.EndTimeAlreadySet();
        if(endTime_ == 0) revert Errors.InvalidEndTime();
        if(endTime_ <= block.timestamp) revert Errors.InvalidEndTime();

        endTime = endTime_;

        emit StakingEndTimeSet(endTime_);

        // update all active distributions tt exceed endTime_
        // note: only shortens distribution endTime, does not extend
        for(uint256 i; i < activeDistributions.length; ++i){
            uint256 distributionId = activeDistributions[i];

            DataTypes.Distribution storage distribution = distributions[distributionId];

            if(distribution.endTime > 0) {

                if(distribution.endTime > endTime_) {
                    // endTime_ is in the future, so newTotalRequired is +ve (and > totalEmitted)
                    uint256 newTimeLeft = endTime_ - distribution.lastUpdateTimeStamp;
                    uint256 newTotalRequired = (newTimeLeft * distribution.emissionPerSecond) + distribution.totalEmitted;
                    
                    // update storage
                    distribution.endTime = endTime_;
                    // update rewards vault
                    if(distributionId > 0) REWARDS_VAULT.updateDistribution(distributionId, newTotalRequired);
                }

            } else{
                
                // D0: endTime is not set
                distribution.endTime = endTime_;
            }
        }
    }

    /**
     * @notice Updates the rewards vault address
     * @param newRewardsVault The address of the new rewards vault contract
     * @dev reverts if there are active token distributions - D0 is allowed
     */
    function setRewardsVault(address newRewardsVault) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(newRewardsVault == address(0)) revert Errors.InvalidAddress();   

        // other than D0, there should not be any other active distributions
        if(activeDistributions.length > 1) revert Errors.ActiveTokenDistributions();

        emit RewardsVaultSet(address(REWARDS_VAULT), newRewardsVault);
        REWARDS_VAULT = IRewardsVault(newRewardsVault);    
    }

    /**
     * @notice Updates the maximum number of active distributions allowed
     * @dev Cannot reduce below current number of active distributions
     * @param newMaxActiveAllowed The new maximum number of active distributions to allow
     */
    function updateMaxActiveDistributions(uint256 newMaxActiveAllowed) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(newMaxActiveAllowed == 0) revert Errors.InvalidMaxActiveAllowed();
        if(newMaxActiveAllowed < activeDistributions.length) revert Errors.MaxActiveDistributions();

        MAX_ACTIVE_DISTRIBUTIONS = newMaxActiveAllowed;

        emit MaximumActiveDistributionsUpdated(newMaxActiveAllowed);
    }

    /**
     * @notice Updates the maximum fee factor; dictates the amount of rewards that go to moca stakers
     * @dev Fee factor can be 0, in which case all rewards go to moca stakers
     * @dev Fee factor cannot exceed PRECISION_BASE; else fees would exceed 100%
     * @param newFactor The new maximum fee factor to set
     */
    function updateMaximumFeeFactor(uint256 newFactor) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(newFactor > Constants.PRECISION_BASE) revert Errors.InvalidMaxFeeFactor();

        uint256 oldFactor = MAXIMUM_FEE_FACTOR;
        MAXIMUM_FEE_FACTOR = newFactor;

        emit MaximumFeeFactorUpdated(oldFactor, newFactor);
    }

    /**
     * @notice Updates the minimum realm points required for staking
     * @param newAmount The new minimum realm points required
    */
    function updateMinimumRealmPoints(uint256 newAmount) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(newAmount == 0) revert Errors.InvalidAmount();
        
        uint256 oldAmount = MINIMUM_REALMPOINTS_REQUIRED;
        MINIMUM_REALMPOINTS_REQUIRED = newAmount;

        emit MinimumRealmPointsUpdated(oldAmount, newAmount);
    }

    /**
     * @notice Updates the number of NFTs required to create a vault
     * @dev Zero values are accepted, allowing vault creation without NFT requirements
     * @param newAmount The new number of NFTs required for vault creation
     */
    function updateCreationNfts(uint256 newAmount) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        uint256 oldAmount = CREATION_NFTS_REQUIRED;
        CREATION_NFTS_REQUIRED = newAmount; 

        emit CreationNftRequiredUpdated(oldAmount, newAmount);
    }

    /**
     * @notice Updates the cooldown duration for vaults.
     * @notice Changes are meant to be forward-looking; i.e. they will only affect future vaults.
     * @dev Zero values are accepted. New duration can be less or more than current value
     * @param newDuration The new cooldown duration to set
     */
    function updateVaultCooldown(uint256 newDuration) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        emit VaultCooldownDurationUpdated(VAULT_COOLDOWN_DURATION, newDuration);     
        VAULT_COOLDOWN_DURATION = newDuration;
    }

    /**
     * @notice Sets up a new token distribution schedule. Cannot exceed max.
     * @dev Distribution must not already exist.
     * @dev Distribution ID 0 is reserved for staking power and is the only ID allowed to have indefinite endTime
     * @param distributionId Unique identifier for this distribution (0 reserved for staking power)
     * @param distributionStartTime Timestamp when distribution begins, must be in the future
     * @param distributionEndTime Timestamp when distribution ends (0 allowed only for ID 0)
     * @param emissionPerSecond Rate of token emissions per second (must be > 0)
     * @param tokenPrecision Decimal precision for the distributed token (must be > 0)
     */
    function setupDistribution(uint256 distributionId, uint256 distributionStartTime, uint256 distributionEndTime, uint256 emissionPerSecond, uint256 tokenPrecision,
        uint32 dstEid, bytes32 tokenAddress
    ) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {

        // cannot exceed max
        if(activeDistributions.length >= MAX_ACTIVE_DISTRIBUTIONS) revert Errors.MaxActiveDistributions();

        // d0 must be first
        if(activeDistributions.length == 0) {
            if(distributionId != 0) revert Errors.InvalidDistributionId();
        }
            
        if(tokenPrecision == 0) revert Errors.ZeroTokenPrecision();
        if(emissionPerSecond == 0) revert Errors.ZeroEmissionRate();

        // distributionStartTime has implicit zero check
        if(distributionStartTime < startTime) revert Errors.InvalidDistributionStartTime();
        if(distributionStartTime < block.timestamp) revert Errors.InvalidDistributionStartTime();

        // contract endTime check
        if(endTime > 0){
            // distribution start and end times must be <= endTime
            if(distributionEndTime > endTime) revert Errors.InvalidEndTime();
            if(distributionStartTime > endTime) revert Errors.InvalidStartTime();
        }

        // rebase check: smallest tick rebased must be > 0. sanity checks _calculateDistributionIndex 
        uint256 emissionPerSecondRebased = (emissionPerSecond * 1E18) / tokenPrecision;
        if(emissionPerSecondRebased == 0) revert Errors.RebasedEmissionRateIsZero();
    
        // token distributions must have valid dstEid + tokenAddress
        if(distributionId > 0){
            // endTime must be > startTime
            if(distributionEndTime <= distributionStartTime) revert Errors.InvalidDistributionEndTime();

            // LZ sanity checks
            if(dstEid == 0) revert Errors.InvalidDstEid();
            if(tokenAddress == bytes32(0)) revert Errors.InvalidTokenAddress();

        } else{
            
            // D0: endTime is 0
            distributionEndTime = 0;
        }

        // lazy load startTime, instead of entire struct
        DataTypes.Distribution storage distributionPointer = distributions[distributionId]; 
        
        // check if fresh id
        if(distributionPointer.startTime > 0) revert Errors.DistributionAlreadySetup();
            
        // Initialize struct
        DataTypes.Distribution memory distribution;
            distribution.distributionId = distributionId;
            distribution.TOKEN_PRECISION = tokenPrecision;
            distribution.endTime = distributionEndTime;
            distribution.startTime = distributionStartTime;
            distribution.emissionPerSecond = emissionPerSecond;
            distribution.lastUpdateTimeStamp = distributionStartTime;

        // update storage
        distributions[distributionId] = distribution;

        // update distribution tracking
        activeDistributions.push(distributionId);

        emit DistributionCreated(distributionId, distributionStartTime, distributionEndTime, emissionPerSecond, tokenPrecision);
        

        // REWARDS_VAULT setup: only for non-staking power distributions
        if(distributionId > 0) {

            uint256 totalRequired = (distributionEndTime - distributionStartTime) * emissionPerSecond;
            REWARDS_VAULT.setupDistribution(distributionId, dstEid, tokenAddress, totalRequired);
        }
    }

    /** 
     * @notice Updates the parameters of an existing distribution
     * @dev Can modify:
     *      - startTime (only if distribution hasn't started)
     *      - endTime (can extend or shorten, must be > block.timestamp)
     *      - emission rate (can be modified at any time)
     * @dev At least one parameter must be modified (non-zero)
     * @param distributionId ID of the distribution to update
     * @param newStartTime New start time for the distribution. Must be > block.timestamp if modified
     * @param newEndTime New end time for the distribution. Must be > block.timestamp if modified
     * @param newEmissionPerSecond New emission rate per second. Must be > 0 if modified
     */
    function updateDistribution(uint256 distributionId, uint256 newStartTime, uint256 newEndTime, uint256 newEmissionPerSecond) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        // contract startTime check
        if(newStartTime > 0){
            if(newStartTime < startTime) revert Errors.InvalidStartTime();
        }

        // contract endTime check
        if(endTime > 0){
            // newEndTime must be <= endTime
            if(newEndTime > endTime) revert Errors.InvalidEndTime();
            // newStartTime must be <= endTime
            if(newStartTime > endTime) revert Errors.InvalidStartTime();
        }

        // all null inputs: also checks for zero emission scenario
        uint256 totalInputs = newStartTime + newEndTime + newEmissionPerSecond;
        if(totalInputs == 0) revert Errors.InvalidDistributionParameters(); 

        uint256 newTotalRequired = PoolLogic.executeUpdateDistributionParams(distributions, distributionId, newStartTime, newEndTime, newEmissionPerSecond, 
            totalBoostedRealmPoints, totalBoostedStakedTokens);

        // transfer rewards to user, from rewardsVault
        if(distributionId > 0) REWARDS_VAULT.updateDistribution(distributionId, newTotalRequired);
    }

    /**
     * @notice Immediately ends a distribution
     * @param distributionId ID of the distribution to end
     */
    function endDistributionManually(uint256 distributionId) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(distributionId == 0) revert Errors.InvalidDistributionId();
        DataTypes.Distribution memory distribution = distributions[distributionId];
        
        if(distribution.startTime == 0) revert Errors.NonExistentDistribution();
        if(block.timestamp >= distribution.endTime) revert Errors.DistributionEnded();

        if(distribution.manuallyEnded == 1) revert Errors.DistributionManuallyEnded();
   
        // update distribution index
        distribution = PoolLogic.executeUpdateDistributionIndex(distribution, totalBoostedRealmPoints, totalBoostedStakedTokens);

        // end distribution
        distribution.manuallyEnded = 1;
        // distributions that have not started yet, will not have lastUpdateTimestamp be updated in executeUpdateDistributionIndex
        distribution.endTime = distribution.lastUpdateTimeStamp = block.timestamp; 

        // update storage   
        distributions[distributionId] = distribution;

        emit DistributionEnded(distributionId, distribution.endTime, distribution.totalEmitted);

        // only for token distributions
        REWARDS_VAULT.endDistribution(distributionId, distribution.totalEmitted);
    }

    /**
        ended distributions are not removed automatically from activeDistributions array. 
        this is intentional.
        it is the responsibility of the operator to remove ended distributions from the activeDistributions array.
        this is done via the popEndedDistribution function.

        Process:
        1. CRON_JOB calls updateAllVaultAccounts(vaultIds[], distributionId)
        2. Ensure all vaults are updated against the recently ended distribution
        3. Once confirmed, OPERATOR call popEndedDistribution(distributionId)
            - OPERATOR could be owner multisig
     */

    /**
     * @notice Removes an ended distribution from the active distributions list
     * @dev Can only be called by the operator
     * @param distributionId The ID of the distribution to remove
     */
    function popEndedDistribution(uint256 distributionId) external whenNotEnded whenNotPaused onlyRole(Constants.OPERATOR_ROLE) {
        if(distributionId == 0) revert Errors.InvalidDistributionId();
        
        // get distribution
        DataTypes.Distribution storage distribution = distributions[distributionId];

        // sanity checks
        if(distribution.startTime == 0) revert Errors.NonExistentDistribution();
        if(block.timestamp < distribution.endTime) revert Errors.DistributionNotEnded();
        if(distribution.lastUpdateTimeStamp != distribution.endTime) revert Errors.DistributionNotUpdated();

        uint256 numOfActiveDistributions = activeDistributions.length;
        
        // Remove from active distributions and mark as completed
        bool found = false;
        for (uint256 i; i < numOfActiveDistributions; ++i) {
            if (activeDistributions[i] == distributionId) {
                // Move last element to current position and pop
                activeDistributions[i] = activeDistributions[numOfActiveDistributions - 1];
                activeDistributions.pop();
                found = true;
                break;
            }
        }

        if(!found) revert Errors.DistributionNotFound();
        
        emit DistributionPopped(distributionId);
    }


//-----------------------------  MAINTENANCE: RP, NFT  ---------------------------------------------


    /*//////////////////////////////////////////////////////////////
                            MAINTENANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets contract to maintenance mode for operational updates
     */
    function enableMaintenance() external whenNotEnded whenNotPaused whenNotUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        if(isUnderMaintenance == 1) revert Errors.InMaintenance();
        
        isUnderMaintenance = 1;
        emit MaintenanceEnabled(block.timestamp);
    }

    /**
     * @notice Disables maintenance mode
     */
    function disableMaintenance() external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        if(isUnderMaintenance == 0) revert Errors.NotInMaintenance();
        
        isUnderMaintenance = 0;
        emit MaintenanceDisabled(block.timestamp);
    }

//-----------------------------  MAINTENANCE: RP  ---------------------------------------------------

    
    /*//////////////////////////////////////////////////////////////
                            RESETTING RP 
    //////////////////////////////////////////////////////////////*/


    /**    
        1. enableMaintenance
        2. updateActiveDistributions
        3. updateAllVaultAccounts
        4. resetRealmPoints
        5. incrementSeason
        6. disableMaintenance
     */


    /**
     * @notice Resets realm points for the current season for a specific vault and set of users
     * @dev Loops through users for a specific vault to reset realm points
     * @param vaultId The ID of the vault to reset realm points for
     * @param userAddresses Array of user addresses whose realm points will be reset
     */
    function resetRealmPoints(bytes32 vaultId, address[] calldata userAddresses) external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        
        // get num of users + sanity check
        uint256 numOfUsers = userAddresses.length;
        if(numOfUsers == 0) revert Errors.InvalidArray();

        // get vault + sanity check
        DataTypes.Vault storage vault = vaults[vaultId];
        if(vault.creator == address(0)) revert Errors.NonExistentVault(vaultId);

        // counters
        uint256 baseRealmPointsSum;
        uint256 boostedRealmPointsSum;

        // loop thru all users against the same vault
        for(uint256 i; i < numOfUsers; ++i){
            address user = userAddresses[i];

            // get user assets for specified vault
            DataTypes.User storage userVaultAssets = users[user][vaultId];
            
            // increment counter
            baseRealmPointsSum += userVaultAssets.stakedRealmPoints;
            
            // reset user's rp
            delete userVaultAssets.stakedRealmPoints;
        }

        // calculate boosted rp
        boostedRealmPointsSum += (baseRealmPointsSum * vault.totalBoostFactor) / Constants.PRECISION_BASE;


        // decrement vault totals
        vault.stakedRealmPoints -= baseRealmPointsSum;
        vault.boostedRealmPoints -= boostedRealmPointsSum;


        // decrement global totals
        totalStakedRealmPoints -= baseRealmPointsSum;
        totalBoostedRealmPoints -= boostedRealmPointsSum;

        emit RealmPointsReset(vaultId, userAddresses, baseRealmPointsSum, boostedRealmPointsSum);
    }


    /**
     * @notice Increments the season
     */
    function incrementSeason() external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        if(totalBoostedRealmPoints > 0) revert Errors.RpNotResetCorrectly();
        if(totalBoostedStakedTokens > 0) revert Errors.RpNotResetCorrectly();

        ++SEASON;

        emit SeasonIncremented(SEASON);
    }


//-----------------------------  MAINTENANCE: NFT  ---------------------------------------------


    /*//////////////////////////////////////////////////////////////
                            NFT MULTIPLIER
    //////////////////////////////////////////////////////////////*/


    /**    
        1. enableMaintenance
        2. updateActiveDistributions
        3. updateAllVaultAccounts
        4. updateNftMultiplier
        5. updateBoostedBalances
        6. disableMaintenance
     */
     

    /**
     * @notice Updates active distribution indexes
     * @dev Updates all active distribution indexes to current timestamp 
     * @dev This ensures all rewards are properly calculated and booked
     */
    function updateActiveDistributions() external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {

        uint256 numOfDistributions = activeDistributions.length;
        
        if(numOfDistributions > 0){           
            
            for(uint256 i; i < numOfDistributions; ++i) {
                
                uint256 distributionId = activeDistributions[i];

                // update distribution index
                distributions[distributionId] 
                        = PoolLogic.executeUpdateDistributionIndex(distributions[distributionId], totalBoostedRealmPoints, totalBoostedStakedTokens);
            }

            emit DistributionsUpdated(activeDistributions);
        }
    }

    /**
     * @notice Updates each vault's vault account, for specified distribution
     * @dev distribution.lastUpdateTimeStamp is not checked, we expect distributions to be updated in updateDistributions()
     * @param vaultIds Array of vault IDs to update
     */
    function updateAllVaultAccounts(bytes32[] calldata vaultIds, uint256 distributionId) external whenNotEnded whenNotPaused {
        
        if(isUnderMaintenance == 1){
            // caller must have OPERATOR role
            if(!hasRole(Constants.OPERATOR_ROLE, msg.sender)) revert Errors.InvalidCaller();
        } else {
            // caller must have CRON_JOB role
            if(!hasRole(Constants.CRON_JOB_ROLE, msg.sender)) revert Errors.InvalidCaller();
        }

        uint256 numOfVaults = vaultIds.length;
        if(numOfVaults == 0) revert Errors.InvalidArray();

        DataTypes.Distribution memory distribution = distributions[distributionId];
        // distribution must have started: else no emissions, nothing pending to book
        if(distribution.startTime > block.timestamp) revert Errors.DistributionNotStarted();        
        // do not enforce this check: update process could be long, and result in time drift
        //if(distribution.lastUpdateTimeStamp < block.timestamp) revert Error.NotUpdated;

        DataTypes.UpdateAccountsIndexesParams memory params;
            //params.user = msg.sender; -> NOT USED
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        PoolLogic.executeUpdateVaultsAndAccounts(vaults, vaultAccounts, distribution, params, vaultIds, numOfVaults);

        emit VaultAccountsUpdated(vaultIds);
    }    

    /**
     * @notice Updates the NFT multiplier used to calculate boost factors
     * @param newMultiplier The new multiplier value to set
     */
    function updateNftMultiplier(uint256 newMultiplier) external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        if(newMultiplier == 0) revert Errors.InvalidMultiplier();
        
        uint256 oldMultiplier = NFT_MULTIPLIER;
        NFT_MULTIPLIER = newMultiplier;

        emit NftMultiplierUpdated(oldMultiplier, newMultiplier);
    }

    /**
     * @notice Updates boosted balances for specified vaults using the current NFT multiplier
     * @dev Should only be called after NFT_MULTIPLIER has been updated. Recalculates boost factors and updates global totals.
     * @param vaultIds Array of vault IDs to update boosted balances 
     */
    function updateBoostedBalances(bytes32[] calldata vaultIds) external whenNotEnded whenNotPaused whenUnderMaintenance onlyRole(Constants.OPERATOR_ROLE) {
        uint256 numOfVaults = vaultIds.length;
        if(numOfVaults == 0) revert Errors.InvalidArray();

        // for each vault
        for(uint256 i; i < numOfVaults; ++i) {
            
            bytes32 vaultId = vaultIds[i];

            // get vault + ensure it exists
            DataTypes.Vault memory vault = vaults[vaultId];
            if(vault.creator == address(0)) revert Errors.NonExistentVault(vaultId);

            // decrement global totals before updating vault
            totalBoostedRealmPoints -= vault.boostedRealmPoints;
            totalBoostedStakedTokens -= vault.boostedStakedTokens;

            // update vault with new multiplier
            vault.totalBoostFactor = (vault.stakedNfts * NFT_MULTIPLIER) + Constants.PRECISION_BASE;  // expressed as 1.XXX
            vault.boostedRealmPoints = (vault.stakedRealmPoints * vault.totalBoostFactor) / Constants.PRECISION_BASE;    
            vault.boostedStakedTokens = (vault.stakedTokens * vault.totalBoostFactor) / Constants.PRECISION_BASE;

            // Write back vault changes to storage
            vaults[vaultId] = vault;

            // increment global totals with new values
            totalBoostedRealmPoints += vault.boostedRealmPoints;
            totalBoostedStakedTokens += vault.boostedStakedTokens;
        }

        emit BoostedBalancesUpdated(vaultIds);
    }

//------------------------------- risk -------------------------------------------------------

    /**
     * @notice Pause pool. Cannot pause once frozen
     */
    function pause() external whenNotPaused onlyRole(Constants.MONITOR_ROLE) {
        if(isFrozen == 1) revert Errors.IsFrozen(); 
        _pause();
    }

    /**
     * @notice Unpause pool. Cannot unpause once frozen
     */
    function unpause() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if(isFrozen == 1) revert Errors.IsFrozen(); 
        _unpause();
    }

    /**
     * @notice To freeze the pool in the event of something untoward occurring
     * @dev Only callable from a paused state, affirming that staking should not resume
     *      Nothing to be updated. Freeze as is.
     *      Enables emergencyExit() to be called.
     */
    function freeze() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if(isFrozen == 1) revert Errors.IsFrozen();
        isFrozen = 1;
        emit PoolFrozen(block.timestamp);
    }  


    /*//////////////////////////////////////////////////////////////
                            EMERGENCY EXIT
    //////////////////////////////////////////////////////////////*/
    
    /** 
     * @notice Allows users to recover their principal assets when contract is frozen
     * @dev Rewards and fees are not withdrawn; indexes are not updated. Preserves state history at time of failure.
     * @param vaultIds Array of vault IDs to recover assets from
     * @param onBehalfOf Address to receive the recovered assets
     */
    function emergencyExit(bytes32[] calldata vaultIds, address onBehalfOf) external whenStarted { 
        if(isFrozen == 0) revert Errors.NotFrozen();
        if(vaultIds.length == 0) revert Errors.InvalidArray();

        // if caller is not OPERATOR, can only call for self
        if(!hasRole(Constants.OPERATOR_ROLE, msg.sender)){
            onBehalfOf = msg.sender;
        }

        uint256 userTotalStakedNfts;
        uint256 userTotalStakedTokens;
        uint256 userTotalCreationNfts;

        for(uint256 i; i < vaultIds.length; ++i){

            // get vault + check if has been created            
            bytes32 vaultId = vaultIds[i];
            DataTypes.Vault storage vault = vaults[vaultId];
            if(vault.creator == address(0)) revert Errors.NonExistentVault(vaultId);

            // get user data for vault
            DataTypes.User storage userVaultAssets = users[onBehalfOf][vaultId];

            // check user has non-zero holdings
            uint256 stakedNfts = userVaultAssets.tokenIds.length;
            uint256 stakedTokens = userVaultAssets.stakedTokens;       
            if (
                !(vault.creator == onBehalfOf && vault.creationTokenIds.length > 0)     // if creator, check if there are creator nfts to retrieve 
                && stakedNfts == 0                                                       // user has no staked nfts
                && stakedTokens == 0                                                     // user has no staked tokens 
                ) revert Errors.UserHasNothingStaked(vaultId, onBehalfOf);

            // update balances: user + vault
            if(stakedTokens > 0){

                // decrement
                vault.stakedTokens -= stakedTokens;
                delete userVaultAssets.stakedTokens;
                
                // track total
                userTotalStakedTokens += stakedTokens;
            }

            uint256[] memory userTotalTokenIds;

            // update balances: user + vault
            if(stakedNfts > 0){

                // track total
                userTotalTokenIds = PoolLogic.concatArrays(userTotalTokenIds, userVaultAssets.tokenIds);
                userTotalStakedNfts += stakedNfts;

                // decrement
                vault.stakedNfts -= stakedNfts;
                delete userVaultAssets.tokenIds;
            }

            // creation nfts
            if(vault.creator == onBehalfOf){

                userTotalTokenIds = PoolLogic.concatArrays(userTotalTokenIds, vault.creationTokenIds);
                userTotalCreationNfts += vault.creationTokenIds.length;

                delete vault.creationTokenIds;
            }

            // record unstake with registry, else users nfts will be locked in locker
            NFT_REGISTRY.recordUnstake(onBehalfOf, userTotalTokenIds, vaultId);
            emit NftsExited(onBehalfOf, vaultId, userTotalTokenIds);        
        }

        // update global
        totalStakedNfts -= userTotalStakedNfts;
        totalStakedTokens -= userTotalStakedTokens;
        totalCreationNfts -= userTotalCreationNfts;

        // return total principal staked
        if(userTotalStakedTokens > 0) STAKED_TOKEN.safeTransfer(onBehalfOf, userTotalStakedTokens); 
        emit TokensExited(onBehalfOf, vaultIds, userTotalStakedTokens);      

        /** Note:
            
            `emergencyExit()` assumes that the contract is broken and any state updates made to be invalid; hence it does not update rewards and fee calculations.
            Focus is for users to recover their principal assets as quickly as possible. 

            To that end, we do not zero out/decrement/re-calculate the following values: 
                1. totalBoostedRealmPoints
                2. totalBoostedStakedTokens
                3. vault.totalBoostFactor
                4. vault.boostedRealmPoints
                5. vault.boostedStakedTokens
        */
    }

//-------------------------------internal-----------------------------------------------------

    ///@dev Generate a vaultId. keccak256 is cheaper than using a counter with a SSTORE, even accounting for eventual collision retries.
    function _generateVaultId(uint256 salt, address user) internal view returns (bytes32) {
        return bytes32(keccak256(abi.encode(user, block.timestamp, salt)));
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    //REDUCES CONTRACT SIZE
    function _whenStarted() internal view {
        if(block.timestamp < startTime) revert Errors.NotStarted();    
    }

    //note > or >= ?
    function _whenNotEnded() internal view {
        if(endTime > 0 && block.timestamp > endTime) revert Errors.StakingEnded();
    }

    function _whenNotFrozen() internal view {
        if(isFrozen == 1) revert Errors.IsFrozen();
    }

    function _whenUnderMaintenance() internal view {
        if(isUnderMaintenance == 0) revert Errors.NotInMaintenance();
    }

    function _whenNotUnderMaintenance() internal view {
        if(isUnderMaintenance == 1) revert Errors.InMaintenance();
    }

    modifier whenStartedAndNotEnded() {
        _whenStarted();
        _whenNotEnded();
        _;
    }

    modifier whenStarted() {
        _whenStarted();
        _;
    }

    modifier whenNotEnded() {
        _whenNotEnded();
        _;
    }

    modifier whenNotFrozen() {
        _whenNotFrozen();
        _;
    }
    
    modifier whenUnderMaintenance() {
        _whenUnderMaintenance();
        _;
    }

    modifier whenNotUnderMaintenance() {
        _whenNotUnderMaintenance();
        _;
    }

//-------------------------------view--------------------------------------------------------- 

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the number of active distributions
     * @return The length of the activeDistributions array
     */
    function getActiveDistributionsLength() external view returns (uint256) {
        return activeDistributions.length;
    }
    
    // to help with returning nested array: uint256[] creationTokenIds
    function getVault(bytes32 vaultId) external view returns (DataTypes.Vault memory) { 
        return vaults[vaultId];
    }
    
    // to help with returning nested array: uint256[] tokenIds
    function getUser(address user, bytes32 vaultId) external view returns (DataTypes.User memory) { 
        return users[user][vaultId];
    }

    function getClaimableRewards(address user, bytes32 vaultId, uint256 distributionId) external view returns(uint256) {

        // staking not started: return early
        if (block.timestamp <= startTime) return 0;

        DataTypes.UpdateAccountsIndexesParams memory params;
            params.user = user;   
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        // calc. unbooked
        uint256 totalUnclaimedRewards
         = PoolLogic.viewClaimRewards(vaults, distributions, users, vaultAccounts, userAccounts, params, 
            distributionId);

        // latest value, storage not updated
        return totalUnclaimedRewards;
    }


    function getUpdatedDistribution(uint256 distributionId) external view returns (DataTypes.Distribution memory) {

        // get latest distributionIndex, if not already updated
        DataTypes.Distribution memory distribution = PoolLogic.viewDistributionIndex(
            distributions[distributionId], 
            totalBoostedRealmPoints, 
            totalBoostedStakedTokens
        );

        return distribution;
    }

    function getUpdatedVaultAccount(bytes32 vaultId, uint256 distributionId) external view 
        returns (DataTypes.VaultAccount memory, DataTypes.Distribution memory) {
        
        DataTypes.UpdateAccountsIndexesParams memory params;
            params.vaultId = vaultId;
            params.totalBoostedRealmPoints = totalBoostedRealmPoints;
            params.totalBoostedStakedTokens = totalBoostedStakedTokens;

        (
            DataTypes.VaultAccount memory vaultAccount, 
            DataTypes.Distribution memory distribution
        ) 
            = PoolLogic.viewVaultAccount(
                vaults[vaultId], 
                vaultAccounts[vaultId][distributionId], 
                distributions[distributionId], 
                params);

        return (vaultAccount, distribution);
    }

    function getUpdatedUserAccount(address user, bytes32 vaultId, uint256 distributionId) external view 
        returns (DataTypes.UserAccount memory, DataTypes.VaultAccount memory, DataTypes.Distribution memory) {

            DataTypes.UpdateAccountsIndexesParams memory params;
                params.user = user;
                params.vaultId = vaultId;
                params.totalBoostedRealmPoints = totalBoostedRealmPoints;
                params.totalBoostedStakedTokens = totalBoostedStakedTokens;

            (
                DataTypes.UserAccount memory userAccount, 
                DataTypes.VaultAccount memory vaultAccount, 
                DataTypes.Distribution memory distribution
            ) 
                = PoolLogic.viewUserAccount(
                    users[user][vaultId], 
                    userAccounts[user][vaultId][distributionId], 
                    vaults[vaultId], 
                    vaultAccounts[vaultId][distributionId],
                    distributions[distributionId], 
                    params);

            return (userAccount, vaultAccount, distribution);
    }
}