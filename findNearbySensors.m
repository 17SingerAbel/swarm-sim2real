function nearby_sensors = findNearbySensors(sensor_id, node_positions, communication_range)
sensor_pos = node_positions(sensor_id, :);
distances = vecnorm(node_positions - sensor_pos, 2, 2);
nearby_sensors = find(distances <= communication_range & distances > 0);
end
