# MCMF Stage 3 Short Controlled Simulation README

## Summary

Stage 3 is the first test that runs a real V46-derived simulation loop with the MCMF path enabled. It uses `example_v46_stage3_Yeqi.m`, which is a dedicated Stage 3 copy of `example_V46_Yeqi.m` containing the controlled injection hook.

This document is a README-style test report rather than only a future plan. It explains how the Stage 3 controlled simulation is configured, how to run it, how to change the injection time, what result was observed, and what evidence can be used in the report.

The purpose is not to wait for a rare natural simultaneous handover. Instead, Stage 3 uses a default-off injection to force target 1 and target 2 into `PENDING_SELECTION` at a deterministic time, then lets the real V46 loop execute the existing MCMF selection, state updates, interceptor movement, logging, and MAT saving.

This test answers a different question from `MCMF_TEST_PLAN.md`:

```text
Stage 1 adapter tests:
mock simulation state -> cost matrix -> MCMF assignment

Stage 3 short controlled simulation:
real simulation loop -> forced simultaneous PENDING_SELECTION -> real MCMF assignment -> real state update and movement
```

## How To Run

Run this from MATLAB:

```matlab
cd('C:/Users/abel/Desktop/MIE8888/mie8888')
result = run_mcmf_stage3_short_controlled_simulation();
```

By default, the real simulation run uses MCMF. To run the same injected Stage 3 scenario with the real legacy assignment path, pass `false`:

```matlab
result = run_mcmf_stage3_short_controlled_simulation(false);
```

Or from PowerShell:

```powershell
& 'C:\Program Files\MATLAB\R2024b\bin\matlab.exe' -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); result = run_mcmf_stage3_short_controlled_simulation();"
```

The runner sets these environment variables before calling `example_v46_stage3_Yeqi`:

```text
ENABLE_MCMF_STAGE3_TEST = 1
MCMF_STAGE3_SIMULATION_TIME = 8
MCMF_STAGE3_INJECTION_TIME = 5
MCMF_STAGE3_USE_MCMF = 1
```

Normal simulation runs are unchanged because `example_V46_Yeqi.m` no longer contains the Stage 3 injection hook. The hook is isolated in `example_v46_stage3_Yeqi.m`.

## How To Change Injection Time

The injection time is controlled in [run_mcmf_stage3_short_controlled_simulation.m](C:\Users\abel\Desktop\MIE8888\mie8888\run_mcmf_stage3_short_controlled_simulation.m), near the top of the file:

```matlab
setenv('ENABLE_MCMF_STAGE3_TEST', '1');
setenv('MCMF_STAGE3_SIMULATION_TIME', '8');
setenv('MCMF_STAGE3_INJECTION_TIME', '5');
```

To inject at a different time, change the third line. For example, to inject at `t = 6.00 s`:

```matlab
setenv('MCMF_STAGE3_INJECTION_TIME', '6');
```

The injection time must be smaller than the total Stage 3 simulation time. If you inject at `t = 10.00 s`, also increase the total runtime:

```matlab
setenv('MCMF_STAGE3_SIMULATION_TIME', '12');
setenv('MCMF_STAGE3_INJECTION_TIME', '10');
```

Recommended use:

```text
Keep t = 5.00 s as the standard report case because it is already verified and documented.
Use other injection times only as sensitivity checks.
If you change the injection time for a reported result, rerun the Stage 3 runner and update the cost matrix, selected interceptors, total cost, MAT output, and log output in this README.
```

Important caveat:

```text
Changing injection time changes the live simulation state.
That means the candidate sensors, cost matrix, selected interceptors, and MCMF-vs-legacy comparison may also change.
```

## Automatic Legacy Comparison

You do not need to read the log manually to compare against legacy after changing the injection time. The runner automatically recomputes the legacy result from the exact same Stage 3 event:

```matlab
[legacy_assignments, legacy_info] = solveInterceptorAssignments( ...
    event.calling_targets(:), event.candidate_sensors(:), event.cost_matrix, ...
    event.requested_slots_per_target, false);
```

This means the comparison uses:

```text
same calling targets
same candidate sensors
same cost matrix
same requested slots per target
legacy solver instead of MCMF solver
```

After the run, the returned `result` struct contains:

| Result field | Meaning |
|---|---|
| `result.actual_algorithm` | Algorithm actually used inside the Stage 3 simulation run |
| `result.actual_assignments` | Per-target assignment actually applied by the simulation |
| `result.actual_total_cost` | Total cost from the algorithm actually run in the simulation |
| `result.mcmf_assignments` | Per-target MCMF assignment from the real simulation event |
| `result.mcmf_assigned_sensors` | Flattened MCMF selected sensor list |
| `result.mcmf_total_cost` | MCMF total cost |
| `result.legacy_assignments` | Legacy assignment recomputed on the same event cost matrix |
| `result.legacy_assigned_sensors` | Flattened legacy selected sensor list |
| `result.legacy_total_cost` | Legacy total cost |
| `result.mcmf_cost_improvement` | `legacy_total_cost - mcmf_total_cost` |
| `result.candidate_sensors` | Candidate sensors used by both algorithms |
| `result.cost_matrix` | Cost matrix used by both algorithms |

For example, after changing the runner to:

```matlab
setenv('MCMF_STAGE3_SIMULATION_TIME', '30');
setenv('MCMF_STAGE3_INJECTION_TIME', '15');
```

the runner produced:

```text
Assignment time: 15.00 s
Calling targets: [1  2]
MCMF target 1 -> [6  8]
MCMF target 2 -> [7  9]
MCMF total cost: 1.0341
Legacy target 1 -> [8  6]
Legacy target 2 -> [7  12]
Legacy total cost: 1.0968
MCMF cost improvement: 0.0626
```

This is now automated in `run_mcmf_stage3_short_controlled_simulation.m`.

To run the same injected event with legacy as the real algorithm:

```matlab
result = run_mcmf_stage3_short_controlled_simulation(false);
```

This real-legacy run is useful because it checks more than an offline legacy recomputation. It verifies that the legacy-selected sensors can also pass through the Stage 3 simulation movement logic.

Observed legacy-mode verification for `simulation_time = 30` and `injection_time = 15`:

```text
Actual algorithm run in simulation: LEGACY
Actual assigned sensors: [8   6   7  12]
Actual total cost: 1.0968

MCMF target 1 -> [6  8]
MCMF target 2 -> [7  9]
MCMF total cost: 1.0341

Legacy target 1 -> [8  6]
Legacy target 2 -> [7  12]
Legacy total cost: 1.0968
MCMF cost improvement: 0.0626
```

Observed legacy-mode verification for the earlier `simulation_time = 8` and `injection_time = 5` case:

```text
Actual algorithm run in simulation: LEGACY
Actual assigned sensors: [7  11   6   8]
Actual total cost: 1.3038

MCMF target 1 -> [6  7]
MCMF target 2 -> [8  9]
MCMF total cost: 1.2443

Legacy target 1 -> [7  11]
Legacy target 2 -> [6  8]
Legacy total cost: 1.3038
MCMF cost improvement: 0.0595
```

Note: this `8 s / 5 s / legacy` case originally exposed a Stage 3 movement edge case. In the low-confidence branch, a legacy-selected interceptor could be switched to `RETURNING_HOME` before `new_direction` was assigned. The Stage 3 script now skips the intercept movement update when `new_direction` is empty, which allows the real legacy-mode run to complete.

## Test Setup

This Stage 3 test is a short controlled simulation, not a pure unit test and not a full natural simulation.

The setup is:

| Setup item | Value |
|---|---|
| MATLAB entry point | `run_mcmf_stage3_short_controlled_simulation.m` |
| Real simulation script called by runner | `example_v46_stage3_Yeqi.m` |
| Assignment algorithm | `USE_MCMF_ASSIGNMENT = true` |
| Test flag | `ENABLE_MCMF_STAGE3_TEST = 1` |
| Total runtime | `8.00 s` |
| Injection time | `5.00 s` |
| Natural EKF/loss trigger required? | No, bypassed only for the injected event |
| Cost function changed? | No |
| `P_home` / home distance disabled? | No |
| Target trajectories changed? | No |
| Normal 82 s run affected by default? | No |
| Stage 3 output prefix | `logs/mcmf_stage3_*` |

The reason for this setup is to isolate the next integration question:

```text
Can the real V46 loop consume one simultaneous MCMF selection event and continue running?
```

This is stronger than the adapter tests because it runs inside a real V46-derived simulation loop. It is still controlled because it does not rely on a rare natural moment when two targets both enter `PENDING_SELECTION` at the same time.

The injected event creates this controlled handover state:

| Simulation variable | Injected value |
|---|---|
| `interceptor_process_state{1}` | `PENDING_SELECTION` |
| `interceptor_process_state{2}` | `PENDING_SELECTION` |
| `active_trackers{1}` | `[1; 2]` |
| `active_trackers{2}` | `[3; 4]` |
| `sensor_states{1}` | `TRACKING` |
| `sensor_states{2}` | `TRACKING` |
| `sensor_states{3}` | `TRACKING` |
| `sensor_states{4}` | `TRACKING` |
| `sensor_roles{1}` | `PRIMARY_TRACKER` |
| `sensor_roles{2}` | `SECONDARY_TRACKER` |
| `sensor_roles{3}` | `PRIMARY_TRACKER` |
| `sensor_roles{4}` | `SECONDARY_TRACKER` |
| `interceptor_process_data{1}.predictor_id` | `1` |
| `interceptor_process_data{2}.predictor_id` | `3` |
| `interceptor_process_data{1}.intercept_point` | `[8.4996 0.4203]` |
| `interceptor_process_data{2}.intercept_point` | `[4.0899 5.5874]` |

The candidate pool is the set of all sensors excluding the injected active trackers:

```text
All sensors = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]
Active trackers = [1 2 3 4]
Candidate sensors = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]
```

The expected high-level behavior is:

```text
1. Target 1 and target 2 are detected as simultaneous calling targets.
2. V46 builds a real cost matrix from live simulation variables.
3. MCMF chooses 4 unique sensors because each of 2 targets requests 2 interceptors.
4. No active tracker is selected.
5. Selected sensors become INTERCEPTING.
6. Selected sensors receive INTERCEPTOR_CANDIDATE role.
7. Selected sensors receive target-specific proactive intercept points.
8. The simulation continues from t = 5.00 s to t = 8.00 s.
```

## Injected Simulation State

At `t = 5.00 s`, the test injects one simultaneous selection event:

| Field | Value |
|---|---|
| Forced calling targets | `[1 2]` |
| Target 1 active trackers | `[1 2]` |
| Target 2 active trackers | `[3 4]` |
| Target 1 predictor sensor | `1` |
| Target 2 predictor sensor | `3` |
| Forced target 1 velocity estimate | `[1.0 0.2]` |
| Forced target 2 velocity estimate | `[0.8 0.25]` |
| Target 1 safe intercept point | `[8.4996 0.4203]` |
| Target 2 safe intercept point | `[4.0899 5.5874]` |
| Injection marker in log | `[MCMF_TEST_INJECTION]` |

The injected active trackers are deliberately excluded from assignment. Therefore candidate sensors are all non-active sensors:

```text
[5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]
```

## Adapter Cost Matrix Inside The Real Loop

The following matrix was generated by the real V46 call to `buildAssignmentCostMatrixForCallingTargets(...)` during the Stage 3 injected event. The rows are candidate sensors and the columns are the two calling targets.

| Candidate sensor | Cost to target 1 | Cost to target 2 |
|---:|---:|---:|
| 5 | 0.4887 | 0.4628 |
| 6 | 0.3088 | 0.3262 |
| 7 | 0.2531 | 0.3384 |
| 8 | 0.3310 | 0.3395 |
| 9 | 0.4213 | 0.3429 |
| 10 | 0.4689 | 0.4377 |
| 11 | 0.3851 | 0.3635 |
| 12 | 0.3932 | 0.3854 |
| 13 | 0.4228 | 0.4245 |
| 14 | 0.4625 | 0.4693 |
| 15 | 0.5067 | 0.5163 |
| 16 | 0.4323 | 0.4074 |
| 17 | 0.4283 | 0.4111 |
| 18 | 0.4428 | 0.4344 |
| 19 | 0.4711 | 0.4696 |
| 20 | 0.5076 | 0.5107 |
| 21 | 0.4709 | 0.4494 |
| 22 | 0.4751 | 0.4599 |
| 23 | 0.4925 | 0.4838 |
| 24 | 0.5200 | 0.5167 |
| 25 | 0.5544 | 0.5551 |

## Theoretical Optimal MCMF Result

Each target requests 2 interceptor slots, so total demand is 4. There are 21 candidates, so this is not a shortage case. The MCMF objective is:

```text
1. maximize assigned slots;
2. among full 4-slot assignments, minimize total cost;
3. enforce that each sensor can be assigned at most once.
```

The selected MCMF assignment is:

| Target | Selected interceptors | Cost |
|---:|---:|---:|
| 1 | `[6 7]` | `0.3088 + 0.2531 = 0.5619` |
| 2 | `[8 9]` | `0.3395 + 0.3429 = 0.6824` |
| Total | `[6 7 8 9]` | `1.2443` |

Why this is optimal:

```text
Sensor 7 is the cheapest candidate for target 1.
Sensor 6 is the second-cheapest candidate for target 1.
Sensor 8 and sensor 9 are the best remaining candidates for target 2 after reserving sensors 6 and 7 for target 1.
The assignment uses four unique sensors and fills all requested slots.
```

## Legacy vs MCMF On The Same Real Simulation Event

For report comparison, the same cost matrix was also evaluated with the legacy path.

Legacy result:

```text
Target 1 -> [7 11]
Target 2 -> [6 8]
Total cost = 1.3038
Assigned slots = 4
```

MCMF result:

```text
Target 1 -> [6 7]
Target 2 -> [8 9]
Total cost = 1.2443
Assigned slots = 4
```

Interpretation:

```text
Both algorithms fill all four requested slots.
MCMF achieves a lower total cost on the exact same candidates and cost matrix.
The improvement is 1.3038 - 1.2443 = 0.0595.
```

This is useful evidence because it comes from a real V46 simulation loop event, not only from a standalone mock adapter test.

## Test Result Summary

The Stage 3 test passed.

The actual result from the latest run was:

| Result item | Observed value |
|---|---|
| MAT output | `logs/mcmf_stage3_data_20260407_140150.mat` |
| Log output | `logs/mcmf_stage3_log_20260407_140150.log` |
| Injection time | `5.00 s` |
| Assignment event time | `5.00 s` |
| Algorithm used | `MCMF` |
| Calling targets | `[1 2]` |
| Candidate sensors | `[5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25]` |
| MCMF selected target 1 interceptors | `[6 7]` |
| MCMF selected target 2 interceptors | `[8 9]` |
| All selected interceptors | `[6 7 8 9]` |
| MCMF total cost | `1.2443` |
| Legacy total cost on same matrix | `1.3038` |
| MCMF cost improvement | `0.0595` |
| Final simulation time | `8.00 s` |
| Post-assignment continuation time | `3.00 s` |

The runner assertions verified:

```text
assignment_events exists and is non-empty.
stage3_injection_info.injected == true.
stage3_assignment_snapshot exists.
assignment_events(event_index).algorithm == 'MCMF'.
calling_targets includes both target 1 and target 2.
assigned sensors are unique.
assigned sensors do not intersect active trackers [1 2 3 4].
selected sensors are INTERCEPTING immediately after assignment.
selected sensors have INTERCEPTOR_CANDIDATE role immediately after assignment.
selected sensors have non-empty proactive_targets.
simulation continues at least 1.0 s after assignment.
at least one selected sensor shows movement after assignment.
MAT output exists.
```

This means Stage 3 provides real-loop evidence for the MCMF integration:

```text
The MCMF module is not only correct in isolation; V46 can call it during the actual simulation loop,
apply its result to real simulation state variables, and continue running.
```

## State Update Verification

Immediately after the MCMF event, the Stage 3 runner captures `stage3_assignment_snapshot`. The snapshot verifies that V46 consumed the MCMF result correctly:

| Selected sensor | State after assignment | Role after assignment | Proactive target |
|---:|---|---|---|
| 6 | `INTERCEPTING` | `INTERCEPTOR_CANDIDATE` | `[8.4996 0.4203]` |
| 7 | `INTERCEPTING` | `INTERCEPTOR_CANDIDATE` | `[8.4996 0.4203]` |
| 8 | `INTERCEPTING` | `INTERCEPTOR_CANDIDATE` | `[4.0899 5.5874]` |
| 9 | `INTERCEPTING` | `INTERCEPTOR_CANDIDATE` | `[4.0899 5.5874]` |

The selected sensors are not active trackers:

```text
Active trackers at injection time = [1 2 3 4]
Selected interceptors = [6 7 8 9]
Intersection = []
```

The simulation also continued after the assignment:

```text
Assignment time = 5.00 s
Final Stage 3 simulation time = 8.00 s
Post-assignment runtime = 3.00 s
```

The runner verifies that at least one selected sensor shows movement in `sensor_trajectories` after assignment.

## Latest Verification Result

Latest Stage 3 runner output:

```text
Stage 3 MCMF short controlled simulation passed.
MAT output: logs/mcmf_stage3_data_20260407_140150.mat
Log output: logs/mcmf_stage3_log_20260407_140150.log
Assignment time: 5.00 s
Calling targets: [1  2]
Assigned sensors: [6  7  8  9]
Total cost: 1.2443
```

Existing module and adapter tests still pass:

```text
Running test_interceptor_assignment
.....
Done test_interceptor_assignment

Running test_mcmf_simulation_adapter
.....
Done test_mcmf_simulation_adapter
```

The new runner has no `checkcode` issues:

```text
run_mcmf_stage3_short_controlled_simulation.m checkcode issues: 0
```

The V46 scripts still have historical `checkcode` warnings, mainly `datestr`, `now`, global variables, and existing dynamic-array growth warnings. These are not Stage 3 parsing errors.

## What This Test Proves

Stage 3 proves:

```text
1. The default-off injection mechanism can force a controlled simultaneous selection inside the real loop.
2. The real V46 `PENDING_SELECTION` branch calls the MCMF wrapper.
3. The real adapter creates a valid candidate set and cost matrix from live simulation variables.
4. MCMF assigns unique non-tracker sensors.
5. Selected sensors enter INTERCEPTING with INTERCEPTOR_CANDIDATE role.
6. Selected sensors receive target-specific proactive intercept points.
7. The simulation continues for multiple timesteps after the assignment.
8. Stage 3 MAT and log outputs are saved separately from normal full-simulation outputs.
```

## What This Test Does Not Prove Yet

Stage 3 does not prove the full natural 82 s behavior. It intentionally bypasses the natural EKF/loss-prediction timing only for the injected event.

Still unproven until later stages:

```text
Natural EKF convergence timing.
Natural prediction stability timing.
Naturally occurring simultaneous PENDING_SELECTION.
Full 82 s behavior after an injected event.
Full no-injection natural behavior.
```

The next recommended step is Stage 4: run the full 82 s simulation with the same default-off injection mechanism, then verify that MCMF assignment remains stable over the complete run.
