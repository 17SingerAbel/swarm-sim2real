import math
import rclpy
from rclpy.node import Node
from swarm_interfaces.msg import TargetState, SensorState


class SensorAgentNode(Node):
    def __init__(self):
        super().__init__('sensor_agent')

        self.declare_parameter('sensor_id', 0)
        self.declare_parameter('pos_x', 0.0)
        self.declare_parameter('pos_y', 0.0)
        self.declare_parameter('detection_radius', 1.5)
        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)

        self.sensor_id = self.get_parameter('sensor_id').value
        self.pos_x = self.get_parameter('pos_x').value
        self.pos_y = self.get_parameter('pos_y').value
        self.r_d = self.get_parameter('detection_radius').value
        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value

        self.fsm_state = 'IDLE'
        self.role = 'NONE'
        self.assigned_target_id = -1
        self.target_positions = {}  # {target_id: (x, y)}

        for i in range(self.num_targets):
            self.create_subscription(
                TargetState,
                f'/targets/target_{i}/ground_truth',
                lambda msg, tid=i: self._target_cb(msg, tid),
                10,
            )

        self.state_pub = self.create_publisher(
            SensorState,
            f'/sensors/sensor_{self.sensor_id}/state',
            10,
        )

        self.create_timer(self.dt, self._fsm_step)
        self.get_logger().info(
            f'sensor_agent {self.sensor_id} ready at '
            f'({self.pos_x}, {self.pos_y}), r_d={self.r_d}'
        )

    def _target_cb(self, msg, target_id):
        self.target_positions[target_id] = (msg.x, msg.y)

    def _in_range(self):
        result = []
        for tid, (x, y) in self.target_positions.items():
            dist = math.sqrt((x - self.pos_x) ** 2 + (y - self.pos_y) ** 2)
            if dist <= self.r_d:
                result.append(tid)
        return result

    def _fsm_step(self):
        in_range = self._in_range()

        if self.fsm_state == 'IDLE':
            if in_range:
                self.assigned_target_id = in_range[0]
                self.fsm_state = 'DETECTING'
                self.get_logger().info(
                    f'IDLE → DETECTING  target={self.assigned_target_id}'
                )

        elif self.fsm_state == 'DETECTING':
            if self.assigned_target_id in in_range:
                self.fsm_state = 'TRACKING'
                self.get_logger().info(
                    f'DETECTING → TRACKING  target={self.assigned_target_id}'
                )
            else:
                self.fsm_state = 'IDLE'
                self.assigned_target_id = -1
                self.get_logger().info('DETECTING → IDLE  (target left range)')

        elif self.fsm_state == 'TRACKING':
            if self.assigned_target_id not in in_range:
                self.fsm_state = 'IDLE'
                self.assigned_target_id = -1
                self.get_logger().info('TRACKING → IDLE  (target left range)')

        self._publish()

    def _publish(self):
        msg = SensorState()
        msg.sensor_id = self.sensor_id
        msg.fsm_state = self.fsm_state
        msg.role = self.role
        msg.assigned_target_id = self.assigned_target_id
        msg.pos_x = self.pos_x
        msg.pos_y = self.pos_y
        msg.stamp = self.get_clock().now().to_msg()
        self.state_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = SensorAgentNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
