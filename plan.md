# ROS 2 Sim-to-Real Plan

## Goal
Port the cooperative multi-target tracking and proactive handover logic from the MATLAB baseline into a ROS 2 Humble stack on Ubuntu 22.04, then validate it in Crazyflie simulation before moving to real hardware.

The near-term goal is not a direct one-shot rewrite. The goal is to preserve the current algorithmic behavior while translating it into a ROS-native architecture that can scale from software-in-the-loop testing to controlled flight experiments.

## Current MATLAB Baseline
The active simulation baseline is [`example_V47_Yeqi.m`](C:/Users/abel/Desktop/yaki-robotics/projects/swarm-sim2real/matlab-sim/src/example_V47_Yeqi.m). It currently contains:

- Target motion generation for three targets with staggered start times.
- Per-sensor, per-target EKF estimation.
- System-level and sensor-level FSM logic.
- Proactive loss prediction and interceptor selection.
- Legacy and global assignment backends for multi-target conflicts.
- Plotting, event logging, and post-run persistence.

The helper functions in [`matlab-sim/src`](C:/Users/abel/Desktop/yaki-robotics/projects/swarm-sim2real/matlab-sim/src) already separate part of the assignment logic from the main script. That makes `V47` the right baseline for a later modular port, even though the main control loop is still monolithic.

## Target ROS 2 Architecture
The first ROS implementation should use a centralized coordination pattern. This matches the current MATLAB control structure and keeps behavior easier to validate during the first port.

Planned responsibilities:

- `estimator node`
  - Maintains target state estimates and uncertainty.
  - In simulation, can begin with ground-truth-assisted measurements and then move toward noisy observation models.
  - Publishes target estimate topics used by the coordinator.

- `handover/assignment coordinator node`
  - Owns the global mission state, active trackers, interceptor pipeline state, and role assignment.
  - Runs the loss-prediction gate, bidding trigger, assignment selection, and tracker/interceptor transitions.
  - Publishes desired assignments and intercept goals for each drone.

- `Crazyflie command adapter node`
  - Converts coordinator outputs into Crazyswarm2-compatible commands.
  - Handles takeoff, land, go-to, hover, and waypoint/intercept command translation.
  - Encapsulates robot-specific command limits, frame conventions, and safety checks.

- `logging/analysis pipeline`
  - Records ROS topics, events, assignments, and target-estimate streams using `rosbag2`.
  - Produces replayable datasets and post-run summaries for comparison with MATLAB logs.
  - Serves as the main regression tool between MATLAB behavior and ROS behavior.

This architecture intentionally avoids embedding algorithm logic directly into upstream Crazyswarm2 packages. The algorithm should live in user-owned ROS packages so upstream updates remain easy to pull in.

## Package Layout
Target platform:

- Ubuntu 22.04
- ROS 2 Humble
- Crazyswarm2
- Crazyflie simulation first, hardware second

Recommended workspace shape:

```text
ros2_ws/
  src/
    crazyswarm2/                 # upstream dependency, kept clean
    wsn_tracking_msgs/           # custom messages/events if needed
    wsn_tracking_core/           # estimator + coordinator logic
    wsn_tracking_bringup/        # launch files, configs, scenarios
    wsn_tracking_analysis/       # rosbag tools, replay, evaluation
    wsn_tracking_cf_adapter/     # Crazyflie command adaptation layer
```

Rules for the implementation:

- Do not modify upstream Crazyswarm2 packages unless there is no extension point.
- Keep custom launch/config files in the user workspace.
- Use parameters and YAML configs for target scenarios, sensor/drone names, and controller tuning.
- Prefer Python nodes first for speed of iteration unless a hard real-time or performance bottleneck justifies C++.

## Porting Order
Port the MATLAB system by behavior group instead of by file length.

1. Extract the ROS-side data model:
   - target IDs
   - tracker/interceptor roles
   - active tracker tables
   - handover pipeline state
   - target estimate messages

2. Implement the coordinator state machine without commanding real drones yet:
   - system states
   - per-drone role/state bookkeeping
   - assignment events

3. Port the assignment logic:
   - bid computation
   - candidate filtering
   - legacy/global solver selection
   - per-target assignment outputs

4. Port motion-facing behavior:
   - loss prediction
   - intercept point generation
   - tracker replacement rules
   - recovery/return-home behavior

5. Attach the coordinator to simulated Crazyflie commands.

6. Add replay and regression comparison against MATLAB run outputs.

## Milestones
1. ROS 2 and Crazyswarm2 environment setup
   - Install ROS 2 Humble on Ubuntu 22.04.
   - Build a local `ros2_ws`.
   - Install and verify Crazyswarm2.
   - Confirm example launch files run.

2. Single-drone simulation control
   - Launch one simulated Crazyflie.
   - Verify takeoff, land, hover, and go-to commands.
   - Confirm namespaces, frames, and clock behavior.

3. Multi-drone simulation control
   - Launch 2-5 simulated Crazyflies.
   - Verify per-drone addressing, simultaneous commands, and stable startup.
   - Confirm a repeatable scenario configuration flow.

4. Port MATLAB state/assignment logic into ROS 2 coordinator
   - Implement the centralized coordinator node.
   - Port role/state updates, loss prediction, and assignment logic.
   - Publish debug topics and event messages.

5. Reproduce one MATLAB handover scenario in simulation
   - Start with one target and two active trackers.
   - Reproduce proactive handover and tracker replacement.
   - Match MATLAB event order and assignment decisions as closely as practical.

6. Add logging and replay
   - Record topic streams and event summaries with `rosbag2`.
   - Build a small comparison tool for ROS vs MATLAB event timelines.
   - Freeze one reference scenario for regression use.

7. Move to real Crazyflie tests
   - Start with one-drone indoor flight validation.
   - Add multi-drone tests only after command stability and localization are reliable.
   - Revalidate assignment and handover behavior under real latency and measurement noise.

## Validation Strategy
Validation should compare behavior, not just code structure.

Core checks:

- State-transition correctness
  - system FSM transitions occur in the expected order
  - drone role/state transitions preserve tracker-count invariants

- Assignment correctness
  - candidate filtering matches MATLAB intent
  - assignment outputs are deterministic for fixed seeds/configuration
  - multi-target conflict resolution produces valid, non-overlapping teams

- Motion-command correctness
  - intercept commands are issued at the right time
  - return-home and reassignment actions do not conflict

- Replayability
  - one fixed scenario can be rerun and compared across MATLAB and ROS
  - bag replay reproduces event timing closely enough for regression use

Recommended regression assets:

- one simple one-target handover case
- one two-target conflict case
- one three-target simultaneous coordination case

## Hardware Notes
The hardware plan should assume Crazyflie simulation first and real flights second.

Important hardware note:

- Crazyflie 2.0 is end-of-life and is not a good default for a new setup.
- Unless there is a fixed hardware constraint, Crazyflie 2.1+ is the safer default platform for new work.

Additional practical notes:

- Plan for a reliable localization system before serious multi-drone tests.
- Motion capture or Lighthouse is a better fit than a purely relative setup for this project.
- Keep ROS command rates, flight-area constraints, and emergency-stop procedures in scope from the beginning.

## Risks and Open Items
- The MATLAB implementation is centralized and monolithic, so hidden coupling may surface during porting.
- Assignment behavior may depend on MATLAB-specific ordering details that need to be made explicit in ROS.
- Simulated timing and real Crazyflie timing will differ, especially around communication delay and localization updates.
- The estimator model used in ROS may need a staged rollout: idealized simulation first, noisy sensing second.
- If Gazebo is introduced later, it should be treated as an additional validation environment, not the first place where the algorithm is debugged.
- Message definitions may need to be introduced once the coordinator interface becomes concrete.
