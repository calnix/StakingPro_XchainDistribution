# TODO

## 2. Write a section on cross-contract calls

- cover all cross-contract calls in the staking pro
- consider when they may revert or fail, due to states: paused, endTime, etc.

---

# Post-deployment

## integration suite

- build an integration testing surface to ensure all functionality works as expected wrt to integrating tokens of differing precisions
- overflow could occur for a sufficiently large supply of tokens, given that we raise all internal variables to 30 dp
