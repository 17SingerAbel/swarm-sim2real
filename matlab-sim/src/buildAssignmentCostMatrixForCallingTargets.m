function [available_sensors, assignment_cost_matrix] = buildAssignmentCostMatrixForCallingTargets(calling_targets, num_nodes, num_targets, active_trackers, node_positions, original_positions, interceptor_process_data, sensor_ekf_states, sensor_detection_times, current_time, communication_range, wsn_width, wsn_height)
available_sensors = [];

for sensor_id = 1:num_nodes
    is_active_tracker = false;
    for tid = 1:num_targets
        if ismember(sensor_id, active_trackers{tid})
            is_active_tracker = true;
            break;
        end
    end

    if ~is_active_tracker
        available_sensors = [available_sensors; sensor_id]; %#ok<AGROW>
    end
end

assignment_cost_matrix = inf(length(available_sensors), length(calling_targets));

for i = 1:length(available_sensors)
    sensor_id = available_sensors(i);

    for j = 1:length(calling_targets)
        calling_tid = calling_targets(j);
        safe_intercept_point = interceptor_process_data{calling_tid}.intercept_point;
        predictor_id = interceptor_process_data{calling_tid}.predictor_id;

        if predictor_id > 0 && ~isempty(sensor_ekf_states{predictor_id, calling_tid})
            target_vel_estimate = sensor_ekf_states{predictor_id, calling_tid}(3:4)';
        else
            target_vel_estimate = [0, 0];
        end

        [~, ~, confidence] = getSharedTargetInfo(sensor_id, node_positions, sensor_ekf_states, ...
            sensor_detection_times, current_time, communication_range, calling_tid);

        assignment_cost_matrix(i, j) = calculateEnhancedBid(sensor_id, node_positions(sensor_id,:), ...
            original_positions(sensor_id,:), safe_intercept_point, target_vel_estimate, confidence, ...
            interceptor_process_data{calling_tid}.target_position, wsn_width, wsn_height);
    end
end
end
