# Swarm WSN Cooperative Multi-Target Tracking

A ROS 2 Humble implementation of a **distributed wireless sensor network (WSN)** for cooperative multi-target tracking using proactive handover and finite-state-machine-based sensor coordination.

> Built on: Yeqi Sang et al., *"Reconfigurable Wireless Sensor Network Coordination for Simultaneous Multi-Target Tracking"*, MDPI Robotics (under review).  
> Report: *"Expanded Joint Interceptor Assignment for Cooperative Multi-Target Tracking"*, MIE8888 Final Report, 2025.

---

## What This System Does

**25 mobile sensors** arranged in a staggered hexagonal grid cooperatively track up to **3 moving targets**. When a tracker predicts it will lose a target, it triggers a **distributed bidding process** to recruit interceptor sensors before the target is lost.

Key properties:
- **No central coordinator** — each sensor computes bids locally and independently reconstructs the same assignment decision from shared bid messages (consensus-by-reconstruction)
- **Proactive handover** — interception is dispatched before tracking loss, not after
- **Distributed DES architecture** — sensors communicate via event messages (handover requests, bids, commitments); state transitions are FSM-driven
- **EKF-based estimation** — each sensor maintains its own Extended Kalman Filter per tracked target
- **Multi-target conflict resolution** — expanded joint assignment scope prevents a later handover request from silently stealing an interceptor already committed to another target

---

## System Architecture

```
[target_simulator]
    │ /targets/{id}/ground_truth  (simulation oracle)
    ▼
[sensor_agent_0] ── [sensor_agent_1] ── ... ── [sensor_agent_24]
    each node:
      - gates measurement by detection range (r_d = 1.5 units)
      - runs EKF per tracked target
      - FSM: IDLE / DETECTING / TRACKING / INTERCEPTING / RETURNING_HOME
      - publishes bids to /swarm/bids when handover is triggered
      - independently reconstructs and solves the assignment after bidding window
      - self-assigns role after assignment resolution

[swarm_visualization]  →  RViz2
[swarm_bringup]        →  launch files + YAML configs
```

Full architecture decisions, ROS graph, message definitions, and Gazebo integration path are documented in [`ros2-design.md`](ros2-design.md).

---

## Simulation Parameters

| Parameter | Value |
|---|---|
| Grid | 5×5 staggered hexagonal, 25 sensors |
| Node spacing | 12 units |
| Detection radius r_d | 1.5 units |
| Communication range r_c | 18 units |
| Max trackers per target | 2 |
| Max interceptors per target | 2 |
| Sensor max speed | 0.75 units/TU |
| EKF timestep | 0.1 s |

---

## Milestone Progress

| # | Description | Status |
|---|---|---|
| M1 | Minimal graph: target simulator + sensor FSM, visible in `ros2 topic echo` | ✅ Done |
| M2 | All 25 sensors on hex grid, launched from YAML config | ✅ Done |
| M3 | Per-sensor EKF with noisy measurements, estimate topics | ⏳ Planned |
| M4 | Distributed handover: request → bidding window → local assignment reconstruction | ⏳ Planned |
| M5 | Multi-target conflict resolution via expanded joint assignment scope | ⏳ Planned |
| M6 | RViz2 visualization: grid, targets, FSM state colors | ⏳ Planned |
| M7 | Gazebo + Crazyflie integration via `swarm_cf_adapter` package | ⏳ Planned |
| M8 | Realistic communication constraints: latency, packet loss, bid deadlines | ⏳ Planned |

---

## Repository Structure

```
swarm-sim2real/
  matlab-sim/
    src/                    # MATLAB simulation source (active baseline: example_V47_Yeqi.m)
    archive/                # historical versions
    generated/logs/         # MATLAB run outputs (.log, .mat)
  ros2_ws/
    src/
      swarm_interfaces/     # custom ROS 2 message definitions (ament_cmake)
      target_simulator/     # publishes target ground-truth motion (ament_python)
      sensor_agent/         # sensor FSM + EKF + distributed bidding logic (ament_python)
      swarm_visualization/  # RViz2 MarkerArray visualization (ament_python)
      swarm_bringup/        # launch files and YAML configs (ament_python)
  ros2-design.md            # full architecture reference document
  plan.md                   # ROS 2 porting roadmap
```

---

## Running Milestone 2

**Prerequisites:** M1 built and sourced (see M1 section below).

```bash
cd ros2_ws

# Rebuild swarm_bringup to pick up the new launch + config files
colcon build --packages-select swarm_bringup
source install/setup.bash

# Launch all 25 sensors
ros2 launch swarm_bringup sim_m2.launch.py
```

**Verify in a second terminal:**
```bash
# Should show 26 nodes: /target_simulator + /sensor_agent_0 … /sensor_agent_24
ros2 node list | sort | wc -l

# Spot-check that sensor 5 (first odd-column sensor) has the correct y offset
ros2 param get /sensor_agent_5 pos_x   # → 12.0
ros2 param get /sensor_agent_5 pos_y   # → 6.0  (= node_spacing / 2)
```

Expected: `ros2 node list` shows exactly 26 running nodes. Sensor IDs follow the convention `col * 5 + row` (0-indexed), matching the MATLAB grid numbering.

### M2 Implementation Notes

**What changed from M1:**

| File | Role |
|---|---|
| `swarm_bringup/config/sim_m2_params.yaml` | Defines `swarm.node_spacing`, `grid_size`, and shared defaults. The `swarm:` block is read by the launch Python; it is not a ROS parameter namespace. |
| `swarm_bringup/launch/sim_m2.launch.py` | Reads `node_spacing` and `grid_size` from YAML, computes 25 hex grid positions in Python, and generates 25 `Node()` declarations dynamically. |
| `swarm_bringup/setup.py` | `data_files` updated to install both new files into the package share directory. |

**Key design decisions in M2:**
- `node_spacing` lives in YAML (user-visible config); position arithmetic lives in the launch Python. Changing `node_spacing` in one place regenerates all 25 positions automatically.
- The `swarm:` YAML block is a custom config section, not a `ros__parameters` namespace. The launch Python reads it with `yaml.safe_load()` before any nodes are created.
- Parameters are passed as inline Python dicts (not a file path) because each node's `pos_x`/`pos_y` values are different — they cannot be expressed statically in a shared YAML file.
- `communication_range` is stored in the YAML for reference but not passed to `sensor_agent` nodes yet — the node does not declare that parameter until M4.

**Hex grid geometry:**
```
dy = node_spacing × √3 / 2  ≈ 10.39 units
even columns: y = row × dy
odd  columns: y = row × dy + node_spacing / 2   (+ 6.0 units offset)
sensor_id = col × 5 + row   (matches MATLAB node numbering)
```

**ROS 2 concepts practiced:**
- Reading a YAML config file in a launch script with `yaml.safe_load()` before node creation
- Dynamic `Node()` generation with a Python loop — equivalent to a parameterized node factory
- Passing per-node parameters as inline dicts vs. a shared YAML file path, and when each is appropriate
- `data_files` in `setup.py`: why both launch files and config files must be listed explicitly

---

## Running Milestone 1

**Prerequisites:** ROS 2 Humble installed on Ubuntu 22.04.

```bash
cd ros2_ws

# Build interfaces first (required before other packages)
colcon build --packages-select swarm_interfaces
source install/setup.bash

# Build remaining packages
colcon build --packages-select target_simulator sensor_agent swarm_bringup
source install/setup.bash

# Launch
ros2 launch swarm_bringup sim_m1.launch.py
```

**Verify in a second terminal:**
```bash
# See target ground truth
ros2 topic echo /targets/target_0/ground_truth

# See sensor FSM state transitions
ros2 topic echo /sensors/sensor_0/state

# See the full node graph
rqt_graph
```

Expected: sensor FSM transitions `IDLE → DETECTING → TRACKING` as target_0 enters sensor_0's detection radius (r_d = 1.5 units), then back to `IDLE` when the target passes through. With default config, target_0 enters range at ≈ t=3.5 s and exits at ≈ t=6.5 s.

### M1 Implementation Notes

**Packages built:**

| Package | Build type | Role |
|---|---|---|
| `swarm_interfaces` | ament_cmake | Custom message definitions (TargetState, SensorState) |
| `target_simulator` | ament_python | Publishes 3 targets with linear motion at 10 Hz |
| `sensor_agent` | ament_python | 3-state FSM (IDLE / DETECTING / TRACKING), distance-gated |
| `swarm_bringup` | ament_python | Launch file + YAML parameter config |

**Key design decisions in M1:**
- Topic names use string prefixes to avoid the ROS 2 rule against numeric topic segments: `/targets/target_0/ground_truth`, not `/targets/0/ground_truth`
- FSM is **timer-driven** (10 Hz tick), not callback-driven. Target callbacks only store the latest position; the FSM step checks distance and transitions once per tick.
- DETECTING → TRACKING is immediate in M1 (one tick). EKF convergence will gate this transition in M3.
- `swarm_interfaces` must be built **before** other packages because Python nodes import its generated message types.
- Launch files and YAML configs must be declared in `setup.py` `data_files` to be installed into the share directory where `get_package_share_directory()` can find them.

**ROS 2 concepts practiced:**
- `ament_cmake` vs `ament_python` build types and when to use each
- Publisher / subscriber pattern with custom message types
- Timer-driven node loops with `create_timer()`
- Node parameters declared with `declare_parameter()` and loaded from YAML
- `entry_points` in `setup.py` as the mechanism that makes `ros2 run` work
- `colcon build --packages-select` for incremental builds
- `source install/setup.bash` requirement after every build

---

## MATLAB Baseline

The MATLAB simulation (`matlab-sim/src/example_V47_Yeqi.m`) is the algorithmic ground truth for this project. It implements the complete system including EKF, FSMs, proactive handover, bidding, and multi-target conflict resolution in a centralized loop.

The ROS 2 port preserves the same algorithmic behavior while translating it into a distributed, event-driven, node-per-sensor architecture. MATLAB logs in `matlab-sim/generated/logs/` serve as regression baselines for validating ROS 2 behavior.

Helper modules and their ROS 2 equivalents:

| MATLAB | ROS 2 |
|---|---|
| `calculateEnhancedBid.m` | `sensor_agent/bidding.py` |
| `buildAssignmentCostMatrixForCallingTargets.m` | `sensor_agent/assignment.py` |
| `solveInterceptorAssignmentOptimal.m` | `sensor_agent/assignment.py` (two-stage LP) |
| `expandCallingTargetsForAssignment.m` | `sensor_agent/assignment.py` (scope expansion) |

---

## Tech Stack

- **Algorithm:** Python 3.10 / rclpy
- **Middleware:** ROS 2 Humble
- **Simulation:** Crazyswarm2 + Gazebo (planned, M7)
- **Hardware target:** Crazyflie 2.0 (planned)
- **OS:** Ubuntu 22.04

---

## Background Reading

- [`ros2-design.md`](ros2-design.md) — full system design, ROS graph, message definitions, Gazebo integration path, communication model roadmap
- [`plan.md`](plan.md) — porting strategy and validation approach
- `Yeqi-mie8888-final-report.pdf` — technical report describing the expanded joint assignment method (not public, available on request)

---

## Author

Yeqi Sang — [yeqisang@gmail.com](mailto:yeqisang@gmail.com)
