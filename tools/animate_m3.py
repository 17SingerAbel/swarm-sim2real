#!/usr/bin/env python3
"""
M3 animation: reads a ROS 2 bag, renders a 10-second animation.

Usage:
  source ~/projects/swarm-sim2real/ros2_ws/install/setup.bash
  python3 tools/animate_m3.py swarm_m3_bag/
  python3 tools/animate_m3.py swarm_m3_bag/ --out m3.gif --sim-secs 20
"""

import argparse
import os
import sys
import yaml
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import matplotlib.patches as mpatches

import rosbag2_py
from rclpy.serialization import deserialize_message
from rosidl_runtime_py.utilities import get_message

# -----------------------------------------------------------------
# Constants
# -----------------------------------------------------------------

FSM_COLORS = {
    'IDLE':           '#3a4a5c',
    'DETECTING':      '#f0c040',
    'TRACKING':       '#40c880',
    'INTERCEPTING':   '#e05050',
    'SEARCHING':      '#c060c0',
    'RETURNING_HOME': '#4080cc',
}
TARGET_COLORS = ['#ff6b6b', '#4ecdc4', '#ffe66d']
DETECTION_RADIUS = 1.5


# -----------------------------------------------------------------
# Bag reading
# -----------------------------------------------------------------

def _storage_id(bag_path):
    meta = os.path.join(bag_path, 'metadata.yaml')
    if os.path.exists(meta):
        with open(meta) as f:
            d = yaml.safe_load(f)
        return d.get('rosbag2_bagfile_information', {}).get('storage_identifier', 'sqlite3')
    return 'sqlite3'


def read_bag(bag_path):
    """
    Returns three dicts keyed by id, each a time-sorted list of tuples:
      sensor_frames  {sid: [(t, px, py, fsm_state, assigned_tid), ...]}
      target_frames  {tid: [(t, x,  y), ...]}
      ekf_frames     {sid: [(t, tid, est_x, est_y, converged), ...]}
    """
    storage_options = rosbag2_py.StorageOptions(
        uri=bag_path, storage_id=_storage_id(bag_path))
    converter_options = rosbag2_py.ConverterOptions('', '')
    reader = rosbag2_py.SequentialReader()
    reader.open(storage_options, converter_options)

    type_map = {t.name: t.type for t in reader.get_all_topics_and_types()}

    sensor_frames, target_frames, ekf_frames = {}, {}, {}

    while reader.has_next():
        topic, data, t_ns = reader.read_next()
        if topic not in type_map:
            continue
        t = t_ns * 1e-9
        msg = deserialize_message(data, get_message(type_map[topic]))

        if '/sensors/' in topic and topic.endswith('/state'):
            sid = msg.sensor_id
            sensor_frames.setdefault(sid, []).append(
                (t, msg.pos_x, msg.pos_y, msg.fsm_state, msg.assigned_target_id))

        elif '/targets/' in topic and topic.endswith('/ground_truth'):
            tid = msg.target_id
            target_frames.setdefault(tid, []).append((t, msg.x, msg.y))

        elif '/sensors/' in topic and topic.endswith('/ekf_estimate'):
            sid = msg.sensor_id
            ekf_frames.setdefault(sid, []).append(
                (t, msg.target_id, msg.x, msg.y, msg.ekf_converged))

    for d in (sensor_frames, target_frames, ekf_frames):
        for k in d:
            d[k].sort(key=lambda e: e[0])

    return sensor_frames, target_frames, ekf_frames


def _lookup(lst, t):
    """Binary-search: return entry with largest timestamp <= t."""
    lo, hi = 0, len(lst) - 1
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if lst[mid][0] <= t:
            lo = mid
        else:
            hi = mid - 1
    return lst[lo]


# -----------------------------------------------------------------
# Animation
# -----------------------------------------------------------------

def make_animation(bag_path, out_path, sim_secs=30.0, fps=10):
    print(f"Reading {bag_path} …")
    sensor_frames, target_frames, ekf_frames = read_bag(bag_path)

    if not sensor_frames:
        sys.exit("ERROR: no /sensors/*/state messages found in bag")

    t0 = min(v[0][0] for v in sensor_frames.values())
    n_frames = fps * 10        # always 10 seconds of animation
    dt_frame = sim_secs / n_frames   # sim-seconds per animation frame

    print(f"  {len(sensor_frames)} sensors | {len(target_frames)} targets")
    print(f"  sim {t0:.1f}s → {t0+sim_secs:.1f}s  →  10 s @ {fps} fps  (×{sim_secs/10:.1f} speed)")

    sensor_ids = sorted(sensor_frames)

    # ---- figure setup ----
    fig, ax = plt.subplots(figsize=(9, 8))
    fig.patch.set_facecolor('#0d1117')
    ax.set_facecolor('#0d1117')
    ax.set_xlim(-12, 62)
    ax.set_ylim(-18, 58)
    ax.set_aspect('equal')
    ax.set_xlabel('x (units)', color='#8b949e', fontsize=9)
    ax.set_ylabel('y (units)', color='#8b949e', fontsize=9)
    ax.tick_params(colors='#8b949e', labelsize=8)
    for sp in ax.spines.values():
        sp.set_edgecolor('#30363d')
    ax.set_title('ROS 2 M3 — Distributed EKF Swarm Tracking',
                 color='#e6edf3', fontsize=12, pad=10)

    # sensor body dots
    sensor_sc = ax.scatter([], [], s=110, zorder=4)
    # converged white ring
    conv_sc = ax.scatter([], [], s=200, facecolors='none',
                         edgecolors='#ffffff', linewidths=2.0, zorder=5)
    # EKF estimate ×
    ekf_sc = ax.scatter([], [], s=50, marker='x', color='white',
                        linewidths=1.2, alpha=0.75, zorder=6)

    # detection-radius circles (one per sensor, toggled visible)
    det_circles = []
    for _ in sensor_ids:
        c = plt.Circle((0, 0), DETECTION_RADIUS,
                        fill=False, edgecolor='#ffffff18', linewidth=0.8, zorder=2)
        ax.add_patch(c)
        c.set_visible(False)
        det_circles.append(c)

    # target stars + trails
    tgt_objs = []
    for i, tid in enumerate(sorted(target_frames)):
        sc = ax.scatter([], [], s=250, marker='*',
                        color=TARGET_COLORS[i % len(TARGET_COLORS)],
                        zorder=8, label=f'Target {tid}')
        trail, = ax.plot([], [], color=TARGET_COLORS[i % len(TARGET_COLORS)],
                         alpha=0.35, lw=1.8, zorder=3)
        tgt_objs.append((tid, sc, trail))

    time_text = ax.text(0.02, 0.97, '', transform=ax.transAxes,
                        color='#e6edf3', fontsize=10, va='top', family='monospace')

    # legend
    fsm_patches = [mpatches.Patch(color=c, label=s.replace('_', ' '))
                   for s, c in FSM_COLORS.items()
                   if s in ('IDLE', 'DETECTING', 'TRACKING', 'RETURNING_HOME')]
    conv_patch = mpatches.Patch(facecolor='none', edgecolor='white',
                                linewidth=1.5, label='EKF converged (ring)')
    ekf_handle = mpatches.Patch(color='white', label='EKF estimate (×)',
                                alpha=0.75)
    ax.legend(handles=fsm_patches + [conv_patch, ekf_handle],
              loc='lower right', fontsize=7.5,
              facecolor='#161b22', labelcolor='#e6edf3', edgecolor='#30363d')

    # ---- per-frame update ----
    def update(frame_idx):
        t = t0 + frame_idx * dt_frame

        s_xy, s_colors = [], []
        conv_xy, ekf_xy = [], []

        for j, sid in enumerate(sensor_ids):
            if not sensor_frames.get(sid):
                continue
            _, px, py, fsm, _ = _lookup(sensor_frames[sid], t)
            s_xy.append([px, py])
            s_colors.append(FSM_COLORS.get(fsm, '#3a4a5c'))

            active = fsm in ('DETECTING', 'TRACKING')
            det_circles[j].center = (px, py)
            det_circles[j].set_visible(active)

            # converged ring
            if fsm == 'TRACKING' and sid in ekf_frames and ekf_frames[sid]:
                _, _, ex, ey, converged = _lookup(ekf_frames[sid], t)
                ekf_xy.append([ex, ey])
                if converged:
                    conv_xy.append([px, py])

        sensor_sc.set_offsets(np.array(s_xy) if s_xy else np.empty((0, 2)))
        sensor_sc.set_facecolor(s_colors)

        conv_sc.set_offsets(np.array(conv_xy) if conv_xy else np.empty((0, 2)))
        ekf_sc.set_offsets(np.array(ekf_xy) if ekf_xy else np.empty((0, 2)))

        # targets
        for tid, sc, trail in tgt_objs:
            if not target_frames.get(tid):
                continue
            _, tx, ty = _lookup(target_frames[tid], t)
            sc.set_offsets([[tx, ty]])
            pts = [(x, y) for ts, x, y in target_frames[tid] if t - 4.0 <= ts <= t]
            if pts:
                trail.set_data(*zip(*pts))

        time_text.set_text(f't = {t - t0:5.1f} s')

        artists = [sensor_sc, conv_sc, ekf_sc, time_text]
        artists += [sc for _, sc, _ in tgt_objs]
        artists += [tr for _, _, tr in tgt_objs]
        return artists

    ani = animation.FuncAnimation(fig, update, frames=n_frames,
                                  interval=1000 // fps, blit=True)

    print(f"Rendering {n_frames} frames → {out_path} …")
    if out_path.endswith('.gif'):
        writer = animation.PillowWriter(fps=fps)
        ani.save(out_path, writer=writer, dpi=100)
    else:
        # LinkedIn-compatible MP4: H.264 baseline, yuv420p (no hardware needed)
        # Falls back to GIF automatically if ffmpeg is missing
        mp4_args = [
            '-vcodec', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-profile:v', 'baseline',   # maximum device compatibility
            '-level', '3.0',
            '-movflags', '+faststart',   # enables streaming on LinkedIn
        ]
        try:
            writer = animation.FFMpegWriter(fps=fps, bitrate=1800, extra_args=mp4_args)
            ani.save(out_path, writer=writer, dpi=120)
        except FileNotFoundError:
            gif_path = out_path.replace('.mp4', '.gif')
            print(f"ffmpeg not found — falling back to GIF: {gif_path}")
            writer = animation.PillowWriter(fps=fps)
            ani.save(gif_path, writer=writer, dpi=100)
            out_path = gif_path
    print(f"Done → {out_path}")
    plt.close()


# -----------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------

if __name__ == '__main__':
    ap = argparse.ArgumentParser(
        description='Generate 10-second M3 swarm animation from a ROS 2 bag')
    ap.add_argument('bag', help='Path to ros2 bag directory (e.g. swarm_m3_bag)')
    ap.add_argument('--out', default='m3_animation.mp4',
                    help='Output file — .mp4 (FFmpeg) or .gif (Pillow). Default: m3_animation.mp4')
    ap.add_argument('--sim-secs', type=float, default=30.0,
                    help='Seconds of sim time to compress into 10 s (default: 30)')
    ap.add_argument('--fps', type=int, default=10,
                    help='Animation fps (default: 10)')
    args = ap.parse_args()

    if not os.path.isdir(args.bag):
        sys.exit(f"ERROR: '{args.bag}' is not a directory")

    make_animation(args.bag, args.out, sim_secs=args.sim_secs, fps=args.fps)
