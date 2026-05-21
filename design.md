# Design Document — WSN Multi-Target Cooperative Tracking

**Project:** MIE8888 — Proactive Handover in Mobile Wireless Sensor Networks
**File:** `example_V45_V38_b.m`
**Date:** 2025

---

## 1. Problem Statement

A 5×5 mobile WSN must continuously track up to 3 independently moving targets across the sensor field. Because sensors are mobile but speed-limited, a target can outrun any single tracker. The core challenge is **proactive handover**: predicting when a tracker will lose a target and dispatching replacement sensors to intercept the target *before* tracking is lost — all without centralized ground-truth access.

---

## 2. Network Topology

| Property | Value |
|----------|-------|
| Grid arrangement | 5×5 staggered hexagonal |
| Total nodes | 25 |
| Node spacing | 12 units (= 8 × detection radius) |
| Detection radius | 1.5 units |
| Communication range | 18 units (= 1.5 × node spacing) |
| Sensor speed | 0.75 units/s |

Grid generation (staggered hex):
```
x_col = (col-1) * node_spacing
y_row = (row-1) * node_spacing * sqrt(3)/2
odd rows shifted right by node_spacing/2
```

WSN field dimensions:
```
wsn_width  = (nx-1)*node_spacing + 0.5*node_spacing + 2*a
wsn_height = (ny-1)*node_spacing*sqrt(3)/2 + 2*a
```

---

## 3. Target Motion Model

Targets follow piecewise-linear waypoint paths with additive Gaussian noise:

```
dir = next_waypoint - current_pos
target_pos += (dir/|dir| + N(0, 0.01)) * v_target * dt
```

Speeds: Target 1 = 1.0, Target 2 = 1.1, Target 3 = 1.2 units/s
Entry times: Target 1 = 0 s, Target 2 = 4.0 s, Target 3 = 6.5 s

---

## 4. Extended Kalman Filter (EKF)

Each sensor maintains an **independent EKF per target** it has detected.

### State Vector
```
x = [x_pos, y_pos, vx, vy]^T   (4×1)
```

### Constant-Velocity Process Model
```
F = [1  0  dt  0 ]      G = [dt²/2    0   ]
    [0  1   0 dt ]          [   0   dt²/2 ]
    [0  0   1  0 ]          [  dt      0  ]
    [0  0   0  1 ]          [   0     dt  ]

Q_k = G * Q * G',    Q = 0.01 * I₂
```

### Measurement Model (position only)
```
H = [1  0  0  0]
    [0  1  0  0]

R = 0.0025 * I₂
```

### EKF Predict / Update
```
Predict:  x̂⁻ = F * x̂
          P⁻  = F * P * F' + Q_k

Update:   K = P⁻ * H' * (H * P⁻ * H' + R)⁻¹
          x̂ = x̂⁻ + K * (z - H * x̂⁻)
          P = (I - K*H) * P⁻
```

First detection: EKF initialized with noisy position measurement, zero velocity, `P = I₄`.

### EKF Convergence Check
Used to gate loss prediction — prevents predictions from noisy early estimates:
```
converged = (P(3,3) < 0.006) AND (P(4,4) < 0.006)
```

---

## 5. Finite State Machine Architecture

### 5.1 System-Level FSM

```
        target detected
IDLE ──────────────────────► TRACKING
 ▲                              │
 │ all targets lost              │ all targets lost
 │ & reacquired                  ▼
 └──────────── REACQUIRING ◄── SEARCHING
```

| State | Description |
|-------|-------------|
| IDLE | No targets active in the field |
| TRACKING | ≥1 target being tracked |
| SEARCHING | All targets lost, contour search active |
| REACQUIRING | Lost target re-detected |

### 5.2 Sensor-Level FSM

```
IDLE ──detect──► DETECTING ──assigned──► TRACKING ──loss predicted──► (interceptor call)
  ▲                                           │
  │                                    target lost
  │                                           ▼
RETURNING_HOME ◄──────────────────── SEARCHING
                                           ▲
INTERCEPTING ──target enters range──► TRACKING
```

| State | Description |
|-------|-------------|
| IDLE | At home grid position, no assignment |
| DETECTING | Target just entered detection range |
| TRACKING | Actively following assigned target with EKF |
| INTERCEPTING | Moving to predicted intercept point |
| SEARCHING | Sweeping contour ellipse for lost target |
| RETURNING_HOME | Returning to home after handover or loss |

**Dual-tracker invariant:** Every tracked target always has exactly `MAX_ACTIVE_TRACKERS = 2` sensors in TRACKING state (PRIMARY + SECONDARY roles).

---

## 6. Loss Prediction Algorithm

When a tracker's EKF has converged, it predicts when the target will exit its detection radius using relative motion kinematics:

```
rel_pos = target_pos - sensor_pos
rel_vel = target_vel - sensor_vel   (sensor moves toward target at 0.75 units/s)

Quadratic equation for exit time Δt:
  a·Δt² + b·Δt + c = 0
  a = rel_vel · rel_vel
  b = 2 * (rel_pos · rel_vel)
  c = rel_pos · rel_pos - r²       (r = detection radius)

  discriminant = b² - 4ac

if discriminant ≥ 0:
  t1 = (-b + √discriminant) / (2a)
  t2 = (-b - √discriminant) / (2a)
  loss_Δt = max(t1, t2)             → the later exit root
  loss_time = current_time + loss_Δt
  loss_point = target_pos + target_vel * loss_Δt
```

### Prediction Stability Gate
Before triggering handover, predictions must be stable:
```
|loss_time(k) - loss_time(k-1)| < 0.5 TU    for 2 consecutive steps
```

---

## 7. Interceptor Selection — Bidding Protocol

When the earliest-predicting tracker triggers handover, all non-tracking sensors submit bids. Lower bid = better candidate.

### Bid Cost Function
```
bid = w₁·P_home + w₂·P_spatial + w₃·P_temporal + w₄·P_uncertainty

P_home     = |sensor_pos - home_pos| / max_network_dist     (displacement penalty)
P_spatial  = |sensor_pos - intercept_point| / max_network_dist
P_temporal = clamp((t_sensor - t_target) / t_target, 0, 1)  (sensor arrives too late)
P_uncertainty = 1 - shared_confidence

Weights (default): w₁=0.4, w₂=0.3, w₃=0.2, w₄=0.1
```

The **safety margin** shifts the intercept point 10% closer to the tracker's EKF estimate:
```
safe_intercept = sensor_pos + (loss_point - sensor_pos) * 0.9
```

### Handover Pipeline
```
NONE → PENDING_BROADCAST → PENDING_BIDDING → PENDING_SELECTION → NONE
```
Each stage is processed in a separate simulation step to simulate realistic multi-hop delay.

---

## 8. Conflict Resolution (Minimax)

When multiple targets simultaneously request interceptors, naive greedy selection causes the same sensor to be assigned to multiple targets. Minimax combinatorial optimization resolves this:

1. Collect all available sensors (not currently tracking any target)
2. Build bid matrix `B[i,j]` for all sensor–target pairs
3. For two-target conflict: enumerate all non-overlapping 2+2 sensor assignments from the top 8 bidders per target
4. Select the assignment that minimizes the **maximum team cost** across targets:

```
(team₁*, team₂*) = argmin_{(team₁,team₂) disjoint} max(cost(team₁,t₁), cost(team₂,t₂))

where cost(team, t) = Σ bid(sensor, t)  for sensor in team
```

This reduces search space to ≈ `C(16,2)² ≈ 14,400` combinations (top 8 bidders: `C(16,2)` per target).

---

## 9. Proportional Navigation Guidance (PNG)

Intercepting sensors navigate to the intercept point using PNG once assigned:

```
r       = target_pos - robot_pos              (LOS vector)
v_rel   = target_vel - robot_vel              (relative velocity)

θ̇_LOS  = (r × v_rel) / |r|²                 (LOS angular rate, 2D cross product)

If |v_robot| > 0:
  n̂ = unit normal to robot velocity
  a_PNG = λ · |v_robot| · θ̇_LOS · n̂

If robot stationary:
  n̂ = unit normal to LOS
  a_PNG = λ · θ̇_LOS · n̂
```

Navigation constant `λ` (proportional gain) tunes aggressiveness. The PNG command is applied as a steering correction on top of direct pursuit to eliminate wobble.

---

## 10. Shared Information Fusion

Each sensor can obtain weighted estimates from neighbors within `communication_range`:

```
weight(neighbor) = exp(-Δt · 0.1) / (1 + dist · 0.1)

shared_pos = Σ(weight · pos_estimate) / Σ weight
shared_vel = Σ(weight · vel_estimate) / Σ weight
confidence = min(1.0, Σ weight)
```

`Δt` = time since neighbor last detected the target; `dist` = distance to neighbor.

---

## 11. Contour-Based Search

When a target is lost, searching sensors sweep a **chi-square uncertainty ellipse** derived from the last known EKF covariance:

```
Ellipse: sqrt(χ²(p,2)) · √Λ · V · [cos θ; sin θ] + center

where:
  [V, Λ] = eig(P_position_block)     (eigendecomposition of 2×2 position covariance)
  χ²(0.9973, 2) ≈ 11.83              (3-sigma confidence level, 2 DOF)
  p = 0.9973 → corresponds to 3σ boundary
```

The contour is updated every 10 time steps. Sensors are directed along the contour boundary outward from the last known position.

---

## 12. Return-to-Home Protocol

When a sensor completes its interceptor duty or loses tracking:
1. Transition to `RETURNING_HOME`
2. Move directly toward `original_positions(sensor_id, :)` at full speed
3. On arrival: transition to `IDLE`, role cleared to `NONE`

The sensor farthest from home among a departing group is prioritized to return first (`findFarthestSensorFromHome`).

---

## 13. Key Design Parameters Summary

| Parameter | Symbol | Value |
|-----------|--------|-------|
| Detection radius | a | 1.5 units |
| Node spacing | — | 12 units |
| Comm. range | — | 18 units |
| Sensor speed | v_s | 0.75 units/s |
| Time step | dt | 0.1 s |
| Simulation duration | — | 75 s |
| EKF process noise | Q | 0.01 · I₂ |
| EKF measurement noise | R | 0.0025 · I₂ |
| Velocity convergence threshold | — | 0.006 units²/s² |
| Prediction stability threshold | — | 0.5 TU |
| Min stable predictions | — | 2 steps |
| Safety margin | — | 10% |
| Bid weights | w₁–w₄ | 0.4, 0.3, 0.2, 0.1 |
| Max trackers per target | — | 2 |
| Minimax top-bidder limit | — | 8 per target |

---

## 14. Key Design Decisions

1. **EKF convergence gate**: Prevents premature handover calls when velocity estimates are still noisy immediately after detection.
2. **Prediction stability gate**: Two consecutive predictions within 0.5 TU required — filters transient spikes.
3. **Dual-tracker invariant**: Always maintaining two trackers per target provides redundancy and ensures smooth handover (one continues while the other is released).
4. **Minimax conflict resolution**: Prevents the greedy winner-takes-all problem when multiple targets need interceptors simultaneously; ensures fair sensor allocation under contention.
5. **PNG over pure pursuit**: Eliminates the oscillation (wobble) seen in naive direct-approach tracking of a moving intercept point.
6. **Per-sensor independent EKF**: Avoids the need for a central coordinator; each sensor makes autonomous decisions based only on its own estimates and shared information from neighbors.
7. **Chi-square contour search**: Probabilistically principled search boundary that adapts to the actual uncertainty of the last known EKF state.
