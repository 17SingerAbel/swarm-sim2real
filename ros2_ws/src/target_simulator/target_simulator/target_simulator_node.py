import math
import rclpy
from rclpy.node import Node
from swarm_interfaces.msg import TargetState


class TargetSimulatorNode(Node):
    def __init__(self):
        super().__init__('target_simulator')

        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)
        self.declare_parameter('speeds', [1.0, 1.1, 1.2])
        self.declare_parameter('start_times', [0.0, 4.0, 6.5])

        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value
        self.speeds = list(self.get_parameter('speeds').value)
        self.start_times = list(self.get_parameter('start_times').value)

        # Waypoints as flattened [x0,y0,x1,y1,...] — default matches MATLAB V47 lines 158-160
        _default_wps = [
            [0.0, -0.308, 10.0, -0.308, 25.0, 3.692, 36.0, 9.692, 48.0, 22.692, 55.0, 32.692, 70.0, 44.692],
            [0.0, 41.56, 10.0, 41.56, 25.0, 37.56, 36.0, 31.56, 48.0, 18.56, 55.0, 8.56, 70.0, -3.4],
            [0.0, 9.692, 10.0, 9.692, 25.0, 13.692, 36.0, 19.692, 48.0, 32.692, 55.0, 42.692, 70.0, 54.692],
        ]

        self.waypoints = []
        for i in range(self.num_targets):
            default = _default_wps[i] if i < len(_default_wps) else _default_wps[-1]
            self.declare_parameter(f'waypoints_{i}', default)
            flat = list(self.get_parameter(f'waypoints_{i}').value)
            wps = [[flat[j], flat[j + 1]] for j in range(0, len(flat), 2)]
            self.waypoints.append(wps)

        # Each target starts at its first waypoint
        self.sim_time = 0.0
        self.states = []
        for i in range(self.num_targets):
            wp0 = self.waypoints[i][0]
            self.states.append({
                'x': wp0[0], 'y': wp0[1],
                'vx': 0.0, 'vy': 0.0,
                'wp_idx': 0,
            })

        self.pubs = []
        for i in range(self.num_targets):
            pub = self.create_publisher(TargetState, f'/targets/target_{i}/ground_truth', 10)
            self.pubs.append(pub)

        self.create_timer(self.dt, self.tick)
        self.get_logger().info(
            f'target_simulator ready — {self.num_targets} targets | waypoint mode | '
            f'speeds={self.speeds} start_times={self.start_times}'
        )

    def tick(self):
        self.sim_time += self.dt

        for i in range(self.num_targets):
            s = self.states[i]
            wps = self.waypoints[i]
            speed = self.speeds[i]

            if self.sim_time >= self.start_times[i] and s['wp_idx'] < len(wps) - 1:
                next_wp = wps[s['wp_idx'] + 1]
                dx = next_wp[0] - s['x']
                dy = next_wp[1] - s['y']
                dist = math.sqrt(dx * dx + dy * dy)
                step = speed * self.dt

                if dist <= step:
                    # Snap to waypoint and advance
                    s['x'] = next_wp[0]
                    s['y'] = next_wp[1]
                    s['wp_idx'] += 1
                    if s['wp_idx'] < len(wps) - 1:
                        nx = wps[s['wp_idx'] + 1]
                        dx2 = nx[0] - s['x']
                        dy2 = nx[1] - s['y']
                        d2 = math.sqrt(dx2 * dx2 + dy2 * dy2)
                        s['vx'] = (dx2 / d2) * speed if d2 > 0 else 0.0
                        s['vy'] = (dy2 / d2) * speed if d2 > 0 else 0.0
                    else:
                        s['vx'] = 0.0
                        s['vy'] = 0.0
                else:
                    s['x'] += (dx / dist) * step
                    s['y'] += (dy / dist) * step
                    s['vx'] = (dx / dist) * speed
                    s['vy'] = (dy / dist) * speed

            msg = TargetState()
            msg.target_id = i
            msg.x = s['x']
            msg.y = s['y']
            msg.vx = s['vx']
            msg.vy = s['vy']
            msg.stamp = self.get_clock().now().to_msg()
            self.pubs[i].publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = TargetSimulatorNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()