import numpy as np


def solve_assignment(calling_targets, candidates, cost_matrix, slots_per_target=2):
    """
    Two-stage min-cost max-flow interceptor assignment.

    Faithfully ported from solveInterceptorAssignmentOptimal.m.

    Stage 1: maximize total filled interceptor slots (no target left unserved if avoidable).
    Stage 2: among all max-slot solutions, minimize total assignment cost.

    This is encoded as a single MCMF by using a large `assignment_reward` that
    makes filling a slot always cheaper than leaving it empty, regardless of cost.

    Parameters
    ----------
    calling_targets  : list[int] — target IDs requesting interceptors
    candidates       : list[int] — candidate sensor IDs eligible to bid
    cost_matrix      : array-like, shape (len(candidates), len(calling_targets))
                       Use math.inf for infeasible sensor→target pairs
    slots_per_target : int — max interceptors per target (default 2)

    Returns
    -------
    dict[int, list[int]] — {target_id: [assigned_sensor_id, ...]}
    """
    num_candidates = len(candidates)
    num_targets = len(calling_targets)
    assignments = {t: [] for t in calling_targets}

    if num_candidates == 0 or num_targets == 0:
        return assignments

    cost_matrix = np.array(cost_matrix, dtype=float)

    # Expand each target into slots_per_target slot nodes
    slot_target_idx = []  # slot index → index into calling_targets
    for t_idx in range(num_targets):
        for _ in range(slots_per_target):
            slot_target_idx.append(t_idx)
    num_slots = len(slot_target_idx)

    # Node layout (0-based):
    #   0                        : source
    #   1 .. num_candidates      : sensor nodes
    #   num_candidates+1 .. +S   : slot nodes (S = num_slots)
    #   num_candidates+S+1       : sink
    source = 0
    sensor_base = 1
    slot_base = sensor_base + num_candidates
    sink = slot_base + num_slots
    n = sink + 1

    capacity = np.zeros((n, n), dtype=int)
    edge_cost = np.full((n, n), np.nan)

    # Source → sensor edges (capacity 1, cost 0)
    for s_idx in range(num_candidates):
        sn = sensor_base + s_idx
        capacity[source, sn] = 1
        edge_cost[source, sn] = 0.0

    # assignment_reward: large enough that filling any slot beats any cost combination
    finite = cost_matrix[np.isfinite(cost_matrix)]
    if finite.size == 0:
        assignment_reward = 1.0
    else:
        assignment_reward = (num_candidates * max(1, slots_per_target) + 1) * (finite.max() + 1)

    # Sensor → slot edges (capacity 1, cost = raw_cost - assignment_reward)
    for s_idx in range(num_candidates):
        sn = sensor_base + s_idx
        for sl_idx in range(num_slots):
            t_idx = slot_target_idx[sl_idx]
            raw = cost_matrix[s_idx, t_idx]
            if not np.isfinite(raw):
                continue
            sl_node = slot_base + sl_idx
            capacity[sn, sl_node] = 1
            edge_cost[sn, sl_node] = raw - assignment_reward

    # Slot → sink edges (capacity 1, cost 0)
    for sl_idx in range(num_slots):
        sl_node = slot_base + sl_idx
        capacity[sl_node, sink] = 1
        edge_cost[sl_node, sink] = 0.0

    flow = _run_mcmf(capacity, edge_cost, source, sink)

    # Read assignments from flow
    for s_idx in range(num_candidates):
        sn = sensor_base + s_idx
        for sl_idx in range(num_slots):
            sl_node = slot_base + sl_idx
            if flow[sn, sl_node] > 0:
                t_idx = slot_target_idx[sl_idx]
                assignments[calling_targets[t_idx]].append(candidates[s_idx])

    return assignments


def _run_mcmf(capacity, edge_cost, source, sink):
    """Successive shortest paths via Bellman-Ford on residual graph."""
    n = capacity.shape[0]
    flow = np.zeros((n, n), dtype=int)

    while True:
        found, parent, direction, dist = _bellman_ford(capacity, edge_cost, flow, source, sink)
        if not found or not np.isfinite(dist[sink]) or dist[sink] >= 0:
            break
        # Augment along cheapest negative-cost path
        node = sink
        while node != source:
            prev = parent[node]
            if direction[node] == 1:
                flow[prev, node] += 1
            else:
                flow[node, prev] -= 1
            node = prev

    return flow


def _bellman_ford(capacity, edge_cost, flow, source, sink):
    """
    Find cheapest path source→sink in residual graph.

    Uses -1 as sentinel for 'not reached' in parent array.
    Stops early when an iteration changes nothing.
    """
    n = capacity.shape[0]
    dist = np.full(n, np.inf)
    parent = np.full(n, -1, dtype=int)
    direction = np.zeros(n, dtype=int)
    dist[source] = 0.0

    for _ in range(n - 1):
        updated = False
        for u in range(n):
            if not np.isfinite(dist[u]):
                continue
            for v in range(n):
                # Forward edge: residual capacity > 0
                if capacity[u, v] - flow[u, v] > 0 and np.isfinite(edge_cost[u, v]):
                    c = dist[u] + edge_cost[u, v]
                    if c < dist[v]:
                        dist[v] = c
                        parent[v] = u
                        direction[v] = 1
                        updated = True
                # Reverse edge: cancel existing flow
                if flow[v, u] > 0 and np.isfinite(edge_cost[v, u]):
                    c = dist[u] - edge_cost[v, u]
                    if c < dist[v]:
                        dist[v] = c
                        parent[v] = u
                        direction[v] = -1
                        updated = True
        if not updated:
            break

    return parent[sink] != -1, parent, direction, dist