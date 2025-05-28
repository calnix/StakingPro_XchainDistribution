// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import './Events.sol';
import {Errors} from './Errors.sol';
import {DataTypes} from './DataTypes.sol';
import {PoolHelpers} from './PoolHelpers.sol';

import {INftRegistry} from "./interfaces/INftRegistry.sol";

library PoolRiskLogic {

    function executeEmergencyExit(
        address onBehalfOf,
        bytes32[] calldata vaultIds, 
        mapping(bytes32 vaultId => DataTypes.Vault vault) storage vaults,
        mapping(address user => mapping(bytes32 vaultId => DataTypes.User userVaultAssets)) storage users,
        INftRegistry NFT_REGISTRY
    ) external returns(uint256, uint256, uint256){


        uint256 userTotalStakedNfts;
        uint256 userTotalStakedTokens;
        uint256 userTotalCreationNfts;
        
        for(uint256 i; i < vaultIds.length; ++i){

            // get vault + check if exists            
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

            // for both creation + staked
            uint256[] memory userTotalTokenIds;

            // update balances: user + vault
            if(stakedNfts > 0){

                // track total
                userTotalTokenIds = PoolHelpers._concatArrays(userTotalTokenIds, userVaultAssets.tokenIds);
                userTotalStakedNfts += stakedNfts;

                // decrement
                vault.stakedNfts -= stakedNfts;
                delete userVaultAssets.tokenIds;
            }

            // creation nfts
            if(vault.creator == onBehalfOf){

                userTotalTokenIds = PoolHelpers._concatArrays(userTotalTokenIds, vault.creationTokenIds);
                userTotalCreationNfts += vault.creationTokenIds.length;

                delete vault.creationTokenIds;
            }

            // record unstake with registry, else users nfts will be locked in locker
            NFT_REGISTRY.recordUnstake(onBehalfOf, userTotalTokenIds, vaultId);
            emit NftsExited(onBehalfOf, vaultId, userTotalTokenIds);   
        }

        return (userTotalStakedNfts, userTotalStakedTokens, userTotalCreationNfts);   
    }
}