# Interceptor Bidding Progress and Implementation Plan

## Current Progress

The current MATLAB implementation has been reviewed with a focus on the interceptor bidding and selection process in [`example_V45_V38_b_Yeqi.m`](/C:/Users/abel/Desktop/MIE8888/mie8888/example_V45_V38_b_Yeqi.m).

The following points have been confirmed from the code:

- The current bidding logic supports single-target interceptor selection by choosing the lowest-cost valid bidders for one calling target.
- The current implementation contains a partial conflict-resolution branch for the two-target case.
- The current implementation does not fully handle general simultaneous conflict among three or more targets.
- The current method is heuristic. It is not a single unified global optimizer over all active targets and available interceptor candidates.

The main conclusion at this stage is that the current code already contains the required ingredients for a global assignment method, including candidate filtering, bid-cost computation, and target-specific selection, but the global resolution logic is incomplete and case-specific.

## Problem Definition

The generalized interceptor allocation problem can be stated as follows:

- There are `k` active targets requesting interceptor support.
- Each target can request up to `m` interceptors.
- Each candidate sensor can be assigned at most once.
- The allocation objective is to maximize filled target-slot coverage first, and then reduce the total bidding cost.

In this formulation, each target is interpreted as having up to `m` interceptor slots. A feasible global assignment maps sensors to these slots under uniqueness and capacity constraints.

An important caveat is that standard min-cost max-flow does not, by itself, guarantee balanced per-target coverage. It maximizes total filled slots and minimizes total cost among those maximum-coverage solutions, but it may still assign multiple interceptors to one target while another target remains under-served if that configuration is globally cheaper under the standard objective.

## Key Findings from Discussion

Three related allocation ideas have been distinguished during the discussion:

- **Greedy minimum-cost assignment**: repeatedly choose the currently cheapest feasible sensor-slot assignment and fix it permanently.
- **Standard min-cost max-flow**: solve a global assignment problem in which earlier assignments may be revised through residual reverse edges if a lower-cost global solution is found later.
- **Fairness-aware or hierarchical allocation**: introduce an additional service-priority rule, such as baseline target coverage before global optimization of the remaining slots.

For this project, max flow should be interpreted as **maximum target-slot coverage**. In the ideal case, all target slots are filled. If resources are insufficient, max flow means that the largest feasible number of target slots has been filled under the assignment constraints.

It is also important to record that min-cost max-flow is not greedy. During successive augmentation, previously selected assignments may be revised through residual reverse edges. This is the key reason the method can recover a globally optimal allocation instead of being locked into early local decisions.

## Implementation Plan

The code change should remain narrowly scoped to the interceptor selection logic only. The surrounding FSM structure, role assignment, and state transition handling should remain intact in the first implementation.

The planned implementation steps are:

1. Identify the set of simultaneously calling targets inside the current bidding/selection stage.
2. Collect all eligible candidate sensors using the existing active-tracker exclusion logic and any existing feasibility checks.
3. Build target slots for the active calling targets so that each target contributes up to `m` assignment slots.
4. Compute the bid-cost matrix using the existing bid-cost calculation function and the same target/intercept-point information already used by the current code.
5. Replace the current conflict-resolution branch with a global allocation routine that returns sensor-to-target-slot assignments.
6. Translate the returned assignments back into the current MATLAB state variables, including interceptor states, roles, proactive targets, and call flags.
7. Preserve the existing FSM transitions and role/state update logic around the new selection output, instead of attempting a large structural refactor.

The implementation should first target the current practical case behaviorally, namely `k = 2` and `m = 2`, because that is where the current code already attempts conflict resolution. However, the formulation and interface should be written so that they can later support general `k` and `m`.

Because the current codebase is monolithic, the first implementation step should conceptually isolate the selection logic even if the first code version remains inside the existing `PENDING_SELECTION` region of the main script.

## Open Design Decision

One design question remains open at this stage:

- whether to use standard min-cost max-flow directly for the whole allocation step, or
- whether to introduce a hierarchical baseline-coverage stage before global optimization.

The default working assumption for the first implementation is:

- use standard min-cost max-flow as the primary global allocation method,
- document balanced-coverage allocation as the next design extension rather than the first implementation target.

This keeps the first implementation focused, while preserving a clear path for future fairness-aware development.

## Validation Plan

The new global allocation method should be compared against the current heuristic bidding logic in the following dimensions:

- assignment quality,
- overlap and conflict handling,
- runtime per bidding event,
- online feasibility under the current WSN scale.

The target runtime and evaluation metrics should include:

- solve time per reallocation event,
- deadline satisfaction rate,
- real-time ratio,
- optional optimality-gap comparison against the current heuristic.

The validation should focus especially on multi-target conflict cases, since this is where the current method is weakest and where a global allocation method is expected to provide the clearest improvement.

## Notes

- This document is intended as a progress-stage engineering record, not as a final-paper section.
- The main MATLAB script remains the implementation target, specifically the bidding and conflict-resolution region.
- No large refactor is planned in the first step; the primary goal is to improve the interceptor selection logic while minimizing disruption to the existing simulation behavior.
