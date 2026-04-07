function [assignments, diagnostics] = solveInterceptorAssignments(calling_targets, candidates, cost_matrix, slots_per_target, use_mcmf)
%SOLVEINTERCEPTORASSIGNMENTS Select assignment strategy for interceptor teams.
%   This wrapper keeps the legacy solver available for A/B comparison while
%   allowing the simulation and unit tests to call a single stable entrypoint.

if nargin < 4 || isempty(slots_per_target)
    slots_per_target = 2;
end

if nargin < 5
    use_mcmf = true;
end

if use_mcmf
    [assignments, diagnostics] = solveInterceptorAssignmentMCMF( ...
        calling_targets, candidates, cost_matrix, slots_per_target);
else
    [assignments, diagnostics] = solveInterceptorAssignmentLegacy( ...
        calling_targets, candidates, cost_matrix, slots_per_target);
end

diagnostics.calling_targets = calling_targets(:)';
diagnostics.candidates = candidates(:)';
diagnostics.strategy = string(use_mcmf);
end
