---
name: viz-requirements-matlab-v47
description: Full visual requirements for animate_m3.py — must match MATLAB V47 main animation semantics
metadata:
  type: project
---

User's visualization requirements for `tools/animate_m3.py`.
Goal: make the ROS 2 animation look like the MATLAB V47 main animation as closely as possible.

**Why:** User is finalizing Milestone 3 and wants the ROS 2 output to be directly comparable to the MATLAB simulation results.

**How to apply:** Use this as the spec whenever editing `animate_m3.py`.

---

## Global style
- White background (not dark)

## 1. Sensors (25, 5×5 staggered hex grid)
- Center marker (dot)
- Semi-transparent detection/coverage disk — always shown for all 25 sensors
- Numbered label that follows the sensor when it moves

## 2. Targets
- T1: red, T2: green, T3: blue
- Star marker at current position
- Full historical trajectory as solid line (same color)

## 3. Sensor state colors (priority order)
- TRACKING / PRIMARY_TRACKER → bright red
- TRACKING / SECONDARY_TRACKER → dark red
- INTERCEPTING assigned to T1 → orange
- INTERCEPTING assigned to T2 → green
- INTERCEPTING assigned to T3 → gray
- RETURNING_HOME → magenta
- DETECTING → cyan
- SEARCHING (default) → purple
- SEARCHING (touched 1σ contour) → black
- SEARCHING (touched 2σ contour) → red
- SEARCHING (touched 3σ contour) → green
- IDLE (previously detected) → light cyan
- IDLE (never detected) → navy blue

## 4. Title
- Dynamic, shows: current sim time + system state

## 5. Status box (bottom area)
- System state
- Total tracking count
- Per-target tracker count (T1/T2/T3)
- Intercepting / Searching / Returning counts
- Touched 1σ/2σ/3σ counts (skip if data unavailable)

## 6. Legend
- Target 1 / 2 / 3 (star markers)
- Target 1 / 2 / 3 Path (lines)
- T1 / T2 / T3 Interceptor (colored patches)
- Primary Tracker
- Secondary Tracker
- Returning Home
- Detecting
- Normal Sensor (never detected)
- Prev. Detected (light cyan)
- Searching

## 7. SEARCHING phase only: EKF covariance contours
- Drawn for each lost target when any sensor is SEARCHING
- 3 sigma levels (3σ outer dashed, 2σ middle solid, 1σ inner solid)
- T1 contours: outer green dashed, middle red, inner blue
- T2 contours: outer magenta dashed, middle yellow, inner cyan
- T3 contours: outer blue dashed, middle gray, inner black

## 8. NOT drawn (intentionally absent — matches MATLAB main animation)
- Sensor trajectory paths
- Loss point marker
- Safe intercept point marker
- Safety margin line
- Covariance trace chart
- Swept-area fill (incomplete in MATLAB too)

## 9. Bag reader requirements
- Read `role` field from SensorState (for PRIMARY vs SECONDARY distinction)
- Read `covariance[0]` (Pxx) and `covariance[1]` (Pyy) from TargetEstimate (for contours)
