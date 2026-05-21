# Report Submission Log

## Summary

This log records what was completed for the V46 MCMF work before report submission, why these steps were important, and why they represent meaningful progress for the project.

## What Was Completed

### 1. V46 MCMF assignment integration

- Implemented the MCMF-based interceptor assignment path in V46.
- Preserved the legacy min-max assignment path for direct A/B comparison.
- Added a shared assignment wrapper so both algorithms can be evaluated under the same candidate sensors and cost matrix.

Why this was a good step:

- It changed the interceptor assignment from a local heuristic into a globally optimized assignment problem.
- It preserved backward comparability, which made validation much more convincing.
- It made it possible to explain improvements as assignment-level improvements rather than unrelated simulation changes.

### 2. Unit and adapter validation

- Built solver-level tests for MCMF and legacy assignment behavior.
- Built adapter-level tests that mock simulation-shaped inputs such as active trackers, intercept points, and EKF-informed states.
- Verified shortage cases, simultaneous target cases, and same-input MCMF-vs-legacy comparisons.

Why this was a good step:

- It isolated the assignment logic from the full simulation.
- It allowed deterministic testing of conflict and shortage scenarios that are difficult to produce naturally.
- It created strong evidence that the algorithm itself was implemented correctly before testing the full simulation.

### 3. Controlled simulation validation

- Built a dedicated Stage 3 simulation script for controlled simultaneous `PENDING_SELECTION` testing.
- Verified that MCMF could run inside a real V46-derived simulation loop.
- Compared MCMF and legacy under the same injected conflict event.

Why this was a good step:

- It bridged the gap between pure unit tests and the full simulation.
- It showed that the MCMF path was not only mathematically correct, but also operational in the real simulation framework.
- It gave report-quality evidence that MCMF can reduce total assignment cost under controlled conflict scenarios.

### 4. Full natural simulation validation

- Ran the clean `example_V46_Yeqi.m` without injection.
- Confirmed that MCMF was naturally invoked in the full simulation.
- Identified a supplementary natural case where target 1 and target 2 naturally entered `PENDING_SELECTION` at the same time.
- Compared MCMF and legacy on that naturally occurring event.

Why this was a good step:

- It showed that the clean full simulation remained compatible with the new MCMF path.
- It provided no-injection evidence, which is especially valuable for credibility.
- Even though the natural improvement was smaller than in controlled tests, it showed that MCMF can still outperform legacy in a genuine natural multi-target conflict case.

### 5. Report structure and evidence organization

- Organized the validation story into a report-friendly progression:
  - design
  - unit/adapter validation
  - controlled simulation validation
  - natural full-simulation validation
- Generated and updated an HTML validation report for easy review.
- Preserved a copy of the natural-conflict V46 script for future reuse.

Why this was a good step:

- The project now has both implementation evidence and communication-quality evidence.
- The report is not just a description of code changes; it explains why the results are trustworthy.
- The preserved script version makes it easier to revisit the best natural example later without losing it.

## Why This Submission Was Meaningful

This was a strong project milestone because it did not stop at implementation. The work moved through the full chain of:

- algorithm design,
- isolated correctness testing,
- simulation integration,
- natural full-system verification,
- and report-ready documentation.

That matters because in a system as coupled as this one, correctness is not obvious from the final animation alone. By building layered validation instead of relying on a single end result, the final report can make a much stronger claim: the MCMF module is not only implemented, but validated in a way that is technically interpretable and reproducible.

## Good Next Steps

- Explore more natural multi-target conflict cases under clean simulation settings.
- Optionally test relaxed trigger conditions as supplementary future work, without replacing the clean natural baseline.
- Refine trajectories or target timing to increase the likelihood of natural resource competition.
- Continue using the preserved natural-conflict V46 script as a reference point for future comparisons.

## Files Worth Keeping Track Of

- `example_V46_Yeqi.m`
- `example_V46_natural_conflict_Yeqi.m`
- `test_interceptor_assignment.m`
- `test_mcmf_simulation_adapter.m`
- `MCMF_VALIDATION_REPORT.html`
- `uoft-mie8888-report.docx`
