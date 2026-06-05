import math
import os
import yaml

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def _hex_grid_positions(grid_size, node_spacing):
    dy = node_spacing * math.sqrt(3) / 2
    positions = []
    for col in range(grid_size):
        for row in range(grid_size):
            x = col * node_spacing
            y = row * dy + (node_spacing / 2.0 if col % 2 == 1 else 0.0)
            positions.append({
                'sensor_id': col * grid_size + row,
                'x': x,
                'y': y,
            })
    return positions


def generate_launch_description():
    config_path = os.path.join(
        get_package_share_directory('swarm_bringup'),
        'config', 'sim_m3_params.yaml',
    )

    with open(config_path, 'r') as f:
        cfg = yaml.safe_load(f)

    swarm = cfg['swarm']
    grid_size = int(swarm['grid_size'])
    node_spacing = float(swarm['node_spacing'])
    detection_radius = float(swarm['detection_radius'])
    num_targets = int(swarm['num_targets'])
    dt = float(swarm['dt'])
    ekf_r_std = float(swarm['ekf_r_std'])
    ekf_q_std = float(swarm['ekf_q_std'])
    ekf_thresh = float(swarm['ekf_convergence_threshold'])
    sensor_max_speed = float(swarm['sensor_max_speed'])

    tgt = cfg['targets']

    nodes = [
        Node(
            package='target_simulator',
            executable='target_simulator_node',
            name='target_simulator',
            parameters=[{
                'num_targets': num_targets,
                'dt': dt,
                'init_x':  [float(v) for v in tgt['init_x']],
                'init_y':  [float(v) for v in tgt['init_y']],
                'init_vx': [float(v) for v in tgt['init_vx']],
                'init_vy': [float(v) for v in tgt['init_vy']],
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
                'num_targets': num_targets,
                'dt': dt,
                'ekf_r_std': ekf_r_std,
                'ekf_q_std': ekf_q_std,
                'ekf_convergence_threshold': ekf_thresh,
                'sensor_max_speed': sensor_max_speed,
            }],
            output='screen',
        ))

    return LaunchDescription(nodes)