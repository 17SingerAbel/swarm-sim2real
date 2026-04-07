function bid = calculateEnhancedBid(sensor_id, sensor_pos, original_home, intercept_point, target_vel, shared_confidence, target_current_pos, wsn_width, wsn_height)
max_network_distance = sqrt(wsn_width^2 + wsn_height^2);

P_home = norm(sensor_pos - original_home) / max_network_distance;
P_spatial = norm(sensor_pos - intercept_point) / max_network_distance;

sensor_velocity = 0.75;
time_to_intercept = norm(sensor_pos - intercept_point) / sensor_velocity;

target_distance_to_intercept = norm(target_current_pos - intercept_point);
target_speed = norm(target_vel);

if target_speed > 0.01
    target_time_to_intercept = target_distance_to_intercept / target_speed;
    P_temporal = min(1.0, max(0, (time_to_intercept - target_time_to_intercept) / target_time_to_intercept));
else
    P_temporal = 0.0;
end

P_uncertainty = 1 - shared_confidence;

global OPTIMIZATION_WEIGHTS;
if ~isempty(OPTIMIZATION_WEIGHTS)
    w1 = OPTIMIZATION_WEIGHTS(1);
    w2 = OPTIMIZATION_WEIGHTS(2);
    w3 = OPTIMIZATION_WEIGHTS(3);
    w4 = OPTIMIZATION_WEIGHTS(4);
else
    w1 = 0.4; w2 = 0.3; w3 = 0.2; w4 = 0.1;
end

bid = w1 * P_home + w2 * P_spatial + w3 * P_temporal + w4 * P_uncertainty;
end
