import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    params = os.path.join(
        get_package_share_directory('swarm_bringup'),
        'config', 'sim_m1_params.yaml',
    )

    return LaunchDescription([
        Node(
            package='target_simulator',
            executable='target_simulator_node',
            name='target_simulator',
            parameters=[params],
            output='screen',
        ),
        Node(
            package='sensor_agent',
            executable='sensor_agent_node',
            name='sensor_agent_0',
            parameters=[params],
            output='screen',
        ),
    ])