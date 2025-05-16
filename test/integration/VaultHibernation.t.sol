// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../unit/PoolT86466.t.sol";

/** Vault Hibernation Test
 
 Consider how vault indexes are updated when a distribution ends.
 Assume Distribution ends at time X.

 At time X:
 1. V1 has first staking action [As a consequence of staking action, D1 is updated - this is the final update]
 2. V2 has first staking action [D1 will not be updated since final update done]
 
 At time X+10:
 1. V3 has first staking action [D1 will not be updated since final update done]
 */

abstract contract StateT86466p_SetD1EndTimeInTenSeconds is StateT86466_User2UnstakedFromVault2 {

    function setUp() public virtual override {
        super.setUp();

        // end D1 in ten seconds
        vm.startPrank(operator);
            pool.updateDistribution(1, 0, block.timestamp + 10, 0);
        vm.stopPrank();
    }
}

contract StateT86466p_SetD1EndTimeInTenSecondsTest is StateT86466p_SetD1EndTimeInTenSeconds {

    function testD1EndsInTenSeconds() public {
        // D1 ended at time X
        DataTypes.Distribution memory distribution = getDistribution(1);
        assertEq(distribution.endTime, block.timestamp + 10);
    }
}

abstract contract StateT86466p_EndD1Ended is StateT86466p_SetD1EndTimeInTenSeconds {
    
    bytes32 public V1_id;
    bytes32 public V2_id;
    bytes32 public V3_id;

    function setUp() public virtual override {
        super.setUp();
        
        DataTypes.Distribution memory distribution = getDistribution(1);

        // D1 ends at this time
        vm.warp(distribution.endTime);

        // advance block number to 100
        vm.roll(100);

        // remove nft requirement
        vm.startPrank(operator);
            pool.updateCreationNfts(0);
        vm.stopPrank();
        
        uint256[] memory tokenIds = new uint256[](0);
        

        console.log("block.number:", block.number);
        console.log("block.timestamp:", block.timestamp);

        // create V1,V2,V3
        vm.startPrank(user2);
            pool.createVault(tokenIds, 0, 0, 0);         // 0x14e2413b875469fa30381d480c072d7f0626084e0149d9562f3a7302d538fada
            pool.createVault(tokenIds, 0, 0, 0);         // 0x394536f898ddd5aa628223a3f33e9eb517a5f798d600aebc92d69e11da9cb069
            pool.createVault(tokenIds, 0, 0, 0);         // 0xbc0ea96761194fe7a925242f706cb2ef7c5af6e960ed156ab639fc3e4725d497
        vm.stopPrank();

        // store vaultIds
        // note: V1_id = generateVaultId(block.number - 1, user2) returns 0x24f6c86cc299508a85c4c0de7b08ff7d3fba2a939acdfe2307e0465e9e417506; which is based on `block.number - 100`
        // this is a foundry bug due to vm.roll
        V1_id = 0x14e2413b875469fa30381d480c072d7f0626084e0149d9562f3a7302d538fada;
        
        V2_id = generateVaultId(block.number - 2, user2);   // 0x394536f898ddd5aa628223a3f33e9eb517a5f798d600aebc92d69e11da9cb069
        console.logBytes32(V2_id);
        V3_id = generateVaultId(block.number - 3, user2);   // 0xbc0ea96761194fe7a925242f706cb2ef7c5af6e960ed156ab639fc3e4725d497
        console.logBytes32(V3_id);        
    }
}

contract StateT86466p_EndD1EndedTest is StateT86466p_EndD1Ended {

    function test_V1FirstStakingAction_D1EndedNotUpdated() public {
        // get D1
        DataTypes.Distribution memory distribution_before = getDistribution(1);

        // get vault account for D1 before
        DataTypes.VaultAccount memory vaultAccount_before = getVaultAccount(V1_id, 1);
        assertEq(vaultAccount_before.index, 0);
        assertGt(distribution_before.index, vaultAccount_before.index);

        vm.startPrank(user2);
            mocaToken.approve(address(pool), 10 ether);
            pool.stakeTokens(V1_id, 10 ether);
        vm.stopPrank();

        // get D1
        DataTypes.Distribution memory distribution_after = getDistribution(1);
        // get vault account for D1 after
        DataTypes.VaultAccount memory vaultAccount_after = getVaultAccount(V1_id, 1);
        

        // vault index == 0 although d1.index was incremented on final update
        assertEq(vaultAccount_after.index, 0);
        assertGt(distribution_after.index, distribution_before.index);
    }
}

abstract contract StateT86466p_D1FinalUpdateDone is StateT86466p_EndD1Ended {

    function setUp() public virtual override {
        super.setUp();
        

        // D1 updated via staking action
        vm.startPrank(user2);
            mocaToken.approve(address(pool), 10 ether);
            pool.stakeTokens(V1_id, 10 ether);
        vm.stopPrank();
    }
}

contract StateT86466p_D1FinalUpdateDoneTest is StateT86466p_D1FinalUpdateDone {

    function test_V2Stakes_D1FinalUpdateDone() public {
        // get D1
        DataTypes.Distribution memory distribution_before = getDistribution(1);

        // get vault account for D1 before
        DataTypes.VaultAccount memory vaultAccount_before = getVaultAccount(V2_id, 1);
        assertEq(vaultAccount_before.index, 0);
        assertGt(distribution_before.index, vaultAccount_before.index);

        vm.startPrank(user2);
            mocaToken.approve(address(pool), 10 ether);
            pool.stakeTokens(V2_id, 10 ether);
        vm.stopPrank();

        // get D1
        DataTypes.Distribution memory distribution_after = getDistribution(1);
        // get vault account for D1 after
        DataTypes.VaultAccount memory vaultAccount_after = getVaultAccount(V2_id, 1);

        // vault index == 0 | d1 index unchanged 
        assertEq(vaultAccount_after.index, 0);
        assertEq(distribution_after.index, distribution_before.index);
    }

    function test_V3Stakes_D1FinalUpdateDone() public {
        // get D1
        DataTypes.Distribution memory distribution_before = getDistribution(1);

        // get vault account for D1 before
        DataTypes.VaultAccount memory vaultAccount_before = getVaultAccount(V3_id, 1);
        assertEq(vaultAccount_before.index, 0);
        assertGt(distribution_before.index, vaultAccount_before.index);

        vm.warp(block.timestamp + 10);
        
        //V3_id = bytes32(0xdb5c99fe20df3256ad6e6af0511c3d4b18307422320cfd8f8f4067ed37472dd3);

        vm.startPrank(user2);
            mocaToken.approve(address(pool), 10 ether);
            pool.stakeTokens(V3_id, 10 ether);
        vm.stopPrank();

        // get D1
        DataTypes.Distribution memory distribution_after = getDistribution(1);
        // get vault account for D1 after
        DataTypes.VaultAccount memory vaultAccount_after = getVaultAccount(V3_id, 1);

        // vault index == 0 | d1 index unchanged 
        assertEq(vaultAccount_after.index, 0);
        assertEq(distribution_after.index, distribution_before.index);
    }    

}