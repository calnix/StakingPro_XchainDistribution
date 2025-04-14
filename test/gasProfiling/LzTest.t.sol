// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../utils/TestingHarness.sol";

/*
abstract contract GasProfilingForPayRewards is TestingHarness {
    using stdStorage for StdStorage;

    function setUp() public virtual override {
        super.setUp();


        /**
        
        modify storage of rewardsVault
        d2 is some remote distribution
        
        Distribution({
                dstEid: 1111,
                tokenAddress: bytes32(1),
                totalRequired: 0,
                totalClaimed: 0,
                totalDeposited: 100 ether})
         */
/*
        // dstEid   
        stdstore
            .enable_packed_slots()
            .target(address(rewardsVault))
            .sig("distributions(uint256)")
            .with_key(2)
            .depth(0)
            .checked_write(uint256(1111));

        // tokenAddress   
        stdstore
            .enable_packed_slots()
            .target(address(rewardsVault))
            .sig("distributions(uint256)")
            .with_key(2)
            .depth(1)
            .checked_write(bytes32(1));

        // totalDeposited
        stdstore
            .enable_packed_slots()
            .target(address(rewardsVault))
            .sig("distributions(uint256)")
            .with_key(2)
            .depth(4)
            .checked_write(uint256(100 ether));

        vm.startPrank(address(pool));
            rewardsVaultV2.payRewards(2, 100 ether, address(0));
        vm.stopPrank();

        // check assets
    }
}

contract GasProfilingForPayRewardsTest is GasProfilingForPayRewards {
}
*/

import "../../src/EvmVault.sol";
import { EndpointV2Mock } from "../mocks/EndpointV2Mock.sol";

abstract contract GasProfilingForEVMVault is TestingHarness {
    using stdStorage for StdStorage;

    EVMVault public evmVault;

    function setUp() public virtual override {
        super.setUp();
        
        // setup evmVault
        vm.startPrank(address(owner));
            evmVault = new EVMVault(address(lzMock), owner, monitor, depositor);
        vm.stopPrank();
        
        // mint directly to evmVault
        rewardsToken1.mint(address(evmVault), 100 ether);

        // modify totalDeposited
        stdstore
            .enable_packed_slots()
            .target(address(evmVault))
            .sig("tokens(address)")
            .with_key(address(rewardsToken1))
            .depth(0)
            .checked_write(uint256(100 ether));
    }
    
    function addressToBytes32(address addr) public pure returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddress(bytes32 bytes32_) public pure returns(address) {
        return address(uint160(uint256(bytes32_)));
    }
}



contract GasProfilingForEVMVaultTest is GasProfilingForEVMVault {
    
    //Available balance is less than requested amount, but there is enough to transfer
    function testGasUsedIfAvailableBalanceIsLessThanRequestedAmount(uint64 nonce, bytes32 guid, address executor) public {
        // setup
        bytes32 addressAsBytes = addressToBytes32(address(evmVault));
        uint32 eid = 1;

        vm.prank(address(owner));
        evmVault.setPeer(eid, addressAsBytes);

        // token address

        //lzReceive params
        Origin memory _origin = Origin({srcEid: eid, sender: addressAsBytes, nonce: nonce});
        bytes32 _guid = guid;
        address _executor = executor;
        bytes memory _extraData = "";
        
        // (bytes32 tokenAddress, uint256 amount, address receiver)
        bytes32 tokenAddressAsBytes = addressToBytes32(address(rewardsToken1));
        uint256 amount = 200 ether;
        address receiver = address(user1);
        bytes memory payload = abi.encode(tokenAddressAsBytes, amount, receiver);
        
        // call
        vm.prank(address(lzMock));

        //Note: gasleft requires “2 gas” to execute
        uint256 initialGas = gasleft();
        evmVault.lzReceive(_origin, _guid, payload, _executor, _extraData);
        uint256 finalGas = gasleft();

        uint256 gasUsed = initialGas - finalGas;
        console2.log("gasUsed", gasUsed);
    }


    //Note: calling EVMVault::lzReceive
    //      gas profiling to define options on RewardsVaultV2::payRewards
    function testGasUsedElseCase(uint64 nonce, bytes32 guid, address executor) public {
        // setup
        bytes32 addressAsBytes = addressToBytes32(address(evmVault));
        uint32 eid = 1;

        vm.prank(address(owner));
        evmVault.setPeer(eid, addressAsBytes);

        // token address

        //lzReceive params
        Origin memory _origin = Origin({srcEid: eid, sender: addressAsBytes, nonce: nonce});
        bytes32 _guid = guid;
        address _executor = executor;
        bytes memory _extraData = "";
        
        // (bytes32 tokenAddress, uint256 amount, address receiver)
        bytes32 tokenAddressAsBytes = addressToBytes32(address(rewardsToken1));
        uint256 amount = 100 ether;
        address receiver = address(user1);
        bytes memory payload = abi.encode(tokenAddressAsBytes, amount, receiver);
        
        // call
        vm.prank(address(lzMock));

        //Note: gasleft requires “2 gas” to execute
        uint256 initialGas = gasleft();
        evmVault.lzReceive(_origin, _guid, payload, _executor, _extraData);
        uint256 finalGas = gasleft();

        uint256 gasUsed = initialGas - finalGas;
        console2.log("gasUsed", gasUsed);
    }

    
}

/**
    calling EVMVault::lzReceive

    if: Available balance is less than requested amount, but there is enough to transfer
    - gas used: 87228 +2 

    else: Full amount available, transfer it all 
    - gas used: 42943 +2 

*/