# V46 MCMF Changelog

## Overview

V46 upgrades the interceptor selection logic from a mostly local/legacy bidding process to a testable global assignment workflow based on min-cost max-flow (MCMF).

The main goal is not only to change the assignment algorithm, but also to make the assignment layer independently testable before relying on the full 82 s simulation. This reduces the risk of debugging EKF timing, loss prediction, sensor motion, and assignment logic all at the same time.

## Implemented

### MCMF Assignment Strategy

- Added a standalone MCMF solver: `solveInterceptorAssignmentMCMF(...)`.
- Added a shared strategy wrapper: `solveInterceptorAssignments(...)`.
- Kept the legacy solver available through `solveInterceptorAssignmentLegacy(...)`.
- The wrapper supports A/B switching through the `use_mcmf` argument.
- The MCMF model expands each calling target into `slots_per_target` interceptor slots.
- Each candidate sensor has capacity `1`, so a sensor cannot be assigned to multiple targets.
- The MCMF objective is lexicographic:
  1. maximize assigned interceptor slots;
  2. among equal-slot assignments, minimize total assignment cost.

### Simulation Adapter Layer

- Extracted adapter and helper functions into standalone `.m` files so `example_V46_Yeqi.m` and the unit tests use the same implementation.
- `buildAssignmentCostMatrixForCallingTargets(...)` builds the simulation-facing candidate list and cost matrix.
- `calculateEnhancedBid(...)` computes the weighted bid cost.
- `getSharedTargetInfo(...)` estimates shared target state/confidence from neighboring sensors.
- `findNearbySensors(...)` identifies sensors within communication range.

### V46 Integration

- Added `USE_MCMF_ASSIGNMENT = true` in `example_V46_Yeqi.m`.
- Updated the `PENDING_SELECTION` path to call `solveInterceptorAssignments(...)`.
- Preserved legacy assignment by switching `USE_MCMF_ASSIGNMENT` to `false`.
- Added `assignment_events` logging for post-simulation analysis.
- Saved `assignment_events` into the MAT output alongside the existing simulation data.

### Stage 3 Short Controlled Simulation

- Copied the verified Stage 3 injection version into `example_v46_stage3_Yeqi.m`.
- Restored `example_V46_Yeqi.m` so the main V46 simulation no longer contains the Stage 3 injection hook.
- Added a default-off Stage 3 injection path in `example_v46_stage3_Yeqi.m`.
- The injection is enabled only by the environment variable `ENABLE_MCMF_STAGE3_TEST`.
- Normal runs of `example_V46_Yeqi.m` remain unchanged when the flag is not set.
- Added `run_mcmf_stage3_short_controlled_simulation.m` to run an 8 s controlled simulation slice.
- The runner injects simultaneous `PENDING_SELECTION` for target 1 and target 2 at `t = 5.00 s`.
- The injected event logs the marker `[MCMF_TEST_INJECTION]`.
- Stage 3 outputs use separate filenames:
  - `logs/mcmf_stage3_log_*.log`
  - `logs/mcmf_stage3_data_*.mat`
- Added `stage3_injection_info` and `stage3_assignment_snapshot` to MAT output so the report can verify assignment state immediately after MCMF selection.
- Updated `run_mcmf_stage3_short_controlled_simulation.m` to automatically recompute the legacy assignment on the same Stage 3 event cost matrix.
- The runner now returns and prints `mcmf_total_cost`, `legacy_total_cost`, and `mcmf_cost_improvement`, so changed injection times do not require manual log parsing for A/B comparison.
- The runner now accepts `run_mcmf_stage3_short_controlled_simulation(false)` to run the real Stage 3 simulation with the legacy assignment path while still printing the MCMF comparison on the same event.
- Fixed a Stage 3 movement edge case found by the `8 s / 5 s / legacy` run: if the low-confidence branch switches a legacy-selected interceptor to `RETURNING_HOME`, the script no longer tries to use an unassigned `new_direction`.

### Stage 4 Full Injected Simulation

- Added `example_v46_stage4_Yeqi.m` as the dedicated Stage 4 simulation script, keeping Stage 3 and Stage 4 injection logic separate.
- Added `run_mcmf_stage4_full_injected_simulation.m` for full 82 s injected simulation runs.
- Stage 4 uses an `AUGMENT_OR_FALLBACK` injection policy:
  - augment an existing valid natural `PENDING_SELECTION` target when available;
  - otherwise use fallback controlled target 1/2 injection.
- Stage 4 writes separate output prefixes:
  - `logs/mcmf_stage4_log_*.log`
  - `logs/mcmf_stage4_data_*.mat`
- Verified Stage 4 MCMF run completed to `82.00 s` with fallback controlled injection at `15.00 s`.

### Legacy Compatibility Fix

- Fixed a legacy solver edge case for multi-target shortage/exact-team-size inputs.
- The legacy path now avoids incorrectly entering the 2-target minimax branch when candidates are insufficient to fill all requested target teams.
- This keeps legacy available for A/B comparison without crashing on shortage scenarios.

## Validation

### Unit Tests

`test_interceptor_assignment.m` currently has 5 passing tests:

- `testSingleTargetMCMFPicksLowestTwo`
- `testTwoTargetMCMFAvoidsCandidateConflicts`
- `testMCMFHandlesShortageWithPartialAssignment`
- `testLegacySingleTargetRemainsAvailable`
- `testLegacyMultiTargetExactTeamSizeRemainsAvailable`

`test_mcmf_simulation_adapter.m` currently has 5 passing tests:

- `testBuildCostMatrixExcludesActiveTrackers`
- `testTwoTargetsPendingSelectionBatchAssignment`
- `testShortageCaseStillProducesPartialAssignment`
- `testLegacyAndMCMFUseSameAdapterInputs`
- `testThreeTargetsWithCandidateShortageUsesAllAvailableSensors`

### Verification Command

```powershell
matlab.exe -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); results = runtests({'test_interceptor_assignment.m','test_mcmf_simulation_adapter.m'}); assertSuccess(results);"
```

Latest observed result:

```text
Running test_interceptor_assignment
.....
Done test_interceptor_assignment

Running test_mcmf_simulation_adapter
.....
Done test_mcmf_simulation_adapter
```

### Static Check

`test_mcmf_simulation_adapter.m` currently reports `0` `checkcode` issues.

The extracted helper files are also clean except for the retained global-weight pattern in `calculateEnhancedBid(...)`, which is kept for compatibility with the original script's `OPTIMIZATION_WEIGHTS` mechanism.

### Stage 3 Verification Command

```powershell
matlab.exe -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); result = run_mcmf_stage3_short_controlled_simulation();"
```

Latest observed result:

```text
Stage 3 MCMF short controlled simulation passed.
MAT output: logs/mcmf_stage3_data_20260407_140150.mat
Log output: logs/mcmf_stage3_log_20260407_140150.log
Assignment time: 5.00 s
Calling targets: [1  2]
Assigned sensors: [6  7  8  9]
Total cost: 1.2443
```

The new Stage 3 runner reports `0` `checkcode` issues.

## Important Evidence

### Test 1: Adapter Filtering

`testBuildCostMatrixExcludesActiveTrackers` verifies that active trackers are excluded before assignment.

Mock state:

- Target 1 active trackers: `[1; 2]`
- Target 2 active trackers: `[3; 4]`
- Expected candidates: `[5; 6; 7; 8]`

This test does not claim MCMF superiority. It proves the simulation adapter builds valid MCMF input.

### Test 2: MCMF Correctness From Larger Candidate Pool

`testTwoTargetsPendingSelectionBatchAssignment` verifies that MCMF can choose the best 4 interceptors from 6 available candidates.

Candidates:

```text
[5 6 7 8 9 10]
```

Cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.3889 | 0.3139 |
| 6 | 0.0169 | 0.1073 |
| 7 | 0.1408 | 0.3288 |
| 8 | 0.0296 | 0.0223 |
| 9 | 0.1269 | 0.0112 |
| 10 | 0.0079 | 0.0723 |

MCMF result:

| Target | Selected interceptors | Cost |
|---:|---:|---:|
| 1 | `[6 10]` | `0.0248` |
| 2 | `[8 9]` | `0.0335` |
| Total | `[6 10 8 9]` | `0.0582` |

Unused candidates are `[5 7]`, which are not part of the lowest-cost feasible full assignment.

### Test 3: Two-Target Shortage

`testShortageCaseStillProducesPartialAssignment` shows MCMF behavior when 2 targets request 4 total slots but only 2 candidates are available.

Cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 4 | 0.2552 | 0.1008 |
| 5 | 0.1117 | 0.1836 |

Legacy result:

```text
Target 1 -> [5 4]
Target 2 -> []
Total cost = 0.3669
Assigned slots = 2
```

MCMF result:

```text
Target 1 -> [5]
Target 2 -> [4]
Total cost = 0.2125
Assigned slots = 2
```

This demonstrates MCMF's advantage under shortage: it assigns the same number of sensors but distributes them more sensibly across targets with lower total cost.

### Test 4: Same-Input Legacy vs MCMF A/B Case

`testLegacyAndMCMFUseSameAdapterInputs` uses the same adapter-generated input for both algorithms and shows MCMF achieving lower total cost.

Cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.3681 | 0.1387 |
| 6 | 0.3673 | 0.0106 |
| 7 | 0.4213 | 0.1168 |
| 8 | 0.3396 | 0.0394 |

Legacy result:

```text
Target 1 -> [8 6]
Target 2 -> [5 7]
Total cost = 0.9623
```

MCMF result:

```text
Target 1 -> [5 8]
Target 2 -> [6 7]
Total cost = 0.8350
```

This demonstrates that MCMF can outperform legacy under the exact same adapter input.

### Test 5: Three-Target Shortage

`testThreeTargetsWithCandidateShortageUsesAllAvailableSensors` is the strongest adapter-level evidence because it tests 3 simultaneous targets with insufficient candidates.

Mock state:

- Target 1 active trackers: `[1; 2]`
- Target 2 active trackers: `[3; 4]`
- Target 3 active trackers: `[5; 6]`
- Candidates: `[7; 8; 9; 10; 11]`
- Requested slots: `6`
- Available candidates: `5`

Cost matrix:

| Candidate sensor | Cost to target 1 | Cost to target 2 | Cost to target 3 |
|---:|---:|---:|---:|
| 7 | 0.1501 | 0.2382 | 0.2204 |
| 8 | 0.0297 | 0.2720 | 0.1958 |
| 9 | 0.0194 | 0.2756 | 0.0492 |
| 10 | 0.0446 | 0.2889 | 0.0170 |
| 11 | 0.2169 | 0.3070 | 0.0210 |

Legacy result:

```text
Target 1 -> [9 8]
Target 2 -> [7 10]
Target 3 -> [11]
Total cost = 0.5971
Assigned slots = 5
```

MCMF result:

```text
Target 1 -> [8 9]
Target 2 -> [7]
Target 3 -> [10 11]
Total cost = 0.3251
Assigned slots = 5
```

This demonstrates MCMF's global behavior: it preserves sensors 10 and 11 for target 3, where they are most valuable, instead of consuming sensor 10 for target 2.

### Stage 3: Real-Loop Short Controlled Simulation Evidence

Stage 3 runs the real V46 simulation loop for 8 s and injects simultaneous target 1/2 selection at `t = 5.00 s`.

Injected state:

```text
Target 1 active trackers = [1 2]
Target 2 active trackers = [3 4]
Candidate sensors = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]
```

MCMF result:

```text
Target 1 -> [6 7]
Target 2 -> [8 9]
Total cost = 1.2443
```

Legacy comparison on the same event cost matrix:

```text
Target 1 -> [7 11]
Target 2 -> [6 8]
Total cost = 1.3038
```

Stage 3 proves that the real V46 loop can consume the MCMF result, mark the selected sensors as `INTERCEPTING`, assign `INTERCEPTOR_CANDIDATE` roles, write non-empty `proactive_targets`, continue running after assignment, and save MAT/log output.

## Known Gap

- Full 82 s simulation loop has not been validated end-to-end yet.
- The current tests do not yet validate EKF convergence timing, loss prediction stability, actual `interceptor_process_state` timing, physical interceptor movement, or handover completion.
- This is expected: the current layer intentionally isolates assignment correctness before testing the complete dynamic system.
- Stage 3 uses injection to bypass natural simultaneous-trigger timing. It is real-loop evidence, but not yet natural full-simulation evidence.

## Recommended Next Step

Proceed to Stage 4: run the full 82 s simulation with the default-off injection mechanism, then verify that MCMF assignment remains stable across the complete run.

After Stage 4 passes, run Stage 5 with injection disabled and `USE_MCMF_ASSIGNMENT = true` to validate natural full-simulation behavior.
