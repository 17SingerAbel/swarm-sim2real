# CLAUDE.md — WSN Multi-Target Cooperative Tracking

## Project Overview
MATLAB simulation of cooperative multi-target tracking using a mobile Wireless Sensor Network (WSN).
Sensors autonomously coordinate via a Finite State Machine (FSM) to track up to 3 moving targets
simultaneously, proactively handing off tracking to new sensors before losing contact.

## Primary File
- `example_V45_V38_b.m` — single monolithic MATLAB script (~2878 lines)

## Domain Concepts
- **WSN**: Wireless Sensor Network — 5×5 staggered hex grid of mobile sensor nodes
- **EKF**: Extended Kalman Filter — per-sensor, per-target state estimator ([x, y, vx, vy])
- **FSM**: Finite State Machine — governs both system-level and sensor-level behavior
- **Handover**: proactive transfer of tracking duty before the tracker loses the target
- **Interceptor**: idle sensor assigned to reach a predicted intercept point before loss occurs
- **Dual-tracker**: each target is always assigned exactly 2 active trackers (PRIMARY + SECONDARY)

## System-Level FSM States
| State | Description |
|-------|-------------|
| IDLE | No targets active |
| TRACKING | ≥1 target being tracked |
| SEARCHING | All targets lost |
| REACQUIRING | Target re-detected after loss |

## Sensor-Level FSM States
| State | Description |
|-------|-------------|
| IDLE | At home grid position |
| DETECTING | Target just entered detection range |
| TRACKING | Actively following assigned target |
| INTERCEPTING | Moving to predicted intercept point |
| SEARCHING | Searching for lost target (contour-based) |
| RETURNING_HOME | Returning to home grid position |

## Sensor Roles
| Role | Value | Description |
|------|-------|-------------|
| NONE | 'NONE' | No active role |
| PRIMARY_TRACKER | 'PRIMARY_TRACKER' | Lead tracker for a target |
| SECONDARY_TRACKER | 'SECONDARY_TRACKER' | Backup tracker for a target |
| INTERCEPTOR_CANDIDATE | 'INTERCEPTOR_CANDIDATE' | Assigned to intercept a target |

## Key Parameters
| Parameter | Value | Description |
|-----------|-------|-------------|
| `a` (detection_radius) | 1.5 units | Sensor coverage radius |
| `node_spacing` | 8*a = 12 units | Hex grid node spacing |
| `communication_range` | node_spacing*1.5 = 18 units | Peer comm range (broadcast used in practice) |
| `sensor_velocity` | 0.75 units/s | Mobile node speed |
| `dt` | 0.1 s | Simulation time step |
| `simulation_time` | 75 s | Total simulation time |
| `Q` | 0.01 * eye(2) | EKF process noise |
| `R` | 0.0025 * eye(2) | EKF measurement noise |
| `grid_size` | 5×5 = 25 nodes | Network size |
| `num_targets` | 3 | Number of tracked targets |
| `MAX_ACTIVE_TRACKERS` | 2 | Always exactly 2 trackers per target |
| `SAFETY_MARGIN` | 0.1 (10%) | Intercept point safety margin |
| `EKF_VELOCITY_CONVERGENCE_THRESHOLD` | 0.006 units²/s² | Velocity variance threshold for EKF convergence |
| `PREDICTION_STABILITY_THRESHOLD` | 0.5 TU | Max allowed change between consecutive predictions |
| `MIN_STABLE_PREDICTIONS` | 2 | Consecutive stable predictions needed before handover |
| `noise` | 0.01 | Target trajectory movement randomness |

## Coding Conventions
- All sensor/node indices are **1-based** (MATLAB default)
- FSM states are **string constants** stored in structs (`SYSTEM_STATES`, `SENSOR_STATES`, `SENSOR_ROLES`)
- EKF state vector is **4D column vector**: `[x; y; vx; vy]`
- All positions in abstract **"units"** (not meters)
- `node_positions(i,:)` — current position of sensor `i`
- `original_positions(i,:)` — home/grid position of sensor `i`
- `sensor_ekf_states{i, target_id}` — EKF state for sensor `i` tracking target `target_id`
- `sensor_P_matrices{i, target_id}` — EKF covariance for sensor `i` on target `target_id`
- `active_trackers{target_id}` — list of sensor IDs currently tracking `target_id`
- `interceptor_process_state{target_id}` — handover pipeline state per target
- Figures: Figure 2 = real-time animation

## Interceptor Pipeline States (per target)
`'NONE'` → `'PENDING_BROADCAST'` → `'PENDING_BIDDING'` → `'PENDING_SELECTION'` → `'NONE'`

## Bid Cost Function Weights (default)
`w1=0.4` (displacement from home), `w2=0.3` (distance to intercept), `w3=0.2` (temporal penalty), `w4=0.1` (uncertainty)

## How to Run
Open MATLAB and run:
```matlab
example_V45_V38_b
```
Simulation runs for 75 s with real-time Figure 2 animation. Console prints debug/event log.

## Research Context
MIE8888 research project on proactive handover in mobile WSN. Key innovations:
- EKF convergence + prediction stability gate before triggering handover
- Minimax combinatorial conflict resolution for simultaneous multi-target handovers
- Dual-tracker principle (PRIMARY + SECONDARY roles) per target at all times
- Contour-based search using chi-square 3-sigma uncertainty ellipse for lost targets
- Proportional Navigation Guidance (PNG) for intercepting sensors
