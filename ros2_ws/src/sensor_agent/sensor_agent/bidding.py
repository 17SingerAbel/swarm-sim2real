import math

# Default weights: w1=P_home, w2=P_spatial, w3=P_temporal, w4=P_uncertainty
# From MATLAB OPTIMIZATION_WEIGHTS default (calculateEnhancedBid.m line 29)
_DEFAULT_WEIGHTS = (0.4, 0.3, 0.2, 0.1)


def calculate_bid_cost(
    sensor_pos,
    home_pos,
    intercept_point,
    target_vel,
    confidence,
    target_current_pos,
    wsn_width,
    wsn_height,
    sensor_velocity=0.75,
    weights=None,
):
    """
    Compute bid cost c(i, k) from paper §3.2.

    Parameters
    ----------
    sensor_pos          : (x, y) — current sensor position
    home_pos            : (x, y) — sensor home position
    intercept_point     : (x, y) — predicted interception point for the target
    target_vel          : (vx, vy) — estimated target velocity (from EKF)
    confidence          : float in [0, 1] — EKF confidence (1 = fully converged)
    target_current_pos  : (x, y) — current estimated target position
    wsn_width           : float — WSN grid width in simulation units
    wsn_height          : float — WSN grid height in simulation units
    sensor_velocity     : float — sensor max speed (default 0.75 units/s)
    weights             : (w1, w2, w3, w4) or None for defaults

    Returns
    -------
    float — bid cost (lower is better)
    """
    if weights is None:
        weights = _DEFAULT_WEIGHTS
    w1, w2, w3, w4 = weights

    max_network_distance = math.sqrt(wsn_width ** 2 + wsn_height ** 2)

    P_home = _dist(sensor_pos, home_pos) / max_network_distance
    P_spatial = _dist(sensor_pos, intercept_point) / max_network_distance

    sensor_time = _dist(sensor_pos, intercept_point) / sensor_velocity
    target_dist_to_intercept = _dist(target_current_pos, intercept_point)
    target_speed = math.sqrt(target_vel[0] ** 2 + target_vel[1] ** 2)

    if target_speed > 0.01:
        target_time = target_dist_to_intercept / target_speed
        P_temporal = min(1.0, max(0.0, (sensor_time - target_time) / target_time))
    else:
        P_temporal = 0.0

    P_uncertainty = 1.0 - confidence

    return w1 * P_home + w2 * P_spatial + w3 * P_temporal + w4 * P_uncertainty


def _dist(a, b):
    return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)
