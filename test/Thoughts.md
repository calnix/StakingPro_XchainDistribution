# Add notes

## 2. ending distributions and last update

distributions that have ended are demarked by `distribution.lastUpdateTimeStamp == distribution.endTime`

```solidity
        if(isPaused) return distribution;
        
        if(block.timestamp < distribution.startTime) return distribution;

        // ..... Distribution has ended: does not apply to distributionId == 0 .....
        if (distribution.endTime > 0 && block.timestamp >= distribution.endTime) {
                if (distribution.lastUpdateTimeStamp <= distribution.endTime) {...}
        }
```

Problem:
- `if (distribution.lastUpdateTimeStamp <= distribution.endTime) {...}` will allow ended distributions to cycle through the final update sequence.


So back to original w/ a add check:

```solidity        
        if(isPaused) return distribution;

        // distribution has ended, and final update done
        if(distribution.lastUpdateTimeStamp == distribution.endTime) return distribution;

        if(block.timestamp < distribution.startTime) return distribution;

        // ..... Distribution has ended: does not apply to distributionId == 0 .....
        if (distribution.endTime > 0 && block.timestamp >= distribution.endTime) {
                if (distribution.lastUpdateTimeStamp < distribution.endTime) {...}
        }
```

- `if (distribution.lastUpdateTimeStamp < distribution.endTime) {...}` will prevent ended distributions from cycling through the final update sequence.
- additionally, `if(distribution.lastUpdateTimeStamp == distribution.endTime) return distribution;` will prevent ended distributions from being updated again.

for `endDistribution()`:

- distribution is updated to latest [lastUpdateTimeStamp == block.timestamp]
- then endTime is set to block.timestamp
- popped from activeDistribution array

> if this distribution is submitted to claimRewards() after it has been ended, it will not go into final update.
> it will return early because `if(distribution.lastUpdateTimeStamp == distribution.endTime) return distribution;`

```
T41: stakeTokens [distribution.lastUpdateTimeStamp == distribution.endTime]
T41: endDistribution -> will not go into final update
```