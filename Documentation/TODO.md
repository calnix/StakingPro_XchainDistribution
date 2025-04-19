# TODO

## 2. Write a section on cross-contract calls

- cover all cross-contract calls in the staking pro
- consider when they may revert or fail, due to states: paused, endTime, etc.

---

# STAKING PRO MISC

1. RP can be uint128; struct packing
2. struct packing for fees, as input params: createVault + updateVaultFees
3. pack library return variables into struct: gas savings?
4. check internal fns in library, make sure no extra inputs/mappings/outputs

Check dups in errors,events and remove.

# Post-deployment

## integration suite

- build an integration testing surface to ensure all functionality works as expected wrt to integrating tokens of differing precisions
- overflow could occur for a sufficiently large supply of tokens, given that we raise all internal variables to 30 dp
