import rclpy
from rclpy.node import Node
from swarm_interfaces.msg import TargetState


class TargetSimulatorNode(Node):
    def __init__(self):
        super().__init__('target_simulator')

        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)
        self.declare_parameter('init_x',  [-5.0,  30.0,  15.0])
        self.declare_parameter('init_y',  [ 0.0,  20.0,  -8.0])
        self.declare_parameter('init_vx', [ 1.0,  -0.8,   0.3])
        self.declare_parameter('init_vy', [ 0.0,   0.2,   1.1])

        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value
        init_x  = self.get_parameter('init_x').value
        init_y  = self.get_parameter('init_y').value
        init_vx = self.get_parameter('init_vx').value
        init_vy = self.get_parameter('init_vy').value

        self.states = [
            {'x': init_x[i], 'y': init_y[i], 'vx': init_vx[i], 'vy': init_vy[i]}
            for i in range(self.num_targets)
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
