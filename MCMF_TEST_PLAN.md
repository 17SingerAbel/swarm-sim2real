# V46 MCMF Adapter Test Plan

## Summary

The adapter tests are designed to validate the middle layer between the full WSN simulation and the MCMF solver:

```text
mock simulation state -> buildAssignmentCostMatrixForCallingTargets -> solveInterceptorAssignments
```

This is intentionally separate from the full 82 s animation simulation. It lets us force simultaneous `PENDING_SELECTION`-like situations without depending on EKF convergence timing, target trajectories, or random target motion.

The important idea is that each test uses simulation-shaped data: active trackers, sensor positions, target intercept points, predictor EKF states, and detection times. The adapter then produces the same type of candidate list and cost matrix that V46 uses inside the real simulation.

The five adapter tests have distinct roles:

| Test case | Main point |
|---|---|
| `testBuildCostMatrixExcludesActiveTrackers` | Only tests whether the adapter correctly excludes active trackers from interceptor candidates. |
| `testTwoTargetsPendingSelectionBatchAssignment` | Tests whether MCMF can choose the best 4 interceptors from a larger candidate pool when candidates exceed requested slots. |
| `testShortageCaseStillProducesPartialAssignment` | Tests a 2-target shortage case where MCMF is more reasonable than legacy because it distributes limited sensors across targets. |
| `testLegacyAndMCMFUseSameAdapterInputs` | Tests a same-input A/B case where MCMF gives a lower total cost than legacy. |
| `testThreeTargetsWithCandidateShortageUsesAllAvailableSensors` | Tests a more complex 3-target shortage case with simultaneous target competition and insufficient candidates. |

## Shared Cost Meaning

For every test, the cost matrix has this interpretation:

```text
cost_matrix(i, j) = bid cost for candidate sensor i to serve calling target j
```

Lower cost is better. In MCMF, each target is expanded into `2` interceptor slots because `MAX_ACTIVE_TRACKERS = 2`. Each sensor has capacity `1`, so one sensor cannot be assigned to two target slots.

The MCMF objective is lexicographic:

```text
1. maximize the number of assigned interceptor slots
2. among assignments with the same number of slots, minimize total assignment cost
```

## Test Case 1: `testBuildCostMatrixExcludesActiveTrackers`

Purpose: verify the adapter creates the correct candidate list and edge-cost matrix before assignment.

Mock simulation state:

| Item | Value |
|---|---|
| Number of sensors | `8` |
| Number of targets | `2` |
| Calling targets | `[1; 2]` |
| Target 1 active trackers | `[1; 2]` |
| Target 2 active trackers | `[3; 4]` |
| Available sensors expected | `[5; 6; 7; 8]` |
| Target 1 intercept point | `[14, 2]` |
| Target 2 intercept point | `[4, 3]` |
| Target 1 predictor | sensor `1`, EKF velocity `[1.0, 0.1]` |
| Target 2 predictor | sensor `3`, EKF velocity `[-0.8, 0.2]` |

Adapter-generated cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.1117 | 0.1836 |
| 6 | 0.0362 | 0.2906 |
| 7 | 0.0192 | 0.3073 |
| 8 | 0.0450 | 0.3331 |

Expected adapter result:

| Check | Expected |
|---|---|
| Candidate sensors | `[5 6 7 8]` |
| Cost matrix size | `4 x 2` |
| Costs finite | yes |

Legacy vs MCMF:

| Method | Assignment if this matrix is passed to solver | Total cost |
|---|---|---:|
| Legacy | Target 1 -> `[7 8]`, Target 2 -> `[6 5]` | `0.5385` |
| MCMF | Target 1 -> `[7 8]`, Target 2 -> `[5 6]` | `0.5385` |

Interpretation:

- The actual assertion in this test only checks the adapter output, not solver selection.
- The important proof is that active trackers `[1 2 3 4]` are not allowed to bid.
- If the generated matrix is passed to both solvers, both produce a valid full assignment with the same total cost.

## Test Case 2: `testTwoTargetsPendingSelectionBatchAssignment`

Purpose: verify that two simultaneous calling targets can be solved as one global batch.

Mock simulation state:

| Item | Value |
|---|---|
| Number of sensors | `10` |
| Number of targets | `2` |
| Calling targets | `[1; 2]` |
| Target 1 active trackers | `[1; 2]` |
| Target 2 active trackers | `[3; 4]` |
| Available candidate sensors | `[5; 6; 7; 8; 9; 10]` |
| Requested slots | `2 targets x 2 slots = 4` |
| Target 1 intercept point | `[11.5792, 13.0016]` |
| Target 2 intercept point | `[16.7848, 11.9030]` |

Adapter-generated cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.3889 | 0.3139 |
| 6 | 0.0169 | 0.1073 |
| 7 | 0.1408 | 0.3288 |
| 8 | 0.0296 | 0.0223 |
| 9 | 0.1269 | 0.0112 |
| 10 | 0.0079 | 0.0723 |

Theoretical optimal result under full assignment:

| Target | Selected interceptors | Cost |
|---:|---:|---:|
| 1 | `[6 10]` | `0.0169 + 0.0079 = 0.0248` |
| 2 | `[8 9]` | `0.0223 + 0.0112 = 0.0335` |
| Total | `[6 10 8 9]` | `0.0582` |
| Unused candidates | `[5 7]` | not assigned |

Legacy vs MCMF:

| Method | Assignment | Assigned slots | Total cost |
|---|---|---:|---:|
| Legacy | Target 1 -> `[10 6]`, Target 2 -> `[9 8]` | `4` | `0.0582` |
| MCMF | Target 1 -> `[6 10]`, Target 2 -> `[8 9]` | `4` | `0.0582` |

Interpretation:

- This is a sanity case where both legacy and MCMF produce the same optimal total cost.
- It proves the new MCMF path can choose the best 4 sensors from a larger pool of 6 candidates.
- Sensors 5 and 7 are left unused because they are not part of the lowest-cost feasible assignment.
- It also proves the V46 batch path can handle simultaneous `PENDING_SELECTION` without duplicate sensors when there are more candidates than required slots.

## Test Case 3: `testShortageCaseStillProducesPartialAssignment`

Purpose: verify behavior when requested slots exceed the number of candidate sensors.

Mock simulation state:

| Item | Value |
|---|---|
| Number of sensors | `5` |
| Number of targets | `2` |
| Calling targets | `[1; 2]` |
| Target 1 active trackers | `[1; 2]` |
| Target 2 active trackers | `[3]` |
| Available candidate sensors | `[4; 5]` |
| Requested slots | `2 targets x 2 slots = 4` |
| Available slots possible | `2`, because only two candidates exist |

Adapter-generated cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 4 | 0.2552 | 0.1008 |
| 5 | 0.1117 | 0.1836 |

Theoretical optimal result under shortage:

| Target | Selected interceptors | Cost |
|---:|---:|---:|
| 1 | `[5]` | `0.1117` |
| 2 | `[4]` | `0.1008` |
| Total | `[5 4]` | `0.2125` |

Legacy vs MCMF:

| Method | Assignment | Assigned slots | Total cost |
|---|---|---:|---:|
| Legacy | Target 1 -> `[5 4]`, Target 2 -> `[]` | `2` | `0.3669` |
| MCMF | Target 1 -> `[5]`, Target 2 -> `[4]` | `2` | `0.2125` |

Interpretation:

- Full allocation is impossible because the system asks for 4 slots but only 2 candidate sensors exist.
- Legacy greedily fills target 1 first, so target 2 receives no interceptor.
- MCMF distributes the limited sensors globally: sensor 5 is best for target 1, and sensor 4 is best for target 2.
- This is a clear example of MCMF power: same number of assigned sensors, lower total cost, and better target coverage.

## Test Case 4: `testLegacyAndMCMFUseSameAdapterInputs`

Purpose: verify A/B testing is fair and show a 2-target case where MCMF produces a lower total cost than legacy.

Mock simulation state:

| Item | Value |
|---|---|
| Number of sensors | `8` |
| Number of targets | `2` |
| Calling targets | `[1; 2]` |
| Active trackers | target 1 -> `[1; 2]`, target 2 -> `[3; 4]` |
| Available candidate sensors | `[5; 6; 7; 8]` |
| Requested slots | `4` |
| Target 1 intercept point | `[17.8437, 0.0254]` |
| Target 2 intercept point | `[10.8040, 13.3937]` |
| Target 1 target position | `[6.7645, 2.8537]` |
| Target 2 target position | `[14.2187, 3.9583]` |

Shared adapter-generated cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.3681 | 0.1387 |
| 6 | 0.3673 | 0.0106 |
| 7 | 0.4213 | 0.1168 |
| 8 | 0.3396 | 0.0394 |

Legacy vs MCMF:

| Method | Assignment | Assigned slots | Total cost |
|---|---|---:|---:|
| Legacy | Target 1 -> `[8 6]`, Target 2 -> `[5 7]` | `4` | `0.9623` |
| MCMF | Target 1 -> `[5 8]`, Target 2 -> `[6 7]` | `4` | `0.8350` |

Interpretation:

- Both methods receive the same candidates and cost matrix.
- Both methods assign all 4 slots with no duplicate sensors.
- Legacy selects a balanced/minimax-style assignment: target 1 cost is `0.3396 + 0.3673 = 0.7069`, target 2 cost is `0.1387 + 0.1168 = 0.2555`, total cost `0.9623`.
- MCMF selects the lower total-cost assignment: target 1 cost is `0.3681 + 0.3396 = 0.7077`, target 2 cost is `0.0106 + 0.1168 = 0.1274`, total cost `0.8350`.
- The target 1 cost is nearly the same in both assignments, but MCMF saves cost on target 2 by preserving sensor 6 for target 2, where it is extremely cheap (`0.0106`).
- This supports the report claim that the V46 switch enables controlled A/B comparison and that MCMF can outperform the legacy method under the same adapter input.

## Test Case 5: `testThreeTargetsWithCandidateShortageUsesAllAvailableSensors`

Purpose: stress test the exact type of scenario that is difficult to force naturally in the full simulation: more than two simultaneous target calls with insufficient candidates.

Mock simulation state:

| Item | Value |
|---|---|
| Number of sensors | `11` |
| Number of targets | `3` |
| Calling targets | `[1; 2; 3]` |
| Target 1 active trackers | `[1; 2]` |
| Target 2 active trackers | `[3; 4]` |
| Target 3 active trackers | `[5; 6]` |
| Available candidate sensors | `[7; 8; 9; 10; 11]` |
| Requested slots | `3 targets x 2 slots = 6` |
| Available slots possible | `5`, because only five candidates exist |
| Target 1 intercept point | `[13, 2]` |
| Target 2 intercept point | `[6, 6]` |
| Target 3 intercept point | `[17, 4]` |

Adapter-generated cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 | Cost to target 3 |
|---:|---:|---:|---:|
| 7 | 0.1501 | 0.2382 | 0.2204 |
| 8 | 0.0297 | 0.2720 | 0.1958 |
| 9 | 0.0194 | 0.2756 | 0.0492 |
| 10 | 0.0446 | 0.2889 | 0.0170 |
| 11 | 0.2169 | 0.3070 | 0.0210 |

Theoretical optimal result under shortage:

| Target | Selected interceptors | Cost |
|---:|---:|---:|
| 1 | `[8 9]` | `0.0297 + 0.0194 = 0.0491` |
| 2 | `[7]` | `0.2382` |
| 3 | `[10 11]` | `0.0170 + 0.0210 = 0.0380` |
| Total | `[8 9 7 10 11]` | `0.3251` |

Legacy vs MCMF:

| Method | Assignment | Assigned slots | Total cost |
|---|---|---:|---:|
| Legacy | Target 1 -> `[9 8]`, Target 2 -> `[7 10]`, Target 3 -> `[11]` | `5` | `0.5971` |
| MCMF | Target 1 -> `[8 9]`, Target 2 -> `[7]`, Target 3 -> `[10 11]` | `5` | `0.3251` |

Interpretation:

- Full allocation is impossible because 6 interceptor slots are requested but only 5 candidate sensors are available.
- Legacy assigns target 2 sensor 10 even though sensor 10 is extremely valuable for target 3: target 2 cost is `0.2889`, target 3 cost is only `0.0170`.
- MCMF preserves sensor 10 and sensor 11 for target 3, where they are most cost-effective.
- MCMF assigns sensor 7 to target 2 because it is the best remaining option for target 2 after target 1 and target 3 receive their strongest candidates.
- This is the strongest adapter-level evidence that MCMF can improve the real simulation: it handles simultaneous 3-target competition, shortage, and non-overlap in one global optimization step.

## Why This Supports Full Simulation Integration

- The tests use the same adapter and solver functions that `example_V46_Yeqi.m` calls inside `PENDING_SELECTION`.
- The mock state includes the same categories of data used by the real simulation: active trackers, current sensor positions, original home positions, target intercept points, predictor IDs, EKF velocity estimates, detection times, communication range, and WSN dimensions.
- The tests avoid random trajectory and EKF timing noise, so they isolate the assignment logic before testing the complete system.
- The 3-target shortage case is especially relevant because it exercises the hard case that is difficult to create naturally in the animation: simultaneous multi-target handover with too few idle sensors.

## Verification Commands

```powershell
matlab.exe -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); results = runtests({'test_interceptor_assignment.m','test_mcmf_simulation_adapter.m'}); assertSuccess(results);"
```

```powershell
matlab.exe -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); issues = checkcode('example_V46_Yeqi.m','-id'); disp(issues);"
```

## Assumptions

- Do not modify target trajectories or EKF convergence logic for this test layer.
- Do not add a full-simulation debug injection flag yet.
- Add full simulation injection only after the adapter tests pass.

For the full simulation integration strategy, see `MCMF_SIMULATION_INTEGRATION_PLAN.md`.

For the Stage 3 short controlled simulation report case, see `MCMF_STAGE3_TEST_PLAN.md`.
