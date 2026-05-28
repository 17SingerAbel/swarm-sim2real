"""Per-target 4-state constant-velocity Extended Kalman Filter.

State vector: [px, py, vx, vy]
Measurement:  [px, py]  (position-only, gated by detection radius in the node)

Convergence is declared when velocity covariance Pvx and Pvy both drop below
ekf_convergence_threshold (= 0.006 from MATLAB EKF_VELOCITY_CONVERGENCE_THRESHOLD).
"""

import numpy as np


class TargetEKF:

    def __init__(self, dt: float, r_std: float, q_std: float,
                 convergence_threshold: float = 0.006):
        """
        dt    : time step (seconds)
        r_std : measurement noise std dev (units)
        q_std : process noise std dev (units/s)
        """
        self.dt = dt
        self.threshold = convergence_threshold

        # Constant-velocity transition matrix
        self.F = np.array([
            [1.0, 0.0,  dt, 0.0],
            [0.0, 1.0, 0.0,  dt],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0],
        ])

        # Observation matrix: we measure [px, py] only
        self.H = np.array([
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
        ])

        # Measurement noise covariance
        self.R = np.diag([r_std ** 2, r_std ** 2])

        # Process noise covariance (diagonal approximation)
        self.Q = np.diag([
            (q_std * dt) ** 2,   # px
            (q_std * dt) ** 2,   # py
            q_std ** 2,          # vx
            q_std ** 2,          # vy
        ])

        self.x = None          # state [px, py, vx, vy]
        self.P = None          # 4x4 covariance
        self.initialized = False
        self.converged = False

    def initialize(self, meas_x: float, meas_y: float):
        """Bootstrap the filter from the first position measurement."""
        self.x = np.array([meas_x, meas_y, 0.0, 0.0])
        # High initial velocity uncertainty; position seeded from measurement
        self.P = np.diag([self.R[0, 0], self.R[1, 1], 100.0, 100.0])
        self.initialized = True
        self.converged = False

    def predict(self):
        """Propagate state and covariance one time step (no measurement)."""
        if not self.initialized:
            return
        self.x = self.F @ self.x
        self.P = self.F @ self.P @ self.F.T + self.Q

    def update(self, meas_x: float, meas_y: float):
        """Kalman update with a new position measurement."""
        if not self.initialized:
            return
        z = np.array([meas_x, meas_y])
        y = z - self.H @ self.x                     # innovation
        S = self.H @ self.P @ self.H.T + self.R     # innovation covariance
        K = self.P @ self.H.T @ np.linalg.inv(S)    # Kalman gain
        self.x = self.x + K @ y
        self.P = (np.eye(4) - K @ self.H) @ self.P
        self._check_convergence()

    def _check_convergence(self):
        if not self.converged:
            self.converged = (
                self.P[2, 2] < self.threshold
                and self.P[3, 3] < self.threshold
            )

    @property
    def covariance_diag(self):
        """Return [Pxx, Pyy, Pvx, Pvy] for the TargetEstimate message."""
        if not self.initialized:
            return [1e6, 1e6, 1e6, 1e6]
        return [self.P[0, 0], self.P[1, 1], self.P[2, 2], self.P[3, 3]]
