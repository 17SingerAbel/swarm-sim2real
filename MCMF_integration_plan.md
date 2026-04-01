# MCMF Integration Plan (V46)

## Scope
- Baseline file: `example_V45_V38_b.m` (do not edit)
- Working file: `example_V46_mcmf_proposal.m`
- Goal: replace local bidding + conflict-repair with global min-cost max-flow assignment

## Steps
1. Freeze baseline and add switch
- Keep V45 unchanged.
- Add `USE_MCMF_ASSIGNMENT = true` in V46 for A/B test vs legacy.

2. Isolate current assignment code
- Refactor current `PENDING_BIDDING` / `PENDING_SELECTION` logic into helper functions.
- No behavior change in this step.

3. Build global allocation inputs
- Calling target set `T`.
- Candidate sensor set `S` (non-tracking, optionally include RETURNING_HOME).
- Slot expansion: each target gets `m=2` slots.
- Cost matrix `C(i,j)` from `calculateEnhancedBid(...)`.

4. Implement MCMF solver
- Add function: `solveInterceptorAssignmentMCMF(calling_targets, candidates, C, m)`.
- Output: non-overlapping assignments target -> sensors.
- Lexicographic objective:
  - maximize assigned slots first,
  - minimize total cost second.

5. Replace selection path
- In `PENDING_SELECTION`, call MCMF for both single and multi-target events.
- Keep legacy path as fallback behind flag if needed.

6. Handle shortage cases
- Allow partial allocation when candidates are insufficient.
- Log shortage explicitly per target.

7. Add logging and MAT outputs
- Log calling targets, candidate count, requested slots, assigned slots, total cost.
- Save `assignment_events` to MAT for post analysis.

8. Validate behavior
- Scenario A: single target call.
- Scenario B: simultaneous multi-target calls (enough sensors).
- Scenario C: insufficient sensors.
- Compare against legacy:
  - successful intercepts,
  - missed intercepts,
  - assignment cost,
  - per-target coverage fairness.

9. Phase-2 enhancement (optional)
- Balanced coverage policy:
  - ensure at least one interceptor per calling target when feasible,
  - then optimize remaining slots by cost.

