---
name: project-ros2-design
description: Core ROS 2 architecture decisions for the swarm WSN tracking system — distributed DES, no central coordinator, Gazebo/CF2 integration path, milestone plan
metadata:
  type: project
---

The full ROS 2 system design is documented in `ros2-design.md` at the project root. Always read that file at the start of a new session before writing any code.

**Why:** It was written after a full architectural review session (2026-05-24) that included reading the paper (Yeqi-mie8888-final-report.pdf, especially sections 4.4 and 4.5) and the MATLAB baseline (example_V47_Yeqi.m).

**How to apply:** At the start of any ROS 2 session, read `ros2-design.md` first. Ask the user which milestone they are on. Do not skip ahead.

Key non-negotiable decisions (details in ros2-design.md §2):
- No `assignment_manager` node — assignment is fully distributed (each sensor reconstructs independently after bidding window)
- Sensor subscribes to all target ground truth topics always, but gates measurement by distance ≤ r_d = 1.5 units
- EKF lives inside `sensor_agent`, not a separate node
- Gazebo + Crazyflie 2.0 integration via a separate `swarm_cf_adapter` package that the algorithm never imports

Current milestone: **M1** (as of 2026-05-24) — minimal running graph with 3 targets and 1 sensor. M1 code was designed in this session.
