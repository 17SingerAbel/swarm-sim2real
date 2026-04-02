# V46 Test Plan (MCMF + Shortage)

## Purpose
Validate that V46 interceptor allocation behaves correctly after Step 6:
- Global MCMF assignment path is used.
- Shortage is handled with partial allocation (no crashes, no duplicate sensor assignment).
- Logs provide target-level required/assigned/shortage metrics.

## Pre-check
1. Run `example_V46_mcmf_proposal`.
2. Open latest log file in `logs/`.
3. Confirm `[MCMF]` and `[MCMF][SHORTAGE]` entries exist.

## Scenario A: Single Target, Sufficient Candidates
- Setup:
  - Default simulation settings.
  - Use a period where only one target calls interceptors.
- Expected:
  - `required=2`, `assigned=2`, `shortage=0`.
  - Exactly two assigned sensors for the calling target.
  - No duplicate sensor in the same event.

## Scenario B: Multi-target Simultaneous Call, Sufficient Candidates
- Setup:
  - Trigger two targets to reach `PENDING_SELECTION` in same step (or close enough to be co-processed).
- Expected:
  - Combined capacity summary shows `assigned == required`.
  - Each calling target reports `required=2`, `assigned=2`, `shortage=0`.
  - Assigned sensor sets across targets are disjoint.

## Scenario C: Multi-target Simultaneous Call, Limited Candidates
- Setup:
  - Reduce eligible candidates (e.g., many sensors occupied as trackers/interceptors).
- Expected:
  - Combined summary shows `shortage > 0`.
  - At least one target has `assigned < required`.
  - No target gets more than `required` slots.
  - No sensor assigned to more than one slot.

## Scenario D: Extreme Shortage
- Setup:
  - Candidate pool very small (0 or 1) while >=2 targets are calling.
- Expected:
  - Assignment still completes without runtime error.
  - Logs show explicit shortage per target.
  - `interceptor_call_triggered` is true only for targets that received assignments.

## Log Checks
For each assignment event, verify:
1. `[MCMF] Assigned X/Y slots, total cost=...`
2. `[MCMF] Capacity summary: required=Y assigned=X shortage=Y-X`
3. Per target line:
   - `[MCMF][SHORTAGE] Target t required=2 assigned=a shortage=s`
4. Consistency rule:
   - `assigned + shortage == required` per target.

## Output Checks (MAT + state consistency)
1. No sensor appears in multiple target assignments for one event.
2. Assigned sensors transition to `INTERCEPTING`.
3. Reassigned-out interceptors transition to `RETURNING_HOME` unless still serving a non-calling target.

## Acceptance Criteria
- All four scenarios execute without MATLAB runtime errors.
- No assignment uniqueness violations.
- Shortage accounting is correct in logs for every assignment event.
- Simulation still produces `.log` and `.mat` outputs.
