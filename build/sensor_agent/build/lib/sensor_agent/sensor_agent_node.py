import math

import numpy as np
import rclpy
from rclpy.node import Node

from swarm_interfaces.msg import TargetEstimate, TargetState, SensorState

from sensor_agent.ekf import TargetEKF


class SensorAgentNode(Node):
    def __init__(self):
        super().__init__('sensor_agent')

        self.declare_parameter('sensor_id', 0)
        self.declare_parameter('pos_x', 0.0)
        self.declare_parameter('pos_y', 0.0)
        self.declare_parameter('detection_radius', 1.5)
        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)
        self.declare_parameter('ekf_r_std', 0.3)          # measurement noise std dev
        self.declare_parameter('ekf_q_std', 0.5)          # process noise std dev
        self.declare_parameter('ekf_convergence_threshold', 0.006)
        self.declare_parameter('sensor_max_speed', 0.8)   # units/s

        self.sensor_id = self.get_parameter('sensor_id').value
        self.pos_x = self.get_parameter('pos_x').value
        self.pos_y = self.get_parameter('pos_y').value
        self.home_x = self.pos_x   # home position never changes
        self.home_y = self.pos_y
        self.r_d = self.get_parameter('detection_radius').value
        self.max_speed = self.get_parameter('sensor_max_speed').value
        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value
        r_std = self.get_parameter('ekf_r_std').value
        q_std = self.get_parameter('ekf_q_std').value
        ekf_thresh = self.get_parameter('ekf_convergence_threshold').value

        self.fsm_state = 'IDLE'
        self.role = 'NONE'
        self.assigned_target_id = -1
        self.target_positions = {}   # {target_id: (x, y)} — raw ground truth

        # One EKF instance per target (created on first detection)
        self._ekf_params = (r_std, q_std, ekf_thresh)
        self.ekfs = {}               # {target_id: TargetEKF}

        # Seeded RNG so runs with fixed params are reproducible
        self._rng = np.random.default_rng(seed=self.sensor_id)
        self._r_std = r_std

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
        self.estimate_pub = self.create_publisher(
            TargetEstimate,
            f'/sensors/sensor_{self.sensor_id}/ekf_estimate',
            10,
        )

        self.create_timer(self.dt, self._fsm_step)
        self.get_logger().info(
            f'sensor_agent {self.sensor_id} ready at '
            f'({self.pos_x:.1f}, {self.pos_y:.1f}), r_d={self.r_d}'
        )

    # ------------------------------------------------------------------
    # Subscriptions
    # ------------------------------------------------------------------

    def _target_cb(self, msg, target_id):
        self.target_positions[target_id] = (msg.x, msg.y)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _in_range(self):
        """Return list of target_ids currently within detection radius."""
        result = []
        for tid, (x, y) in self.target_positions.items():
            dist = math.sqrt((x - self.pos_x) ** 2 + (y - self.pos_y) ** 2)
            if dist <= self.r_d:
                result.append(tid)
        return result

    def _make_ekf(self):
        r_std, q_std, thresh = self._ekf_params
        return TargetEKF(self.dt, r_std, q_std, thresh)

    def _move_toward(self, goal_x, goal_y):
        """Move sensor one dt step toward goal, capped at max_speed."""
        dx = goal_x - self.pos_x
        dy = goal_y - self.pos_y
        dist = math.sqrt(dx * dx + dy * dy)
        if dist < 1e-6:
            return
        step = min(self.max_speed * self.dt, dist)
        self.pos_x += (dx / dist) * step
        self.pos_y += (dy / dist) * step

    def _noisy_measurement(self, true_x, true_y):
        """Add Gaussian noise to a ground-truth position (simulates sensor hardware)."""
        noise = self._rng.normal(0.0, self._r_std, size=2)
        return true_x + noise[0], true_y + noise[1]

    # ------------------------------------------------------------------
    # FSM + EKF step
    # ------------------------------------------------------------------

    def _fsm_step(self):
        in_range = self._in_range()

        # --- EKF predict for all initialized filters ---
        for ekf in self.ekfs.values():
            ekf.predict()

        # --- EKF update for targets currently in range ---
        for tid in in_range:
            tx, ty = self.target_positions[tid]
            zx, zy = self._noisy_measurement(tx, ty)

            if tid not in self.ekfs:
                # First detection: create and initialize the filter
                ekf = self._make_ekf()
                ekf.initialize(zx, zy)
                self.ekfs[tid] = ekf
                self.get_logger().debug(
                    f's{self.sensor_id}: EKF initialized for target {tid}'
                )
            else:
                self.ekfs[tid].update(zx, zy)

        # --- FSM transitions ---
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

        # --- Move sensor ---
        if self.fsm_state == 'TRACKING' and self.assigned_target_id in self.ekfs:
            ekf = self.ekfs[self.assigned_target_id]
            if ekf.initialized:
                self._move_toward(ekf.x[0], ekf.x[1])
        else:
            self._move_toward(self.home_x, self.home_y)

        # --- Publish ---
        self._publish_state()
        self._publish_estimates()

    # ------------------------------------------------------------------
    # Publishers
    # ------------------------------------------------------------------

    def _publish_state(self):
        msg = SensorState()
        msg.sensor_id = self.sensor_id
        msg.fsm_state = self.fsm_state
        msg.role = self.role
        msg.assigned_target_id = self.assigned_target_id
        msg.pos_x = self.pos_x
        msg.pos_y = self.pos_y
        msg.stamp = self.get_clock().now().to_msg()
        self.state_pub.publish(msg)

    def _publish_estimates(self):
        """Publish one TargetEstimate per initialized EKF (all detected targets)."""
        now = self.get_clock().now().to_msg()
        for tid, ekf in self.ekfs.items():
            if not ekf.initialized:
                continue
            msg = TargetEstimate()
            msg.sensor_id = self.sensor_id
            msg.target_id = tid
            msg.x = ekf.x[0]
            msg.y = ekf.x[1]
            msg.vx = ekf.x[2]
            msg.vy = ekf.x[3]
            cov = ekf.covariance_diag
            msg.covariance = [cov[0], cov[1], cov[2], cov[3]]
            msg.ekf_converged = ekf.converged
            msg.stamp = now
            self.estimate_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = SensorAgentNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()