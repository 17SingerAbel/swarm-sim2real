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
- `CLAUDE.md`
- `plan.md`
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
This repository is still MATLAB-first.

Current priorities:

1. keep the MATLAB baseline organized and runnable
2. preserve behavior while extracting cleaner module boundaries
3. prepare the logic for later ROS 2 porting

The ROS 2 implementation itself has not started in this repository yet. The current roadmap lives in `plan.md`.

## Agent Working Rules
These rules apply to any coding agent working in this repository.

- Treat `matlab-sim/src/example_V47_Yeqi.m` as the active baseline unless the user asks to switch.
- Do not edit archived versions in `matlab-sim/archive/versions/` unless the user explicitly requests it.
- Do not treat `matlab-sim/archive/generated/` as active source.
- Prefer behavior-preserving cleanup before algorithm changes.
- Keep filesystem cleanup, refactoring, and logic changes as separate steps when possible.
- When changing run/output paths, keep them inside `matlab-sim/generated/` unless the user asks otherwise.
- When documenting behavior, prefer current file paths over historical ones.

## Codex + Claude Collaboration Guidance
The preferred workflow in this repository is:

- Codex does planning, design review, task decomposition, and validation.
- Claude is used as a narrow execution worker for bounded coding tasks.

If preparing work for another agent such as Claude:

- keep the task narrow
- specify exactly which files may be changed
- include clear acceptance criteria
- avoid broad open-ended refactors
- avoid assigning multiple architectural decisions in one prompt
- prefer one behavior slice at a time

Good Claude tasks in this repo:

- extract one helper function
- clean one logging/output path
- add one test or regression check
- port one MATLAB subsystem into a ROS prototype

Bad Claude tasks in this repo:

- "port everything to ROS 2"
- "clean the whole codebase"
- "rewrite all MATLAB into Python"

## Sim-to-Real Direction
The intended future stack is:

- Ubuntu 22.04
- ROS 2 Humble
- Crazyswarm2
- Crazyflie simulation first
- real Crazyflie hardware later

Recommended porting strategy:

- start with a centralized coordinator architecture
- validate in simulation before hardware
- preserve MATLAB behavior first, optimize later

Hardware note:

- Crazyflie 2.0 is not the preferred default for a new setup
- Crazyflie 2.1+ is the safer default unless hardware constraints require 2.0

## Related Documents
- `plan.md` for the ROS 2 sim-to-real roadmap
- `matlab-sim/docs/design.md` for system design notes
- `matlab-sim/docs/debug_interception_analysis.md` for bug and logic analysis
- `CLAUDE.md` for any Claude-specific repository guidance
