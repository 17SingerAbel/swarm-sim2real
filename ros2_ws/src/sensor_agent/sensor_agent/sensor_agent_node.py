import math

import numpy as np
import rclpy
from rclpy.node import Node
from rclpy.qos import DurabilityPolicy, HistoryPolicy, QoSProfile, ReliabilityPolicy

from swarm_interfaces.msg import (
    AcquisitionMsg,
    BidMsg,
    CommitmentMsg,
    HandoverRequest,
    SensorState,
    TargetEstimate,
    TargetState,
)

from sensor_agent.assignment import solve_assignment
from sensor_agent.bidding import calculate_bid_cost
from sensor_agent.ekf import TargetEKF


def _dist(a, b):
    return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)


class SensorAgentNode(Node):
    def __init__(self):
        super().__init__('sensor_agent')

        # ---- Parameters ----
        self.declare_parameter('sensor_id', 0)
        self.declare_parameter('pos_x', 0.0)
        self.declare_parameter('pos_y', 0.0)
        self.declare_parameter('detection_radius', 1.5)
        self.declare_parameter('num_targets', 3)
        self.declare_parameter('dt', 0.1)
        self.declare_parameter('ekf_r_std', 0.3)
        self.declare_parameter('ekf_q_std', 0.5)
        self.declare_parameter('ekf_convergence_threshold', 0.006)
        self.declare_parameter('sensor_max_speed', 0.75)
        # M4
        self.declare_parameter('communication_range', 18.0)
        self.declare_parameter('bidding_window', 0.5)
        self.declare_parameter('max_interceptors', 2)
        self.declare_parameter('grid_size', 5)
        self.declare_parameter('node_spacing', 12.0)
        self.declare_parameter('handover_lookahead', 2.0)

        self.sensor_id = self.get_parameter('sensor_id').value
        self.pos_x = self.get_parameter('pos_x').value
        self.pos_y = self.get_parameter('pos_y').value
        self.home_x = self.pos_x
        self.home_y = self.pos_y
        self.r_d = self.get_parameter('detection_radius').value
        self.max_speed = self.get_parameter('sensor_max_speed').value
        self.num_targets = self.get_parameter('num_targets').value
        self.dt = self.get_parameter('dt').value
        r_std = self.get_parameter('ekf_r_std').value
        q_std = self.get_parameter('ekf_q_std').value
        ekf_thresh = self.get_parameter('ekf_convergence_threshold').value
        self.r_c = self.get_parameter('communication_range').value
        self.bidding_window = self.get_parameter('bidding_window').value
        self.max_interceptors = self.get_parameter('max_interceptors').value
        self.handover_lookahead = self.get_parameter('handover_lookahead').value
        grid_size = self.get_parameter('grid_size').value
        node_spacing = self.get_parameter('node_spacing').value

        # WSN dimensions used to normalize bid costs
        dy = node_spacing * math.sqrt(3) / 2
        self._wsn_width = (grid_size - 1) * node_spacing
        self._wsn_height = (grid_size - 1) * dy

        # ---- FSM state ----
        self.fsm_state = 'IDLE'
        self.role = 'NONE'
        self.assigned_target_id = -1
        self.target_positions = {}   # {target_id: (x, y)}

        # ---- EKF ----
        self._ekf_params = (r_std, q_std, ekf_thresh)
        self.ekfs = {}
        self._rng = np.random.default_rng(seed=self.sensor_id)
        self._r_std = r_std

        # ---- M4: handover protocol state ----
        self._handover_fired = set()   # target_ids already requested
        self._bid_buffers = {}         # request_id → [BidMsg]
        self._active_requests = {}     # request_id → HandoverRequest
        self._bidding_timers = {}      # request_id → timer handle
        self._intercept_goal = None    # (x, y) for INTERCEPTING movement
        self._intercept_target_id = -1
        self._intercept_request_id = ''
        self._my_requests = {}         # request_id → target_id (requests WE fired)
        self._commitment_counts = {}   # request_id → int (commitments received so far)

        # ---- QoS ----
        event_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        # ---- Subscriptions ----
        for i in range(self.num_targets):
            self.create_subscription(
                TargetState,
                f'/targets/target_{i}/ground_truth',
                lambda msg, tid=i: self._target_cb(msg, tid),
                10,
            )
        self.create_subscription(
            HandoverRequest, '/swarm/handover_request',
            self._handover_request_cb, event_qos,
        )
        self.create_subscription(BidMsg, '/swarm/bids', self._bid_cb, event_qos)
        self.create_subscription(
            CommitmentMsg, '/swarm/commitment',
            self._commitment_cb, event_qos,
        )
        self.create_subscription(
            AcquisitionMsg, '/swarm/acquisition',
            self._acquisition_cb, event_qos,
        )

        # ---- Publishers ----
        self.state_pub = self.create_publisher(
            SensorState, f'/sensors/sensor_{self.sensor_id}/state', 10)
        self.estimate_pub = self.create_publisher(
            TargetEstimate, f'/sensors/sensor_{self.sensor_id}/ekf_estimate', 10)
        self._handover_pub = self.create_publisher(
            HandoverRequest, '/swarm/handover_request', event_qos)
        self._bid_pub = self.create_publisher(BidMsg, '/swarm/bids', event_qos)
        self._commitment_pub = self.create_publisher(
            CommitmentMsg, '/swarm/commitment', event_qos)
        self._acquisition_pub = self.create_publisher(
            AcquisitionMsg, '/swarm/acquisition', event_qos)

        self.create_timer(self.dt, self._fsm_step)
        self.get_logger().info(
            f'sensor_agent {self.sensor_id} ready at '
            f'({self.pos_x:.1f}, {self.pos_y:.1f}), r_d={self.r_d}, r_c={self.r_c}'
        )

    # ------------------------------------------------------------------
    # Ground truth callback
    # ------------------------------------------------------------------

    def _target_cb(self, msg, target_id):
        self.target_positions[target_id] = (msg.x, msg.y)

    # ------------------------------------------------------------------
    # FSM step  (runs every dt seconds)
    # ------------------------------------------------------------------

    def _fsm_step(self):
        in_range = self._in_range()

        for ekf in self.ekfs.values():
            ekf.predict()

        for tid in in_range:
            tx, ty = self.target_positions[tid]
            zx, zy = self._noisy_measurement(tx, ty)
            if tid not in self.ekfs:
                ekf = self._make_ekf()
                ekf.initialize(zx, zy)
                self.ekfs[tid] = ekf
            else:
                self.ekfs[tid].update(zx, zy)

        if self.fsm_state == 'IDLE':
            if in_range:
                self.assigned_target_id = in_range[0]
                self.fsm_state = 'DETECTING'
                self.get_logger().info(
                    f'IDLE → DETECTING  target={self.assigned_target_id}')

        elif self.fsm_state == 'DETECTING':
            if self.assigned_target_id in in_range:
                self.fsm_state = 'TRACKING'
                self.role = 'PRIMARY_TRACKER'
                self.get_logger().info(
                    f'DETECTING → TRACKING  target={self.assigned_target_id}')
            else:
                self.assigned_target_id = -1
                self.fsm_state = 'IDLE'
                self.get_logger().info('DETECTING → IDLE  (target left range)')

        elif self.fsm_state == 'TRACKING':
            if self.assigned_target_id not in in_range:
                self._handover_fired.discard(self.assigned_target_id)
                self.role = 'NONE'
                self.assigned_target_id = -1
                self.fsm_state = 'IDLE'
                self.get_logger().info('TRACKING → IDLE  (target lost)')
            else:
                self._check_handover_trigger()

        elif self.fsm_state == 'INTERCEPTING':
            if self._intercept_target_id in in_range:
                self.assigned_target_id = self._intercept_target_id
                self.role = 'SECONDARY_TRACKER'
                request_id = self._intercept_request_id
                self._intercept_goal = None
                self._intercept_target_id = -1
                self._intercept_request_id = ''
                self.fsm_state = 'TRACKING'
                self.get_logger().info(
                    f'INTERCEPTING → TRACKING  target={self.assigned_target_id}')
                self._publish_acquisition(request_id, self.assigned_target_id)

        elif self.fsm_state == 'RETURNING_HOME':
            if _dist((self.pos_x, self.pos_y), (self.home_x, self.home_y)) < 0.5:
                self.pos_x = self.home_x
                self.pos_y = self.home_y
                self.role = 'NONE'
                self.assigned_target_id = -1
                self.fsm_state = 'IDLE'
                self.get_logger().info('RETURNING_HOME → IDLE')

        self._update_position()
        self._publish_state()
        self._publish_estimates()

    # ------------------------------------------------------------------
    # Handover trigger
    # ------------------------------------------------------------------

    def _check_handover_trigger(self):
        tid = self.assigned_target_id
        if tid in self._handover_fired:
            return
        ekf = self.ekfs.get(tid)
        if ekf is None or not ekf.converged:
            return
        pred_x = ekf.x[0] + ekf.x[2] * self.handover_lookahead
        pred_y = ekf.x[1] + ekf.x[3] * self.handover_lookahead
        if _dist((pred_x, pred_y), (self.pos_x, self.pos_y)) > self.r_d:
            self._fire_handover_request(tid, ekf)

    def _fire_handover_request(self, target_id, ekf):
        now_sec = self.get_clock().now().nanoseconds / 1e9
        t_loss = self.handover_lookahead

        msg = HandoverRequest()
        msg.calling_target_id = target_id
        msg.requesting_sensor_id = self.sensor_id
        msg.requesting_sensor_x = self.pos_x
        msg.requesting_sensor_y = self.pos_y
        msg.target_x = float(ekf.x[0])
        msg.target_y = float(ekf.x[1])
        msg.target_vx = float(ekf.x[2])
        msg.target_vy = float(ekf.x[3])
        msg.intercept_x = float(ekf.x[0] + ekf.x[2] * t_loss)
        msg.intercept_y = float(ekf.x[1] + ekf.x[3] * t_loss)
        msg.predicted_loss_time = now_sec + t_loss
        msg.stamp = self.get_clock().now().to_msg()
        msg.request_id = f'T{target_id}_S{self.sensor_id}_t{now_sec:.1f}'

        self._handover_pub.publish(msg)
        self._handover_fired.add(target_id)
        self._my_requests[msg.request_id] = target_id
        self._commitment_counts[msg.request_id] = 0
        self.get_logger().info(
            f'HandoverRequest: {msg.request_id}  '
            f'intercept=({msg.intercept_x:.1f}, {msg.intercept_y:.1f})')

    # ------------------------------------------------------------------
    # Handover protocol callbacks
    # ------------------------------------------------------------------

    def _handover_request_cb(self, msg):
        if msg.requesting_sensor_id == self.sensor_id:
            return

        # r_c gate: requester position is in the message itself
        if _dist((self.pos_x, self.pos_y),
                 (msg.requesting_sensor_x, msg.requesting_sensor_y)) > self.r_c:
            return

        # Skip if already committed elsewhere
        if self.fsm_state == 'INTERCEPTING':
            return
        if self.fsm_state == 'TRACKING' and self.assigned_target_id != msg.calling_target_id:
            return

        ekf = self.ekfs.get(msg.calling_target_id)
        if ekf is not None and ekf.initialized:
            confidence = 1.0 if ekf.converged else 0.3
            target_vel = (float(ekf.x[2]), float(ekf.x[3]))
            target_current_pos = (float(ekf.x[0]), float(ekf.x[1]))
        else:
            confidence = 0.3
            target_vel = (float(msg.target_vx), float(msg.target_vy))
            target_current_pos = (float(msg.target_x), float(msg.target_y))

        cost = calculate_bid_cost(
            sensor_pos=(self.pos_x, self.pos_y),
            home_pos=(self.home_x, self.home_y),
            intercept_point=(msg.intercept_x, msg.intercept_y),
            target_vel=target_vel,
            confidence=confidence,
            target_current_pos=target_current_pos,
            wsn_width=self._wsn_width,
            wsn_height=self._wsn_height,
            sensor_velocity=self.max_speed,
        )

        bid = BidMsg()
        bid.request_id = msg.request_id
        bid.bidder_sensor_id = self.sensor_id
        bid.target_id = msg.calling_target_id
        bid.bid_cost = cost
        bid.stamp = self.get_clock().now().to_msg()
        self._bid_pub.publish(bid)

        self.get_logger().debug(
            f's{self.sensor_id}: bid={cost:.3f} for {msg.request_id}')

        rid = msg.request_id
        if rid not in self._bid_buffers:
            self._bid_buffers[rid] = []
            self._active_requests[rid] = msg
            timer = self.create_timer(
                self.bidding_window,
                lambda r=rid: self._bidding_window_expired(r),
            )
            self._bidding_timers[rid] = timer

    def _bid_cb(self, msg):
        if msg.request_id in self._bid_buffers:
            self._bid_buffers[msg.request_id].append(msg)

    def _bidding_window_expired(self, request_id):
        timer = self._bidding_timers.pop(request_id, None)
        if timer is not None:
            timer.cancel()

        bids = self._bid_buffers.pop(request_id, [])
        req = self._active_requests.pop(request_id, None)
        if req is None or not bids:
            return

        target_id = req.calling_target_id
        all_bidders = {b.bidder_sensor_id: b.bid_cost for b in bids}
        candidates = sorted(all_bidders.keys())
        cost_matrix = [[all_bidders[s]] for s in candidates]

        result = solve_assignment(
            calling_targets=[target_id],
            candidates=candidates,
            cost_matrix=cost_matrix,
            slots_per_target=self.max_interceptors,
        )
        winners = result.get(target_id, [])

        self.get_logger().info(
            f's{self.sensor_id}: assignment {request_id}  '
            f'candidates={candidates}  winners={winners}')

        if self.sensor_id not in winners:
            return

        self._intercept_goal = (req.intercept_x, req.intercept_y)
        self._intercept_target_id = target_id
        self._intercept_request_id = request_id
        self.assigned_target_id = target_id
        self.role = 'INTERCEPTOR_CANDIDATE'
        self.fsm_state = 'INTERCEPTING'
        self.get_logger().info(
            f's{self.sensor_id}: → INTERCEPTING T{target_id} '
            f'goal=({req.intercept_x:.1f}, {req.intercept_y:.1f})')

        commit = CommitmentMsg()
        commit.request_id = request_id
        commit.sensor_id = self.sensor_id
        commit.assigned_target_id = target_id
        commit.intercept_x = req.intercept_x
        commit.intercept_y = req.intercept_y
        commit.stamp = self.get_clock().now().to_msg()
        self._commitment_pub.publish(commit)

    def _commitment_cb(self, msg):
        if msg.sensor_id == self.sensor_id:
            return
        self.get_logger().debug(
            f's{self.sensor_id}: s{msg.sensor_id} committed to T{msg.assigned_target_id}')

        # Commitments mean "accepted assignment"; acquisition completes the handover.
        rid = msg.request_id
        if rid not in self._my_requests:
            return
        self._commitment_counts[rid] = self._commitment_counts.get(rid, 0) + 1

    def _publish_acquisition(self, request_id, target_id):
        if not request_id:
            return

        msg = AcquisitionMsg()
        msg.request_id = request_id
        msg.sensor_id = self.sensor_id
        msg.target_id = target_id
        msg.x = self.pos_x
        msg.y = self.pos_y
        msg.stamp = self.get_clock().now().to_msg()
        self._acquisition_pub.publish(msg)
        self.get_logger().info(
            f's{self.sensor_id}: Acquisition {request_id} T{target_id}')

    def _acquisition_cb(self, msg):
        if msg.sensor_id == self.sensor_id:
            return

        rid = msg.request_id

        if (rid in self._my_requests
                and self.fsm_state == 'TRACKING'
                and self.assigned_target_id == self._my_requests[rid]):
            self.get_logger().info(
                f's{self.sensor_id}: acquisition by s{msg.sensor_id} '
                f'→ RETURNING_HOME (T{self.assigned_target_id})')
            self._handover_fired.discard(self.assigned_target_id)
            self.role = 'NONE'
            self.assigned_target_id = -1
            self.fsm_state = 'RETURNING_HOME'
            self._my_requests.pop(rid, None)
            self._commitment_counts.pop(rid, None)
            return

        if (self.fsm_state == 'INTERCEPTING'
                and self._intercept_request_id == rid
                and self._intercept_target_id == msg.target_id):
            self.get_logger().info(
                f's{self.sensor_id}: acquisition by s{msg.sensor_id} '
                f'for {rid} → RETURNING_HOME')
            self._intercept_goal = None
            self._intercept_target_id = -1
            self._intercept_request_id = ''
            self.role = 'NONE'
            self.assigned_target_id = -1
            self.fsm_state = 'RETURNING_HOME'

    # ------------------------------------------------------------------
    # Movement
    # ------------------------------------------------------------------

    def _update_position(self):
        if self.fsm_state == 'TRACKING' and self.assigned_target_id in self.ekfs:
            ekf = self.ekfs[self.assigned_target_id]
            if ekf.initialized:
                self._move_toward(ekf.x[0], ekf.x[1])
        elif self.fsm_state == 'INTERCEPTING' and self._intercept_goal is not None:
            self._move_toward(self._intercept_goal[0], self._intercept_goal[1])
        else:
            self._move_toward(self.home_x, self.home_y)

    def _move_toward(self, goal_x, goal_y):
        dx = goal_x - self.pos_x
        dy = goal_y - self.pos_y
        d = math.sqrt(dx * dx + dy * dy)
        if d < 1e-6:
            return
        step = min(self.max_speed * self.dt, d)
        self.pos_x += (dx / d) * step
        self.pos_y += (dy / d) * step

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _in_range(self):
        return [
            tid for tid, (x, y) in self.target_positions.items()
            if _dist((x, y), (self.pos_x, self.pos_y)) <= self.r_d
        ]

    def _make_ekf(self):
        r_std, q_std, thresh = self._ekf_params
        return TargetEKF(self.dt, r_std, q_std, thresh)

    def _noisy_measurement(self, true_x, true_y):
        noise = self._rng.normal(0.0, self._r_std, size=2)
        return true_x + noise[0], true_y + noise[1]

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
        now = self.get_clock().now().to_msg()
        for tid, ekf in self.ekfs.items():
            if not ekf.initialized:
                continue
            msg = TargetEstimate()
            msg.sensor_id = self.sensor_id
            msg.target_id = tid
            msg.x = float(ekf.x[0])
            msg.y = float(ekf.x[1])
            msg.vx = float(ekf.x[2])
            msg.vy = float(ekf.x[3])
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
