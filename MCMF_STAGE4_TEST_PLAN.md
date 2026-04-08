# MCMF Stage 4 Full Injected Simulation README

## Summary

Stage 4 is the validation layer after the Stage 3 short controlled simulation. It does not change the MCMF algorithm, cost function, target trajectories, EKF parameters, or the main `example_V46_Yeqi.m` file.

The main idea is:

```text
Stage 3:
short controlled run + one forced simultaneous PENDING_SELECTION event

Stage 4:
full 75 s simulation run + one forced simultaneous PENDING_SELECTION event
```

Stage 4 is still not a fully natural run, because it still uses injection to force simultaneous target 1 and target 2 selection. The difference is that after the injected assignment, the simulation continues for the rest of the full 75 s horizon. This tests whether the MCMF assignment remains compatible with the longer FSM, movement, tracking, returning-home, handover, logging, and MAT-output behavior.

## Why Stage 4 Is Different From Stage 3

Stage 3 answers:

```text
Can the real V46-derived loop consume a controlled simultaneous MCMF assignment and continue for a short time?
```

Stage 4 answers:

```text
Can the full 75 s simulation remain stable after a controlled simultaneous MCMF assignment?
```

The difference is the evidence target:

| Layer | Runtime | Trigger | Main evidence |
|---|---:|---|---|
| Stage 1 | No simulation loop | Mock inputs | Solver and adapter correctness |
| Stage 3 | Short run, e.g. 8 s or 30 s | Injected simultaneous selection | Real-loop assignment and immediate post-assignment behavior |
| Stage 4 | Full 75 s run | Injected simultaneous selection | Long-run stability after injected assignment |
| Stage 5 | Full 75 s run | Natural EKF/loss prediction trigger | Final no-injection behavior |

Stage 4 is stronger than Stage 3 because it allows later simulation logic to interact with the selected interceptors over a much longer period.

Stage 4 is weaker than Stage 5 because it still bypasses natural simultaneous-trigger timing.

## Proposed Setup

Use the dedicated Stage 4 script:

```text
example_v46_stage4_Yeqi.m
```

Reason:

```text
The main example_V46_Yeqi.m file should remain clean and free of injection hooks.
The Stage 4 script contains the augment-or-fallback injection mechanism.
Stage 3 remains isolated in example_v46_stage3_Yeqi.m.
```

Runner:

```text
run_mcmf_stage4_full_injected_simulation.m
```

Recommended environment settings:

```matlab
setenv('ENABLE_MCMF_STAGE3_TEST', '1');
setenv('MCMF_STAGE3_SIMULATION_TIME', '82');
setenv('MCMF_STAGE3_INJECTION_TIME', '15');
setenv('MCMF_STAGE3_USE_MCMF', '1');
```

Although some environment variable names still say `STAGE3`, the Stage 4 runner now calls `example_v46_stage4_Yeqi.m` and writes `logs/mcmf_stage4_*` outputs.

## Injection Choice

Recommended initial injection time:

```text
t = 15.00 s
```

Reason:

```text
This timing has already been tested in Stage 3 with simulation_time = 30 s.
It produced a valid simultaneous target 1/2 selection.
It also produced a useful MCMF-vs-legacy comparison:
MCMF total cost = 1.0341
Legacy total cost = 1.0968
MCMF improvement = 0.0626
```

The injected state should remain the same as Stage 3:

| Simulation variable | Injected value |
|---|---|
| `interceptor_process_state{1}` | `PENDING_SELECTION` |
| `interceptor_process_state{2}` | `PENDING_SELECTION` |
| `active_trackers{1}` | `[1; 2]` |
| `active_trackers{2}` | `[3; 4]` |
| Target 1 predictor | Sensor `1` |
| Target 2 predictor | Sensor `3` |
| Injection marker | `[MCMF_TEST_INJECTION]` |

## Expected Result

The expected Stage 4 behavior is:

```text
1. The simulation starts normally.
2. At t = 15.00 s, target 1 and target 2 are forced into PENDING_SELECTION.
3. The real assignment path runs with MCMF enabled.
4. assignment_events records an MCMF event for targets [1 2].
5. Selected sensors are unique.
6. Selected sensors do not include active trackers [1 2 3 4].
7. Selected sensors receive INTERCEPTING state and INTERCEPTOR_CANDIDATE role.
8. Selected sensors receive non-empty proactive_targets.
9. The simulation continues after the injected event.
10. The run reaches the full 75 s horizon or the normal simulation stopping condition.
11. MAT/log outputs are saved.
```

## Suggested Assertions

The future Stage 4 runner should verify at least:

```text
stage4 run completed without runtime error.
stage3_injection_info.injected == true.
stage3_assignment_snapshot exists.
assignment_events contains the injected event.
actual algorithm == MCMF.
calling_targets includes [1 2].
assigned sensors are unique.
assigned sensors do not intersect [1 2 3 4].
selected sensors were INTERCEPTING immediately after assignment.
selected sensors had INTERCEPTOR_CANDIDATE role immediately after assignment.
selected sensors had non-empty proactive_targets immediately after assignment.
current_time is close to 75 s or the run ended by a documented normal stop condition.
at least one selected sensor moved after assignment.
MAT output exists.
log output exists.
```

Optional stronger checks:

```text
No selected sensor remains in an impossible state.
No duplicate active tracker assignment appears after the injected event.
interceptor_events for target 1 and target 2 are updated with selected_sensors.
The log contains [MCMF_TEST_INJECTION].
The log contains the MCMF assignment line for targets [1 2].
```

## Legacy Comparison

Stage 4 should keep the automatic A/B comparison from the Stage 3 runner:

```text
Use the actual event cost matrix.
Run MCMF on the same matrix.
Run legacy on the same matrix.
Report MCMF total cost, legacy total cost, and cost improvement.
```

This means the runner should still expose fields like:

```text
result.actual_algorithm
result.mcmf_assignments
result.mcmf_total_cost
result.legacy_assignments
result.legacy_total_cost
result.mcmf_cost_improvement
result.cost_matrix
result.candidate_sensors
```

If the Stage 4 injection time is changed, the cost matrix and assignments should be regenerated from that specific run.

## What Stage 4 Would Prove

Stage 4 would prove:

```text
The injected MCMF assignment can survive a full simulation run.
The full 75 s loop can continue after controlled simultaneous target assignment.
The longer-run FSM, movement, logging, and MAT saving are compatible with the MCMF integration.
```

## What Stage 4 Would Not Prove

Stage 4 would not prove:

```text
Natural EKF/loss-prediction timing triggers simultaneous selection by itself.
The full no-injection simulation is validated.
MCMF improves every natural run.
Every future handover event is optimal or stable.
```

Those claims should wait for Stage 5:

```text
Full 75 s simulation with injection disabled and USE_MCMF_ASSIGNMENT = true.
```

## Implementation Recommendation

Do not modify `example_V46_Yeqi.m` for Stage 4.

Implemented approach:

```text
1. Created run_mcmf_stage4_full_injected_simulation.m.
2. Created example_v46_stage4_Yeqi.m.
3. Set simulation time to 75 s.
4. Kept injection time at 15 s for the first Stage 4 run.
5. Kept MCMF enabled for the first Stage 4 verified run.
6. Preserved automatic legacy comparison on the same event cost matrix.
```

This keeps the main V46 simulation clean while allowing controlled full-run integration testing.

## Latest Verification Result

Latest verified Stage 4 MCMF run:

```text
Stage 4 full injected simulation passed.
MAT output: logs/mcmf_stage4_data_20260407_174002.mat
Log output: logs/mcmf_stage4_log_20260407_174002.log
Injection policy: AUGMENT_OR_FALLBACK
Actual injection mode: FALLBACK_CONTROLLED
Assignment time: 15.00 s
Final simulation time: 82.00 s
Actual algorithm run in simulation: MCMF
Calling targets: [1  2]
Actual assigned sensors: [6  8  7  9]
Actual total cost: 1.0341

MCMF target 1 -> [6  8]
MCMF target 2 -> [7  9]
MCMF total cost: 1.0341

Legacy target 1 -> [8  6]
Legacy target 2 -> [7  12]
Legacy total cost: 1.0968
MCMF cost improvement: 0.0626
```

Interpretation:

```text
At t = 15.00 s, no valid natural PENDING_SELECTION was available to augment, so Stage 4 used FALLBACK_CONTROLLED injection.
The simulation continued to the full 82.00 s horizon after the injected MCMF assignment.
The same event cost matrix still shows MCMF lower total cost than legacy.
```

Validation also reran the existing module and adapter tests:

```text
test_interceptor_assignment: 5 passed
test_mcmf_simulation_adapter: 5 passed
run_mcmf_stage4_full_injected_simulation.m checkcode issues: 0
```
