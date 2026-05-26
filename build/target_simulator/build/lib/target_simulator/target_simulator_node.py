import rclpy
from rclpy.node import Node
from swarm_interfaces.msg import TargetState


class TargetSimulatorNode(Node):
    def __init__(self):
        super().__init__('target_simulator')

        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)

        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value

        # Target 0 starts at x=-5, moves right at vx=1.0
        # → enters sensor 0's detection range (r_d=1.5) at t≈3.5s
        # → exits at t≈6.5s — FSM transitions will be visible
        self.states = [
            {'x': -5.0, 'y':  0.0, 'vx': 1.0, 'vy': 0.0},
            {'x': 30.0, 'y': 20.0, 'vx': -0.8, 'vy': 0.2},
            {'x': 15.0, 'y': -8.0, 'vx': 0.3, 'vy': 1.1},
        ]

        self.pubs = []
        for i in range(self.num_targets):
            pub = self.create_publisher(TargetState, f'/targets/target_{i}/ground_truth', 10)
            self.pubs.append(pub)

        self.create_timer(self.dt, self.tick)
        self.get_logger().info(f'target_simulator ready — {self.num_targets} targets')

    def tick(self):
        for i in range(self.num_targets):
            s = self.states[i]
            s['x'] += s['vx'] * self.dt
            s['y'] += s['vy'] * self.dt

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
