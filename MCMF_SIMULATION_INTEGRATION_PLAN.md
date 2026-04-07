# MCMF Simulation Integration Plan

## Summary

The current MCMF validation now has two completed layers:

```text
Stage 1: module and adapter tests
Stage 3: short controlled simulation with default-off injection
```

Stage 2 was intentionally skipped. It would only be useful if V46's assignment-state mutation logic were extracted into a shared helper and tested directly. Since the next concern is whether the real simulation loop can consume MCMF assignments, the project moved directly to Stage 3 instead.

This document intentionally separates simulation integration testing from `MCMF_TEST_PLAN.md`, which remains focused on module and adapter testing.

For the detailed Stage 3 test case, cost matrix, legacy comparison, and verification output, see `MCMF_STAGE3_TEST_PLAN.md`.

For the proposed Stage 4 full injected simulation test plan, see `MCMF_STAGE4_TEST_PLAN.md`.

## Stage Definitions

### Stage 1: Module And Adapter Tests

Status: complete.

Question answered:

```text
Did MCMF choose the right sensors from adapter-generated candidates and cost matrices?
```

Covered by:

```text
test_interceptor_assignment.m
test_mcmf_simulation_adapter.m
MCMF_TEST_PLAN.md
```

Boundary:

```text
simulation-like state -> buildAssignmentCostMatrixForCallingTargets -> solveInterceptorAssignments
```

Stage 1 does not run the real simulation loop.

### Stage 2: Assignment Application Runner

Status: skipped / optional.

Original idea:

```text
selected assignments -> sensor_states / sensor_roles / proactive_targets / assignment_events
```

Reason for skipping:

```text
If this runner copied V46 logic, it would test a duplicate rather than the real simulation.
If it required extracting a shared helper, it would add refactor cost before the real-loop integration question was answered.
```

Decision:

```text
Skip Stage 2 for now and proceed directly to Stage 3.
```

Stage 2 can be revisited later only if we decide to refactor V46's assignment-state update into a shared helper.

### Stage 3: Short Controlled Simulation

Status: implemented and passing.

Question answered:

```text
Can the real V46 simulation loop consume a controlled simultaneous MCMF selection event and continue running?
```

Implementation:

```text
run_mcmf_stage3_short_controlled_simulation.m
```

The runner enables these environment variables before calling the dedicated Stage 3 script `example_v46_stage3_Yeqi`:

```text
ENABLE_MCMF_STAGE3_TEST = 1
MCMF_STAGE3_SIMULATION_TIME = 8
MCMF_STAGE3_INJECTION_TIME = 5
```

The V46 script then injects one event at `t = 5.00 s`:

```text
Target 1 active trackers = [1 2]
Target 2 active trackers = [3 4]
Target 1 and target 2 state = PENDING_SELECTION
```

The injection log marker is:

```text
[MCMF_TEST_INJECTION]
```

Latest observed result:

```text
Assignment time = 5.00 s
Calling targets = [1 2]
MCMF selected sensors = [6 7 8 9]
Total cost = 1.2443
Final Stage 3 simulation time = 8.00 s
```

Stage 3 validates:

```text
The real PENDING_SELECTION branch calls the MCMF wrapper.
Selected sensors are unique.
Selected sensors are not active trackers.
Selected sensors enter INTERCEPTING.
Selected sensors receive INTERCEPTOR_CANDIDATE role.
Selected sensors receive non-empty proactive_targets.
The simulation continues after assignment without runtime error.
MAT and log outputs are generated.
```

### Stage 4: Full Simulation With Injection

Status: not implemented yet.

Question to answer:

```text
Does the full 82 s simulation remain stable after one controlled simultaneous MCMF selection event?
```

Recommended approach:

```text
Reuse the default-off injection mechanism.
Run the full 82 s simulation instead of the 8 s Stage 3 slice.
Keep USE_MCMF_ASSIGNMENT = true.
Keep the real cost function unchanged.
Check assignment_events, selected sensors, movement, handover aftermath, and MAT outputs.
```

Stage 4 can bypass EKF convergence and prediction stability only for the injected event because those are handover trigger gates, not the MCMF assignment objective.

Stage 4 must not disable `P_home` or the home-distance penalty because that would change the assignment objective being tested.

### Stage 5: Full Natural Simulation

Status: not implemented yet.

Question to answer:

```text
Does the normal no-injection V46 simulation behave well with USE_MCMF_ASSIGNMENT = true?
```

Stage 5 must run with:

```text
ENABLE_MCMF_STAGE3_TEST = false
USE_MCMF_ASSIGNMENT = true
```

Natural triggers should be restored:

```text
EKF convergence
prediction stability
loss prediction
normal PENDING_BROADCAST -> PENDING_BIDDING -> PENDING_SELECTION
```

This is the stage for final natural-simulation claims.

## Parameter Policy

### Safe To Bypass In Injected Tests

It is acceptable to bypass EKF convergence and prediction stability only for the injected event.

Reason:

```text
These conditions are trigger gates.
They decide when MCMF should be called.
They are not part of the MCMF assignment objective itself.
```

### Do Not Disable Cost Function Terms

Do not disable `P_home` or the home-distance penalty during integration testing.

Reason:

```text
P_home is part of calculateEnhancedBid(...).
It directly changes the assignment objective.
If disabled, the integration test no longer represents the V46 MCMF objective.
```

### Avoid Changing Core Dynamics

Do not change these parameters just to make injected tests easier:

```text
MAX_ACTIVE_TRACKERS
sensor_velocity
dt
target trajectories
EKF noise parameters
```

Changing them would mix assignment validation with motion-model or estimation-model changes.

## Why Injection Does Not Pollute Normal Simulation

The injection path is safe because:

```text
The injection hook is isolated in example_v46_stage3_Yeqi.m.
The normal run command remains example_V46_Yeqi.
The main example_V46_Yeqi.m file does not contain the Stage 3 injection block.
The Stage 3 block runs only when ENABLE_MCMF_STAGE3_TEST is explicitly enabled.
Every injection log line includes [MCMF_TEST_INJECTION].
Stage 3 outputs use mcmf_stage3_* filenames.
Stage 5 requires the injection flag to be off.
```

## Recommended Next Step

Proceed to Stage 4:

```text
Run a full 82 s simulation with the same default-off injection mechanism.
Verify that the system remains stable after the MCMF event over the complete run.
Document the full-run assignment event, movement behavior, and any handover aftermath.
```
