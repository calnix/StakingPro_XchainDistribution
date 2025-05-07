// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {StakingPro, Constants} from "../src/StakingPro.sol";
import {RewardsVaultV1} from "../src/RewardsVaultV1.sol";
import {NftRegistry} from "./../lib/NftLocker/src/NftRegistry.sol";

// mocks
import {ERC20Mock} from "./../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "./../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployTest is Script {
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

        rewardsVault = new RewardsVaultV1(
            owner,
            owner,
            owner,
            address(pool)
        );

        console.log("Deployed StakingPro at:", address(pool));
        console.log("Deployed RewardsVault at:", address(rewardsVault));

        // connect pool and rewardsVault
        pool.setRewardsVault(address(rewardsVault));
        NftRegistry(registry).setPool(address(pool));

        // setup distribution
        pool.setupDistribution(
            0,
            startTime_,
            0,
            1e18,
            1E18,
            0,
            bytes32(0)
        );

        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:DeployTest --rpc-url base_sepolia --broadcast --verify -vvvvv --etherscan-api-key base_sepolia

abstract contract ContractAddresses {

    address public owner = 0x8C9C001F821c04513616fd7962B2D8c62f925fD2;

    StakingPro public pool = StakingPro(0x2531f0C4A7161C0203C21BEc446757fA4D509Fb0);
    RewardsVaultV1 public rewardsVault = RewardsVaultV1(0xa8dC9344DfAbbb8d831426108da937F60514fCd8);
}

/*
contract SetUpD0 is Script, ContractAddresses {

    function run() public {
        console.log("Setting up distribution 0...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TEST");
        vm.startBroadcast(deployerPrivateKey);

        // setup distribution
        pool.setupDistribution(
            0,
            block.timestamp,
            0,
            1e18,
            1E18,
            0,
            bytes32(0)
        );

        vm.stopBroadcast();   
    }
}*/

// forge script script/DeployTest.s.sol:SetUpD0 --rpc-url base_sepolia --broadcast -vvvvv --etherscan-api-key base_sepolia


contract SetupD1 is Script, ContractAddresses {
    ERC20Mock public mockToken;
    
    function run() public {
        console.log("Setting up distribution 1...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TEST");
        vm.startBroadcast(deployerPrivateKey);

        // get pool start time
        uint256 poolStartTime = pool.startTime();

        // distribution 1
        uint256 duration = 90 days;
        uint256 startTime = poolStartTime > block.timestamp ? poolStartTime : block.timestamp + 200;
        uint256 endTime = startTime + duration;

        uint256 totalRewards = 90 ether;
        uint256 emissionPerSecond = 1 ether; // 90 / 90 days = 1 ether per day

        // mock token
        mockToken = new ERC20Mock();
        mockToken.mint(owner, totalRewards);
        mockToken.approve(address(rewardsVault), totalRewards);

        // setup distribution
        pool.setupDistribution(
            1,
            startTime,
            endTime,
            emissionPerSecond,
            1E18,
            30184,              // BASE EID
            bytes32(uint256(uint160(address(mockToken))))
        );

        // deposit rewards
        rewardsVault.deposit(1, totalRewards, owner);
        
        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:SetupD1 --rpc-url base_sepolia --broadcast -vvvvv

contract Roles is Script, ContractAddresses {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TEST");
        vm.startBroadcast(deployerPrivateKey);

        address target = 0x800954e76c4F7Fc77c0cB7E4e8EDC3Ba2065518B;

        pool.grantRole(Constants.OPERATOR_ROLE, target);
        pool.grantRole(Constants.MONITOR_ROLE, target);
        pool.grantRole(Constants.CRON_JOB_ROLE, target);

        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:Roles --rpc-url base_sepolia --broadcast -vvvvv
