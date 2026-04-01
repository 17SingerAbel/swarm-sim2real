# Agent Notes: WSN Multi-Target Tracking (`mie8888`)

## 1) 项目定位
- 这是一个 **MATLAB 单脚本仿真项目**，核心文件是 `example_V45_V38_b.m`（约 2932 行）。
- 目标：在 5x5 移动传感器网络中，协同跟踪 3 个目标，并在预测即将丢失时发起 **主动交接（handover）**。
- 核心机制：`系统级 FSM + 传感器级 FSM + 每传感器每目标 EKF + 拦截器竞价分配 + 冲突消解(minimax)`。

## 2) 关键文档与代码来源
- `design.md`：算法设计说明（状态机、EKF、损失预测、竞价、冲突消解、PNG 导航）。
- `CLAUDE.md`：项目摘要、参数总览、命名约定。
- `example_V45_V38_b.m`：唯一执行脚本，含主循环、辅助函数、可视化、结果保存。

## 3) 代码结构（按执行顺序）
1. 参数与状态初始化  
2. 局部辅助函数定义（日志、损失预测、共享信息、PNG、轮廓等）  
3. 绘图对象初始化  
4. 主仿真循环 `for t = 1:simulation_time/dt`
5. 后处理统计与可视化
6. 保存 `.log` 和 `.mat`

## 4) 主循环里实际发生了什么
每个时间步（`dt=0.1`）大致顺序：
1. 更新 3 个目标位置（分时入场，不同速度，不同路径）。
2. 对全局 EKF 和各传感器 EKF 做 prediction。
3. 检测阶段：
   - 已跟踪目标：使用本地 EKF 估计判断是否仍在检测半径内。
   - 新检测：用真值+测量噪声触发 EKF 初始化。
4. 对每个目标的 active trackers 做丢失预测：
   - 必须先通过 EKF 收敛门限（速度方差阈值）。
   - 丢失预测还需通过稳定性门限（连续稳定次数）。
5. 触发拦截流程：
   - `NONE -> PENDING_BROADCAST -> PENDING_BIDDING -> PENDING_SELECTION -> NONE`
   - 正常情况：选 bid 最低的两个传感器作为 interceptor。
   - 多目标同时触发：进入冲突消解（minimax）。
6. 系统级 FSM 更新（`IDLE/TRACKING/SEARCHING/REACQUIRING`）。
7. 传感器级 FSM 更新（`IDLE/DETECTING/TRACKING/INTERCEPTING/SEARCHING/RETURNING_HOME`）。
8. 按状态推进传感器运动：
   - TRACKING：追 EKF 估计位置
   - INTERCEPTING：追拦截点，必要时叠加 PNG 导引
   - RETURNING_HOME：返航
9. 更新显示、统计、退出条件（目标出界后全体回家）。

## 5) 读代码时最重要的变量
- `active_trackers{target_id}`：每个目标当前 tracker 列表（目标约束是 2 个）。
- `sensor_states{i}` / `sensor_roles{i}`：传感器状态和角色。
- `sensor_ekf_states{i,target_id}` / `sensor_P_matrices{i,target_id}`：本地 EKF。
- `interceptor_process_state{target_id}`：交接流程状态机。
- `interceptor_process_data{target_id}`：本次交接的预测点、拦截点、触发器等数据。
- `proactive_targets{i}`：某传感器当前拦截目标点。
- `interceptor_call_triggered(target_id)`：目标级交接触发锁。

## 6) 辅助函数职责（脚本内）
- `predictTrackerLoss(...)`：计算 tracker 预计丢失时刻和位置。
- `isEKFConverged(...)`：EKF 收敛判定（速度协方差门限）。
- `getSharedTargetInfo(...)`：邻居信息融合与置信度估计。
- `calculateEnhancedBid(...)`：竞价评分（home/spatial/temporal/uncertainty 加权）。
- `calculatePNGAcceleration(...)`：拦截时 PNG 导引加速度。
- `generate3SigmaContour(...)`：搜索阶段不确定性轮廓。

## 7) 运行与产物
- 运行：在 MATLAB 中执行 `example_V45_V38_b`。
- 输出：
  - `logs/wsn_log_<timestamp>.log`
  - `wsn_data_<timestamp>.mat`
- `.mat` 里保存了重放和分析关键量：`node_positions_history`、`interceptor_events`、`sensor_state_history`、`target_trajectories` 等。

## 8) 当前代码理解下的注意点（后续重构优先）
- 单文件过大，逻辑耦合高（FSM/运动/绘图/统计混在主循环），建议先拆：
  1) `step_targets`
  2) `step_detection_and_ekf`
  3) `step_handover`
  4) `step_fsm`
  5) `step_motion`
  6) `step_render`
- `INTERCEPTING` 与 `RETURNING_HOME` 的状态处理在不同区段有重复逻辑，后续改动易引入不一致。
- 冲突消解分支复杂，且与普通竞价分支共享变量较多，调试时优先看日志标签：
  - `[HANDOVER]`, `[BIDDING]`, `[CONFLICT]`, `[ASSIGN]`, `[INTERCEPT]`, `[STATUS]`。

## 9) 给后续 Agent 的实操建议
- 先固定随机种子（脚本已 `rng(0)`），每次只改一类逻辑并比对日志。
- 先看 `active_trackers` 与 `sensor_states` 是否一致，再看轨迹和图像。
- 如果要调参数，优先：`EKF_VELOCITY_CONVERGENCE_THRESHOLD`、`PREDICTION_STABILITY_THRESHOLD`、`MIN_STABLE_PREDICTIONS`、`w1..w4`。

