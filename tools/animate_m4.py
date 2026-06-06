#!/usr/bin/env python3
"""
M4 animation — extends M3 with handover/commitment event tracking.

Usage:
  source ~/projects/swarm-sim2real/ros2_ws/install/setup.bash
  python3 tools/animate_m4.py swarm_m4_bag/
  python3 tools/animate_m4.py swarm_m4_bag/ --out m4.mp4 --sim-secs 60 --fps 10
"""

import argparse
import math
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.animation as animation
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import numpy as np
import yaml
from matplotlib.lines import Line2D
from matplotlib.patches import Ellipse

import rosbag2_py
from rclpy.serialization import deserialize_message
from rosidl_runtime_py.utilities import get_message


# ── Visual constants (MATLAB V47 semantics) ───────────────────────────────────

# Target: T1 red · T2 green · T3 blue
TARGET_COLORS = ['#cc0000', '#007700', '#0044cc']
TARGET_NAMES  = ['Target 1', 'Target 2', 'Target 3']

# Interceptor color depends on assigned target
INTERCEPTOR_COLORS = {0: '#ff7700', 1: '#007700', 2: '#888888'}

COLOR_PRIMARY      = '#ff0000'  # bright red
COLOR_SECONDARY    = '#770000'  # dark red
COLOR_RETURNING    = '#ee00ee'  # magenta
COLOR_DETECTING    = '#00bbbb'  # cyan
COLOR_IDLE_NORMAL  = '#001f5b'  # navy blue
COLOR_IDLE_PREV    = '#99ccdd'  # light cyan  (previously detected)
COLOR_SEARCHING    = '#660066'  # purple

# EKF covariance contour styles per target: [(color, linestyle), ...] 3σ→2σ→1σ
COV_STYLES = {
    0: [('#009900', '--'), ('#cc0000', '-'), ('#0000cc', '-')],  # T1: green/red/blue
    1: [('#cc00cc', '--'), ('#aaaa00', '-'), ('#009999', '-')],  # T2: magenta/yellow/cyan
    2: [('#0000cc', '--'), ('#666666', '-'), ('#000000', '-')],  # T3: blue/gray/black
}
SIGMA_LEVELS   = [3, 2, 1]
DETECTION_R    = 1.5


# ── Color helper ──────────────────────────────────────────────────────────────

def _sensor_color(fsm, role, atid, ever_active):
    if fsm == 'TRACKING':
        return COLOR_PRIMARY if role == 'PRIMARY_TRACKER' else COLOR_SECONDARY
    if fsm == 'INTERCEPTING':
        return INTERCEPTOR_COLORS.get(atid, '#ff7700')
    if fsm == 'RETURNING_HOME':
        return COLOR_RETURNING
    if fsm == 'DETECTING':
        return COLOR_DETECTING
    if fsm == 'SEARCHING':
        return COLOR_SEARCHING
    # IDLE
    return COLOR_IDLE_PREV if ever_active else COLOR_IDLE_NORMAL


# ── Bag reading ───────────────────────────────────────────────────────────────

def _storage_id(bag_path):
    meta = os.path.join(bag_path, 'metadata.yaml')
    if os.path.exists(meta):
        with open(meta) as f:
            d = yaml.safe_load(f)
        return d.get('rosbag2_bagfile_information', {}).get('storage_identifier', 'sqlite3')
    return 'sqlite3'


def read_bag(bag_path):
    """
    Returns four dicts:
      sensor_frames   {sid: [(t, px, py, fsm, role, atid), ...]}
      target_frames   {tid: [(t, x,  y), ...]}
      ekf_frames      {sid: [(t, tid, ex, ey, conv, Pxx, Pyy), ...]}
      commit_events   [(t, sensor_id, target_id), ...]  — CommitmentMsg events
    """
    storage_options = rosbag2_py.StorageOptions(
        uri=bag_path, storage_id=_storage_id(bag_path))
    reader = rosbag2_py.SequentialReader()
    reader.open(storage_options, rosbag2_py.ConverterOptions('', ''))
    type_map = {t.name: t.type for t in reader.get_all_topics_and_types()}

    sensor_frames, target_frames, ekf_frames = {}, {}, {}
    commit_events = []

    while reader.has_next():
        topic, data, t_ns = reader.read_next()
        if topic not in type_map:
            continue
        t   = t_ns * 1e-9
        msg = deserialize_message(data, get_message(type_map[topic]))

        if '/sensors/' in topic and topic.endswith('/state'):
            sid  = msg.sensor_id
            role = getattr(msg, 'role', 'NONE')
            sensor_frames.setdefault(sid, []).append(
                (t, msg.pos_x, msg.pos_y, msg.fsm_state, role,
                 msg.assigned_target_id))

        elif '/targets/' in topic and topic.endswith('/ground_truth'):
            target_frames.setdefault(msg.target_id, []).append(
                (t, msg.x, msg.y))

        elif '/sensors/' in topic and topic.endswith('/ekf_estimate'):
            sid = msg.sensor_id
            cov = list(getattr(msg, 'covariance', [0.0, 0.0, 0.0, 0.0]))
            ekf_frames.setdefault(sid, []).append(
                (t, msg.target_id, msg.x, msg.y, msg.ekf_converged,
                 float(cov[0]), float(cov[1])))  # Pxx, Pyy

        elif topic == '/swarm/commitment':
            commit_events.append((t, msg.sensor_id, msg.assigned_target_id))

    for d in (sensor_frames, target_frames, ekf_frames):
        for k in d:
            d[k].sort(key=lambda e: e[0])
    commit_events.sort(key=lambda e: e[0])

    return sensor_frames, target_frames, ekf_frames, commit_events


def _lookup(lst, t):
    """Binary search: last entry with timestamp <= t."""
    lo, hi = 0, len(lst) - 1
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if lst[mid][0] <= t:
            lo = mid
        else:
            hi = mid - 1
    return lst[lo]


# ── Animation ─────────────────────────────────────────────────────────────────

def make_animation(bag_path, out_path, sim_secs=30.0, fps=10):
    print(f"Reading {bag_path} …")
    sensor_frames, target_frames, ekf_frames, commit_events = read_bag(bag_path)

    if not sensor_frames:
        sys.exit("ERROR: no /sensors/*/state messages found in bag")

    t0         = min(v[0][0] for v in sensor_frames.values())
    n_frames   = fps * 10          # always 10 s of animation
    dt_frame   = sim_secs / n_frames
    sensor_ids = sorted(sensor_frames)
    target_ids = sorted(target_frames)
    n_tgt      = len(target_ids)

    print(f"  {len(sensor_ids)} sensors | {n_tgt} targets | {len(commit_events)} commitment events")
    print(f"  sim {t0:.1f}s → {t0+sim_secs:.1f}s  →  10 s @ {fps} fps  "
          f"(×{sim_secs/10:.1f} speed)")

    # -- pre-compute first activation time per sensor (for prev-detected coloring)
    first_active = {}
    for sid, frames in sensor_frames.items():
        for frame in frames:
            if frame[3] != 'IDLE':          # fsm_state is index 3
                first_active[sid] = frame[0]
                break

    # -- pre-compute time-sorted active assignments per sensor (for SEARCHING context)
    active_asgn = {}
    for sid, frames in sensor_frames.items():
        active_asgn[sid] = [(f[0], f[5]) for f in frames if f[5] >= 0]

    def _last_assigned(sid, t):
        for tf, atid in reversed(active_asgn.get(sid, [])):
            if tf <= t:
                return atid
        return -1

    # ── Figure (white background) ─────────────────────────────────────────────
    fig = plt.figure(figsize=(13, 9), facecolor='white')
    # main axes: left ~60% of figure
    ax  = fig.add_axes([0.05, 0.12, 0.60, 0.82])
    ax.set_facecolor('white')
    ax.set_xlim(-10, 62)
    ax.set_ylim(-8, 60)
    ax.set_aspect('equal')
    ax.set_xlabel('x (units)', fontsize=9, color='#333333')
    ax.set_ylabel('y (units)', fontsize=9, color='#333333')
    ax.tick_params(colors='#333333', labelsize=8)
    for sp in ax.spines.values():
        sp.set_edgecolor('#cccccc')
    ax.grid(True, color='#eeeeee', linewidth=0.5, zorder=0)
    title_obj = ax.set_title('', fontsize=11, color='#111111', pad=8)

    # ── Coverage disks — all 25, always shown, semi-transparent ──────────────
    cov_circles = []
    for _ in sensor_ids:
        c = plt.Circle((0, 0), DETECTION_R,
                        facecolor='#999999', alpha=0.10,
                        edgecolor='#aaaaaa', linewidth=0.5, zorder=1)
        ax.add_patch(c)
        cov_circles.append(c)

    # ── Target full-history trails ────────────────────────────────────────────
    trail_lines = {}
    for i, tid in enumerate(target_ids):
        line, = ax.plot([], [], color=TARGET_COLORS[i % 3],
                        lw=1.5, alpha=0.65, zorder=3)
        trail_lines[tid] = line

    # ── Target star markers ───────────────────────────────────────────────────
    tgt_stars = {}
    for i, tid in enumerate(target_ids):
        sc = ax.scatter([], [], s=300, marker='*',
                        color=TARGET_COLORS[i % 3], zorder=9,
                        edgecolors='none')
        tgt_stars[tid] = sc

    # ── Sensor center dots ────────────────────────────────────────────────────
    sensor_sc = ax.scatter([], [], s=80, zorder=5, edgecolors='none')

    # ── EKF estimate × marks (shown when TRACKING / DETECTING) ───────────────
    ekf_sc = ax.scatter([], [], s=40, marker='x', color='#444444',
                        linewidths=1.0, alpha=0.55, zorder=6)

    # ── Sensor numbered labels ────────────────────────────────────────────────
    sensor_labels = []
    for _ in sensor_ids:
        txt = ax.text(0, 0, '', fontsize=6, color='#222222',
                      ha='center', va='bottom', zorder=7)
        sensor_labels.append(txt)

    # ── EKF covariance contour ellipses (3 targets × 3 σ levels) ─────────────
    cov_ellipses = {}
    for tid in range(3):
        cov_ellipses[tid] = []
        styles = COV_STYLES.get(tid, COV_STYLES[0])
        for _sigma, (color, ls) in zip(SIGMA_LEVELS, styles):
            e = Ellipse((0, 0), 0, 0, facecolor='none', edgecolor=color,
                        linewidth=1.2, linestyle=ls, zorder=4)
            e.set_visible(False)
            ax.add_patch(e)
            cov_ellipses[tid].append(e)

    # ── Status text box (lower-left inside main axes) ─────────────────────────
    status_box = ax.text(
        0.01, 0.01, '',
        transform=ax.transAxes,
        fontsize=7.5, va='bottom', ha='left', family='monospace',
        color='#111111',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='#f8f8f8',
                  edgecolor='#999999', alpha=0.90),
        zorder=10)

    # ── Legend panel (right ~30% of figure) ──────────────────────────────────
    ax_leg = fig.add_axes([0.68, 0.05, 0.30, 0.92])
    ax_leg.axis('off')
    ax_leg.set_title('Legend', fontsize=9, loc='left', pad=8, color='#333333')

    leg_handles = []

    # Target stars
    for i in range(n_tgt):
        name = TARGET_NAMES[i] if i < len(TARGET_NAMES) else f'Target {i+1}'
        leg_handles.append(Line2D([0], [0], marker='*', color='w',
            markerfacecolor=TARGET_COLORS[i], markersize=11, label=name))

    # Target paths
    for i in range(n_tgt):
        name = TARGET_NAMES[i] if i < len(TARGET_NAMES) else f'Target {i+1}'
        leg_handles.append(Line2D([0], [0], color=TARGET_COLORS[i],
            lw=1.5, alpha=0.7, label=f'{name} Path'))

    # Target interceptor colors
    int_labels = ['T1 Interceptor', 'T2 Interceptor', 'T3 Interceptor']
    for i in range(min(3, n_tgt)):
        leg_handles.append(mpatches.Patch(
            color=INTERCEPTOR_COLORS[i], label=int_labels[i]))

    # Sensor role / state patches
    leg_handles += [
        mpatches.Patch(color=COLOR_PRIMARY,     label='Primary Tracker'),
        mpatches.Patch(color=COLOR_SECONDARY,   label='Secondary Tracker'),
        mpatches.Patch(color=COLOR_RETURNING,   label='Returning Home'),
        mpatches.Patch(color=COLOR_DETECTING,   label='Detecting'),
        mpatches.Patch(color=COLOR_IDLE_NORMAL, label='Normal Sensor'),
        mpatches.Patch(color=COLOR_IDLE_PREV,   label='Prev. Detected'),
        mpatches.Patch(color=COLOR_SEARCHING,   label='Searching'),
    ]

    ax_leg.legend(handles=leg_handles, loc='upper left',
                  fontsize=8.5, framealpha=0.9, edgecolor='#cccccc',
                  labelcolor='#111111')

    # ── Per-frame update ──────────────────────────────────────────────────────
    def update(frame_idx):
        t = t0 + frame_idx * dt_frame

        s_xy, s_colors = [], []
        ekf_xy = []
        counts = {k: 0 for k in
                  ('TRACKING', 'INTERCEPTING', 'SEARCHING',
                   'RETURNING_HOME', 'DETECTING')}
        per_tgt = {tid: 0 for tid in target_ids}
        searching_ekf = {}   # tid → (ex, ey, Pxx, Pyy)

        for j, sid in enumerate(sensor_ids):
            if not sensor_frames.get(sid):
                continue
            _, px, py, fsm, role, atid = _lookup(sensor_frames[sid], t)
            ever_active = t >= first_active.get(sid, float('inf'))

            s_xy.append([px, py])
            s_colors.append(_sensor_color(fsm, role, atid, ever_active))

            # Move coverage disk and label
            cov_circles[j].center = (px, py)
            sensor_labels[j].set_position((px, py + DETECTION_R * 1.2))
            sensor_labels[j].set_text(str(sid))

            # State counts
            if fsm in counts:
                counts[fsm] += 1
            if fsm == 'TRACKING' and atid in per_tgt:
                per_tgt[atid] += 1

            # EKF estimates
            if sid in ekf_frames and ekf_frames[sid]:
                if fsm in ('TRACKING', 'DETECTING'):
                    e = _lookup(ekf_frames[sid], t)
                    ekf_xy.append([e[2], e[3]])
                elif fsm == 'SEARCHING':
                    stid = _last_assigned(sid, t)
                    if stid >= 0:
                        relevant = [e for e in ekf_frames[sid]
                                    if e[1] == stid and e[0] <= t]
                        if relevant and stid not in searching_ekf:
                            e = relevant[-1]
                            searching_ekf[stid] = (e[2], e[3], e[5], e[6])

        sensor_sc.set_offsets(np.array(s_xy) if s_xy else np.empty((0, 2)))
        sensor_sc.set_facecolor(s_colors)
        ekf_sc.set_offsets(np.array(ekf_xy) if ekf_xy else np.empty((0, 2)))

        # Target trails (full history) + star position
        for i, tid in enumerate(target_ids):
            if not target_frames.get(tid):
                continue
            pts = [(x, y) for ts, x, y in target_frames[tid] if ts <= t]
            if pts:
                xs, ys = zip(*pts)
                trail_lines[tid].set_data(xs, ys)
            _, tx, ty = _lookup(target_frames[tid], t)
            tgt_stars[tid].set_offsets([[tx, ty]])

        # Covariance contour ellipses (only during SEARCHING)
        for tid in range(3):
            if tid in searching_ekf:
                ex, ey, pxx, pyy = searching_ekf[tid]
                sx = math.sqrt(max(pxx, 1e-9))
                sy = math.sqrt(max(pyy, 1e-9))
                for k, (sigma, ell) in enumerate(
                        zip(SIGMA_LEVELS, cov_ellipses[tid])):
                    ell.set_center((ex, ey))
                    ell.width  = 2 * sigma * sx
                    ell.height = 2 * sigma * sy
                    ell.set_visible(True)
            else:
                for ell in cov_ellipses[tid]:
                    ell.set_visible(False)

        # Title — time + system state
        any_active = (counts['TRACKING'] + counts['INTERCEPTING']
                      + counts['DETECTING']) > 0
        sys_state  = ('TRACKING'  if any_active else
                      'SEARCHING' if counts['SEARCHING'] > 0 else 'IDLE')
        n_commits_so_far = sum(1 for ce in commit_events if ce[0] <= t)
        title_obj.set_text(
            f'ROS 2 M4 — Distributed Handover + Assignment     '
            f't = {t - t0:5.1f} s     System: {sys_state}')

        # Status box
        t_track = '  '.join(
            f'T{i+1}:{per_tgt.get(tid, 0)}'
            for i, tid in enumerate(target_ids))
        status_box.set_text(
            f'System: {sys_state}\n'
            f'Tracking: {counts["TRACKING"]}   '
            f'Detecting: {counts["DETECTING"]}\n'
            f'Intercepting: {counts["INTERCEPTING"]}   '
            f'Searching: {counts["SEARCHING"]}   '
            f'Returning: {counts["RETURNING_HOME"]}\n'
            f'Trackers per target:  {t_track}\n'
            f'Commitments so far: {n_commits_so_far}')

        return ([sensor_sc, ekf_sc, title_obj, status_box]
                + list(trail_lines.values())
                + list(tgt_stars.values())
                + cov_circles
                + sensor_labels
                + [e for lst in cov_ellipses.values() for e in lst])

    ani = animation.FuncAnimation(fig, update, frames=n_frames,
                                  interval=1000 // fps, blit=True)

    # ── Save ──────────────────────────────────────────────────────────────────
    print(f"Rendering {n_frames} frames → {out_path} …")
    if out_path.endswith('.gif'):
        ani.save(out_path, writer=animation.PillowWriter(fps=fps), dpi=100)
    else:
        mp4_args = ['-vcodec', 'libx264', '-pix_fmt', 'yuv420p',
                    '-profile:v', 'baseline', '-level', '3.0',
                    '-movflags', '+faststart']
        try:
            ani.save(out_path,
                     writer=animation.FFMpegWriter(fps=fps, bitrate=1800,
                                                   extra_args=mp4_args),
                     dpi=120)
        except FileNotFoundError:
            gif_path = out_path.replace('.mp4', '.gif')
            print(f"ffmpeg not found — falling back to GIF: {gif_path}")
            ani.save(gif_path, writer=animation.PillowWriter(fps=fps), dpi=100)
            out_path = gif_path
    print(f"Done → {out_path}")
    plt.close()


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == '__main__':
    ap = argparse.ArgumentParser(
        description='Generate M4 swarm animation from ROS 2 bag '
                    '(handover + commitment events, visual style: MATLAB V47)')
    ap.add_argument('bag',
                    help='Path to ros2 bag directory (e.g. swarm_m4_bag/)')
    ap.add_argument('--out', default='m4_animation.mp4',
                    help='Output file (.mp4 or .gif). Default: m4_animation.mp4')
    ap.add_argument('--sim-secs', type=float, default=60.0,
                    help='Sim seconds to compress into 10 s (default: 60)')
    ap.add_argument('--fps', type=int, default=10,
                    help='Animation fps (default: 10)')
    args = ap.parse_args()

    if not os.path.isdir(args.bag):
        sys.exit(f"ERROR: '{args.bag}' is not a directory")

    make_animation(args.bag, args.out,
                   sim_secs=args.sim_secs, fps=args.fps)
