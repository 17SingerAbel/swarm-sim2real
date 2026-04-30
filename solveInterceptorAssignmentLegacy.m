function [assignments, diagnostics] = solveInterceptorAssignmentLegacy(calling_targets, candidates, cost_matrix, slots_per_target)
%SOLVEINTERCEPTORASSIGNMENTLEGACY Preserve the pre-V46 team selection logic.
%   The legacy solver keeps the older greedy/minimax flavor available for
%   comparison, while the new MCMF path can be switched on independently.

if nargin < 4 || isempty(slots_per_target)
    slots_per_target = 2;
end

calling_targets = calling_targets(:);
candidates = candidates(:);
[num_candidates, num_targets] = size(cost_matrix);

if num_candidates ~= numel(candidates)
    error('solveInterceptorAssignmentLegacy:CandidateSizeMismatch', ...
        'Rows of cost_matrix must match number of candidates.');
end

if num_targets ~= numel(calling_targets)
    error('solveInterceptorAssignmentLegacy:TargetSizeMismatch', ...
        'Columns of cost_matrix must match number of calling targets.');
end

assignments = cell(num_targets, 1);
assigned_slots_per_target = zeros(num_targets, 1);
assignment_costs_per_target = zeros(num_targets, 1);

if isempty(candidates) || isempty(calling_targets)
    diagnostics = buildLegacyDiagnostics(assignments, assigned_slots_per_target, ...
        assignment_costs_per_target, slots_per_target, 'EMPTY', false);
    diagnostics.algorithm = 'LEGACY';
    return;
end

if num_targets == 1
    num_to_assign = min(slots_per_target, num_candidates);
    [sorted_costs, sort_idx] = sort(cost_matrix(:, 1), 'ascend');
    chosen = sort_idx(1:num_to_assign);
    assignments{1} = candidates(chosen)';
    assigned_slots_per_target(1) = num_to_assign;
    assignment_costs_per_target(1) = sum(sorted_costs(1:num_to_assign));
    comparison_mode = 'SINGLE_TARGET_GREEDY';
    used_two_target_minimax = false;
else
    [assignments, assigned_slots_per_target, assignment_costs_per_target, ...
        comparison_mode, used_two_target_minimax] = ...
        solveMultiTargetLegacy(candidates, cost_matrix, slots_per_target);
end

diagnostics = buildLegacyDiagnostics(assignments, assigned_slots_per_target, ...
    assignment_costs_per_target, slots_per_target, comparison_mode, ...
    used_two_target_minimax);
diagnostics.algorithm = 'LEGACY';
end

function [assignments, assigned_slots_per_target, assignment_costs_per_target, comparison_mode, used_two_target_minimax] = solveMultiTargetLegacy(candidates, cost_matrix, slots_per_target)
num_targets = size(cost_matrix, 2);
num_candidates = numel(candidates);
assignments = cell(num_targets, 1);
assigned_slots_per_target = zeros(num_targets, 1);
assignment_costs_per_target = zeros(num_targets, 1);
comparison_mode = 'MULTI_TARGET_GREEDY';
used_two_target_minimax = false;

team_size = min(slots_per_target, num_candidates);
best_teams = cell(num_targets, 1);
team_costs = inf(num_targets, 1);

for target_idx = 1:num_targets
    if team_size == 0
        best_teams{target_idx} = [];
        team_costs(target_idx) = 0;
        continue;
    end

    combos = nchoosek(1:num_candidates, team_size);
    combo_costs = zeros(size(combos, 1), 1);
    for combo_idx = 1:size(combos, 1)
        combo_costs(combo_idx) = sum(cost_matrix(combos(combo_idx, :), target_idx));
    end
    [team_costs(target_idx), best_idx] = min(combo_costs);
    best_teams{target_idx} = candidates(combos(best_idx, :))';
end

all_assigned = [best_teams{:}];
conflicts_exist = numel(unique(all_assigned)) ~= numel(all_assigned);

if conflicts_exist && num_targets == 2 && slots_per_target == 2 && num_candidates >= num_targets * slots_per_target
    [assignments, assigned_slots_per_target, assignment_costs_per_target] = ...
        solveTwoTargetMinimaxLegacy(candidates, cost_matrix);
    comparison_mode = 'TWO_TARGET_MINIMAX_TOP8';
    used_two_target_minimax = true;
    return;
end

if num_targets == 2 && slots_per_target == 2
    if ~conflicts_exist
        comparison_mode = 'TWO_TARGET_GREEDY_NO_CONFLICT';
    else
        comparison_mode = 'TWO_TARGET_GREEDY_INSUFFICIENT_CANDIDATES';
    end
elseif num_targets ~= 2
    comparison_mode = 'MULTI_TARGET_GREEDY_NONMINIMAX';
elseif slots_per_target ~= 2
    comparison_mode = 'MULTI_TARGET_GREEDY_NONSTANDARD_TEAM_SIZE';
end

used_candidates = [];
for target_idx = 1:num_targets
    remaining_mask = ~ismember(candidates, used_candidates);
    remaining_candidates = candidates(remaining_mask);
    remaining_costs = cost_matrix(remaining_mask, target_idx);
    num_to_assign = min(slots_per_target, numel(remaining_candidates));

    if num_to_assign == 0
        continue;
    end

    [sorted_costs, sort_idx] = sort(remaining_costs, 'ascend');
    chosen_candidates = remaining_candidates(sort_idx(1:num_to_assign));
    assignments{target_idx} = chosen_candidates';
    used_candidates = [used_candidates; chosen_candidates(:)]; %#ok<AGROW>
    assigned_slots_per_target(target_idx) = num_to_assign;
    assignment_costs_per_target(target_idx) = sum(sorted_costs(1:num_to_assign));
end
end

function [assignments, assigned_slots_per_target, assignment_costs_per_target] = solveTwoTargetMinimaxLegacy(candidates, cost_matrix)
num_candidates = numel(candidates);
num_top_bidders = min(8, num_candidates);

[~, sort_idx_t1] = sort(cost_matrix(:, 1), 'ascend');
[~, sort_idx_t2] = sort(cost_matrix(:, 2), 'ascend');
top_sensors_t1 = candidates(sort_idx_t1(1:num_top_bidders));
top_sensors_t2 = candidates(sort_idx_t2(1:num_top_bidders));
top_sensors_combined = unique([top_sensors_t1; top_sensors_t2], 'stable');

best_worst_cost = inf;
best_assignment = {[], []};
best_team_costs = [0, 0];

for i1 = 1:numel(top_sensors_combined) - 1
    for i2 = i1 + 1:numel(top_sensors_combined)
        team1 = [top_sensors_combined(i1), top_sensors_combined(i2)];
        idx1 = find(candidates == team1(1), 1);
        idx2 = find(candidates == team1(2), 1);
        cost1 = cost_matrix(idx1, 1) + cost_matrix(idx2, 1);

        for i3 = 1:numel(top_sensors_combined) - 1
            for i4 = i3 + 1:numel(top_sensors_combined)
                team2 = [top_sensors_combined(i3), top_sensors_combined(i4)];
                if ~isempty(intersect(team1, team2))
                    continue;
                end

                idx3 = find(candidates == team2(1), 1);
                idx4 = find(candidates == team2(2), 1);
                cost2 = cost_matrix(idx3, 2) + cost_matrix(idx4, 2);
                worst_cost = max(cost1, cost2);

                if worst_cost < best_worst_cost
                    best_worst_cost = worst_cost;
                    best_assignment = {team1, team2};
                    best_team_costs = [cost1, cost2];
                end
            end
        end
    end
end

assignments = best_assignment(:);
assigned_slots_per_target = cellfun(@numel, assignments);
assignment_costs_per_target = best_team_costs(:);
end

function diagnostics = buildLegacyDiagnostics(assignments, assigned_slots_per_target, assignment_costs_per_target, slots_per_target, comparison_mode, used_two_target_minimax)
diagnostics = struct();
diagnostics.assignments = assignments;
diagnostics.assigned_slots_per_target = assigned_slots_per_target;
diagnostics.assignment_costs_per_target = assignment_costs_per_target;
diagnostics.requested_slots_per_target = slots_per_target;
diagnostics.requested_slots_total = numel(assignments) * slots_per_target;
diagnostics.assigned_slots_total = sum(assigned_slots_per_target);
diagnostics.total_cost = sum(assignment_costs_per_target);
diagnostics.reduced_cost = diagnostics.total_cost;
diagnostics.comparison_mode = comparison_mode;
diagnostics.used_two_target_minimax = used_two_target_minimax;
diagnostics.is_valid_two_target_minimax_case = used_two_target_minimax;

assigned_costs = assignment_costs_per_target(assigned_slots_per_target > 0);
if isempty(assigned_costs)
    diagnostics.worst_team_cost = 0;
else
    diagnostics.worst_team_cost = max(assigned_costs);
end
end
