// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library Errors {

    // generic (used across multiple functions)
    error NotStarted();
    error StakingEnded();
    error InvalidArray();
    error InvalidAmount();
    error InvalidEndTime();
    error InvalidVaultId();
    error InvalidAddress();
    error InvalidStartTime();
    error UserIsNotCreator();
    error InvalidDistributionId();
    error VaultEndTimeSet(bytes32 vaultId);
    error NonExistentVault(bytes32 vaultId);

    // createVault
    error InvalidCreationNfts();
    error InvalidNfts();
    error MaximumFeeFactorExceeded();
    error NoActiveDistributions();

    // stakeRealmPoints
    error SignatureExpired();
    error MinimumRealmPointsRequired();
    error InvalidSignature();
    error UserHasNothingStaked(bytes32 vaultId, address user);
    // migrateRealmPoints
    error InsufficientRealmPoints(uint256 userStakedRealmPoints);

    // claimRewards
    error NotEligibleForRewards();
    error StakingPowerDistribution();
    error DistributionDoesNotExist();

    // activateCooldown
    error VaultAlreadyRemoved();

    // setRewardsVault
    error ActiveTokenDistributions();

    // updateActiveDistributions
    error InvalidMaxActiveAllowed();

    // updateMaximumFeeFactor   
    error InvalidMaxFeeFactor();

    // updateVaultFees
    error CreatorFeeCanOnlyBeDecreased();
    error NftFeeCanOnlyBeIncreased();
    error RealmPointsFeeCanOnlyBeIncreased();
    error IncorrectFeeComposition();

    // setupDistribution
    error MaxActiveDistributions();
    error ZeroTokenPrecision();
    error ZeroEmissionRate();
    error InvalidDistributionStartTime();
    error InvalidDistributionEndTime();
    error InvalidDstEid();
    error InvalidTokenAddress();
    error DistributionAlreadySetup();
    error RebasedEmissionRateIsZero();
    // updateDistribution
    error InvalidDistributionParameters();
    error NonExistentDistribution();
    error DistributionStarted();
    error DistributionEnded();
    error InvalidEmissionPerSecond();
    error InvalidNewTotalRequired();
    error CannotEndStakingPowerDistribution();
    error InvalidDuration();
    // endDistributionImmediately
    error DistributionManuallyEnded();
    // popEndedDistribution
    error DistributionNotEnded();
    error DistributionNotUpdated();
    error DistributionNotFound();

    // updateAllVaultAccounts
    error DistributionNotStarted();
    error InvalidCaller();
    // updateNftMultiplier
    error InvalidMultiplier();

    // freeze
    error IsFrozen();
    error NotFrozen();

    // Operator+Maintenance
    error NotInMaintenance();
    error InMaintenance();

// -------------------------------------- RewardsVault + EvmVault ------------------------------------------------------
    
    error InsufficientDeposit();
    error DistributionNotSetup();
    error ExcessiveDeposit();
    error InsufficientBalance();
    // payRewards::V2
    error InsufficientGas();
    error PayableBlocked();
    // deposit::V2
    error CallDepositOnRemote();
    // collectUnclaimedRewards
    error NoUnclaimedRewards();
    // updateRemoteBalance
    error InvalidOrigin();
    // bytes32ToAddress
    error SafeCastOverflowedUintDowncast();
    error InvalidReceiverAddress();
}