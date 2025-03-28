# Overview

- StakingPro will be initially deployed on Base, paired with a RewardsVaultV1.sol contract.
- Subsequently, StakingPro will be updated with paired with a RewardsVaultV2.sol contract.

V1 supports distributing token rewards on Base only.
V2 supports distributing token rewards X-chain via LayerZero. This utilizes EVMVault.sol as remote deployed peers to RewardsVaultV2.sol.

There isn't a Solana integration at the moment. I.e. The Solana equivalent to EVMVault.sol.

That's maybe for V3. However, I am building it in mind to allow for such modular add-ons. Hence why the remote vaults are just dummies that pay out users according to the xchain message received.

## Note

While we initially began building this to be specifically for our internal use - meaning with MocaNFTS, MocaTokens and RealmPoints.

We wanted this to be useable by other projects in the future. That would require this working w/o RealmPoints or a different NFT collection, perhaps no NFTs at all. To that end, some parts are made modular/flexible - where certain specifics are not enforced/checked.

## Doc directory

* [Documentation/ContractExplanations.md](Documentation/ContractExplanations.md) explains and walkthrough contract functionality. I've tried to be as detailed as possible.
* [Documentation/Risk.md](Documentation/Risk.md) covers the risk approach - like pausing contracts, in what order and such.
* [test/TestOverview.md](test/TestOverview.md) describes the core unit testing scenarios covered in sequence and parallel.
* Additional coverage tests can be found at [test\FunctionStates.md](test/FunctionStates.md).
* src/ignore is out of scope. please ignore.