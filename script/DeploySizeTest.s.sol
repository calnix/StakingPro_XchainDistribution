// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {StakingPro, Constants} from "../src/StakingPro.sol";
import {RewardsVaultV1} from "../src/RewardsVaultV1.sol";
import {NftRegistry} from "./../lib/NftLocker/src/NftRegistry.sol";

// mocks
import {ERC20Mock} from "./../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "./../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeploySizeTest is Script {
    StakingPro public pool;
    RewardsVaultV1 public rewardsVault;

    ERC20Mock public mockToken;

    function addressToBytes32(address addr) public pure returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddress(bytes32 bytes32_) public pure returns(address) {
        return address(uint160(uint256(bytes32_)));
    }

    function run() public {
        console.log("Deploying StakingPro...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TEST");
        vm.startBroadcast(deployerPrivateKey);
        
        // constructor params
        address registry = 0xCd76E8D37b5C7258197581d15dBf7D80e6106c69;
        address stakedToken = 0x012fA6C1295278F922D8ca0C5c770cf32dDDbF26;
        
        // Set start time to 24 hours in the future
        uint256 startTime_ = block.timestamp + 10;
        uint256 nftMultiplier = 1000; // 10% boost
        uint256 creationNftsRequired = 5;
        uint256 vaultCoolDownDuration = 7 days;
        address owner = 0x8C9C001F821c04513616fd7962B2D8c62f925fD2;
        address storedSigner = 0x4260426ab18239De6678A5d2B6aDb31916D624D3;
        //uint256 storedSignerPrivateKey;

        // .... deploy contracts ....

        // signer
        //(storedSigner, storedSignerPrivateKey) = makeAddrAndKey("storedSigner");
        //console.log("Stored signer:", storedSigner);
        //console.log("Stored signer private key:", storedSignerPrivateKey);

        pool = new StakingPro(
            registry,
            stakedToken, 
            startTime_,
            nftMultiplier,
            creationNftsRequired,
            vaultCoolDownDuration,
            owner,
            owner,
            owner,
            storedSigner,
            "StakingPro",
            "1"
        );

        console.log("Deployed StakingPro at:", address(pool));

        vm.stopBroadcast();
    }
}

// forge script script/DeploySizeTest.s.sol:DeploySizeTest --rpc-url base_sepolia --broadcast --verify -vvvvv --etherscan-api-key base_sepolia

contract Unpause is Script {
    function run() public {
        console.log("Unpausing StakingPro...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TEST");
        vm.startBroadcast(deployerPrivateKey);

        address stakingPro = 0xF9077ef2e7DA4e6EF9B8f2cEA3f3FE851050dBF4;
        StakingPro(stakingPro).unpause();   
    }
}

// forge script script/DeploySizeTest.s.sol:Unpause --rpc-url base_sepolia --broadcast --verify -vvvvv --etherscan-api-key base_sepolia