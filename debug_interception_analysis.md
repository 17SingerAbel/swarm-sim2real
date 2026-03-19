# Debug Plan: Interception Logic, Conflict Resolution, Bugs & Sub-optimality

## 1. Interception Pipeline — How It Works

### State Machine (per target)
```
NONE → PENDING_BROADCAST → PENDING_BIDDING → PENDING_SELECTION → NONE
```

| Phase | Lines | Trigger / Action |
|---|---|---|
| **PENDING_BROADCAST** | ~800 | EKF converged (vx/vy variance < 0.006) AND ≥2 consecutive stable loss-time predictions (diff < 0.5 TU) → sets delay counter to 0 |
| **PENDING_BIDDING** | ~836-843 | Delay expires (immediately next step) → all non-tracker sensors calculate bids |
| **PENDING_SELECTION** | ~843-884 | Instant transition → conflict check + winner assignment |
| **Back to NONE** | ~882-1134 | Winners transition to INTERCEPTING; pipeline resets |

### Loss-Time Prediction (`predictTrackerLoss`, lines ~312-372)
- Assumes sensor moves **toward** the target at 0.75 units/s
- Solves quadratic for when ‖target_pos(Δt) − sensor_pos(Δt)‖ = detection_radius (1.5)
- Takes the **larger root** (exit time from detection range), then `loss_point = target_pos + vel × Δt`

### Safety Margin (`applySafetyMargin`, lines ~375-388)
- Moves the intercept point 10% (SAFETY_MARGIN=0.1) closer to the sensor
- Formula: `safe_intercept = sensor_pos + direction/‖direction‖ × ‖direction‖ × 0.9`
- Effect: interceptor aims at 90% of the predicted loss distance

### Bid Cost Function (`calculateEnhancedBid`, lines ~2848-2880)
```
bid = 0.4·P_home + 0.3·P_spatial + 0.2·P_temporal + 0.1·P_uncertainty
```
- **P_home** = ‖sensor_pos − home‖ / max_network_distance (penalty for being displaced)
- **P_spatial** = ‖sensor_pos − intercept_point‖ / max_network_distance (distance to travel)
- **P_temporal** = max(0, (time_to_intercept − target_time_to_intercept) / target_time_to_intercept) — penalises sensors arriving *after* the target
- **P_uncertainty** = 1 − confidence (inverse confidence)

Lower bid = better candidate.

### PNG Guidance (`calculatePNGAcceleration`, lines ~451-474)
- Computes line-of-sight rate θ̇ = (LOS × rel_vel) / ‖LOS‖²
- Acceleration: `a = λ · ‖v_sensor‖ · θ̇ · n̂` (n̂ perpendicular to sensor velocity), λ=4.0 (hardcoded)
- PNG is only applied when `dot_product < 0` (target has already passed the intercept point, line ~1985)
  - Until then, the sensor flies **straight** to the static intercept point

### Handover Completion (lines ~1506-1669)
- **1-for-1**: One interceptor detects target → releases farthest active tracker, becomes tracker
- **2-for-2**: Two interceptors detect same target → releases all current trackers, both become trackers
- If interceptor reaches within 1 unit of intercept point with no detection → RETURNING_HOME

---

## 2. Conflict Resolution — How It Works

Triggered when two or more targets are simultaneously in `PENDING_SELECTION`.

### Step 1 — Available sensors (lines ~912-924)
Collect all sensors **not** in any `active_trackers` list.

### Step 2 — Bid matrix (lines ~927-941)
`all_target_bids[i, j]` = bid of `available_sensors(i)` for `all_calling_targets(j)`.
Shape: `(N_avail × N_calling)`.

### Step 3 — Greedy best-team pre-compute (lines ~943-975)
For each target independently, find the cheapest non-overlapping 2-sensor pair (O(N²) per target).

### Step 4 — Conflict detection (lines ~976)
Checks if any sensor appears in best-teams of two different targets.

### Step 5a — Minimax path (only if exactly 2 targets, lines ~980-1039)
1. Select top-8 bidders per target from `all_target_bids` → `top_sensors_t1`, `top_sensors_t2`
2. `top_sensors_combined = unique([t1; t2])` — union, ≤16 sensors
3. 4 nested loops enumerate all C(k,2)×C(k,2) pairs: `i1<i2` for target 1, `i3<i4` for target 2
4. For disjoint pairs: record `max(cost1, cost2)` per assignment
5. Pick assignment with minimum max cost — the minimax criterion

### Step 5b — Greedy path (all other cases, lines ~1040-1054)
Each target independently gets its greedy best team; no global optimisation.

---

## 3. Confirmed Bugs

### BUG 1 — CRITICAL: Cost Matrix Index Mismatch in Minimax (lines 1001-1002)

```matlab
% i1, i2, i3, i4 are indices into top_sensors_combined (1…k, up to ~16)
cost1 = all_target_bids(i1, 1) + all_target_bids(i2, 1);  % ← WRONG
cost2 = all_target_bids(i3, 2) + all_target_bids(i4, 2);  % ← WRONG
```

**Root cause:** `all_target_bids` rows are indexed by position in `available_sensors` (up to ~23).
But `i1` is an index into `top_sensors_combined`, which is a different (smaller) array.

**Correct fix:**
```matlab
idx1 = find(available_sensors == top_sensors_combined(i1));
idx2 = find(available_sensors == top_sensors_combined(i2));
idx3 = find(available_sensors == top_sensors_combined(i3));
idx4 = find(available_sensors == top_sensors_combined(i4));
cost1 = all_target_bids(idx1, 1) + all_target_bids(idx2, 1);
cost2 = all_target_bids(idx3, 2) + all_target_bids(idx4, 2);
```

**Impact:** The minimax optimisation reads wrong bids. The sensor IDs assigned at line 1026 are
correct (uses `top_sensors_combined(i*)` directly), but the *selection among them* was guided by
wrong costs — so the output is not a true minimax solution.

---

### BUG 2 — CRITICAL: 2-for-2 Replacement Deletes First Interceptor (lines 1597, 1600)

The outer sensor loop processes each interceptor `i` independently.

When `i = detecting_interceptors_for_target(1)`:
- Old trackers released, `active_trackers{target}` cleared, then sensor `i` added as PRIMARY ✓

When `i = detecting_interceptors_for_target(2)` (next iteration):
- Line 1597 runs again: `active_trackers{detected_target_id} = []` → **wipes the first interceptor**
- `if i == detecting_interceptors_for_target(1)` is FALSE → second sensor is never added

**Result after both iterations:**
- `active_trackers{target}` = **empty** (cleared by second iteration)
- Sensor 1 has state `TRACKING` but is NOT in `active_trackers`
- Sensor 2 remains in `INTERCEPTING` state, eventually reaches intercept point and goes home

**Fix:** Handle both interceptors inside the `if i == detecting_interceptors_for_target(1)` block,
or add an `elseif i == detecting_interceptors_for_target(2)` branch that adds the second sensor
as SECONDARY without clearing `active_trackers`.

---

### BUG 3 — MEDIUM: Stability Counter Resets to 1 Instead of 0 (line 763)

```matlab
else
    stable_prediction_counts(tracker_id, target_id) = 1;  % should be 0
end
```

With `MIN_STABLE_PREDICTIONS = 2`, resetting to 1 means after a single outlier only **one** more
stable step is needed. The pattern `stable → outlier → stable` satisfies the gate, violating the
intent of requiring 2 *consecutive* stable predictions.

**Fix:** Reset to `0` instead of `1`.

---

### BUG 4 — MEDIUM: 3-Target Conflict Resolution Missing (line 980)

```matlab
if length(all_calling_targets) == 2
    % minimax ...
end
% ← no else for 3 targets; silently falls to greedy at line 1040
```

The simulation is designed for 3 targets. When all 3 call interceptors simultaneously, the minimax
block is skipped with **no log warning**. The log at line 906 still prints `'ENTERING CONFLICT
RESOLUTION PATH'` even though no optimisation is performed.

**Fix:** Add a 3-target minimax block using 6 nested loops over `top_sensors_combined`, or a
general N-target combinatorial search with the same top-8 pruning.

---

### BUG 5 — MEDIUM: EKF Covariance Uses Basic Update Form (lines 1274, 1499)

```matlab
P = (eye(4) - K * H) * P;   % basic form — numerically unstable
```

Over 820 timesteps × 75 filters, accumulated rounding can make `P` non-symmetric or indefinite.

**Fix (Joseph form):**
```matlab
IKH = eye(4) - K * H;
P = IKH * P * IKH' + K * R * K';
```

---

### BUG 6 — LOW: PNG Applied Only After Target Passes Intercept (line 1985)

```matlab
elseif dot_product < 0 && confidence > 0.2   % target past intercept
    % PNG applied here
else
    % fly straight — no active guidance correction
end
```

For the normal case, the sensor flies straight to the static precomputed point with no correction
for target trajectory changes.

---

## 4. Why the Solution is Sub-optimal

| Reason | Details |
|---|---|
| **Bug 1 corrupts minimax costs** | Even the 2-target minimax path uses wrong bids → not truly minimax |
| **Top-8 pruning** | Sensors ranked 9th+ per target are excluded even if they form the global optimum pair |
| **3-target gap** | When all 3 targets call simultaneously, greedy independent assignment is used — no global min-max |
| **Redundant enumeration** | `(team_A, team_B)` and `(team_B, team_A)` both evaluated; ~50% of O(k⁴) work is wasted |
| **Static intercept point** | Computed once from EKF velocity estimate; not updated as target moves → open-loop error accumulates |
| **PNG not always active** | Interceptor uses straight-line flight until target overshoots; active guidance would improve intercept reliability |
| **Bid ignores EKF covariance** | `P_uncertainty` uses heuristic confidence decay, not the actual EKF covariance P — less accurate uncertainty weighting |

---

## 5. Summary Table

| # | Issue | Lines | Severity | Type |
|---|---|---|---|---|
| 1 | Cost matrix index mismatch in minimax | 1001-1002 | **Critical** | Bug |
| 2 | 2-for-2 replacement wipes first interceptor from active_trackers | 1597, 1600 | **Critical** | Bug |
| 3 | Stability counter resets to 1 not 0 | 763 | Medium | Logic error |
| 4 | 3-target conflict resolution missing (silent greedy fallback) | 980 | Medium | Missing feature |
| 5 | EKF basic covariance update (not Joseph form) | 1274, 1499 | Medium | Numerical |
| 6 | PNG only applied after target passes intercept | 1985 | Low | Suboptimal |
| 7 | Top-8 pruning excludes globally optimal sensors | 982-987 | Low | Heuristic |
| 8 | Intercept point not updated as target moves | — | Low | Open-loop |
| 9 | Redundant O(k⁴) enumeration (each assignment counted twice) | 992-1011 | Low | Inefficiency |
