// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library Constants {

    /**
        If you wish to changes the level of precision, you must update PRECISION_BASE
        and ensure that all feeFactors are expressed in the new precision.
     */

    /*//////////////////////////////////////////////////////////////
                            GLOBAL
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");   // only pause



    /*//////////////////////////////////////////////////////////////
                            STAKINGPRO
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE"); // admin fns to update pool params
    bytes32 public constant CRON_JOB_ROLE = keccak256("CRON_JOB_ROLE"); // cron job to update ended distributions

    // nft multiplier
    uint256 public constant PRECISION_BASE = 10_000;   // feeFactors & nft multiplier expressed in 2dp precision (XX.yy)

    // signature params
    bytes32 public constant TYPEHASH = keccak256("StakeRealmPoints(address user,bytes32 vaultId,uint256 amount,uint256 expiry,uint256 nonce)");



    /*//////////////////////////////////////////////////////////////
                            REWARDSVAULT
    //////////////////////////////////////////////////////////////*/

    // roles
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");
    bytes32 public constant MONEY_MANAGER_ROLE = keccak256("MONEY_MANAGER_ROLE"); // withdraw/deposit

    // LZ constants
    uint32 public constant LOCAL_EID = 30184; // base mainnet

    // LZ Options
    uint128 public constant GAS_LIMIT = 90_000;
}
