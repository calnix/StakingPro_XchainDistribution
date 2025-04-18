// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./../../src/StakingPro.sol";

contract StakingProMock is StakingPro {
    constructor(
        address nftRegistry, address stakedToken, uint256 startTime_, 
        /*uint256 maxFeeFactor, uint256 minRpRequired,*/ uint256 nftMultiplier, 
        uint256 creationNftsRequired, uint256 vaultCoolDownDuration,
        address owner, address monitor, address operator,
        address storedSigner, string memory name, string memory version) payable 

        StakingPro(
            nftRegistry, stakedToken, startTime_, nftMultiplier, creationNftsRequired, vaultCoolDownDuration,
            owner, monitor, operator, storedSigner, name, version
        ) {}

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the hash of the fully encoded EIP712 message for this domain
     *      See EIP712.sol
     */
    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    /**
     * @dev Returns the domain separator for the current chain
     *      See EIP712.sol
     */
    function domainSeparatorV4() external view returns (bytes32) {
        return _domainSeparatorV4();
    }   
    
}
