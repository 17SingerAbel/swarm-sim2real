function [shared_target_pos, shared_target_vel, confidence] = getSharedTargetInfo(sensor_id, node_positions, sensor_ekf_states, sensor_detection_times, current_time, communication_range, target_id)
nearby_sensors = findNearbySensors(sensor_id, node_positions, communication_range);
valid_estimates = [];
weights = [];

for i = 1:length(nearby_sensors)
    nearby_id = nearby_sensors(i);

    if sensor_detection_times(nearby_id, target_id) > 0 && ~isempty(sensor_ekf_states{nearby_id, target_id})
        target_estimate = sensor_ekf_states{nearby_id, target_id}(1:2);
        target_velocity = sensor_ekf_states{nearby_id, target_id}(3:4);

        time_since_detection = current_time - sensor_detection_times(nearby_id, target_id);
        distance = norm(node_positions(sensor_id,:) - node_positions(nearby_id,:));

        weight = exp(-time_since_detection * 0.1) / (1 + distance * 0.1);

        valid_estimates = [valid_estimates; target_estimate', target_velocity']; %#ok<AGROW>
        weights = [weights; weight]; %#ok<AGROW>
    end
end

if ~isempty(valid_estimates)
    total_weight = sum(weights);
    shared_target_pos = sum(valid_estimates(:,1:2) .* weights, 1) / total_weight;
    shared_target_vel = sum(valid_estimates(:,3:4) .* weights, 1) / total_weight;
    confidence = min(1.0, total_weight);
else
    shared_target_pos = [];
    shared_target_vel = [];
    confidence = 0;
end
end
