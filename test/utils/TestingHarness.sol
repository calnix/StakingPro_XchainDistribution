// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2, stdStorage, StdStorage} from "forge-std/Test.sol";

//import "./../../src/StakingPro.sol";
import "./StakingProMock.sol";
import {RewardsVaultV1} from "./../../src/RewardsVaultV1.sol";
import {RewardsVaultV2} from "./../../src/RewardsVaultV2.sol";

// mocks
import "../mocks/MocaToken.sol";
import "../mocks/MockRegistry.sol";
import { EndpointV2Mock } from "../mocks/EndpointV2Mock.sol";
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

// interfaces
import {IRealmPoints} from "./../../src/interfaces/IRealmPoints.sol";
import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

// utils
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

abstract contract TestingHarness is Test {
    using stdStorage for StdStorage;

    // contracts
    StakingProMock public pool;
    RewardsVaultV1 public rewardsVault;
    RewardsVaultV2 public rewardsVaultV2;
    EndpointV2Mock public lzMock;

    // staking assets
    MocaToken public mocaToken;  
    MockRegistry public nftRegistry;   
    
    // rewards
    ERC20Mock public rewardsToken1;
    ERC20Mock public rewardsToken2;
    ERC20Mock public rewardsToken3;

    // entities
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public owner = makeAddr("owner");
    address public monitor = makeAddr("monitor");   
    address public operator = makeAddr("operator");
    address public depositor = makeAddr("depositor");
    address public deployer = makeAddr("deployer");
    address public cronJob = makeAddr("cronJob");

    // ------ staking assets ------
    // user moca
    uint256 public user1Moca = 50 ether;
    uint256 public user2Moca = 100 ether;
    uint256 public user3Moca = 150 ether;

    // user nfts
    uint256 public user1Nfts = 5;
    uint256[] public user1NftsArray = new uint256[](user1Nfts);

    uint256 public user2Nfts = 10;
    uint256[] public user2NftsArray = new uint256[](user1Nfts);

    uint256 public user3Nfts = 15;
    uint256[] public user3NftsArray = new uint256[](user1Nfts);

    // user rp
    uint256 public user1Rp = 500 ether;
    uint256 public user2Rp = 1000 ether;
    uint256 public user3Rp = 1500 ether;

    // ------ stakingPool constructor data ------
    uint256 public startTime = 1;
    uint256 public nftMultiplier = 1000;
    uint256 public creationNftsRequired = 5;
    uint256 public vaultCoolDownDuration = 1 days;

    // ecdsa
    address public storedSigner;
    uint256 public storedSignerPrivateKey;
    
    // LZ
    uint32 public dstEid = 30184; //base mainnet 

    function setUp() public virtual {
        // starting point: T0
        vm.warp(0 days); 
        vm.startPrank(deployer);

        // address endpoint, address owner, address pool, uint32 dstEid
        lzMock = new EndpointV2Mock();
        nftRegistry = new MockRegistry(address(lzMock), owner, dstEid);
        
        // mocaToken
        mocaToken = new MocaToken("MocaToken", "MOCA");   

        // signer
        (storedSigner, storedSignerPrivateKey) = makeAddrAndKey("storedSigner");

        pool = new StakingProMock(
            address(nftRegistry),
            address(mocaToken), 
            startTime,
            nftMultiplier,
            creationNftsRequired,
            vaultCoolDownDuration,
            owner,
            monitor,
            operator,
            storedSigner,
            "StakingPro",
            "1");

        // address moneyManager, address monitor, address owner, address pool
        rewardsVault = new RewardsVaultV1(depositor, monitor, owner, address(pool));

        // V2
        rewardsVaultV2 = new RewardsVaultV2(depositor, monitor, owner, address(pool), address(lzMock));
        
        // rewards
        rewardsToken1 = new ERC20Mock();
        rewardsToken2 = new ERC20Mock();
        rewardsToken3 = new ERC20Mock();

        // mint moca
        mocaToken.mint(user1, user1Moca);
        mocaToken.mint(user2, user2Moca);
        mocaToken.mint(user3, user3Moca);
        // parallel testing
        mocaToken.mint(cronJob, user2Moca/2);

        // register nfts
        for (uint256 i = 0; i < user1Nfts; ++i) {
            // [0, 1, 2, 3, 4]
            user1NftsArray[i] = i;
        }
        nftRegistry.register(user1, user1NftsArray);

        for (uint256 i = user1Nfts; i < user2Nfts; ++i) {
            // [5, 6, 7, 8, 9]
            user2NftsArray[i-user1Nfts] = i;
        }
        nftRegistry.register(user2, user2NftsArray);

        for (uint256 i = user2Nfts; i < user3Nfts; ++i) {
            // [10, 11, 12, 13, 14]
            user3NftsArray[i-user2Nfts] = i;
        }
        nftRegistry.register(user3, user3NftsArray);

        vm.stopPrank();

        // set nftRegistry pool
        vm.startPrank(owner);
            nftRegistry.setPool(address(pool));
        vm.stopPrank();

        vm.startPrank(operator);
            pool.setRewardsVault(address(rewardsVault));
        vm.stopPrank();

        // grant cron job role
        vm.startPrank(owner);
            pool.grantRole(Constants.CRON_JOB_ROLE, cronJob);
        vm.stopPrank();
    }

    function generateSignature(address user, bytes32 vaultId, uint256 amount, uint256 expiry, uint256 nonce) public returns (bytes memory) {
        // Pack the struct data
        bytes32 structHash = keccak256(
            abi.encode(
                Constants.TYPEHASH,
                user,
                vaultId,
                amount,
                expiry,
                nonce
            )
        );
        
        // Get the digest using the contract's domain separator
        bytes32 digest = pool.hashTypedDataV4(structHash);
        
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(storedSignerPrivateKey, digest);
        
        // Return the signature in the correct format
        return abi.encodePacked(r, s, v);
    }

    function generateVaultId(uint256 salt, address user) public view returns (bytes32) {
        return bytes32(keccak256(abi.encode(user, block.timestamp, salt)));
    }

    // binding for userAccounts
    function getUserAccount(address user, bytes32 vaultId, uint256 distributionID) public view returns (DataTypes.UserAccount memory) {
        (
            uint256 index, 
            uint256 nftIndex, 
            uint256 rpIndex, 
            uint256 accStakingRewards, 
            uint256 claimedStakingRewards, 
            uint256 accNftStakingRewards, 
            uint256 claimedNftRewards, 
            uint256 accRealmPointsRewards, 
            uint256 claimedRealmPointsRewards, 
            uint256 claimedCreatorRewards
        ) = pool.userAccounts(user, vaultId, distributionID);

        return DataTypes.UserAccount({
            index: index,
            nftIndex: nftIndex,
            rpIndex: rpIndex,
            accStakingRewards: accStakingRewards,
            claimedStakingRewards: claimedStakingRewards,
            accNftStakingRewards: accNftStakingRewards,
            claimedNftRewards: claimedNftRewards,
            accRealmPointsRewards: accRealmPointsRewards,
            claimedRealmPointsRewards: claimedRealmPointsRewards,
            claimedCreatorRewards: claimedCreatorRewards
        });
    }

    // binding for vaultAccounts
    function getVaultAccount(bytes32 vaultId, uint256 distributionID) public view returns (DataTypes.VaultAccount memory) {
        (
            uint256 index,
            uint256 nftIndex,
            uint256 rpIndex,
            uint256 totalAccRewards,
            uint256 accCreatorRewards,
            uint256 accNftStakingRewards,
            uint256 accRealmPointsRewards,
            uint256 rewardsAccPerUnitStaked,
            uint256 totalClaimedRewards
        ) = pool.vaultAccounts(vaultId, distributionID);

        return DataTypes.VaultAccount({
            index: index,
            nftIndex: nftIndex,
            rpIndex: rpIndex,
            totalAccRewards: totalAccRewards,
            accCreatorRewards: accCreatorRewards,
            accNftStakingRewards: accNftStakingRewards,
            accRealmPointsRewards: accRealmPointsRewards,
            rewardsAccPerUnitStaked: rewardsAccPerUnitStaked,
            totalClaimedRewards: totalClaimedRewards
        });
    }

    // binding for distributions
    function getDistribution(uint256 distributionID) public view returns (DataTypes.Distribution memory) {
        (
            uint256 distributionId,
            uint256 tokenPrecision,
            uint256 endTime,
            uint256 startTime_,
            uint256 emissionPerSecond,
            uint256 index,
            uint256 totalEmitted,
            uint256 lastUpdateTimeStamp,
            uint256 manuallyEnded
        ) = pool.distributions(distributionID);

        return DataTypes.Distribution({
            distributionId: distributionId,
            TOKEN_PRECISION: tokenPrecision,
            endTime: endTime,
            startTime: startTime_,
            emissionPerSecond: emissionPerSecond,
            index: index,
            totalEmitted: totalEmitted,
            lastUpdateTimeStamp: lastUpdateTimeStamp,
            manuallyEnded: manuallyEnded
        });
    }

    function calculateRewards(uint256 balance, uint256 currentIndex, uint256 priorIndex, uint256 PRECISION) public pure returns (uint256) {
        return (balance * (currentIndex - priorIndex)) / PRECISION;
    }

    function getDistributionFromRewardsVaultV2(uint256 distributionId) public view returns (RewardsVaultV1.Distribution memory) {

        (uint32 dstEid_, bytes32 tokenAddress, uint256 totalRequired, uint256 totalClaimed, uint256 totalDeposited) = rewardsVaultV2.distributions(distributionId);
        
        // Convert tuple to struct
        return RewardsVaultV1.Distribution({
            dstEid: dstEid_,
            tokenAddress: tokenAddress,
            totalRequired: totalRequired,
            totalClaimed: totalClaimed,
            totalDeposited: totalDeposited
        });
    }
}

