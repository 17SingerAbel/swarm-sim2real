# AGENTS.md - WSN Multi-Target Cooperative Tracking

## Project Status
This repository currently contains the MATLAB baseline for a wireless sensor network (WSN) cooperative tracking project and the planning artifacts for a later sim-to-real port.

The active codebase is now organized under `matlab-sim/`.

- Active MATLAB baseline: `matlab-sim/src/example_V47_Yeqi.m`
- Archived historical MATLAB versions: `matlab-sim/archive/versions/`
- Active helper functions: `matlab-sim/src/*.m`
- Project docs and analysis notes: `matlab-sim/docs/`
- Reports and papers: `matlab-sim/reports/`
- Media and figures: `matlab-sim/media/`
- Generated run outputs: `matlab-sim/generated/logs/`
- Archived generated artifacts: `matlab-sim/archive/generated/`
- ROS 2 sim-to-real roadmap: `plan.md`

Unless the user explicitly asks otherwise, `example_V47_Yeqi.m` is the canonical MATLAB source of truth.

## Project Overview
The MATLAB simulation models cooperative multi-target tracking using a mobile WSN on a 5x5 staggered hex grid.

Sensors coordinate through a finite state machine (FSM) to:

- track up to 3 moving targets
- maintain exactly 2 active trackers per target whenever possible
- predict tracker loss before the target leaves detection range
- assign new interceptors proactively
- resolve multi-target assignment conflicts

The longer-term goal is to port the validated logic into a ROS 2 Humble stack for Crazyflie-based simulation and later hardware experiments on Ubuntu 22.04.

## Active Repository Layout
Use this structure as the current source of truth.

- `matlab-sim/src/`
  - active MATLAB entrypoint and helper functions
- `matlab-sim/docs/`
  - design notes, debugging notes, submission logs
- `matlab-sim/reports/`
  - reports, manuscripts, supporting PDFs/DOCX/HTML
- `matlab-sim/media/`
  - GIFs, figures, diagrams
- `matlab-sim/generated/logs/`
  - `.log` and `.mat` outputs from MATLAB runs
- `matlab-sim/archive/versions/`
  - old MATLAB baselines and archived zip snapshots
- `matlab-sim/archive/generated/`
  - old temp folders, report-render outputs, browser caches, and other generated support artifacts

Root-level files are mostly meta/control files:

- `AGENTS.md`
- `CLAUDE.md` (legacy reference only; do not follow Claude-specific workflow rules)
- `ros2-design.md`
- `plan.md`
- `CHANGELOG.md`
- `.gitignore`

## Primary MATLAB Files
Canonical entrypoint:

- `matlab-sim/src/example_V47_Yeqi.m`

Current helper functions extracted from the monolithic script:

- `matlab-sim/src/buildAssignmentCostMatrixForCallingTargets.m`
- `matlab-sim/src/calculateEnhancedBid.m`
- `matlab-sim/src/expandCallingTargetsForAssignment.m`
- `matlab-sim/src/findNearbySensors.m`
- `matlab-sim/src/getSharedTargetInfo.m`
- `matlab-sim/src/solveInterceptorAssignments.m`
- `matlab-sim/src/solveInterceptorAssignmentOptimal.m`
- `matlab-sim/src/solveInterceptorAssignmenMinMax.m`

Archived versions:

- `matlab-sim/archive/versions/example_V45_V38_b_Yeqi.m`
- `matlab-sim/archive/versions/example_V46_Yeqi.m`
- `matlab-sim/archive/versions/example_V46_natural_conflict_Yeqi_copy.m`

## Domain Concepts
- **WSN**: Wireless Sensor Network with 25 mobile sensor nodes
- **EKF**: Extended Kalman Filter per sensor and per target, state `[x; y; vx; vy]`
- **FSM**: system-level and sensor-level finite state machines
- **Handover**: proactive reassignment before a tracker loses the target
- **Interceptor**: non-tracking sensor assigned to a predicted intercept point
- **Dual-tracker invariant**: each target should have exactly 2 active trackers when resources permit

## System-Level FSM States
| State | Description |
|-------|-------------|
| `IDLE` | No targets are active |
| `TRACKING` | At least one target is being tracked |
| `SEARCHING` | All targets are currently lost |
| `REACQUIRING` | A lost target has been detected again |

## Sensor-Level FSM States
| State | Description |
|-------|-------------|
| `IDLE` | Sensor is unassigned and near home position |
| `DETECTING` | Target has just entered detection range |
| `TRACKING` | Sensor is actively tracking an assigned target |
| `INTERCEPTING` | Sensor is moving to a predicted intercept point |
| `SEARCHING` | Sensor is performing search behavior for a lost target |
| `RETURNING_HOME` | Sensor is returning to home position |

## Sensor Roles
| Role | Meaning |
|------|---------|
| `NONE` | No active tracking role |
| `PRIMARY_TRACKER` | Lead tracker for a target |
| `SECONDARY_TRACKER` | Backup tracker for a target |
| `INTERCEPTOR_CANDIDATE` | Sensor selected or considered for interception |

## Key Parameters
These values describe the current MATLAB baseline and should be treated as default assumptions unless the user requests a behavior change.

| Parameter | Value |
|-----------|-------|
| `a` | `1.5` units |
| `node_spacing` | `8 * a = 12` units |
| `communication_range` | `node_spacing * 1.5 = 18` units |
| `sensor_velocity` | `0.75` units/s |
| `dt` | `0.1` s |
| `simulation_time` | `75` s |
| `Q` | `0.01 * eye(2)` |
| `R` | `0.0025 * eye(2)` |
| `grid_size` | `5 x 5 = 25` nodes |
| `num_targets` | `3` |
| `MAX_ACTIVE_TRACKERS` | `2` |
| `SAFETY_MARGIN` | `0.1` |
| `EKF_VELOCITY_CONVERGENCE_THRESHOLD` | `0.006` |
| `PREDICTION_STABILITY_THRESHOLD` | `0.5` |
| `MIN_STABLE_PREDICTIONS` | `2` |
| `noise` | `0.01` |

## Coding Conventions
- MATLAB indexing is 1-based.
- FSM states and roles are represented as string-valued struct fields.
- EKF state vectors are 4x1 column vectors: `[x; y; vx; vy]`.
- All positions are represented in abstract simulation "units".
- `node_positions(i,:)` is the current position of sensor `i`.
- `original_positions(i,:)` is the home position of sensor `i`.
- `sensor_ekf_states{i, target_id}` stores one sensor-target EKF state.
- `sensor_P_matrices{i, target_id}` stores the corresponding EKF covariance.
- `active_trackers{target_id}` stores the sensor IDs actively tracking that target.
- `interceptor_process_state{target_id}` stores the handover pipeline state for a target.

## Interceptor Pipeline
Per target, the handover pipeline is:

`NONE -> PENDING_BROADCAST -> PENDING_BIDDING -> PENDING_SELECTION -> NONE`

Default bid weights:

- `w1 = 0.4` home displacement penalty
- `w2 = 0.3` distance-to-intercept penalty
- `w3 = 0.2` temporal lateness penalty
- `w4 = 0.1` uncertainty penalty

## How to Run
From MATLAB:

1. Change directory to `matlab-sim/src/`
2. Run:

```matlab
example_V47_Yeqi
```

Expected behavior:

- The simulation runs for 75 s
- Figure 2 provides the real-time animation
- Console output prints debug and event logs
- `.log` and `.mat` outputs are written under `matlab-sim/generated/logs/`

## Current Development Stage
The MATLAB simulation is complete and serves as the algorithmic baseline.
ROS 2 implementation has begun: architecture is fully designed, M1-M3 are complete, and M4 distributed handover is the next major milestone unless the user says otherwise.

Current priorities:

1. keep the MATLAB baseline organized and runnable as regression ground truth
2. implement ROS 2 milestones in order (M1 → M2 → ... → M9)
3. validate each milestone against MATLAB behavior before advancing

The full ROS 2 architecture is documented in `ros2-design.md`. Treat it as the authoritative ROS 2 design reference. The milestone roadmap lives in `plan.md`, but `plan.md` contains older centralized-coordinator planning notes; if it conflicts with `ros2-design.md`, follow `ros2-design.md`.

## Agent Working Rules
These rules apply to any coding agent working in this repository.

- Treat `matlab-sim/src/example_V47_Yeqi.m` as the active baseline unless the user asks to switch.
- For any ROS 2 work, read `ros2-design.md` first and preserve its distributed DES architecture.
- Do not edit archived versions in `matlab-sim/archive/versions/` unless the user explicitly requests it.
- Do not treat `matlab-sim/archive/generated/` as active source.
- Prefer behavior-preserving cleanup before algorithm changes.
- Keep filesystem cleanup, refactoring, and logic changes as separate steps when possible.
- When changing run/output paths, keep them inside `matlab-sim/generated/` unless the user asks otherwise.
- When documenting behavior, prefer current file paths over historical ones.
- Implement one milestone or one behavior slice at a time.
- Validate behavior against MATLAB logs or deterministic ROS regression scenarios whenever possible.
- Update `CHANGELOG.md` after every meaningful repository change, including docs-only changes.
- If instructions disagree, prioritize in this order: user request, `AGENTS.md`, `ros2-design.md`, current code, `plan.md`, legacy `CLAUDE.md`.

## Changelog Discipline
`CHANGELOG.md` is the project memory log. It exists so the user and future Codex sessions can quickly recover context after several days away.

For each meaningful change:

- Add a newest-first entry to `CHANGELOG.md`.
- Use the format: date, short title, `Scope`, `Changed`, `Why`, `Verified`, and `Next`.
- Mention tests, builds, simulations, or commands actually run. If no verification was run, say why, for example `Not run (docs-only change)`.
- Keep entries concise but specific enough to reconstruct the work without reading the full diff.
- Do not log generated artifacts or temporary files unless they are intentionally part of the project state.
- If a change spans multiple turns, update the entry before handing control back to the user.

## Codex Working Guidance
The preferred workflow in this repository is now Codex-first.

- Codex should do the remaining planning, implementation, refactoring, validation, and documentation work directly.
- Do not prepare handoff prompts for Claude unless the user explicitly asks for one.
- Do not frame work as Claude tasks or assume Claude will execute implementation slices.
- Keep the user involved in learning-heavy ROS 2 decisions, but do not stop at advice when the requested work can be implemented safely.
- Prefer small, verifiable changes over broad rewrites.
- Explain new ROS 2 concepts briefly when they affect the user's understanding or future choices.
- For coding tasks, read the relevant files first, make the focused change, and run the closest available verification.

Good Codex task shapes in this repo:

- implement one ROS 2 milestone slice
- port one MATLAB helper into a ROS/Python module
- add or update one message/interface set
- create one launch/config/test path
- compare one ROS behavior against MATLAB logs
- refactor one subsystem while preserving behavior
- update project docs after an architectural decision

Bad Codex task shapes in this repo:

- "port everything to ROS 2" in one step
- "clean the whole codebase"
- "rewrite all MATLAB into Python"
- introducing a central coordinator to simplify the distributed assignment problem
- mixing filesystem cleanup, large refactors, and algorithm changes in one unverified edit

## Sim-to-Real Direction
The intended future stack is:

- Ubuntu 22.04
- ROS 2 Humble
- Crazyswarm2
- Crazyflie simulation first
- real Crazyflie hardware later

Recommended porting strategy:

- architecture is fully distributed DES: no central coordinator node and no `assignment_manager`
- each `sensor_agent` node owns its FSM, EKF, bidding, assignment reconstruction, and self-assignment logic
- sensors subscribe to target ground-truth topics in simulation, but detection is gated by distance inside `sensor_agent`
- use global ROS topics plus software communication-range filtering for M4; realistic latency, packet loss, and inconsistent bid subsets are M8 concerns
- validate in Crazyswarm2 SITL simulation before real hardware
- preserve MATLAB behavior first, optimize later
- keep Crazyflie-specific logic isolated in `swarm_cf_adapter`; `sensor_agent` must not depend on Crazyswarm2

Hardware note:

- user has explicitly chosen Crazyflie 2.0 as the target hardware

## ROS 2 Architecture Rules
These rules summarize `ros2-design.md` and should be followed for ROS 2 implementation.

- Do not create a central `assignment_manager` or handover coordinator. Debug visibility should be handled by read-only observer nodes.
- Package layout should follow the current distributed design:
  - `swarm_interfaces` for custom messages
  - `target_simulator` for target ground-truth motion
  - `sensor_agent` for FSM, EKF, bidding, assignment reconstruction, and local role transitions
  - `swarm_visualization` for RViz2 markers
  - `swarm_bringup` for launch files and YAML configs
- Keep EKF inside each `sensor_agent`; do not extract it into a separate runtime node.
- Build `swarm_interfaces` before dependent packages.
- Use milestone-specific launch/config naming such as `sim_m4.launch.py` and `sim_m4_params.yaml`.
- Use sensor IDs `0-24` and target IDs `0-2` in ROS 2 code.
- Preserve deterministic assignment behavior: all sensors that receive the same request and bids should reconstruct and solve the same assignment problem.
- Use event topics for handover requests, bids, and commitments:
  - `/swarm/handover_request`
  - `/swarm/bids`
  - `/swarm/commitment`
- Use `RELIABLE` QoS for event messages and lighter QoS for high-rate visualization/state topics when appropriate.

## ROS 2 Milestone Status
Current milestone status from `ros2-design.md`:

| Milestone | Status | Focus |
|-----------|--------|-------|
| M1 | Done | Minimal running graph: 1 sensor, 3 targets, visible FSM transitions |
| M2 | Done | 25-sensor hex grid launched from YAML config |
| M3 | Done | Per-sensor EKF, noisy measurements, estimate topics |
| M4 | Next/in progress | Distributed handover: request, bidding, reconstruction, self-assignment |
| M5 | Planned | Multi-target conflict resolution and expanded joint assignment scope |
| M6 | Planned | RViz2 visualization |
| M7 | Planned | Crazyflie/Crazyswarm2 adapter and simulation integration |
| M8 | Planned | Real communication constraints |
| M9 | Planned | Real Crazyflie 2.0 hardware validation |

## Related Documents
- `ros2-design.md` — authoritative ROS 2 architecture reference (read this first for any ROS 2 session)
- `plan.md` — ROS 2 sim-to-real roadmap; contains some older centralized-coordinator notes superseded by `ros2-design.md`
- `CHANGELOG.md` — newest-first project memory log; update after meaningful changes
- `CLAUDE.md` — legacy Claude-specific guidance; keep only as historical context unless the user explicitly asks about it
- `matlab-sim/docs/design.md` — MATLAB system design notes
- `matlab-sim/docs/debug_interception_analysis.md` — bug and logic analysis
