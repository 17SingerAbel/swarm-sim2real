function [expanded_calling_targets, reselection_events] = expandCallingTargetsForJointReselection(initial_calling_targets, interceptor_assigned_target, num_nodes, num_targets, active_trackers, node_positions, original_positions, interceptor_process_data, sensor_ekf_states, sensor_detection_times, current_time, communication_range, wsn_width, wsn_height, slots_per_target, use_mcmf)
%EXPANDCALLINGTARGETSFORJOINTRESELECTION Add targets whose interceptors are stolen.
%   Runs provisional assignments for the current target set. If a selected
%   sensor is already intercepting for a target outside that set, include the
%   previous owner target and repeat until the joint set is closed.

if nargin < 15 || isempty(slots_per_target)
    slots_per_target = 2;
end

if nargin < 16
    use_mcmf = true;
end

expanded_calling_targets = unique(initial_calling_targets(:), 'stable');
reselection_events = struct('sensor_id', {}, 'from_target_id', {}, 'to_target_id', {});

for expansion_iter = 1:max(1, num_targets)
    [available_sensors, assignment_cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
        expanded_calling_targets, num_nodes, num_targets, active_trackers, node_positions, ...
        original_positions, interceptor_process_data, sensor_ekf_states, ...
        sensor_detection_times, current_time, communication_range, ...
        wsn_width, wsn_height);

    [provisional_assignments, ~] = solveInterceptorAssignments( ...
        expanded_calling_targets, available_sensors, assignment_cost_matrix, ...
        slots_per_target, use_mcmf);

    added_target = false;

    for target_idx = 1:numel(expanded_calling_targets)
        to_target_id = expanded_calling_targets(target_idx);
        selected_team = provisional_assignments{target_idx};

        for sensor_id = selected_team(:)'
            if sensor_id < 1 || sensor_id > numel(interceptor_assigned_target)
                continue;
            end

            from_target_id = interceptor_assigned_target(sensor_id);
            if from_target_id <= 0 || from_target_id == to_target_id || ...
               ismember(from_target_id, expanded_calling_targets)
                continue;
            end

            if from_target_id > num_targets || isempty(interceptor_process_data{from_target_id}) || ...
               ~isfield(interceptor_process_data{from_target_id}, 'intercept_point')
                continue;
            end

            expanded_calling_targets = [expanded_calling_targets; from_target_id]; %#ok<AGROW>
            reselection_events(end + 1) = struct( ... %#ok<AGROW>
                'sensor_id', sensor_id, ...
                'from_target_id', from_target_id, ...
                'to_target_id', to_target_id);
            added_target = true;
        end
    end

    if ~added_target
        break;
    end
end
end
