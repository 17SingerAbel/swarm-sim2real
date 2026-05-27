# ROS 2 System Design — Swarm WSN Multi-Target Tracking
> Reference document for Claude / Codex sessions.
> Written: 2026-05-24. Update this file when major design decisions change.

---

## 1. What This System Does

This is a ROS 2 Humble implementation of a **cooperative multi-target tracking system** using a **mobile wireless sensor network (WSN)**. The algorithm is described in:

> Yeqi Sang, *"Expanded Joint Interceptor Assignment for Cooperative Multi-Target Tracking"*, MIE8888 Final Report (Yeqi-mie8888-final-report.pdf in project root).

The system's job:
- 25 mobile sensors arranged in a **5×5 staggered hexagonal grid** cooperatively track up to 3 moving targets.
- Each sensor runs an **EKF** to estimate target state from noisy measurements.
- When a tracker predicts it will soon lose a target (proactive handover), it triggers a **distributed bidding process** to recruit interceptor sensors.
- Interceptor assignment is solved **locally by each sensor independently** — no central coordinator.
- Sensors follow a **Finite State Machine (FSM)** that governs role transitions.
- The system is designed as a **Discrete Event System (DES)** where events (handover requests, bids, commitments) drive state transitions.

---

## 2. Non-Negotiable Architecture Decisions

These decisions came from careful reading of the paper (especially Sections 4.4 and 4.5) and must not be reversed without a deliberate redesign discussion.

### 2.1 No Central Assignment Manager

**Decision:** There is no `assignment_manager` node. Assignment logic lives inside each `sensor_agent` node.

**Why:** Section 4.4 of the paper explicitly states:
> *"The proposed method preserves the distributed DES architecture by avoiding a coordinator or centralized bid collector."*

The mechanism is **consensus-by-reconstruction**:
1. Tracker broadcasts a handover request (ROS topic, all sensors hear it).
2. Each eligible sensor computes its own bid **locally**.
3. Each sensor publishes its bid to a shared topic.
4. After a fixed bidding window (Δt_bid), each sensor independently reconstructs the full assignment problem from received bids and solves the same deterministic two-stage LP.
5. Under ideal communication all sensors see the same bids → same problem → same solution → no coordinator needed.
6. Each sensor self-transitions its FSM if it determines it was selected.

A central `assignment_manager` would be architecturally wrong for this system. If you need debugging visibility, add a **read-only observer node** that subscribes to all topics but has no authority to publish commands.

### 2.2 Sensor Detection Is Gated by Distance, Not by Subscription

**Decision:** Sensors always subscribe to `/targets/{id}/ground_truth` (simulation oracle). But a sensor only generates a measurement when the target is within detection radius r_d.

**Why:** In the real world, a sensor's hardware detector simply cannot see a target outside its range. In ROS 2 simulation, you cannot physically filter a subscription by distance — so you subscribe always but gate the measurement step.

```
target_callback() always fires → stores raw position
fsm_step() / ekf_update() checks: ||sensor_pos - target_pos|| ≤ r_d?
  YES → generate noisy measurement z = p_target + noise(R) → EKF update + FSM transition
  NO  → no measurement → EKF prediction only → FSM cannot enter TRACKING
```

Paper reference (Section 3.1):
> *"Target detection occurs when ||s_i(t) − p_k(t)|| ≤ r_d. Upon detection, sensor i obtains a noisy position measurement z_ik(t) = p_k(t) + n(t) where n(t) is zero-mean noise with covariance R."*

### 2.3 Assignment Logic Lives Inside sensor_agent

Since there is no central manager, the `sensor_agent` node is responsible for:
- Running its own FSM
- Running EKF per tracked target
- Computing bidding cost when solicited
- Reconstructing the assignment problem after bidding window
- Self-assigning its role
- Broadcasting commitment messages

This is the correct DES/distributed multi-agent architecture.

---

## 3. Key System Parameters (from paper and MATLAB baseline)

| Parameter | Symbol | Value | Source |
|---|---|---|---|
| Detection radius | r_d | 1.5 units | paper §3.1, MATLAB: `a = 1.5` |
| Node spacing | d | 12 units (= 8×a) | MATLAB: `node_spacing = 8*a` |
| Communication range | r_c | 18 units | paper §5.1 |
| Max trackers per target | — | 2 | MATLAB: `MAX_ACTIVE_TRACKERS = 2` |
| Max interceptors per target | m | 2 | paper §3.1 |
| Sensor max speed | v_s | 0.75 units/TU | paper §5.1, MATLAB: `sensor_velocity` |
| Target speed range | v_k | 1.0–1.2 units/TU | MATLAB: `target_velocities` |
| EKF time step | dt | 0.1 s | MATLAB: `dt = 0.1` |
| EKF velocity convergence | — | 0.006 units²/s² | MATLAB: `EKF_VELOCITY_CONVERGENCE_THRESHOLD` |
| Grid size | — | 5×5 = 25 sensors | MATLAB: `grid_size = 5` |
| Grid type | — | staggered hexagonal | MATLAB geometry setup |
| Num targets | K | up to 3 | MATLAB: `num_targets = 3` |

### Bidding cost function (paper §3.2):
```
c(i, k) = w1 * P_home(i) + w2 * P_spatial(i,k) + w3 * P_temporal(i,k) + w4 * P_uncertainty(i,k)
```
- `P_home`: penalizes displacement from home position
- `P_spatial`: penalizes distance to interception point
- `P_temporal`: penalizes poor arrival timing
- `P_uncertainty`: penalizes low EKF confidence

### Two-stage assignment objective (paper §3.2):
- Stage 1: maximize total filled interceptor slots across all involved targets
- Stage 2: among all assignments achieving the max from Stage 1, minimize total assignment cost
- Constraints: each sensor assigned to at most one target; each target gets at most m interceptors

---

## 4. FSM States and Roles

### Sensor-level FSM states (from MATLAB V47):
```
IDLE              → not tracking, at or near home position
DETECTING         → target entered detection range, EKF initializing
TRACKING          → actively tracking an assigned target (primary or secondary)
INTERCEPTING      → moving to predicted interception point
SEARCHING         → lost target, searching area
RETURNING_HOME    → released from assignment, returning to home position
```

### Sensor roles (within TRACKING state):
```
NONE                 → sensor has no active role
PRIMARY_TRACKER      → closest/primary tracker for a target
SECONDARY_TRACKER    → backup tracker for the same target
INTERCEPTOR_CANDIDATE → committed interceptor, moving to interception point
```

### System-level FSM states:
```
IDLE       → no targets detected
TRACKING   → at least one target actively tracked
SEARCHING  → target(s) lost, reacquisition underway
REACQUIRING → recovering tracking after loss
```

---

## 5. Package Architecture

```
ros2_ws/
  src/
    swarm_interfaces/       # custom msg/srv/action definitions (ament_cmake)
    target_simulator/       # publishes target ground-truth motion (ament_python)
    sensor_agent/           # sensor FSM + EKF + bidding logic (ament_python)
    swarm_visualization/    # RViz2 MarkerArray visualization (ament_python)
    swarm_bringup/          # launch files + YAML configs (ament_python)
```

**Why no separate `tracking_ekf` package:** EKF is per-sensor, per-target. Each sensor node owns and runs its own EKF instances. Extracting EKF into a separate node would require a round-trip message per sensor per timestep, adding latency and defeating the point of distributed computation. Keep EKF inside `sensor_agent`.

**Why no `assignment_manager` package:** See Section 2.1 above.

**Why `swarm_interfaces` uses ament_cmake:** ROS 2 message/service/action code generation (`rosidl`) requires CMake. All other packages are pure Python and use `ament_python`.

**Build order:** Always build `swarm_interfaces` first, then other packages:
```bash
colcon build --packages-select swarm_interfaces
source install/setup.bash
colcon build --packages-select target_simulator sensor_agent swarm_visualization swarm_bringup
source install/setup.bash
```

---

## 6. ROS Graph

### Topics

| Topic | Type | Publisher | Subscribers |
|---|---|---|---|
| `/targets/{id}/ground_truth` | `TargetState` | `target_simulator` | all `sensor_agent_{id}` |
| `/sensors/{id}/state` | `SensorState` | `sensor_agent_{id}` | `swarm_visualization`, observer |
| `/sensors/{id}/ekf_estimate` | `TargetEstimate` | `sensor_agent_{id}` | other sensors (shared info), visualization |
| `/swarm/handover_request` | `HandoverRequest` | `sensor_agent_{id}` (tracker role) | all `sensor_agent_*` |
| `/swarm/bids` | `BidMsg` | `sensor_agent_{id}` (candidate role) | all `sensor_agent_*` |
| `/swarm/commitment` | `CommitmentMsg` | `sensor_agent_{id}` (after assignment) | all `sensor_agent_*`, visualization |
| `/visualization_marker_array` | `MarkerArray` | `swarm_visualization` | RViz2 |

### Key Node Parameters

**target_simulator:**
- `num_targets` (int, default 3)
- `dt` (float, default 0.1)
- `target_velocities` (float[], default [1.0, 1.1, 1.2])
- `waypoints` (float[][], per-target trajectory waypoints)

**sensor_agent_{id}:**
- `sensor_id` (int)
- `pos_x`, `pos_y` (float, home position in grid)
- `detection_radius` (float, = r_d = 1.5)
- `communication_range` (float, = r_c = 18.0)
- `num_targets` (int)
- `bidding_window` (float, = Δt_bid, seconds to wait for bids)
- `ekf_convergence_threshold` (float, = 0.006)
- `max_trackers_per_target` (int, = 2)

---

## 7. Custom Message Definitions

### `swarm_interfaces/msg/TargetState.msg`
```
int32 target_id
float64 x
float64 y
float64 vx
float64 vy
builtin_interfaces/Time stamp
```

### `swarm_interfaces/msg/SensorState.msg`
```
int32 sensor_id
string fsm_state        # IDLE | DETECTING | TRACKING | INTERCEPTING | SEARCHING | RETURNING_HOME
string role             # NONE | PRIMARY_TRACKER | SECONDARY_TRACKER | INTERCEPTOR_CANDIDATE
int32 assigned_target_id   # -1 if none
float64 pos_x
float64 pos_y
builtin_interfaces/Time stamp
```

### `swarm_interfaces/msg/TargetEstimate.msg` (added in M3)
```
int32 sensor_id
int32 target_id
float64 x
float64 y
float64 vx
float64 vy
float64[4] covariance   # [Pxx, Pyy, Pvx, Pvy]
bool ekf_converged
builtin_interfaces/Time stamp
```

### `swarm_interfaces/msg/HandoverRequest.msg` (added in M4)
```
int32 calling_target_id
int32 requesting_sensor_id
float64 intercept_x
float64 intercept_y
float64 predicted_loss_time
builtin_interfaces/Time stamp
string request_id       # unique event ID, e.g. "T1_S3_t=42.1"
```

### `swarm_interfaces/msg/BidMsg.msg` (added in M4)
```
string request_id       # matches HandoverRequest.request_id
int32 bidder_sensor_id
int32 target_id
float64 bid_cost        # c(i,k) from paper
builtin_interfaces/Time stamp
```

### `swarm_interfaces/msg/CommitmentMsg.msg` (added in M4)
```
string request_id
int32 sensor_id
int32 assigned_target_id
float64 intercept_x
float64 intercept_y
builtin_interfaces/Time stamp
```

---

## 8. Milestone Plan

| Milestone | Goal | New Components | Done When |
|---|---|---|---|
| **M1** ✅ | Minimal running graph: 1 sensor, 3 targets, FSM transitions visible | `swarm_interfaces` (TargetState, SensorState), `target_simulator` (linear motion), `sensor_agent` (3-state FSM), `swarm_bringup` (launch + YAML) | `ros2 topic echo /sensors/0/state` shows FSM transitions as target enters/leaves range |
| **M2** ✅ | All 25 sensors on hex grid, launched from YAML config | `sim_m2_params.yaml` (grid config), `sim_m2.launch.py` (dynamic Node() generation, hex grid computation in Python) | `ros2 node list` shows 26 nodes (target_simulator + 25 sensor_agent); each has correct home position from `ros2 param get` |
| **M3** | Per-sensor EKF, noisy measurements, estimate topics | `TargetEstimate` msg, EKF class inside sensor_agent | EKF estimates converge toward ground truth; ekf_converged flag transitions correctly |
| **M4** | Distributed handover: request → bidding → reconstruction → self-assignment | `HandoverRequest`, `BidMsg`, `CommitmentMsg` msgs, bidding window timer in sensor_agent | One-target handover event fires, 2 sensors self-assign as interceptors matching expected bid order |
| **M5** | Multi-target conflict resolution (expanded joint assignment scope) | Two-stage LP solver inside sensor_agent, scope expansion logic | Two-target conflict reproduces Section 5.3 result from paper: committed interceptor is not stolen |
| **M6** | RViz2 visualization | `swarm_visualization` node, MarkerArray for grid, targets, FSM colors | Grid + targets + FSM states visible in RViz2 in real time |
| **M7** | Gazebo + Crazyflie 2.0 integration (see Section 10) | `swarm_cf_adapter` package, Gazebo world file, Crazyswarm2 bridge | Simulated Crazyflie moves to interception point on assignment command |
| **M8** | Real communication constraints | Latency model, packet loss filter, bid deadline enforcement | System degrades gracefully when bids arrive late or are dropped |
| **M9** | Real hardware (Crazyflie 2.0 flight) | Flight safety checks, Lighthouse/mocap localization | One physical handover event validated in flight |

---

## 9. Staggered Hex Grid Sensor Positions

The 5×5 staggered hexagonal grid from MATLAB:
- `node_spacing = d = 12` units (= 8 × r_d)
- Even columns: y offset = 0; odd columns: y offset = `d × sqrt(3)/4`

Python function to compute all 25 home positions (use in YAML generator):
```python
import math

def hex_grid_positions(grid_size=5, node_spacing=12.0):
    positions = []
    dy = node_spacing * math.sqrt(3) / 2
    for col in range(grid_size):
        for row in range(grid_size):
            x = col * node_spacing
            y = row * dy + (node_spacing / 2 if col % 2 == 1 else 0)
            sensor_id = col * grid_size + row
            positions.append({'sensor_id': sensor_id, 'x': x, 'y': y})
    return positions
```

Sensor naming convention: `sensor_{id}` where `id = col * 5 + row` (0-indexed, matching MATLAB node numbering).

---

## 10. Gazebo + Crazyflie 2.0 Integration Path

**Target hardware:** Crazyflie 2.0 (noted: Crazyflie 2.1+ is preferred for new setups per hardware notes, but user has 2.0 hardware).

**Integration stack:**
```
sensor_agent (ROS 2 logic) ──assignment command──▶ swarm_cf_adapter ──▶ Crazyswarm2 API
                                                         │
                                               Crazyflie 2.0 firmware
                                               (or Gazebo sim model)
```

**`swarm_cf_adapter` package (M7):**
- Subscribes to `/sensors/{id}/assignment_command` (custom msg)
- Converts to Crazyswarm2 `go_to` / `takeoff` / `land` calls
- Handles coordinate frame conversion (WSN 2D units → Crazyflie world frame in meters)
- Applies safety constraints: max velocity, flight envelope limits
- Provides emergency stop service

**Design rule:** The algorithm logic in `sensor_agent` must never import or depend on Crazyswarm2. The adapter is the only package that knows about Crazyflie. This keeps the algorithm portable and testable without hardware.

**Gazebo world setup:**
- Flat 2D arena, scaled to match WSN coordinate system
- One Crazyflie model per sensor agent that enters INTERCEPTING or TRACKING state
- Ground truth target represented as moving visual marker (not a real drone)
- Use Crazyswarm2's built-in Gazebo integration, do not fork it

**Coordinate scaling:**
- WSN simulation uses abstract "units" (r_d = 1.5 units)
- Real Crazyflie environment uses meters
- Choose a scale factor at bringup (e.g., 1 unit = 0.5 m → 12-unit grid = 6 m × 6 m arena)
- Define this as a parameter in `swarm_bringup/config/cf_params.yaml`

**Crazyswarm2 dependency rule:** Keep Crazyswarm2 as a separate directory under `ros2_ws/src/crazyswarm2/`. Never modify its source. Only call its public API from `swarm_cf_adapter`.

---

## 11. Communication Model Roadmap

The system currently assumes **ideal communication** (all nodes on same ROS 2 DDS network, no packet loss, zero latency). This is fine for simulation.

**Future milestones will add realistic constraints:**

| Constraint | When to add | Implementation approach |
|---|---|---|
| Bidding window deadline (Δt_bid) | M4 | One-shot timer in sensor_agent; bids arriving after deadline are discarded |
| Communication range filter | M4/M5 | Sensor only sends/receives bids from nodes within r_c = 18 units |
| Simulated latency | M8 | Add delay node or use ROS 2 QoS deadline/lifespan on bid topics |
| Packet loss | M8 | Probabilistic drop filter on bid subscriber |
| Inconsistent reconstruction | M8 | Sensors may receive different bid subsets → test robustness of assignment |

**From paper Section 4.5:**
- Request propagation + commitment: ≈ 40 ms on Crazyflie-class hardware
- Local assignment computation: ≈ 33.6 ms (estimated from CPU frequency scaling)
- Total (excluding bidding window): ≈ 73.6% of one 0.1 s DES step
- This is tight. For real hardware, Δt_bid must be set carefully; prefer C++ solver for real-time deployment.

**ROS 2 QoS settings to use for event messages (bids, requests, commitments):**
```python
from rclpy.qos import QoSProfile, ReliabilityPolicy, DurabilityPolicy, HistoryPolicy

event_qos = QoSProfile(
    reliability=ReliabilityPolicy.RELIABLE,
    durability=DurabilityPolicy.VOLATILE,
    history=HistoryPolicy.KEEP_LAST,
    depth=10,
)
```
Use `RELIABLE` for event messages (handover requests, bids, commitments). Use `BEST_EFFORT` for high-rate sensor state topics to reduce latency.

---

## 12. MATLAB Baseline Reference

Active MATLAB source of truth: `matlab-sim/src/example_V47_Yeqi.m`

Key MATLAB helper functions and their ROS 2 equivalents:

| MATLAB function | ROS 2 equivalent |
|---|---|
| `calculateEnhancedBid.m` | `sensor_agent/bidding.py` — bid cost computation |
| `buildAssignmentCostMatrixForCallingTargets.m` | `sensor_agent/assignment.py` — cost matrix builder |
| `solveInterceptorAssignmentOptimal.m` | `sensor_agent/assignment.py` — two-stage LP solver |
| `solveInterceptorAssignmenMinMax.m` | kept for A/B testing comparison |
| `expandCallingTargetsForAssignment.m` | `sensor_agent/assignment.py` — scope expansion logic |
| `findNearbySensors.m` | inside sensor_agent: filter by communication range |
| `getSharedTargetInfo.m` | derived from received EKF estimate topics |

**When porting MATLAB logic to Python:**
- Preserve the algorithm exactly. Do not optimize or restructure until behavior is validated against MATLAB logs.
- MATLAB logs are in `matlab-sim/generated/logs/`. Use these as regression ground truth.
- Port one function at a time, validate against MATLAB output before moving to the next.

---

## 13. Validation Strategy

Behavior validation (not just code review):

1. **FSM transition correctness**: state sequence matches MATLAB event log for same seed/scenario
2. **EKF convergence**: estimate error converges; `ekf_converged` flag fires at same time as MATLAB
3. **Assignment correctness**: for the two-target conflict scenario in paper Section 5.3, the expanded joint assignment should prevent Target 1 from losing S14 to Target 2
4. **Timing**: assignment completes within one DES time step (0.1 s) in simulation
5. **Determinism**: with fixed seed and YAML params, same scenario produces identical event sequence on re-run

**Regression assets to create at M4:**
- One-target handover case (from MATLAB log at t ≈ 15s)
- Two-target conflict case (from paper Section 5.3, t = 40.0s)
- Three-target joint assignment case (from paper Section 5.4, t = 44.2s)

---

## 14. File and Topic Naming Conventions

- Sensor IDs: 0–24 (integer), matching MATLAB node numbering `col * 5 + row`
- Target IDs: 0–2 (integer, 0-indexed)
- Topic pattern: `/sensors/{sensor_id}/state`, `/targets/{target_id}/ground_truth`
- Event request IDs: string format `"T{target_id}_S{sensor_id}_t{time:.1f}"` for traceability
- Launch files: `sim_m{milestone_number}.launch.py` for milestone-specific launches
- Config files: `sim_m{milestone_number}_params.yaml`

---

## 15. What To Do at the Start of a New Session

1. Read this file (`ros2-design.md`) fully.
2. Read `plan.md` for the high-level roadmap.
3. Read `CLAUDE.md` for collaboration rules.
4. Check `matlab-sim/src/example_V47_Yeqi.m` lines 85–200 for FSM state definitions and simulation parameters.
5. Ask the user which milestone they are on before writing any code.
6. Do not implement more than one milestone at a time.
7. Do not add a central `assignment_manager` node — see Section 2.1.
