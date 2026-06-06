import math
import os
import yaml

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def _hex_grid_positions(grid_size, node_spacing):
    dy = node_spacing * math.sqrt(3) / 2
    positions = []
    for row in range(grid_size):
        for col in range(grid_size):
            x = col * node_spacing + (row % 2) * node_spacing / 2
            y = row * dy
            positions.append({
                'sensor_id': row * grid_size + col,
                'x': x,
                'y': y,
            })
    return positions


def generate_launch_description():
    config_path = os.path.join(
        get_package_share_directory('swarm_bringup'),
        'config', 'sim_m4_params.yaml',
    )

    with open(config_path, 'r') as f:
        cfg = yaml.safe_load(f)

    swarm = cfg['swarm']
    grid_size      = int(swarm['grid_size'])
    node_spacing   = float(swarm['node_spacing'])
    detection_radius = float(swarm['detection_radius'])
    comm_range     = float(swarm['communication_range'])
    num_targets    = int(swarm['num_targets'])
    dt             = float(swarm['dt'])
    ekf_r_std      = float(swarm['ekf_r_std'])
    ekf_q_std      = float(swarm['ekf_q_std'])
    ekf_thresh     = float(swarm['ekf_convergence_threshold'])
    sensor_max_speed = float(swarm['sensor_max_speed'])
    bidding_window = float(swarm['bidding_window'])
    max_interceptors = int(swarm['max_interceptors'])
    handover_lookahead = float(swarm['handover_lookahead'])

    tgt = cfg['targets']

    nodes = [
        Node(
            package='target_simulator',
            executable='target_simulator_node',
            name='target_simulator',
            parameters=[{
                'num_targets': num_targets,
                'dt': dt,
                'speeds': [float(v) for v in tgt['speeds']],
                'start_times': [float(v) for v in tgt['start_times']],
                **{
                    f'waypoints_{i}': [float(v) for v in tgt[f'waypoints_{i}']]
                    for i in range(num_targets)
                },
            }],
            output='screen',
        ),
    ]

    for pos in _hex_grid_positions(grid_size, node_spacing):
        sid = pos['sensor_id']
        nodes.append(Node(
            package='sensor_agent',
            executable='sensor_agent_node',
            name=f'sensor_agent_{sid}',
            parameters=[{
                'sensor_id': sid,
                'pos_x': pos['x'],
                'pos_y': pos['y'],
                'detection_radius': detection_radius,
                'communication_range': comm_range,
                'num_targets': num_targets,
                'dt': dt,
                'ekf_r_std': ekf_r_std,
                'ekf_q_std': ekf_q_std,
                'ekf_convergence_threshold': ekf_thresh,
                'sensor_max_speed': sensor_max_speed,
                'bidding_window': bidding_window,
                'max_interceptors': max_interceptors,
                'handover_lookahead': handover_lookahead,
                'grid_size': grid_size,
                'node_spacing': node_spacing,
            }],
            output='screen',
        ))

    return LaunchDescription(nodes)