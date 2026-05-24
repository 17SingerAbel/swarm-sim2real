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
| M1 | Minimal graph: target simulator + sensor FSM, visible in `ros2 topic echo` | 🔨 In progress |
| M2 | All 25 sensors on hex grid, launched from YAML config | ⏳ Planned |
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
ros2 topic echo /targets/0/ground_truth

# See sensor FSM state transitions
ros2 topic echo /sensors/0/state

# See the full node graph
rqt_graph
```

Expected: sensor FSM transitions `IDLE → DETECTING → TRACKING` as a target enters its detection radius, and back to `IDLE` when the target leaves.

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

Yeqi Sang — [yaki.robotics@gmail.com](mailto:yaki.robotics@gmail.com)
