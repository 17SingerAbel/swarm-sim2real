function [assignments, diagnostics] = solveInterceptorAssignmentMCMF(calling_targets, candidates, cost_matrix, slots_per_target)
%SOLVEINTERCEPTORASSIGNMENTMCMF Solve interceptor assignment with min-cost max-flow.
%   The solver expands each target into slots_per_target slots, assigns each
%   candidate sensor to at most one slot, and uses a large assignment reward
%   so the optimization first maximizes assigned slots and then minimizes cost.

if nargin < 4 || isempty(slots_per_target)
    slots_per_target = 2;
end

calling_targets = calling_targets(:);
candidates = candidates(:);
[num_candidates, num_targets] = size(cost_matrix);

if num_candidates ~= numel(candidates)
    error('solveInterceptorAssignmentMCMF:CandidateSizeMismatch', ...
        'Rows of cost_matrix must match number of candidates.');
end

if num_targets ~= numel(calling_targets)
    error('solveInterceptorAssignmentMCMF:TargetSizeMismatch', ...
        'Columns of cost_matrix must match number of calling targets.');
end

assignments = cell(num_targets, 1);
assigned_slots_per_target = zeros(num_targets, 1);
assignment_costs_per_target = zeros(num_targets, 1);

if isempty(candidates) || isempty(calling_targets)
    diagnostics = buildDiagnostics(assignments, assigned_slots_per_target, ...
        assignment_costs_per_target, slots_per_target, 0, 0, 0);
    diagnostics.algorithm = 'MCMF';
    diagnostics.assignment_reward = 0;
    diagnostics.augmentations = 0;
    return;
end

slot_target_indices = repelem((1:num_targets)', slots_per_target);
num_slots = numel(slot_target_indices);
source = 1;
sensor_offset = 1;
slot_offset = sensor_offset + num_candidates;
sink = slot_offset + num_slots + 1;
num_nodes = sink;

capacity = zeros(num_nodes, num_nodes);
edge_costs = nan(num_nodes, num_nodes);

for sensor_idx = 1:num_candidates
    sensor_node = sensor_offset + sensor_idx;
    capacity(source, sensor_node) = 1;
    edge_costs(source, sensor_node) = 0;
end

finite_costs = cost_matrix(isfinite(cost_matrix));
if isempty(finite_costs)
    assignment_reward = 1;
else
    assignment_reward = (num_candidates * max(1, slots_per_target) + 1) * (max(finite_costs) + 1);
end

for sensor_idx = 1:num_candidates
    sensor_node = sensor_offset + sensor_idx;
    for slot_idx = 1:num_slots
        target_idx = slot_target_indices(slot_idx);
        raw_cost = cost_matrix(sensor_idx, target_idx);
        if ~isfinite(raw_cost)
            continue;
        end
        slot_node = slot_offset + slot_idx;
        capacity(sensor_node, slot_node) = 1;
        edge_costs(sensor_node, slot_node) = raw_cost - assignment_reward;
    end
end

for slot_idx = 1:num_slots
    slot_node = slot_offset + slot_idx;
    capacity(slot_node, sink) = 1;
    edge_costs(slot_node, sink) = 0;
end

[flow_matrix, reduced_cost, augmentations] = runNegativePathMinCostFlow(capacity, edge_costs, source, sink);

for sensor_idx = 1:num_candidates
    sensor_node = sensor_offset + sensor_idx;
    for slot_idx = 1:num_slots
        slot_node = slot_offset + slot_idx;
        if flow_matrix(sensor_node, slot_node) > 0
            target_idx = slot_target_indices(slot_idx);
            assignments{target_idx}(end + 1, 1) = candidates(sensor_idx); %#ok<AGROW>
            assigned_slots_per_target(target_idx) = assigned_slots_per_target(target_idx) + 1;
            assignment_costs_per_target(target_idx) = assignment_costs_per_target(target_idx) + cost_matrix(sensor_idx, target_idx);
        end
    end
end

for target_idx = 1:num_targets
    assignments{target_idx} = assignments{target_idx}(:)';
end

total_assigned_slots = sum(assigned_slots_per_target);
total_cost = sum(assignment_costs_per_target);

diagnostics = buildDiagnostics(assignments, assigned_slots_per_target, ...
    assignment_costs_per_target, slots_per_target, total_assigned_slots, ...
    total_cost, reduced_cost);
diagnostics.algorithm = 'MCMF';
diagnostics.assignment_reward = assignment_reward;
diagnostics.augmentations = augmentations;
end

function diagnostics = buildDiagnostics(assignments, assigned_slots_per_target, assignment_costs_per_target, slots_per_target, total_assigned_slots, total_cost, reduced_cost)
diagnostics = struct();
diagnostics.assignments = assignments;
diagnostics.assigned_slots_per_target = assigned_slots_per_target;
diagnostics.assignment_costs_per_target = assignment_costs_per_target;
diagnostics.requested_slots_per_target = slots_per_target;
diagnostics.requested_slots_total = numel(assignments) * slots_per_target;
diagnostics.assigned_slots_total = total_assigned_slots;
diagnostics.total_cost = total_cost;
diagnostics.reduced_cost = reduced_cost;
end

function [flow_matrix, total_cost, augmentations] = runNegativePathMinCostFlow(capacity, edge_costs, source, sink)
num_nodes = size(capacity, 1);
flow_matrix = zeros(num_nodes, num_nodes);
total_cost = 0;
augmentations = 0;

while true
    [path_found, parent, direction, distance] = shortestResidualPath(capacity, flow_matrix, edge_costs, source, sink);
    if ~path_found || ~isfinite(distance(sink)) || distance(sink) >= 0
        break;
    end

    node = sink;
    while node ~= source
        prev_node = parent(node);
        if direction(node) == 1
            flow_matrix(prev_node, node) = flow_matrix(prev_node, node) + 1;
        else
            flow_matrix(node, prev_node) = flow_matrix(node, prev_node) - 1;
        end
        node = prev_node;
    end

    total_cost = total_cost + distance(sink);
    augmentations = augmentations + 1;
end
end

function [path_found, parent, direction, distance] = shortestResidualPath(capacity, flow_matrix, edge_costs, source, sink)
num_nodes = size(capacity, 1);
distance = inf(num_nodes, 1);
parent = zeros(num_nodes, 1);
direction = zeros(num_nodes, 1);
distance(source) = 0;

for iter = 1:num_nodes - 1
    updated = false;
    for u = 1:num_nodes
        if ~isfinite(distance(u))
            continue;
        end

        for v = 1:num_nodes
            if capacity(u, v) - flow_matrix(u, v) > 0 && isfinite(edge_costs(u, v))
                candidate_distance = distance(u) + edge_costs(u, v);
                if candidate_distance < distance(v)
                    distance(v) = candidate_distance;
                    parent(v) = u;
                    direction(v) = 1;
                    updated = true;
                end
            end

            if flow_matrix(v, u) > 0 && isfinite(edge_costs(v, u))
                candidate_distance = distance(u) - edge_costs(v, u);
                if candidate_distance < distance(v)
                    distance(v) = candidate_distance;
                    parent(v) = u;
                    direction(v) = -1;
                    updated = true;
                end
            end
        end
    end

    if ~updated
        break;
    end
end

path_found = parent(sink) ~= 0;
end
