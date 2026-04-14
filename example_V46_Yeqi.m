% WSN Cooperative Tracking with Finite State Machine Architecture
% Date: 22 May 2025
% Revision: 19 July 2025 - FSM Implementation - incorporating Prof's
% TU: time unit
% comments - adding IDLE role- fixing a bug with the primary-secondary role
% - Prof asked for target trajetory which looks like Military evasive maneuvers - sharp turns but not constantly turning.
% this is what he said: "Changes in motion direction should not be                 
% restricted to small variations.  They should be in the range of 15 to 30 degrees. Not too frequent."
% July 24th: Prof asked why S15 is chosen instead of S5 at t = 45 (s)? lots
% of debug output in this code. 
% July 25th: now i am trying to see if some sensors are nearer, they
% override the aheadness. 
% July 28th: Prof says: you need to stop the proximity override approach and simply choose the fastest sensor, period.
% July 29th: 5 new trajectories-I changed the base direction
% July 30th: DYNAMIC INTERCEPT CALCULATION
% August 2nd: Prof wants event-driven centralized control where the earliest loss prediction triggers a system-wide handover to 2 new interceptors.
% V18: tracking is reset in the FSM lines. diiferent results from the V17
% V19: got a lot of comments: had to move to V19
% V22: new trajectory applied
% V23: didnt work
% V24: 1- Changed sensor detection logic to use individual sensor EKF estimates instead of ground truth position for realistic tracking behavior
% 2- Added measurement noise to initial target detection using the existing R matrix parameter to simulate real sensor uncertainty
% 3- Modified EKF updates to use sensor-specific noisy measurements rather than perfect ground truth data for each individual sensor
% 4- Updated loss prediction calculations to use EKF estimated target position and velocity consistently instead of mixing ground truth and estimates
% 5- Fixed intercept point calculations to apply safety margins based on sensor estimates rather than ground truth target position
% 6- Improved sensor movement logic to track toward EKF estimated target positions eliminating backwards movement issues
% 7- Stored interceptor broadcast data using sensor perspective with EKF estimates for consistent decision making throughout the system
% 8- Ensured all noise parameters reference the existing R matrix values so changes to measurement noise affect the entire system automatically
% 9- Maintained the multi-step interceptor process with natural timing progression through prediction, broadcast, bidding, and selection phases
% 10- Preserved the distance-based bidding objective function while using realistic sensor information for all calculations

% V27: this is V24 with some changes to the interceptor. so any interceptor who
% V30: testing weights
% has converged EKF, can call for interceptors. 
% V31: Added dual target tracking: didn't work. moved to V32
% V31: Added dual target tracking capability with independent target trajectories and competitive bidding system
% V32: The issue is that interceptors are currently getting the "best"
% shared information from any target, not their assigned target. so i moved
% to V33
% V33: correcting the shared information issue, also Generate contours for
% all lost targets.
% V34: replaced the conflict resolution section with what i proposed to Prof
% V36: corrected conflict mode issue: the minimax optimization for dual
% targets was computationally intensive.  This creates a computational
% complexity of O(n^4) where n is the number of available sensors. With 23
% available sensors, that's about 23^4 = 279,841 combinations to check.then
% i edited it: This reduces the search space from 23^4 to roughly 12^4 =
% 20,736 combinations, making it about 13x faster while still finding
% near-optimal solutions.
% V37: 3 targets. I revised the legends to handle more than 3 targets. 

% Based on: Original cooperative tracking with interceptor strategy - no
% debug output

% V38_b: Interception logics is updated, no wobbling.

%

close all; clc;
clear;
rng(0);

%% Persistent logging setup
run_timestamp = datestr(now, 'yyyymmdd_HHMMSS');
if ~exist('logs', 'dir'), mkdir('logs'); end
log_filename  = sprintf('logs/wsn_log_%s.log', run_timestamp);
mat_filename  = sprintf('logs/wsn_data_%s.mat', run_timestamp);
global fid;
fid = fopen(log_filename, 'w');
if fid == -1, error('Cannot open log file: %s', log_filename); end
fprintf(fid, '[t= 0.00][INIT] Simulation started: %s\n', run_timestamp);

% Global variable for weight optimization
global OPTIMIZATION_WEIGHTS;
OPTIMIZATION_WEIGHTS = [];  % Empty means use defaults

%% FSM State Definitions
% System-level states
SYSTEM_STATES = struct(...
    'IDLE', 'IDLE', ...
    'TRACKING', 'TRACKING', ...
    'SEARCHING', 'SEARCHING', ...
    'REACQUIRING', 'REACQUIRING' ...
);

% Sensor-level states - ADDED RETURNING_HOME
SENSOR_STATES = struct(...
    'IDLE', 'IDLE', ...
    'DETECTING', 'DETECTING', ...
    'TRACKING', 'TRACKING', ...
    'INTERCEPTING', 'INTERCEPTING', ...
    'SEARCHING', 'SEARCHING', ...
    'RETURNING_HOME', 'RETURNING_HOME' ...
);

% Sensor roles (within states) - REMOVED BACKUP_TRACKER
SENSOR_ROLES = struct(...
    'NONE', 'NONE', ...
    'PRIMARY_TRACKER', 'PRIMARY_TRACKER', ...
    'SECONDARY_TRACKER', 'SECONDARY_TRACKER', ...
    'INTERCEPTOR_CANDIDATE', 'INTERCEPTOR_CANDIDATE' ...
);

%% Simulation Parameters
a = 1.5;                % Sensor coverage radius (increased by 50%)
node_spacing = 8*a;     % Distance between nodes
grid_size = 5;          % Grid size
dt = 0.1;               % Time step (delta_ts)
simulation_time = 75;   % Total simulation time
% target_velocity = 1.0;  % Target speed (units/s)  % Remove global target_velocity, now handled per target
sensor_velocity = 0.75;  % Sensor tracking speed (units/s)
randomness = 0.5;       % Target movement randomness
update_frequency = 1;  % Display update frequency

MAX_ACTIVE_TRACKERS = 2;  % Always exactly 2 trackers per target
SAFETY_MARGIN = 0.1;      % 10% safety margin for interception
communication_range = node_spacing * 1.5;  % units- we are actually broadcasting globally so this variable is not used for now
EKF_VELOCITY_CONVERGENCE_THRESHOLD = 0.006;  % Velocity variance threshold (units²/s²)
PREDICTION_STABILITY_THRESHOLD = 0.5;        % Time difference threshold (TUs)
MIN_STABLE_PREDICTIONS = 2;                  % Need at least 2 consecutive stable predictions
USE_MCMF_ASSIGNMENT = true;                  % V46 switch for A/B testing against legacy assignment

% Grid dimensions (staggered hex grid, including sensor coverage radius)
nx = grid_size;   % number of columns
ny = grid_size;   % number of rows

wsn_width  = (nx-1)*node_spacing + 0.5*node_spacing + 2*a;   % +a left, +a right
wsn_height = (ny-1)*node_spacing*sqrt(3)/2 + 2*a;            % +a bottom, +a top

fprintf(fid, '[t= 0.00][INIT] Node spacing: %.2f, Communication range: %.2f\n', node_spacing, communication_range);
fprintf(fid, '[t= 0.00][INIT] WSN dimensions: %.2f x %.2f\n', wsn_width, wsn_height);

%% Initialize FSM State Variables
% System state
system_state = SYSTEM_STATES.IDLE;
system_state_history = [0, string(system_state)];

% Per-sensor states and roles
num_nodes = grid_size * grid_size;
sensor_states = repmat({SENSOR_STATES.IDLE}, num_nodes, 1);
sensor_roles = repmat({SENSOR_ROLES.NONE}, num_nodes, 1);
sensor_state_history = cell(num_nodes, 1);

% NEW: three target setup
num_targets = 2;  % Or make this configurable
waypoints_list = cell(num_targets, 1);
% waypoints_list{1} = [0,-0.308; 10,-0.308; 25,3.6920; 36,9.6920; 48,22.6920; 55,32.6920; 70,44.6920];
% waypoints_list{2} = [0,4.692; 10,4.692; 25,10; 36,14.692; 48,27.692; 55,37.692; 70,49.692];
% waypoints_list{3} = [0,15; 15,20; 30,25; 45,30; 60,35; 70,40; 80,45];  % Third target path


% Target state arrays
target_positions = zeros(num_targets, 2);
target_trajectories = cell(num_targets, 1);
current_waypoint_idx = ones(num_targets, 1);
noise = 0.01;


waypoints_list = cell(num_targets, 1);

% % EXAMPLE 1
% waypoints_list{1} = [0,-0.308; 10,-0.308; 25,3.6920; 36,9.6920; 48,22.6920; 55,32.6920; 70,44.6920]; % lower left to upper right
% waypoints_list{2} = [0,41.56; 10,41.56; 25,37.56; 36,31.56; 48,18.56; 55,8.56; 70,-3.4]; % upper left to bottom right

% % waypoint 1：y + 10
% waypoints_list{1}(:,2) = waypoints_list{1}(:,2) + 10;

% % waypoint 2：y - 10
% waypoints_list{2}(:,2) = waypoints_list{2}(:,2) - 10;

% % Different speeds per target
% target_velocities = [1.0, 1.0];  % Target 1: normal, Target 2: slightly faster
% % Different entry times
% target_start_time = [0.0, 0.0];  % Staggered entry times

% % Initialize with time lag - Target 2 starts later
% target_positions(1, :) = waypoints_list{1}(1, :);  % Target 1 starts immediately
% target_positions(2, :) = waypoints_list{2}(1, :);
% target_trajectories{1} = target_positions(1, :);
% target_trajectories{2} = target_positions(2, :);

% Example 2
% Same-direction trajectories with time lag
waypoints_list{1} = [0,-0.308; 10,-0.308; 25,3.6920; 36,9.6920; 48,22.6920; 55,32.6920; 70,44.6920];  % lower left to upper right
waypoints_list{2} = [0,4.692; 10,4.692; 25,10; 36,14.692; 48,27.692; 55,37.692; 70,49.692]; % parallel path above target 1

target_velocities = [1.0, 1.0]; 
% Add time lag control
target_start_time = [0, 0.0];  % Target 2 starts 2 seconds later

% Initialize with time lag - Target 2 starts later
target_positions(1, :) = waypoints_list{1}(1, :);  % Target 1 starts immediately
target_positions(2, :) = [0, 0];  % Target 2 starts off-screen, will enter later
target_trajectories{1} = target_positions(1, :);
target_trajectories{2} = target_positions(2, :);



% % Different speeds per target
% target_velocities = [1.0, 1.1, 1.2];  % Target 1: normal, Target 2: slower, Target 3: faster
% % target_velocities = [1.0, 1.3, 1.5];

% % Different entry times
% target_start_time = [0, 4.0, 6.5];  % Staggered entry times

% % Target state arrays
% target_positions = zeros(num_targets, 2);
% target_trajectories = cell(num_targets, 1);
% current_waypoint_idx = ones(num_targets, 1);
% noise = 0.01;

% % Initialize with time lag - Target 2 starts later
% target_positions(1, :) = waypoints_list{1}(1, :);  % Target 1 starts immediately
% target_positions(2, :) = [-15, 0];  % Target 2 starts off-screen, will enter later
% target_trajectories{1} = target_positions(1, :);
% target_trajectories{2} = target_positions(2, :);

% NEW: Prediction stability tracking per target
previous_loss_predictions = zeros(num_nodes, num_targets);     % Track previous prediction for each sensor-target pair
stable_prediction_counts = zeros(num_nodes, num_targets);     % Count consecutive stable predictions per sensor-target

% Initialize state history
for i = 1:num_nodes
    sensor_state_history{i} = [0, string(SENSOR_STATES.IDLE), string(SENSOR_ROLES.NONE)];
end

% NEW: Multi-step natural interceptor process per target
interceptor_process_state = repmat({'NONE'}, num_targets, 1);  % Per-target process states
interceptor_process_data = cell(num_targets, 1);              % Per-target process data
interceptor_bids = zeros(num_nodes, num_targets);              % Bids per sensor per target
interceptor_valid_bidders = cell(num_targets, 1);             % Valid bidders per target

% NEW: Global storage for plotting per target
global_interceptor_data = cell(num_targets, 1);  % Store for plotting later

%% Create 5×5 grid with staggered rows
full_grid = [];
for row = 1:grid_size
    for col = 1:grid_size
        x = (col - 1) * node_spacing;
        y = (row - 1) * node_spacing * sqrt(3)/2;
        if mod(row,2) == 1
            x = x + node_spacing / 2;  % Stagger odd rows
        end
        full_grid = [full_grid; x, y];
    end
end

node_positions = full_grid;
original_positions = node_positions;

%% Initialize tracking variables - UPDATED FOR three TARGETS
active_trackers = cell(num_targets, 1);           % Array of currently active tracking sensors per target
for t = 1:num_targets
    active_trackers{t} = [];
end
sensor_trajectories = cell(num_nodes, 1);

% ADD THIS: Performance tracking
total_successful_intercepts = 0;
interceptor_call_counter = 0;

% NEW: Individual tracker loss prediction per target
individual_loss_predictions = zeros(num_nodes, num_targets);  % Time when each tracker predicts loss per target
loss_prediction_points = cell(num_nodes, num_targets);       % Where each tracker predicts loss per target
interceptor_call_triggered = false(num_targets, 1);          % Flag to ensure single interceptor call per target
sensor_interceptor_call_history = false(num_nodes, num_targets);

interceptor_call_time = zeros(num_targets, 1);               % When interceptor call was made per target

% NEW: Returning home logic
sensors_returning_home = [];    % Sensors in RETURNING_HOME state
return_progress = zeros(num_nodes, 1);  % Progress toward home (0-1)

% Per-sensor EKF tracking per target
sensor_ekf_states = cell(num_nodes, num_targets);
sensor_P_matrices = cell(num_nodes, num_targets);
sensor_P_trace_history = cell(num_nodes, num_targets);
sensor_detection_times = zeros(num_nodes, num_targets);

detected_sensors = cell(num_targets, 1);  % Track sensors that have detected each target
for t = 1:num_targets
    detected_sensors{t} = [];
end

% Initialize contour touch tracking
sensors_touched_3sigma = zeros(num_nodes, 1);
sensors_touched_2sigma = zeros(num_nodes, 1);
sensors_touched_1sigma = zeros(num_nodes, 1);

% Initialize variables to track the 3-sigma contour swept area
all_contour_points = [];

% Add proactive tracking variables
proactive_targets = cell(num_nodes, 1);
target_loss_processed = false;

%% Initialize EKF variables per target
ekf_states = cell(num_targets, 1);
P_matrices = cell(num_targets, 1);
for t = 1:num_targets
    ekf_states{t} = [target_positions(t, :) 0 0]';
    P_matrices{t} = eye(4);
end

Q = 0.01 * eye(2);  % Process noise
R = 0.0025 * eye(2); % Measurement noise

% Capture all scalar parameters for MAT file
params = struct('a', a, 'node_spacing', node_spacing, 'dt', dt, ...
    'simulation_time', simulation_time, 'sensor_velocity', sensor_velocity, ...
    'target_velocities', target_velocities, 'target_start_time', target_start_time, ...
    'Q', Q, 'R', R, 'num_targets', num_targets, 'grid_size', grid_size, ...
    'EKF_VELOCITY_CONVERGENCE_THRESHOLD', EKF_VELOCITY_CONVERGENCE_THRESHOLD, ...
    'PREDICTION_STABILITY_THRESHOLD', PREDICTION_STABILITY_THRESHOLD, ...
    'MIN_STABLE_PREDICTIONS', MIN_STABLE_PREDICTIONS, ...
    'SAFETY_MARGIN', SAFETY_MARGIN, 'rng_seed', 0, ...
    'USE_MCMF_ASSIGNMENT', USE_MCMF_ASSIGNMENT);

% Track covariance history for analysis
covariance_history = struct();
covariance_history.time = [];
covariance_history.sensor = [];
covariance_history.target = [];
covariance_history.covariance = {};
covariance_history.state = {};

%% Initialize search variables
contour_points = [];
last_tracker = -1;
contour_update_interval = 10;
last_contour_update_time = 0;
inner_contour_points = [];
middle_contour_points = [];

contour_periods = [];
current_contour_period = [];
last_contour_state = 0;

%% FSM Helper Functions

% Log sensor state/role transition to log file
function logStateTransition(sensor_id, old_state, new_state, old_role, new_role, time, reason)
    if strcmp(old_state, new_state) && strcmp(old_role, new_role)
        return; % No change — nothing to log
    end
    global fid;
    fprintf(fid, '[t=%5.2f][FSM] Sensor %2d: %s/%s -> %s/%s | %s\n', ...
        time, sensor_id, old_state, old_role, new_state, new_role, reason);
end

% Log system-level FSM transition to log file
function logSystemTransition(old_state, new_state, time, reason)
    if strcmp(old_state, new_state)
        return; % No change — nothing to log
    end
    global fid;
    fprintf(fid, '[t=%5.2f][SYS] System: %s -> %s | %s\n', time, old_state, new_state, reason);
end

% NEW: Calculate when a tracker will lose the target
function [loss_time, loss_point] = predictTrackerLoss(sensor_id, current_time, sensor_pos, target_pos, target_vel, detection_radius)
    if norm(target_vel) < 0.01
        loss_time = inf;
        loss_point = target_pos;
        return;
    end
    
    sensor_speed = 0.75;
    track_direction = target_pos - sensor_pos;
    current_distance = norm(track_direction);
    
    if current_distance > 0
        track_direction = track_direction / current_distance;
    else
        track_direction = [0, 0];
    end
    
    sensor_vel = track_direction * sensor_speed;
    relative_vel = target_vel - sensor_vel;
    
    if norm(relative_vel) < 0.01
        loss_time = inf;
        loss_point = target_pos;
        return;
    end
    
    rel_pos = target_pos - sensor_pos;
    
    a = dot(relative_vel, relative_vel);
    b = 2 * dot(rel_pos, relative_vel);
    c = dot(rel_pos, rel_pos) - detection_radius^2;
    
    discriminant = b^2 - 4*a*c;
    
    if discriminant < 0
        if norm(rel_pos) > detection_radius
            loss_time = current_time;
            loss_point = target_pos;
        else
            loss_time = inf;
            loss_point = target_pos;
        end
        return;
    end
    
    t1 = (-b + sqrt(discriminant)) / (2*a);
    t2 = (-b - sqrt(discriminant)) / (2*a);
    
    if t1 > 0.1 && t2 > 0.1
        loss_dt = max(t1, t2);
    elseif t1 > 0.1
        loss_dt = t1;
    elseif t2 > 0.1
        loss_dt = t2;
    else
        loss_dt = 0.1;
    end
    
    loss_time = current_time + loss_dt;
    loss_point = target_pos + target_vel * loss_dt;
end

% NEW: Apply safety margin to intercept point
function safe_intercept_point = applySafetyMargin(sensor_pos, loss_point, safety_margin)
    direction = loss_point - sensor_pos;
    safe_distance = norm(direction) * (1 - safety_margin);  % 90% of distance
    if norm(direction) > 0
        safe_intercept_point = sensor_pos + (direction / norm(direction)) * safe_distance;
    else
        safe_intercept_point = loss_point;
    end
    
    % Ensure output is same shape as sensor_pos (1x2 row vector)
    if size(safe_intercept_point, 1) > size(safe_intercept_point, 2)
        safe_intercept_point = safe_intercept_point';
    end
end

% NEW: Find sensor farthest from home position
function farthest_sensor = findFarthestSensorFromHome(sensor_list, current_positions, original_positions)
    if isempty(sensor_list)
        farthest_sensor = [];
        return;
    end
    
    max_distance = 0;
    farthest_sensor = sensor_list(1);
    
    for i = 1:length(sensor_list)
        sensor_id = sensor_list(i);
        distance_from_home = norm(current_positions(sensor_id,:) - original_positions(sensor_id,:));
        if distance_from_home > max_distance
            max_distance = distance_from_home;
            farthest_sensor = sensor_id;
        end
    end
end

function a_PNG = calculatePNGAcceleration(robot_pos, robot_vel, target_pos, target_vel, lambda)
    LOS_vector = target_pos - robot_pos;
    
    if norm(LOS_vector) < 0.001
        a_PNG = [0, 0];
        return;
    end
    
    rel_velocity = target_vel - robot_vel;
    
    LOS_cross_rel_vel = LOS_vector(1) * rel_velocity(2) - LOS_vector(2) * rel_velocity(1);
    theta_dot_LOS = LOS_cross_rel_vel / (norm(LOS_vector)^2);
    
    if norm(robot_vel) > 0.001
        vel_normalized = robot_vel / norm(robot_vel);
        normal_direction = [-vel_normalized(2), vel_normalized(1)];
        a_PNG = lambda * norm(robot_vel) * theta_dot_LOS * normal_direction;
    else
        LOS_normalized = LOS_vector / norm(LOS_vector);
        normal_direction = [-LOS_normalized(2), LOS_normalized(1)];
        a_PNG = lambda * theta_dot_LOS * normal_direction;
        % a_PNG = a_PNG * 5.0;
    end
end

function contour_points = generate3SigmaContour(center, covariance, confidence, points)
    chi2val = chi2inv(confidence, 2);
    [eigVec, eigVal] = eig(covariance);
    
    theta = linspace(0, 2*pi, points);
    xy = [cos(theta); sin(theta)];
    
    xy = sqrt(chi2val) * sqrtm(eigVal) * xy;
    xy = eigVec * xy;
    
    x = xy(1,:) + center(1);
    y = xy(2,:) + center(2);
    
    contour_points = [x', y'];
end

% this function is to check EKF convergence
function converged = isEKFConverged(P_matrix, threshold)
    vel_x_variance = P_matrix(3,3);
    vel_y_variance = P_matrix(4,4);
    converged = (vel_x_variance < threshold) && (vel_y_variance < threshold);
end

%% Initialize plot
fig = figure(2); clf;
set(fig, 'Position', [100, 100, 1200, 800]);
hold on; grid on; axis equal;
xlim([-10, 80]);
ylim([-15, 60]);
xlabel('X (unit)'); ylabel('Y (unit)');
title('WSN FSM three Target Tracking - Time: 0.0 s, System State: IDLE');

% Plot sensor grid
th = 0:pi/50:2*pi;
xunit = a * cos(th); yunit = a * sin(th);
node_handles = gobjects(num_nodes, 1);
circle_handles = gobjects(num_nodes, 1);

for i = 1:num_nodes
    node_handles(i) = plot(node_positions(i,1), node_positions(i,2), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b');
    circle_handles(i) = fill(xunit + node_positions(i,1), yunit + node_positions(i,2), 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'b');
end

% Add sensor number labels
sensor_text_handles = gobjects(num_nodes, 1);
for i = 1:num_nodes
    sensor_text_handles(i) = text(node_positions(i,1)+0.3, node_positions(i,2)+0.3, ...
        sprintf('%d', i), 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
end

% Initialize three targets
target_handles = gobjects(num_targets, 1);
trajectory_handles = gobjects(num_targets, 1);
target_colors = {'r', 'g', 'b', 'm', 'c', 'k'};  % Support up to 6 targets

for t = 1:num_targets
    target_handles(t) = plot(target_positions(t,1), target_positions(t,2), [target_colors{t} '*'], 'MarkerSize', 10);
    trajectory_handles(t) = plot(target_positions(t,1), target_positions(t,2), [target_colors{t} '-'], 'LineWidth', 1);
end

status_text = text(-12, -10, 'System: IDLE | No targets detected', 'BackgroundColor', 'white', 'EdgeColor', 'black', 'Margin', 3, 'FontSize', 12);

% Handles for contours
contour_handles = [];
contour_3sigma_handle = [];
swept_area_handle = [];

%% Track target point history for all sensors
sensor_target_history = cell(num_nodes, 1);
for i = 1:num_nodes
    sensor_target_history{i} = [];
end

% Trajectory tracking parameters
TRACK_SENSOR_ID = 18;  % Change this to track different sensors (3, 8, 14, 20, etc.)
sensor_trajectory_history = [];  % Will store [time, x, y, state] for the tracked sensor


% NEW: Add processing delays for interceptor calls
interceptor_process_delay = zeros(num_targets, 1);  % Processing delay counter per target


% Confidence tracking for analysis
confidence_data = [];  % Will store [time, sensor_id, target_id, confidence]

% NEW: Full sensor position history for MAT replay
node_positions_history = zeros(round(simulation_time/dt), num_nodes, 2);

% NEW: Structured log of every interceptor handover event
interceptor_events = struct('time', {}, 'target_id', {}, 'predictor_sensor', {}, ...
    'selected_sensors', {}, 'selected_costs', {}, 'intercept_point', {}, 'loss_time', {});

assignment_events = struct('time', {}, 'algorithm', {}, 'calling_targets', {}, ...
    'candidate_sensors', {}, 'requested_slots_per_target', {}, ...
    'assigned_slots_per_target', {}, 'assigned_slots_total', {}, ...
    'assignments', {}, 'selected_costs', {}, 'assignment_costs_per_target', {}, ...
    'total_cost', {}, 'cost_matrix', {}, ...
    'mcmf_assignments', {}, 'mcmf_selected_costs', {}, ...
    'mcmf_assignment_costs_per_target', {}, 'mcmf_total_cost', {}, ...
    'legacy_assignments', {}, 'legacy_selected_costs', {}, ...
    'legacy_assignment_costs_per_target', {}, 'legacy_total_cost', {}, ...
    'comparison_delta_total_cost', {});

interceptor_employ_events = struct('time', {}, 'sensor_id', {}, ...
    'from_target_id', {}, 'to_target_id', {}, 'algorithm', {}, ...
    'previous_intercept_point', {}, 'new_intercept_point', {}, 'new_assignment_cost', {});

%% Main simulation loop
for t = 1:simulation_time/dt
    current_time = t * dt;
    node_positions_history(t, :, :) = node_positions;

    %% Move multiple targets with different speeds
    for target_id = 1:num_targets
        if current_time >= target_start_time(target_id) && t > 1 && current_waypoint_idx(target_id) < size(waypoints_list{target_id}, 1)
            if current_time == target_start_time(target_id)
                target_positions(target_id, :) = waypoints_list{target_id}(1, :);
            end
            
            dir = waypoints_list{target_id}(current_waypoint_idx(target_id) + 1, :) - target_positions(target_id, :);
            dist = norm(dir);
            if dist < 0.5
                current_waypoint_idx(target_id) = current_waypoint_idx(target_id) + 1;
            else
                dir = dir/dist + randn(1,2)*noise;
                target_positions(target_id, :) = target_positions(target_id, :) + (dir/norm(dir)) * target_velocities(target_id) * dt;
            end
            target_trajectories{target_id} = [target_trajectories{target_id}; target_positions(target_id, :)];
        end
    end
    
    %% EKF prediction for all targets
    F = [1, 0, dt, 0;
         0, 1, 0, dt;
         0, 0, 1, 0;
         0, 0, 0, 1];
    G = [dt^2/2, 0;
         0, dt^2/2;
         dt, 0;
         0, dt];
    Q_k = G * Q * G';
    
    % Predict global EKF states for each target
    for target_id = 1:num_targets
        ekf_states{target_id} = F * ekf_states{target_id};
        P_matrices{target_id} = F * P_matrices{target_id} * F' + Q_k;
    end
    
    % Predict for all active sensor EKFs per target
    for i = 1:num_nodes
        for target_id = 1:num_targets
            if sensor_detection_times(i, target_id) > 0
                sensor_ekf_states{i, target_id} = F * sensor_ekf_states{i, target_id};
                sensor_P_matrices{i, target_id} = F * sensor_P_matrices{i, target_id} * F' + Q_k;
                
                sensor_P_trace_history{i, target_id} = [sensor_P_trace_history{i, target_id}; ...
                    current_time, trace(sensor_P_matrices{i, target_id})];
            end
        end
    end
    
    %% Check for sensor detections (using individual sensor estimates)
    detecting_sensors = [];  % Will store [sensor_id, target_id] pairs
    
    for i = 1:num_nodes
        sensor_pos = node_positions(i,:);
        detected_targets_this_sensor = [];
        
        % Check each target
        for target_id = 1:num_targets
            target_detected = false;
            
            % Check if sensor has any target estimate for this target
            if sensor_detection_times(i, target_id) > 0 && ~isempty(sensor_ekf_states{i, target_id})
                % Sensor is tracking this target - use its own EKF estimate
                estimated_target_pos = sensor_ekf_states{i, target_id}(1:2)';
                distance_to_estimate = norm(sensor_pos - estimated_target_pos);
                
                % Check if estimated target is within sensor range
                if distance_to_estimate <= a 
                    target_detected = true;
                end
                
            else
                % Sensor not tracking this target yet - check for new detection using ground truth
                distance_to_actual = norm(sensor_pos - target_positions(target_id, :));
                
                if distance_to_actual <= a 
                    % First-time detection - add measurement noise
                    measurement_noise_std = sqrt(R(1,1));
                    noisy_detection = target_positions(target_id, :) + randn(1,2) * measurement_noise_std;
                    
                    % Verify noisy detection is still within range (realistic check)
                    distance_to_noisy = norm(sensor_pos - noisy_detection);
                    if distance_to_noisy <= a
                        target_detected = true;
                        
                        % Initialize EKF with noisy first detection
                        sensor_detection_times(i, target_id) = current_time;
                        sensor_ekf_states{i, target_id} = [noisy_detection'; 0; 0];  % Position + zero velocity
                        sensor_P_matrices{i, target_id} = eye(4);
                        sensor_P_trace_history{i, target_id} = [current_time, trace(sensor_P_matrices{i, target_id})];
                    end
                end
            end
            
            if target_detected
                detected_targets_this_sensor = [detected_targets_this_sensor; target_id];
            end
        end
        
        % Sensor chooses nearest target if multiple detected
        if ~isempty(detected_targets_this_sensor)
            if length(detected_targets_this_sensor) == 1
                chosen_target = detected_targets_this_sensor(1);
            else
                % Choose nearest target
                distances_to_targets = zeros(length(detected_targets_this_sensor), 1);
                for k = 1:length(detected_targets_this_sensor)
                    tid = detected_targets_this_sensor(k);
                    distances_to_targets(k) = norm(sensor_pos - target_positions(tid, :));
                end
                [~, min_idx] = min(distances_to_targets);
                chosen_target = detected_targets_this_sensor(min_idx);
            end
            
            detecting_sensors = [detecting_sensors; i, chosen_target];
        end
    end
    
    %% NEW: Individual Tracker Loss Prediction per target (with EKF convergence + stability check)
    % Process each target independently
    for target_id = 1:num_targets
        current_active_trackers = active_trackers{target_id};
        
        if ~isempty(current_active_trackers)

            % fprintf('[DEBUG t=%.1f] Target %d: Checking %d active trackers, call_triggered=%d\n', ...
            % current_time, target_id, length(current_active_trackers), interceptor_call_triggered(target_id));
            % 
            % Reset interceptor call flag only when appropriate
            if interceptor_call_triggered(target_id)
                % Find current interceptors for this target
                current_interceptors = find(cellfun(@(x) strcmp(x, SENSOR_STATES.INTERCEPTING), sensor_states));
                
                should_reset = false;
                
                % Check if original caller is still actively tracking this target
                if interceptor_call_triggered(target_id) && ~isempty(find(individual_loss_predictions(:, target_id) > 0))
                    earliest_active_predictor = find(individual_loss_predictions(:, target_id) == min(individual_loss_predictions(individual_loss_predictions(:, target_id) > 0, target_id)), 1);
                    if isempty(earliest_active_predictor) || ~ismember(earliest_active_predictor, current_active_trackers) || ...
                       ~strcmp(sensor_states{earliest_active_predictor}, SENSOR_STATES.TRACKING)
                        should_reset = true;
                    end
                end
                
                % Check if any interceptors have successfully transitioned to tracking
                for interceptor_id = current_interceptors'
                    if strcmp(sensor_states{interceptor_id}, SENSOR_STATES.TRACKING)
                        should_reset = true;
                        break;
                    end
                end
                
                if should_reset
                    interceptor_call_triggered(target_id) = false;
                end
            end
            
            % Each active tracker individually predicts when it will lose this target
            earliest_loss_time = inf;
            earliest_loss_sensor = -1;
            
            for i = 1:length(current_active_trackers)
                tracker_id = current_active_trackers(i);
                
                % Only predict if tracker is still tracking
                if strcmp(sensor_states{tracker_id}, SENSOR_STATES.TRACKING)
                    
                    % STEP 1: CHECK EKF CONVERGENCE FIRST
                    if ~isempty(sensor_P_matrices{tracker_id, target_id})
                        P = sensor_P_matrices{tracker_id, target_id};
                        ekf_converged = isEKFConverged(P, EKF_VELOCITY_CONVERGENCE_THRESHOLD);
                        
                        if ~ekf_converged
                            continue; % Skip this tracker - wait for convergence
                        end
                        
                        % STEP 2: MAKE LOSS PREDICTION with converged EKF
                        ekf_target_position = sensor_ekf_states{tracker_id, target_id}(1:2)';
                        target_vel_estimate = sensor_ekf_states{tracker_id, target_id}(3:4)';
                        
                        [loss_time, loss_point] = predictTrackerLoss(tracker_id, current_time, ...
                            node_positions(tracker_id,:), ekf_target_position, target_vel_estimate, a);
                        
                        % STEP 3: CHECK PREDICTION STABILITY
                        if previous_loss_predictions(tracker_id, target_id) > 0
                            prediction_difference = abs(loss_time - previous_loss_predictions(tracker_id, target_id));
                            
                            if prediction_difference < PREDICTION_STABILITY_THRESHOLD
                                stable_prediction_counts(tracker_id, target_id) = stable_prediction_counts(tracker_id, target_id) + 1;
                            else
                                stable_prediction_counts(tracker_id, target_id) = 1;
                            end
                        else
                            stable_prediction_counts(tracker_id, target_id) = 1;
                        end
                        
                        % Update tracking
                        previous_loss_predictions(tracker_id, target_id) = loss_time;
                        
                        % STEP 4: ONLY PROCEED if predictions are stable
                        if stable_prediction_counts(tracker_id, target_id) >= MIN_STABLE_PREDICTIONS
                            individual_loss_predictions(tracker_id, target_id) = loss_time;
                            loss_prediction_points{tracker_id, target_id} = loss_point;
                            
                            % Track earliest loss prediction for this target
                            if loss_time < earliest_loss_time
                                earliest_loss_time = loss_time;
                                earliest_loss_sensor = tracker_id;
                            end
                            
                            fprintf(fid, '[t=%5.2f][LOSS] Target %d: Tracker %d predicts loss at t=%.1f\n', ...
                                current_time, target_id, tracker_id, loss_time);
                        end
                    end
                
                end
            end
            
            % NEW: FIRST tracker to predict loss triggers interceptor call for this target
            if earliest_loss_sensor ~= -1 && ~interceptor_call_triggered(target_id) && strcmp(interceptor_process_state{target_id}, 'NONE') && ~sensor_interceptor_call_history(earliest_loss_sensor, target_id)
                
                fprintf(fid, '[t=%5.2f][HANDOVER] *** SENSOR %d CALLS INTERCEPTORS FOR TARGET %d *** Loss predicted at %.1f\n', ...
                     current_time, earliest_loss_sensor, target_id, earliest_loss_time);
                
                sensor_interceptor_call_history(earliest_loss_sensor, target_id) = true;
            
                % Start the multi-step process for this target
                interceptor_process_state{target_id} = 'PENDING_BROADCAST';
                interceptor_process_delay(target_id) = 0;  % 2 time steps processing delay
                
                interceptor_call_counter = interceptor_call_counter + 1;
                
                % Check if there are existing interceptors that will participate
                current_interceptors = find(cellfun(@(x) strcmp(x, SENSOR_STATES.INTERCEPTING), sensor_states));
                
                % Store broadcast data using EKF estimates
                loss_point = loss_prediction_points{earliest_loss_sensor, target_id};
                ekf_target_position = sensor_ekf_states{earliest_loss_sensor, target_id}(1:2)';
                
                safe_intercept_point = applySafetyMargin(ekf_target_position, loss_point, SAFETY_MARGIN);
                
                interceptor_process_data{target_id} = struct('predictor_id', earliest_loss_sensor, ...
                                                           'target_id', target_id, ...
                                                           'loss_time', earliest_loss_time, ...
                                                           'intercept_point', safe_intercept_point, ...
                                                           'target_position', ekf_target_position, ...
                                                           'loss_point', loss_point);
                
                % Store globally for plotting
                global_interceptor_data{target_id} = interceptor_process_data{target_id};

                % Append structured handover event (selected_sensors filled later)
                new_event = struct('time', current_time, 'target_id', target_id, ...
                    'predictor_sensor', earliest_loss_sensor, ...
                    'selected_sensors', [], ...
                    'selected_costs', [], ...
                    'intercept_point', safe_intercept_point, ...
                    'loss_time', earliest_loss_time);
                interceptor_events(end+1) = new_event;
            end
            
            % Multi-step natural interceptor process for this target
            switch interceptor_process_state{target_id}
                case 'PENDING_BROADCAST'
                    if interceptor_process_delay(target_id) > 0
                        interceptor_process_delay(target_id) = interceptor_process_delay(target_id) - 1;
                    else
                        interceptor_process_state{target_id} = 'PENDING_BIDDING';
                    end
                    
                case 'PENDING_BIDDING'
                    interceptor_process_state{target_id} = 'PENDING_SELECTION';
                    
                    % Each sensor calculates its own bid for this target
                    interceptor_bids(:, target_id) = zeros(num_nodes, 1);
                    interceptor_valid_bidders{target_id} = [];
                    
                    safe_intercept_point = interceptor_process_data{target_id}.intercept_point;
                    
                    for sensor_id = 1:num_nodes
                        % NEW: Simple eligibility check - exclude only active trackers
                        is_active_tracker = false;
                        for tid = 1:num_targets
                            if ismember(sensor_id, active_trackers{tid})
                                is_active_tracker = true;
                                break;
                            end
                        end
                        
                        % Can bid if: not an active tracker for any target
                        if ~is_active_tracker
                            % Get target velocity estimate from the calling tracker
                            if ~isempty(sensor_ekf_states{interceptor_process_data{target_id}.predictor_id, target_id})
                                target_vel_estimate = sensor_ekf_states{interceptor_process_data{target_id}.predictor_id, target_id}(3:4)';
                            else
                                target_vel_estimate = [0, 0];
                            end
                
                            % Get shared confidence for this sensor and target
                            [~, ~, confidence] = getSharedTargetInfo(sensor_id, node_positions, sensor_ekf_states, ...
                                sensor_detection_times, current_time, communication_range, target_id);
                
                            interceptor_bids(sensor_id, target_id) = calculateEnhancedBid(sensor_id, node_positions(sensor_id,:), ...
                                original_positions(sensor_id,:), safe_intercept_point, target_vel_estimate, confidence, ...
                                interceptor_process_data{target_id}.target_position, wsn_width, wsn_height);
                
                            interceptor_valid_bidders{target_id} = [interceptor_valid_bidders{target_id}; sensor_id];
                        end
                    end
                    
                case 'PENDING_SELECTION'

                    fprintf(fid, '[t=%5.2f][BIDDING] Target %d: PENDING_SELECTION with %d valid bidders: [%s]\n', ...
                        current_time, target_id, length(interceptor_valid_bidders{target_id}), ...
                        num2str(interceptor_valid_bidders{target_id}'));

                    interceptor_process_state{target_id} = 'NONE';
                    
                    % Get current interceptors before selection
                    current_interceptors = find(cellfun(@(x) strcmp(x, SENSOR_STATES.INTERCEPTING), sensor_states));
                    
                    other_targets_calling = [];
                    for other_tid = 1:num_targets
                        if other_tid ~= target_id && strcmp(interceptor_process_state{other_tid}, 'PENDING_SELECTION')
                            other_targets_calling = [other_targets_calling; other_tid];
                        end
                    end
                    
                    fprintf(fid, '[t=%5.2f][CONFLICT] Target %d: other_targets_calling = [%s]\n', ...
                       current_time, target_id, num2str(other_targets_calling'));
                    all_calling_targets = [target_id; other_targets_calling];
                    [available_sensors, assignment_cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
                        all_calling_targets, num_nodes, num_targets, active_trackers, node_positions, ...
                        original_positions, interceptor_process_data, sensor_ekf_states, ...
                        sensor_detection_times, current_time, communication_range, ...
                        wsn_width, wsn_height);

                    [mcmf_assignments, mcmf_info] = solveInterceptorAssignmentMCMF( ...
                        all_calling_targets, available_sensors, assignment_cost_matrix, ...
                        MAX_ACTIVE_TRACKERS);
                    [legacy_assignments, legacy_info] = solveInterceptorAssignmentLegacy( ...
                        all_calling_targets, available_sensors, assignment_cost_matrix, ...
                        MAX_ACTIVE_TRACKERS);

                    if USE_MCMF_ASSIGNMENT
                        selected_assignments = mcmf_assignments;
                        assignment_info = mcmf_info;
                    else
                        selected_assignments = legacy_assignments;
                        assignment_info = legacy_info;
                    end

                    fprintf(fid, ['[t=%5.2f][ASSIGN] %s selected for targets [%s] with %d candidates, ' ...
                        'requested=%d, assigned=%d, total_cost=%.3f\n'], ...
                        current_time, assignment_info.algorithm, num2str(all_calling_targets'), ...
                        length(available_sensors), assignment_info.requested_slots_total, ...
                        assignment_info.assigned_slots_total, assignment_info.total_cost);

                    fprintf(fid, ['[t=%5.2f][ASSIGN_COMPARE] targets=[%s] candidates=%d | ' ...
                        'MCMF assigned=%d total_cost=%.3f | LEGACY assigned=%d total_cost=%.3f | delta(MCMF-LEGACY)=%.3f\n'], ...
                        current_time, num2str(all_calling_targets'), length(available_sensors), ...
                        mcmf_info.assigned_slots_total, mcmf_info.total_cost, ...
                        legacy_info.assigned_slots_total, legacy_info.total_cost, ...
                        mcmf_info.total_cost - legacy_info.total_cost);

                    mcmf_selected_costs_by_target = cell(length(all_calling_targets), 1);
                    legacy_selected_costs_by_target = cell(length(all_calling_targets), 1);
                    selected_costs_by_target = cell(length(all_calling_targets), 1);
                    for log_idx = 1:length(all_calling_targets)
                        mcmf_team_for_log = mcmf_assignments{log_idx};
                        mcmf_costs_for_log = nan(size(mcmf_team_for_log));
                        mcmf_cost_text = '';
                        for cost_idx = 1:numel(mcmf_team_for_log)
                            selected_sensor = mcmf_team_for_log(cost_idx);
                            candidate_row = find(available_sensors == selected_sensor, 1);
                            if ~isempty(candidate_row)
                                mcmf_costs_for_log(cost_idx) = assignment_cost_matrix(candidate_row, log_idx);
                            end
                            mcmf_cost_text = [mcmf_cost_text, ...
                                sprintf('S%d=%.3f ', selected_sensor, mcmf_costs_for_log(cost_idx))]; %#ok<AGROW>
                        end
                        mcmf_selected_costs_by_target{log_idx} = mcmf_costs_for_log;
                        fprintf(fid, ['[t=%5.2f][BID_RESULT_COMPARE] MCMF target %d selected=[%s] ' ...
                            'selected_costs={%s} target_cost=%.3f\n'], ...
                            current_time, all_calling_targets(log_idx), num2str(mcmf_team_for_log), ...
                            strtrim(mcmf_cost_text), mcmf_info.assignment_costs_per_target(log_idx));

                        legacy_team_for_log = legacy_assignments{log_idx};
                        legacy_costs_for_log = nan(size(legacy_team_for_log));
                        legacy_cost_text = '';
                        for cost_idx = 1:numel(legacy_team_for_log)
                            selected_sensor = legacy_team_for_log(cost_idx);
                            candidate_row = find(available_sensors == selected_sensor, 1);
                            if ~isempty(candidate_row)
                                legacy_costs_for_log(cost_idx) = assignment_cost_matrix(candidate_row, log_idx);
                            end
                            legacy_cost_text = [legacy_cost_text, ...
                                sprintf('S%d=%.3f ', selected_sensor, legacy_costs_for_log(cost_idx))]; %#ok<AGROW>
                        end
                        legacy_selected_costs_by_target{log_idx} = legacy_costs_for_log;
                        fprintf(fid, ['[t=%5.2f][BID_RESULT_COMPARE] LEGACY target %d selected=[%s] ' ...
                            'selected_costs={%s} target_cost=%.3f\n'], ...
                            current_time, all_calling_targets(log_idx), num2str(legacy_team_for_log), ...
                            strtrim(legacy_cost_text), legacy_info.assignment_costs_per_target(log_idx));

                        if USE_MCMF_ASSIGNMENT
                            selected_costs_by_target{log_idx} = mcmf_costs_for_log;
                            selected_cost_text = mcmf_cost_text;
                        else
                            selected_costs_by_target{log_idx} = legacy_costs_for_log;
                            selected_cost_text = legacy_cost_text;
                        end
                        fprintf(fid, ['[t=%5.2f][BID_RESULT] %s target %d selected=[%s] ' ...
                            'selected_costs={%s} target_cost=%.3f\n'], ...
                            current_time, assignment_info.algorithm, all_calling_targets(log_idx), ...
                            num2str(selected_assignments{log_idx}), strtrim(selected_cost_text), ...
                            assignment_info.assignment_costs_per_target(log_idx));
                    end

                    new_assignment_event = struct( ...
                        'time', current_time, ...
                        'algorithm', assignment_info.algorithm, ...
                        'calling_targets', all_calling_targets', ...
                        'candidate_sensors', available_sensors', ...
                        'requested_slots_per_target', MAX_ACTIVE_TRACKERS, ...
                        'assigned_slots_per_target', assignment_info.assigned_slots_per_target', ...
                        'assigned_slots_total', assignment_info.assigned_slots_total, ...
                        'assignments', {selected_assignments}, ...
                        'selected_costs', {selected_costs_by_target}, ...
                        'assignment_costs_per_target', assignment_info.assignment_costs_per_target', ...
                        'total_cost', assignment_info.total_cost, ...
                        'cost_matrix', assignment_cost_matrix, ...
                        'mcmf_assignments', {mcmf_assignments}, ...
                        'mcmf_selected_costs', {mcmf_selected_costs_by_target}, ...
                        'mcmf_assignment_costs_per_target', mcmf_info.assignment_costs_per_target', ...
                        'mcmf_total_cost', mcmf_info.total_cost, ...
                        'legacy_assignments', {legacy_assignments}, ...
                        'legacy_selected_costs', {legacy_selected_costs_by_target}, ...
                        'legacy_assignment_costs_per_target', legacy_info.assignment_costs_per_target', ...
                        'legacy_total_cost', legacy_info.total_cost, ...
                        'comparison_delta_total_cost', mcmf_info.total_cost - legacy_info.total_cost);
                    assignment_events(end+1) = new_assignment_event;

                    for j = 1:length(all_calling_targets)
                        calling_tid = all_calling_targets(j);
                        selected_team = selected_assignments{j};
                        selected_team_costs = selected_costs_by_target{j};

                        if isempty(selected_team)
                            fprintf(fid, '[t=%5.2f][ASSIGN] Target %d: no interceptors assigned in this round\n', ...
                                current_time, calling_tid);
                            continue;
                        end

                        if length(all_calling_targets) == 1
                            losing_interceptors = setdiff(current_interceptors, selected_team);

                            for losing_interceptor = losing_interceptors'
                                is_working_other_target = false;
                                for tid = 1:num_targets
                                    if tid ~= calling_tid && length(losing_interceptor) == 1 && losing_interceptor > 0 && losing_interceptor <= num_nodes && ...
                                       ~isempty(proactive_targets) && length(proactive_targets) >= losing_interceptor && ...
                                       ~isempty(proactive_targets{losing_interceptor})
                                        for other_tid = 1:num_targets
                                            if other_tid ~= calling_tid && ~isempty(global_interceptor_data{other_tid}) && ...
                                               isfield(global_interceptor_data{other_tid}, 'intercept_point')
                                                other_intercept = global_interceptor_data{other_tid}.intercept_point;
                                                if norm(proactive_targets{losing_interceptor} - other_intercept) < 1.0
                                                    is_working_other_target = true;
                                                    break;
                                                end
                                            end
                                        end
                                    end
                                end

                                if ~is_working_other_target && ~isempty(losing_interceptor) && losing_interceptor > 0 && losing_interceptor <= num_nodes
                                    sensor_states{losing_interceptor} = SENSOR_STATES.RETURNING_HOME;
                                    sensor_roles{losing_interceptor} = SENSOR_ROLES.NONE;
                                    sensors_returning_home = [sensors_returning_home; losing_interceptor];
                                    proactive_targets{losing_interceptor} = [];

                                    logStateTransition(losing_interceptor, SENSOR_STATES.INTERCEPTING, SENSOR_STATES.RETURNING_HOME, ...
                                        SENSOR_ROLES.INTERCEPTOR_CANDIDATE, SENSOR_ROLES.NONE, current_time, ...
                                        'Lost rebidding process - returning home');
                                end
                            end
                        end

                        safe_intercept_point = interceptor_process_data{calling_tid}.intercept_point;

                        for winner_idx = 1:numel(selected_team)
                            winner = selected_team(winner_idx);
                            winner_cost = selected_team_costs(winner_idx);
                            if ismember(winner, current_interceptors)
                                previous_assigned_target = -1;
                                previous_intercept_point = [];

                                if ~isempty(proactive_targets) && length(proactive_targets) >= winner && ...
                                   ~isempty(proactive_targets{winner})
                                    previous_intercept_point = proactive_targets{winner};
                                    for previous_tid = 1:num_targets
                                        if previous_tid ~= calling_tid && ~isempty(global_interceptor_data{previous_tid}) && ...
                                           isfield(global_interceptor_data{previous_tid}, 'intercept_point')
                                            previous_target_point = global_interceptor_data{previous_tid}.intercept_point;
                                            if norm(previous_intercept_point - previous_target_point) < 1.0
                                                previous_assigned_target = previous_tid;
                                                break;
                                            end
                                        end
                                    end
                                end

                                if previous_assigned_target > 0
                                    fprintf(fid, ['[t=%5.2f][EMPLOY] Sensor %d was executing target %d intercept ' ...
                                        'and is now employed by target %d (%s); new_cost=%.3f, ' ...
                                        'previous_point=[%.2f,%.2f], new_point=[%.2f,%.2f]\n'], ...
                                        current_time, winner, previous_assigned_target, calling_tid, ...
                                        assignment_info.algorithm, winner_cost, previous_intercept_point(1), ...
                                        previous_intercept_point(2), safe_intercept_point(1), safe_intercept_point(2));

                                    new_employ_event = struct( ...
                                        'time', current_time, ...
                                        'sensor_id', winner, ...
                                        'from_target_id', previous_assigned_target, ...
                                        'to_target_id', calling_tid, ...
                                        'algorithm', assignment_info.algorithm, ...
                                        'previous_intercept_point', previous_intercept_point, ...
                                        'new_intercept_point', safe_intercept_point, ...
                                        'new_assignment_cost', winner_cost);
                                    interceptor_employ_events(end+1) = new_employ_event;
                                end

                                proactive_targets{winner} = safe_intercept_point;
                            else
                                old_state = sensor_states{winner};
                                old_role = sensor_roles{winner};
                                sensor_states{winner} = SENSOR_STATES.INTERCEPTING;
                                sensor_roles{winner} = SENSOR_ROLES.INTERCEPTOR_CANDIDATE;
                                proactive_targets{winner} = safe_intercept_point;

                                logStateTransition(winner, old_state, SENSOR_STATES.INTERCEPTING, ...
                                    old_role, SENSOR_ROLES.INTERCEPTOR_CANDIDATE, current_time, ...
                                    sprintf('%s assignment for target %d', assignment_info.algorithm, calling_tid));
                            end
                        end

                        interceptor_call_triggered(calling_tid) = true;
                        interceptor_call_time(calling_tid) = current_time;

                        event_idx = find([interceptor_events.target_id] == calling_tid, 1, 'last');
                        if ~isempty(event_idx)
                            interceptor_events(event_idx).selected_sensors = selected_team;
                            interceptor_events(event_idx).selected_costs = selected_team_costs;
                        end

                        if length(selected_team) < MAX_ACTIVE_TRACKERS
                            fprintf(fid, '[t=%5.2f][ASSIGN] Target %d: shortage, assigned %d of %d requested interceptors\n', ...
                                current_time, calling_tid, length(selected_team), MAX_ACTIVE_TRACKERS);
                        else
                            fprintf(fid, '[t=%5.2f][ASSIGN] Target %d: assigned interceptors [%s] with costs [%s]\n', ...
                                current_time, calling_tid, num2str(selected_team), num2str(selected_team_costs, '%.3f '));
                        end
                    end

                    for other_tid = other_targets_calling'
                        interceptor_process_state{other_tid} = 'NONE';
                    end
            end
        end

        fprintf(fid, '[t=%5.2f][STATUS] Target %d: Final status - %d active trackers, call_triggered=%d\n', ...
                current_time, target_id, length(active_trackers{target_id}), interceptor_call_triggered(target_id));
    
    end
    
    %% FSM STATE UPDATES
    
    % Store previous states for transition detection
    prev_system_state = system_state;
    prev_sensor_states = sensor_states;
    prev_sensor_roles = sensor_roles;
    
    %% System-level FSM (modified for three targets)
    switch system_state
        case SYSTEM_STATES.IDLE
            if ~isempty(detecting_sensors)
                system_state = SYSTEM_STATES.TRACKING;
                logSystemTransition(prev_system_state, system_state, current_time, 'Target(s) detected');
                system_state_history = [system_state_history; current_time, string(system_state)];
            end
            
        case SYSTEM_STATES.TRACKING
            % Check if all targets are lost
            any_active_trackers = false;
            for target_id = 1:num_targets
                if ~isempty(active_trackers{target_id})
                    any_active_trackers = true;
                    break;
                end
            end
            
            if ~any_active_trackers && current_time > 10.0
                system_state = SYSTEM_STATES.SEARCHING;
                logSystemTransition(prev_system_state, system_state, current_time, 'All targets lost');
                system_state_history = [system_state_history; current_time, string(system_state)];
                target_loss_processed = true;
                
                % Send all displaced sensors home when entering SEARCHING state
                for sensor_id = 1:num_nodes
                    distance_from_home = norm(node_positions(sensor_id,:) - original_positions(sensor_id,:));
                    
                    if distance_from_home > 0.5 && ...
                       ~strcmp(sensor_states{sensor_id}, SENSOR_STATES.RETURNING_HOME) && ...
                       ~strcmp(sensor_states{sensor_id}, SENSOR_STATES.TRACKING) && ...
                       ~strcmp(sensor_states{sensor_id}, SENSOR_STATES.INTERCEPTING)
                        
                        % Reset any prediction tracking for all targets
                        for target_id = 1:num_targets
                            previous_loss_predictions(sensor_id, target_id) = 0;
                            stable_prediction_counts(sensor_id, target_id) = 0;
                        end
                        
                        % Send home
                        sensor_states{sensor_id} = SENSOR_STATES.RETURNING_HOME;
                        sensor_roles{sensor_id} = SENSOR_ROLES.NONE;
                        
                        if ~ismember(sensor_id, sensors_returning_home)
                            sensors_returning_home = [sensors_returning_home; sensor_id];
                        end
                        
                        logStateTransition(sensor_id, SENSOR_STATES.IDLE, SENSOR_STATES.RETURNING_HOME, ...
                            SENSOR_ROLES.NONE, SENSOR_ROLES.NONE, current_time, ...
                            'System lost all targets - displaced sensor returning home');
                    end
                end
            end
            
        case SYSTEM_STATES.SEARCHING
            if ~isempty(detecting_sensors)
                system_state = SYSTEM_STATES.REACQUIRING;
                logSystemTransition(prev_system_state, system_state, current_time, 'Target(s) redetected');
                system_state_history = [system_state_history; current_time, string(system_state)];
            end
            
        case SYSTEM_STATES.REACQUIRING
            any_active_trackers = false;
            for target_id = 1:num_targets
                if ~isempty(active_trackers{target_id})
                    any_active_trackers = true;
                    break;
                end
            end
            
            if any_active_trackers
                system_state = SYSTEM_STATES.TRACKING;
                logSystemTransition(prev_system_state, system_state, current_time, 'Tracking reestablished');
                system_state_history = [system_state_history; current_time, string(system_state)];
            end
    end
    
    %% TRACKING PHASE LOGIC (modified for three targets)
    if strcmp(system_state, SYSTEM_STATES.TRACKING) || strcmp(system_state, SYSTEM_STATES.REACQUIRING)
        target_loss_processed = false;
        
        % Update detected sensors list per target
        for target_id = 1:num_targets
            
            if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                target_detecting_sensors = detecting_sensors(detecting_sensors(:,2) == target_id, 1);
            else
                target_detecting_sensors = [];
            end

            detected_sensors{target_id} = unique([detected_sensors{target_id}; target_detecting_sensors]);
        end
        
        % GLOBAL EKF UPDATE per target
        for target_id = 1:num_targets

            if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                target_detecting_sensors = detecting_sensors(detecting_sensors(:,2) == target_id, 1);
            else
                target_detecting_sensors = [];
            end

            if ~isempty(target_detecting_sensors)
                all_measurements = [];
                
                for detector_id = target_detecting_sensors'
                    if ~isempty(sensor_ekf_states{detector_id, target_id})
                        sensor_estimate = sensor_ekf_states{detector_id, target_id}(1:2);
                        all_measurements = [all_measurements, sensor_estimate];
                    end
                end
                
                if ~isempty(all_measurements)
                    if size(all_measurements, 2) == 1
                        measurement = all_measurements;
                    else
                        measurement = mean(all_measurements, 2);
                    end
                    
                    H = [1, 0, 0, 0; 0, 1, 0, 0];
                    S = H * P_matrices{target_id} * H' + R;
                    K = P_matrices{target_id} * H' / S;
                    ekf_states{target_id} = ekf_states{target_id} + K * (measurement - H * ekf_states{target_id});
                    P_matrices{target_id} = (eye(4) - K * H) * P_matrices{target_id};
                end
            end
        end
        
        %% NEW: Immediate Handover Logic During Active Tracking (per target)
        for target_id = 1:num_targets
            if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                target_detecting_sensors = detecting_sensors(detecting_sensors(:,2) == target_id, 1);
            else
                target_detecting_sensors = [];
            end
            current_active_trackers = active_trackers{target_id};
            
            if ~isempty(current_active_trackers) && ~isempty(target_detecting_sensors)
                new_detectors = setdiff(target_detecting_sensors, current_active_trackers);
                
                % CRITICAL FIX: Exclude interceptors from immediate handover logic
                non_interceptor_detectors = [];
                for detector = new_detectors'
                    % Ensure detector is a scalar
                    if length(detector) == 1 && detector > 0 && detector <= length(sensor_states)
                        if ~strcmp(sensor_states{detector}, SENSOR_STATES.INTERCEPTING)
                            non_interceptor_detectors = [non_interceptor_detectors; detector];
                        end
                    end
                end
                new_detectors = non_interceptor_detectors;
                  
                if ~isempty(new_detectors)
                    % For each new detector, do 1-for-1 replacement for this target
                    for new_detector = new_detectors'
                        if length(current_active_trackers) >= MAX_ACTIVE_TRACKERS

                            % CRITICAL FIX: Remove sensor from any other target's tracker list first
                            for other_target_id = 1:num_targets
                                if other_target_id ~= target_id
                                    active_trackers{other_target_id} = active_trackers{other_target_id}(active_trackers{other_target_id} ~= new_detector);
                                end
                            end
                            
                            % Find farthest tracker from home to replace
                            farthest_tracker = findFarthestSensorFromHome(current_active_trackers, node_positions, original_positions);
                            
                            % Release farthest tracker
                            sensor_states{farthest_tracker} = SENSOR_STATES.RETURNING_HOME;
                            sensor_roles{farthest_tracker} = SENSOR_ROLES.NONE;
                            active_trackers{target_id} = active_trackers{target_id}(active_trackers{target_id} ~= farthest_tracker);
                            
                            logStateTransition(farthest_tracker, SENSOR_STATES.TRACKING, SENSOR_STATES.RETURNING_HOME, ...
                                prev_sensor_roles{farthest_tracker}, SENSOR_ROLES.NONE, current_time, ...
                                sprintf('Released for immediate handover - target %d - farthest from home', target_id));
                            
                            % Add new detector as tracker for this target
                            active_trackers{target_id} = [active_trackers{target_id}; new_detector];
                            
                            % Assign role based on current active trackers for this target
                            if length(active_trackers{target_id}) == 1
                                sensor_roles{new_detector} = SENSOR_ROLES.PRIMARY_TRACKER;
                            else
                                sensor_roles{new_detector} = SENSOR_ROLES.SECONDARY_TRACKER;
                            end
                            
                            % Initialize new tracker's EKF for this target
                            sensor_detection_times(new_detector, target_id) = current_time;
                            sensor_ekf_states{new_detector, target_id} = [target_positions(target_id, 1); target_positions(target_id, 2); 0; 0];
                            sensor_P_matrices{new_detector, target_id} = eye(4);
                            sensor_P_trace_history{new_detector, target_id} = [current_time, trace(sensor_P_matrices{new_detector, target_id})];
                            
                            logStateTransition(new_detector, prev_sensor_states{new_detector}, SENSOR_STATES.TRACKING, ...
                                SENSOR_ROLES.NONE, sensor_roles{new_detector}, current_time, ...
                                sprintf('Added via immediate handover - target %d', target_id));
                            
                        elseif length(current_active_trackers) < MAX_ACTIVE_TRACKERS
                            % CRITICAL FIX: Remove sensor from any other target's tracker list first
                            for other_target_id = 1:num_targets
                                if other_target_id ~= target_id
                                    active_trackers{other_target_id} = active_trackers{other_target_id}(active_trackers{other_target_id} ~= new_detector);
                                end
                            end
                            % Add as additional tracker for this target
                            active_trackers{target_id} = [active_trackers{target_id}; new_detector];
                            
                            if length(active_trackers{target_id}) == 1
                                sensor_roles{new_detector} = SENSOR_ROLES.PRIMARY_TRACKER;
                            else
                                sensor_roles{new_detector} = SENSOR_ROLES.SECONDARY_TRACKER;
                            end
                            
                            % Initialize new tracker's EKF for this target
                            sensor_detection_times(new_detector, target_id) = current_time;
                            sensor_ekf_states{new_detector, target_id} = [target_positions(target_id, 1); target_positions(target_id, 2); 0; 0];
                            sensor_P_matrices{new_detector, target_id} = eye(4);
                            sensor_P_trace_history{new_detector, target_id} = [current_time, trace(sensor_P_matrices{new_detector, target_id})];
                            
                            logStateTransition(new_detector, prev_sensor_states{new_detector}, SENSOR_STATES.TRACKING, ...
                                SENSOR_ROLES.NONE, sensor_roles{new_detector}, current_time, ...
                                sprintf('Added as additional tracker - target %d', target_id));
                        end
                    end
                end
            end
        end
    end
    
    %% Sensor-level FSM updates (modified for three targets)
    for i = 1:num_nodes
        prev_state = sensor_states{i};
        prev_role = sensor_roles{i};
        
        switch sensor_states{i}
            case SENSOR_STATES.IDLE
                % Check for direct detection of any target
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    if ~isempty(sensor_detections)
                        sensor_states{i} = SENSOR_STATES.DETECTING;
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, sprintf('Direct detection of target %d', sensor_detections(1,2)));
                    end
                end
                
            case SENSOR_STATES.DETECTING
                % Find which target this sensor is detecting
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    if ~isempty(sensor_detections)
                        detected_target_id = sensor_detections(1, 2);  % First detected target
                        
                        % Initialize EKF if not done for this target
                        if sensor_detection_times(i, detected_target_id) == 0
                            sensor_detection_times(i, detected_target_id) = current_time;
                            sensor_ekf_states{i, detected_target_id} = [target_positions(detected_target_id, 1); target_positions(detected_target_id, 2); 0; 0];
                            sensor_P_matrices{i, detected_target_id} = eye(4);
                            sensor_P_trace_history{i, detected_target_id} = [current_time, trace(sensor_P_matrices{i, detected_target_id})];
                        end
                        
                        % Transition to tracking
                        sensor_states{i} = SENSOR_STATES.TRACKING;
                        
                        % CRITICAL FIX: Remove sensor from any other target's tracker list first
                        for other_target_id = 1:num_targets
                            if other_target_id ~= detected_target_id
                                active_trackers{other_target_id} = active_trackers{other_target_id}(active_trackers{other_target_id} ~= i);
                            end
                        end

                        % Role assignment for this target
                        if length(active_trackers{detected_target_id}) == 0
                            sensor_roles{i} = SENSOR_ROLES.PRIMARY_TRACKER;
                            active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];
                        elseif length(active_trackers{detected_target_id}) == 1
                            sensor_roles{i} = SENSOR_ROLES.SECONDARY_TRACKER;
                            active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];
                        else
                            % Already have 2 trackers for this target - handled by immediate handover
                            sensor_states{i} = SENSOR_STATES.IDLE;
                            sensor_roles{i} = SENSOR_ROLES.NONE;
                        end
                        
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, sprintf('EKF initialized for target %d with role assignment', detected_target_id));
                    end
                end
    
            case SENSOR_STATES.TRACKING
                % Check if this sensor is still detecting any target it's supposed to track
                still_tracking = false;
                tracking_target_id = -1;
                
                % Find which target this sensor is tracking
                for target_id = 1:num_targets
                    if ismember(i, active_trackers{target_id})
                        tracking_target_id = target_id;
                        break;
                    end
                end
                
                if tracking_target_id > 0
                    % Check if still detecting the target being tracked
                    if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                        sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                        if ~isempty(sensor_detections) && any(sensor_detections(:,2) == tracking_target_id)
                            still_tracking = true;
                        end
                    end
                end
                
                if ~still_tracking
                    if tracking_target_id > 0
                        % ROBUST CLEANUP: Remove from active trackers immediately when not detecting
                        active_trackers{tracking_target_id} = active_trackers{tracking_target_id}(active_trackers{tracking_target_id} ~= i);
                        
                        % Go home immediately
                        sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                        sensor_roles{i} = SENSOR_ROLES.NONE;
                        sensors_returning_home = [sensors_returning_home; i];
                        
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, sprintf('Target %d lost - immediate cleanup (robust)', tracking_target_id));
                        
                        % Check if we need to promote remaining tracker to primary for this target
                        if length(active_trackers{tracking_target_id}) == 1
                            remaining_tracker = active_trackers{tracking_target_id}(1);
                            if strcmp(sensor_roles{remaining_tracker}, SENSOR_ROLES.SECONDARY_TRACKER)
                                sensor_roles{remaining_tracker} = SENSOR_ROLES.PRIMARY_TRACKER;
                                logStateTransition(remaining_tracker, SENSOR_STATES.TRACKING, SENSOR_STATES.TRACKING, ...
                                    SENSOR_ROLES.SECONDARY_TRACKER, SENSOR_ROLES.PRIMARY_TRACKER, current_time, ...
                                    sprintf('Promoted to primary after tracker loss - target %d', tracking_target_id));
                            end
                        end
                    end
                else
                    % Still tracking - update EKF with sensor's own noisy measurement for the tracked target
                    if tracking_target_id > 0
                        measurement_noise_std = sqrt(R(1,1));
                        
                        true_target_pos = target_positions(tracking_target_id, :)';
                        noisy_measurement = true_target_pos + randn(2,1) * measurement_noise_std;
                        
                        % Update individual sensor's EKF for this target
                        H = [1, 0, 0, 0; 0, 1, 0, 0];
                        S = H * sensor_P_matrices{i, tracking_target_id} * H' + R;
                        K = sensor_P_matrices{i, tracking_target_id} * H' / S;
                        sensor_ekf_states{i, tracking_target_id} = sensor_ekf_states{i, tracking_target_id} + K * (noisy_measurement - H * sensor_ekf_states{i, tracking_target_id});
                        sensor_P_matrices{i, tracking_target_id} = (eye(4) - K * H) * sensor_P_matrices{i, tracking_target_id};
                        
                        sensor_P_trace_history{i, tracking_target_id} = [sensor_P_trace_history{i, tracking_target_id}; ...
                            current_time, trace(sensor_P_matrices{i, tracking_target_id})];
                    end
                end
                
            case SENSOR_STATES.INTERCEPTING

                % some debug lines to see what sensors 3,8,14,20 are doing when are called to intercept
                if ismember(i, [3, 8, 14, 20])
                    if ~isempty(proactive_targets{i})
                        current_distance = norm(node_positions(i,:) - proactive_targets{i});
                        fprintf(fid, '[t=%5.2f][SENSOR] Sensor %d: INTERCEPTING, distance_to_target=%.1f, target=[%.1f,%.1f]\n', ...
                            current_time, i, current_distance, proactive_targets{i}(1), proactive_targets{i}(2));
                    end
                end
                
                % Check if reached intercept point or detected any target
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    
                    if ~isempty(sensor_detections)
                        % Interceptor detected a target -> replacement logic
                        detected_target_id = sensor_detections(1, 2);  % First detected target
                        
                        % Count how many interceptors detected this target
                        intercepting_sensors = find(cellfun(@(x) strcmp(x, SENSOR_STATES.INTERCEPTING), sensor_states));
                        detecting_interceptors_for_target = [];
                        
                        for int_sensor = intercepting_sensors'
                            if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                                int_detections = detecting_sensors(detecting_sensors(:,1) == int_sensor, :);
                                if ~isempty(int_detections) && any(int_detections(:,2) == detected_target_id)
                                    detecting_interceptors_for_target = [detecting_interceptors_for_target; int_sensor];
                                end
                            end
                        end
                        
                        current_active_trackers = active_trackers{detected_target_id};
                        
                        if length(detecting_interceptors_for_target) == 1
                            % 1-for-1 replacement for this target
                            if ~isempty(current_active_trackers)
                                farthest_tracker = findFarthestSensorFromHome(current_active_trackers, node_positions, original_positions);
                                
                                % Release farthest tracker
                                sensor_states{farthest_tracker} = SENSOR_STATES.RETURNING_HOME;
                                sensor_roles{farthest_tracker} = SENSOR_ROLES.NONE;
                                active_trackers{detected_target_id} = active_trackers{detected_target_id}(active_trackers{detected_target_id} ~= farthest_tracker);
                                sensors_returning_home = [sensors_returning_home; farthest_tracker];
                                
                                logStateTransition(farthest_tracker, SENSOR_STATES.TRACKING, SENSOR_STATES.RETURNING_HOME, ...
                                    prev_sensor_roles{farthest_tracker}, SENSOR_ROLES.NONE, current_time, ...
                                    sprintf('1-for-1 replacement - target %d - farthest tracker released', detected_target_id));
                            end
                            
                            % Add interceptor as tracker for this target
                            sensor_states{i} = SENSOR_STATES.TRACKING;
                            active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];
                            
                            % Assign role
                            if length(active_trackers{detected_target_id}) == 1
                                sensor_roles{i} = SENSOR_ROLES.PRIMARY_TRACKER;
                            else
                                sensor_roles{i} = SENSOR_ROLES.SECONDARY_TRACKER;
                            end
                            
                            % Initialize EKF for this target
                            sensor_detection_times(i, detected_target_id) = current_time;
                            sensor_ekf_states{i, detected_target_id} = [target_positions(detected_target_id, 1); target_positions(detected_target_id, 2); 0; 0];
                            sensor_P_matrices{i, detected_target_id} = eye(4);
                            sensor_P_trace_history{i, detected_target_id} = [current_time, trace(sensor_P_matrices{i, detected_target_id})];
                            
                            logStateTransition(i, SENSOR_STATES.INTERCEPTING, SENSOR_STATES.TRACKING, ...
                                SENSOR_ROLES.INTERCEPTOR_CANDIDATE, sensor_roles{i}, current_time, ...
                                sprintf('1-for-1 interceptor became tracker - target %d', detected_target_id));
    
                            total_successful_intercepts = total_successful_intercepts + 1;
    
                            % Reset flag only for the specific target that was successfully intercepted
                            interceptor_call_triggered(detected_target_id) = false;
                            
                            fprintf(fid, '[t=%5.2f][INTERCEPT] Reset interceptor call flag for target %d after successful intercept\n', ...
                                 current_time, detected_target_id);

                        elseif length(detecting_interceptors_for_target) == 2
                            % 2-for-2 replacement for this target
                            for old_tracker = current_active_trackers'
                                sensor_states{old_tracker} = SENSOR_STATES.RETURNING_HOME;
                                sensor_roles{old_tracker} = SENSOR_ROLES.NONE;
                                sensors_returning_home = [sensors_returning_home; old_tracker];
                                
                                logStateTransition(old_tracker, SENSOR_STATES.TRACKING, SENSOR_STATES.RETURNING_HOME, ...
                                    prev_sensor_roles{old_tracker}, SENSOR_ROLES.NONE, current_time, ...
                                    sprintf('2-for-2 replacement - target %d - old tracker released', detected_target_id));
                            end
                            
                            active_trackers{detected_target_id} = [];
                            
                            % Add both interceptors as trackers for this target
                            if i == detecting_interceptors_for_target(1)
                                % This is the first interceptor being processed
                                sensor_states{i} = SENSOR_STATES.TRACKING;
                                sensor_roles{i} = SENSOR_ROLES.PRIMARY_TRACKER;
                                active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];
                                
                                % Initialize EKF for this target
                                sensor_detection_times(i, detected_target_id) = current_time;
                                sensor_ekf_states{i, detected_target_id} = [target_positions(detected_target_id, 1); target_positions(detected_target_id, 2); 0; 0];
                                sensor_P_matrices{i, detected_target_id} = eye(4);
                                sensor_P_trace_history{i, detected_target_id} = [current_time, trace(sensor_P_matrices{i, detected_target_id})];
                                
                                logStateTransition(i, SENSOR_STATES.INTERCEPTING, SENSOR_STATES.TRACKING, ...
                                    SENSOR_ROLES.INTERCEPTOR_CANDIDATE, SENSOR_ROLES.PRIMARY_TRACKER, current_time, ...
                                    sprintf('2-for-2 interceptor became primary tracker - target %d', detected_target_id));
    
                                total_successful_intercepts = total_successful_intercepts + 1;

                                % Reset flag only for the specific target that was successfully intercepted
                                interceptor_call_triggered(detected_target_id) = false;
                            end
                        end
                        
                    else
                        % No target detected - check if reached intercept point
                        if ~isempty(proactive_targets{i})
                            distance_to_intercept = norm(node_positions(i,:) - proactive_targets{i});
                            
                            if distance_to_intercept < 1
                                % Immediately go home
                                sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                                sensor_roles{i} = SENSOR_ROLES.NONE;
                                
                                if ~ismember(i, sensors_returning_home)
                                    sensors_returning_home = [sensors_returning_home; i];
                                end
                                
                                proactive_targets{i} = [];
                                
                                logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                                    current_time, 'Reached intercept point but no target detected - returning home');
                            end
                        else
                            sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                            sensor_roles{i} = SENSOR_ROLES.NONE;
                            if ~ismember(i, sensors_returning_home)
                                sensors_returning_home = [sensors_returning_home; i];
                            end
                        end
                    end
                else
                    % No detecting_sensors data - check if reached intercept point
                    if ~isempty(proactive_targets{i})
                        distance_to_intercept = norm(node_positions(i,:) - proactive_targets{i});
                        
                        if distance_to_intercept < 1
                            sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                            sensor_roles{i} = SENSOR_ROLES.NONE;
                            
                            if ~ismember(i, sensors_returning_home)
                                sensors_returning_home = [sensors_returning_home; i];
                            end
                            
                            proactive_targets{i} = [];
                            
                            logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                                current_time, 'Reached intercept point but no target detected - returning home');
                        end
                    end
                end
                
            case SENSOR_STATES.SEARCHING
                % Check for direct detection first
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    if ~isempty(sensor_detections)
                        sensor_states{i} = SENSOR_STATES.DETECTING;
                        detected_target_id = sensor_detections(1, 2);
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, sprintf('Found target %d while searching', detected_target_id));
                    end
                end
                
                if strcmp(sensor_states{i}, SENSOR_STATES.SEARCHING)  % Only move if still searching
                    % Move toward shared target information when available (use first target for simplicity)
                    [shared_target_pos, shared_target_vel, confidence] = ...
                        getSharedTargetInfo(i, node_positions, sensor_ekf_states, ...
                        sensor_detection_times, current_time, communication_range, 1);
                    
                    if ~isempty(shared_target_pos) && confidence > 0.1  %this number is for searching. don't change it
                        direction = shared_target_pos - node_positions(i,:);
                        distance = norm(direction);
                        
                        if distance > 0.5
                            direction = direction / distance;
                            move_distance = sensor_velocity * dt;
                            node_positions(i,:) = node_positions(i,:) + direction * move_distance;
                        end
                    end
                end
                
            case SENSOR_STATES.RETURNING_HOME
                % CHECK FOR TARGET DETECTION WHILE RETURNING HOME
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    if ~isempty(sensor_detections)
                        % Target detected while returning home - transition to detecting
                        sensor_states{i} = SENSOR_STATES.DETECTING;
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, sprintf('Target detected while returning home - target %d', sensor_detections(1,2)));
                    end
                end
                
                % Only continue returning home if no target was detected
                if strcmp(sensor_states{i}, SENSOR_STATES.RETURNING_HOME)
                    % Move toward original position
                    home_position = original_positions(i,:);
                    current_position = node_positions(i,:);
                    distance_to_home = norm(home_position - current_position);
                    
                    if distance_to_home > 0.1
                        direction_home = (home_position - current_position) / distance_to_home;
                        move_distance = min(distance_to_home, sensor_velocity * dt);
                        node_positions(i,:) = current_position + direction_home * move_distance;
                        
                        total_distance = norm(home_position - original_positions(i,:));
                        if total_distance > 0
                            return_progress(i) = 1 - (distance_to_home / total_distance);
                        end
                        
                    else
                        % Reached home
                        node_positions(i,:) = home_position;
                        sensor_states{i} = SENSOR_STATES.IDLE;
                        sensor_roles{i} = SENSOR_ROLES.NONE;
                        sensors_returning_home = sensors_returning_home(sensors_returning_home ~= i);
                        return_progress(i) = 0;
                        
                        sensor_interceptor_call_history(i, :) = false;
                        
                        logStateTransition(i, prev_state, sensor_states{i}, prev_role, sensor_roles{i}, ...
                            current_time, 'Reached home position');
                    end
                end
        end
        % Update state history
        if ~strcmp(prev_state, sensor_states{i}) || ~strcmp(prev_role, sensor_roles{i})
            sensor_state_history{i} = [sensor_state_history{i}; 
                current_time, string(sensor_states{i}), string(sensor_roles{i})];
        end
    end
    
    %% SEARCHING PHASE LOGIC (for all lost targets)
    if strcmp(system_state, SYSTEM_STATES.SEARCHING) && target_loss_processed 
        if mod(t, update_frequency) == 0
            % Clear old contours
            if ishandle(contour_3sigma_handle)
                delete(contour_3sigma_handle);
            end
            if ~isempty(contour_handles)
                for h = contour_handles
                    if ishandle(h)
                        delete(h);
                    end
                end
                contour_handles = [];
            end
            
            % Update EKF prediction and generate contours for all targets
            for target_id = 1:num_targets
                if ~isempty(ekf_states{target_id})
                    
                    % PREVENT CONTOURS BEFORE PROPER DETECTION
                    has_been_detected = false;
                    for sensor_id = 1:num_nodes
                        if sensor_detection_times(sensor_id, target_id) > 0
                            has_been_detected = true;
                            break;
                        end
                    end
                    
                    if ~has_been_detected
                        continue; % Skip contour generation for undetected targets
                    end
                    
                    velocity = ekf_states{target_id}(3:4);
                    velocity_mag = norm(velocity);
                    
                    if velocity_mag > 0
                        velocity_dir = velocity / velocity_mag;
                    else
                        velocity_dir = [1; 0];
                    end
                    
                    % Apply anisotropic process noise for this target
                    alongTrackNoiseStd = 0.04;
                    crossTrackNoiseStd = 0.01;
                    cross_dir = [-velocity_dir(2); velocity_dir(1)];
                    R_matrix = [velocity_dir, cross_dir];
                    D = diag([alongTrackNoiseStd^2, crossTrackNoiseStd^2]);
                    Q_anisotropic = R_matrix * D * R_matrix';
                    
                    % Apply anisotropic noise only to position components
                    P_matrices{target_id}(1:2, 1:2) = P_matrices{target_id}(1:2, 1:2) + Q_anisotropic;
                    
                    projected_center = ekf_states{target_id}(1:2);
                    plot(projected_center(1), projected_center(2), 'mx', 'MarkerSize', 8);
                    
                    % Generate updated contours
                    contour_points = generate3SigmaContour(ekf_states{target_id}(1:2), P_matrices{target_id}(1:2,1:2), 0.9889, 100);
                    inner_contour_points = generate3SigmaContour(ekf_states{target_id}(1:2), P_matrices{target_id}(1:2,1:2), 0.3935, 100);
                    middle_contour_points = generate3SigmaContour(ekf_states{target_id}(1:2), P_matrices{target_id}(1:2,1:2), 0.8647, 100);
                    
                    current_contour_period = [current_contour_period; contour_points];
                    
                    % Use different colors for different targets
                    if target_id == 1
                        % Target 1 contours - Green theme
                        if exist('contour_3sigma_handle_t1', 'var') && ishandle(contour_3sigma_handle_t1)
                            delete(contour_3sigma_handle_t1);
                        end
                        if exist('contour_handles_t1', 'var') && ~isempty(contour_handles_t1)
                            for h = contour_handles_t1
                                if ishandle(h)
                                    delete(h);
                                end
                            end
                        end
                        
                        contour_3sigma_handle_t1 = plot(contour_points(:,1), contour_points(:,2), 'g--', 'LineWidth', 1.5);
                        h1_t1 = plot(inner_contour_points(:,1), inner_contour_points(:,2), 'b-', 'LineWidth', 1);
                        h2_t1 = plot(middle_contour_points(:,1), middle_contour_points(:,2), 'r-', 'LineWidth', 1);
                        contour_handles_t1 = [h1_t1, h2_t1];
                        
                    elseif target_id == 2
                        % Target 2 contours - Magenta theme
                        if exist('contour_3sigma_handle_t2', 'var') && ishandle(contour_3sigma_handle_t2)
                            delete(contour_3sigma_handle_t2);
                        end
                        if exist('contour_handles_t2', 'var') && ~isempty(contour_handles_t2)
                            for h = contour_handles_t2
                                if ishandle(h)
                                    delete(h);
                                end
                            end
                        end
                        
                        contour_3sigma_handle_t2 = plot(contour_points(:,1), contour_points(:,2), 'm--', 'LineWidth', 1.5);
                        h1_t2 = plot(inner_contour_points(:,1), inner_contour_points(:,2), 'c-', 'LineWidth', 1);
                        h2_t2 = plot(middle_contour_points(:,1), middle_contour_points(:,2), 'y-', 'LineWidth', 1);
                        contour_handles_t2 = [h1_t2, h2_t2];
                        
                    elseif target_id == 3
                        % Target 3 contours - Blue theme
                        if exist('contour_3sigma_handle_t3', 'var') && ishandle(contour_3sigma_handle_t3)
                            delete(contour_3sigma_handle_t3);
                        end
                        if exist('contour_handles_t3', 'var') && ~isempty(contour_handles_t3)
                            for h = contour_handles_t3
                                if ishandle(h)
                                    delete(h);
                                end
                            end
                        end
                        
                        contour_3sigma_handle_t3 = plot(contour_points(:,1), contour_points(:,2), 'b--', 'LineWidth', 1.5);
                        h1_t3 = plot(inner_contour_points(:,1), inner_contour_points(:,2), 'k-', 'LineWidth', 1);
                        h2_t3 = plot(middle_contour_points(:,1), middle_contour_points(:,2), 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
                        contour_handles_t3 = [h1_t3, h2_t3];
                    end
                    
                    % Add swept area visualization (for first target only to avoid conflicts)
                    if target_id == 1 && ~isempty(all_contour_points) && size(all_contour_points, 1) > 3
                        k = convhull(all_contour_points(:,1), all_contour_points(:,2));
                        hull_points = all_contour_points(k,:);
                        
                        if ishandle(swept_area_handle)
                            delete(swept_area_handle);
                        end
                        
                        swept_area_handle = fill(hull_points(:,1), hull_points(:,2), 'y', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
                        uistack(swept_area_handle, 'bottom');
                    end
                end
            end
        end
    end
    
        %% SENSOR MOVEMENT based on states (modified for dual targets)
    for i = 1:num_nodes
        switch sensor_states{i}
            case SENSOR_STATES.TRACKING
                % Find which target this sensor is tracking
                tracking_target_id = -1;
                for target_id = 1:num_targets
                    if ismember(i, active_trackers{target_id})
                        tracking_target_id = target_id;
                        break;
                    end
                end
                
                if tracking_target_id > 0
                    % Move toward EKF estimated target position for this target
                    if ~isempty(sensor_ekf_states{i, tracking_target_id}) && length(sensor_ekf_states{i, tracking_target_id}) >= 4
                        estimated_target_pos = sensor_ekf_states{i, tracking_target_id}(1:2)';
                        
                        direction = estimated_target_pos - node_positions(i,:);
                        distance = norm(direction);
                        
                        if distance > 0
                            direction = direction / distance;
                            move_distance = min(distance, sensor_velocity * dt);
                            node_positions(i,:) = node_positions(i,:) + direction * move_distance;
                        end
                    else
                        if ~isempty(sensor_ekf_states{i, tracking_target_id})
                            last_known_pos = sensor_ekf_states{i, tracking_target_id}(1:2)';
                            direction = last_known_pos - node_positions(i,:);
                            distance = norm(direction);
                            if distance > 0
                                direction = direction / distance;
                                move_distance = min(distance, sensor_velocity * dt);
                                node_positions(i,:) = node_positions(i,:) + direction * move_distance;
                            end
                        end
                    end
                end
                
            case SENSOR_STATES.INTERCEPTING
                % Move towards intercept point
                if ~isempty(proactive_targets{i})
                    target_pos = proactive_targets{i};
                    direction = target_pos - node_positions(i,:);
                    distance = norm(direction);
                    
                    if distance > 1.5  % Use complex guidance when far from intercept
                        % Determine which target this interceptor is assigned to
                        assigned_target_id = -1;
                        for target_id = 1:num_targets
                            if ~isempty(global_interceptor_data{target_id}) && ...
                               isfield(global_interceptor_data{target_id}, 'intercept_point')
                                intercept_distance = norm(proactive_targets{i} - global_interceptor_data{target_id}.intercept_point);
                                if intercept_distance < 0.5  % Close match to intercept point
                                    assigned_target_id = target_id;
                                    break;
                                end
                            end
                        end
                        
                       % Always check for target assignment and shared info first
                        assigned_target_id = -1;
                        for target_id = 1:num_targets
                            if ~isempty(global_interceptor_data{target_id}) && ...
                               isfield(global_interceptor_data{target_id}, 'intercept_point')
                                intercept_distance = norm(proactive_targets{i} - global_interceptor_data{target_id}.intercept_point);
                                if intercept_distance < 0.5
                                    assigned_target_id = target_id;
                                    break;
                                end
                            end
                        end
                        
                        % Get shared information for geometric consistency check
                        if assigned_target_id > 0
                            [shared_target_pos, shared_target_vel, confidence] = ...
                                getSharedTargetInfo(i, node_positions, sensor_ekf_states, ...
                                sensor_detection_times, current_time, communication_range, assigned_target_id);
                            
                            % Geometric consistency check
                            if ~isempty(shared_target_pos) && numel(target_pos) == 2 && numel(shared_target_pos) == 2
                                target_pos_vec = reshape(target_pos, 1, 2);
                                shared_pos_vec = reshape(shared_target_pos, 1, 2);
                                target_to_intercept = target_pos_vec - shared_pos_vec;
                                dot_product = dot(target_to_intercept, shared_target_vel);
                            else
                                dot_product = 1; % Default to direct approach
                            end
                            
                            if confidence <= 0.2
                                % Low confidence - return home
                                sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                                sensor_roles{i} = SENSOR_ROLES.NONE;
                                sensors_returning_home = [sensors_returning_home; i];
                                proactive_targets{i} = [];
                                
                            elseif dot_product < 0 && confidence > 0.2
                                % Target passed intercept - use shared information and PNG
                                if confidence > 0.1
                                    % PNG guidance logic here
                                    if ~isempty(sensor_trajectories{i}) && size(sensor_trajectories{i}, 1) > 1
                                        recent_movement = sensor_trajectories{i}(end,:) - sensor_trajectories{i}(end-1,:);
                                        sensor_vel = recent_movement / dt;
                                    else
                                        sensor_vel = direction / norm(direction) * sensor_velocity;
                                    end
                                    
                                    lambda = 4.0;
                                    a_PNG = calculatePNGAcceleration(node_positions(i,:), sensor_vel, ...
                                        shared_target_pos, shared_target_vel, lambda);
                                    
                                    if norm(a_PNG) > 0.01
                                        png_direction = a_PNG / norm(a_PNG);
                                        current_direction = sensor_vel / norm(sensor_vel + 0.0001);
                                        steering_factor = confidence * 0.1;
                                        new_direction = (1-steering_factor) * current_direction + steering_factor * png_direction;
                                        new_direction = new_direction / norm(new_direction);
                                    else
                                        new_direction = direction / norm(direction);
                                    end
                                else
                                    new_direction = direction / norm(direction);
                                end
                            else
                                % Default: Go directly to intercept point (target hasn't passed yet)
                                new_direction = direction / norm(direction);
                            end
                        else
                            % No assigned target - go direct
                            new_direction = direction / norm(direction);
                        end
                        
                        move_distance = max(sensor_velocity * dt, 0.1);
                        node_positions(i,:) = node_positions(i,:) + new_direction * move_distance;
                        
                    else
                        % Final approach - go directly to intercept point
                        new_direction = direction / norm(direction);
                        move_distance = max(sensor_velocity * dt, 0.1);
                        node_positions(i,:) = node_positions(i,:) + new_direction * move_distance;
                    end
                end
                
            case SENSOR_STATES.SEARCHING
                % Stay in place or move toward shared target information
                [shared_target_pos, shared_target_vel, confidence] = ...
                    getSharedTargetInfo(i, node_positions, sensor_ekf_states, ...
                    sensor_detection_times, current_time, communication_range, 1);
                
                if ~isempty(shared_target_pos) && confidence > 0.3
                    direction = shared_target_pos - node_positions(i,:);
                    distance = norm(direction);
                    
                    if distance > 0.5
                        direction = direction / distance;
                        move_distance = sensor_velocity * dt;
                        node_positions(i,:) = node_positions(i,:) + direction * move_distance;
                    end
                end
                
            case SENSOR_STATES.RETURNING_HOME
                % Check for target detection while returning home
                if ~isempty(detecting_sensors) && size(detecting_sensors, 2) >= 2
                    sensor_detections = detecting_sensors(detecting_sensors(:,1) == i, :);
                    if ~isempty(sensor_detections)
                        sensor_states{i} = SENSOR_STATES.DETECTING;
                        logStateTransition(i, SENSOR_STATES.RETURNING_HOME, sensor_states{i}, SENSOR_ROLES.NONE, sensor_roles{i}, ...
                            current_time, sprintf('Target detected while returning home - target %d', sensor_detections(1,2)));
                    end
                end
                
                % Only continue returning home if no target was detected
                if strcmp(sensor_states{i}, SENSOR_STATES.RETURNING_HOME)
                    home_position = original_positions(i,:);
                    current_position = node_positions(i,:);
                    distance_to_home = norm(home_position - current_position);
                    
                    if distance_to_home > 0.1
                        direction_home = (home_position - current_position) / distance_to_home;
                        move_distance = min(distance_to_home, sensor_velocity * dt);
                        node_positions(i,:) = current_position + direction_home * move_distance;
                        
                        total_distance = norm(home_position - original_positions(i,:));
                        if total_distance > 0
                            return_progress(i) = 1 - (distance_to_home / total_distance);
                        end
                    else
                        % Reached home
                        node_positions(i,:) = home_position;
                        sensor_states{i} = SENSOR_STATES.IDLE;
                        sensor_roles{i} = SENSOR_ROLES.NONE;
                        sensors_returning_home = sensors_returning_home(sensors_returning_home ~= i);
                        return_progress(i) = 0;
                        
                        sensor_interceptor_call_history(i, :) = false;
                        
                        logStateTransition(i, SENSOR_STATES.RETURNING_HOME, sensor_states{i}, SENSOR_ROLES.NONE, sensor_roles{i}, ...
                            current_time, 'Reached home position');
                    end
                end
                
            case {SENSOR_STATES.IDLE, SENSOR_STATES.DETECTING}
                % No movement
        end
        
        % Update trajectory for moving sensors
        if ismember(sensor_states{i}, {SENSOR_STATES.TRACKING, SENSOR_STATES.INTERCEPTING})
            sensor_trajectories{i} = [sensor_trajectories{i}; node_positions(i,:)];
        end
    end
    
    %% Update display (modified for three targets)
    if mod(t, update_frequency) == 0 || t == 1
        % Update three target positions
        for target_id = 1:num_targets
            % Only update if target has started moving and has trajectory data
            if current_time >= target_start_time(target_id) && ~isempty(target_trajectories{target_id})
                set(target_handles(target_id), 'XData', target_positions(target_id,1), 'YData', target_positions(target_id,2));
                set(trajectory_handles(target_id), 'XData', target_trajectories{target_id}(:,1), 'YData', target_trajectories{target_id}(:,2));
                
                % Make target visible
                set(target_handles(target_id), 'Visible', 'on');
                set(trajectory_handles(target_id), 'Visible', 'on');
            else
                % Hide targets that haven't started yet
                set(target_handles(target_id), 'Visible', 'off');
                set(trajectory_handles(target_id), 'Visible', 'off');
            end
        end
        
        % Check contour touches (using first target for backward compatibility)
        current_3sigma = zeros(num_nodes, 1);
        current_2sigma = zeros(num_nodes, 1);
        current_1sigma = zeros(num_nodes, 1);
        
        if ~isempty(contour_points) && size(contour_points, 1) > 2 && ...
           ~isempty(inner_contour_points) && ~isempty(middle_contour_points)
            
            contour3_x = contour_points(:,1);
            contour3_y = contour_points(:,2);
            contour2_x = middle_contour_points(:,1);
            contour2_y = middle_contour_points(:,2);
            contour1_x = inner_contour_points(:,1);
            contour1_y = inner_contour_points(:,2);
            
            for i = 1:num_nodes
                % Check 3-sigma contour
                is_in_3sigma = inpolygon(node_positions(i,1), node_positions(i,2), contour3_x, contour3_y);
                if ~is_in_3sigma
                distances = sqrt((contour3_x - node_positions(i,1)).^2 + (contour3_y - node_positions(i,2)).^2);
                    min_distance = min(distances);
                    if min_distance <= a
                        is_in_3sigma = true;
                    end
                end
                
                % Check 2-sigma contour
                is_in_2sigma = inpolygon(node_positions(i,1), node_positions(i,2), contour2_x, contour2_y);
                if ~is_in_2sigma
                    distances = sqrt((contour2_x - node_positions(i,1)).^2 + (contour2_y - node_positions(i,2)).^2);
                    min_distance = min(distances);
                    if min_distance <= a
                        is_in_2sigma = true;
                    end
                end
                
                % Check 1-sigma contour
                is_in_1sigma = inpolygon(node_positions(i,1), node_positions(i,2), contour1_x, contour1_y);
                if ~is_in_1sigma
                    distances = sqrt((contour1_x - node_positions(i,1)).^2 + (contour1_y - node_positions(i,2)).^2);
                    min_distance = min(distances);
                    if min_distance <= a
                        is_in_1sigma = true;
                    end
                end
                
                current_3sigma(i) = is_in_3sigma;
                current_2sigma(i) = is_in_2sigma;
                current_1sigma(i) = is_in_1sigma;
                
                % Update persistent flags
                if is_in_1sigma
                    sensors_touched_1sigma(i) = 1;
                    sensors_touched_2sigma(i) = 1;
                    sensors_touched_3sigma(i) = 1;
                elseif is_in_2sigma
                    sensors_touched_2sigma(i) = 1;
                    sensors_touched_3sigma(i) = 1;
                elseif is_in_3sigma
                    sensors_touched_3sigma(i) = 1;
                end
            end
        end
        
        % Update sensor positions and colors based on states and roles
        for i = 1:num_nodes
            set(node_handles(i), 'XData', node_positions(i,1), 'YData', node_positions(i,2));
            set(circle_handles(i), 'XData', xunit + node_positions(i,1), 'YData', yunit + node_positions(i,2));
            
            % Color scheme for three target tracking
            switch sensor_states{i}
                case SENSOR_STATES.TRACKING
                    if strcmp(sensor_roles{i}, SENSOR_ROLES.PRIMARY_TRACKER)
                        % Primary tracker - BRIGHT RED
                        set(node_handles(i), 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 9);
                        set(circle_handles(i), 'FaceColor', 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'r');
                    elseif strcmp(sensor_roles{i}, SENSOR_ROLES.SECONDARY_TRACKER)
                        % Secondary tracker - DARK RED
                        set(node_handles(i), 'MarkerFaceColor', [0.8, 0, 0], 'MarkerEdgeColor', [0.8, 0, 0], 'MarkerSize', 8);
                        set(circle_handles(i), 'FaceColor', [0.8, 0, 0], 'FaceAlpha', 0.25, 'EdgeColor', [0.8, 0, 0]);
                    end
                    
                case SENSOR_STATES.INTERCEPTING
                    % Interceptor candidate - ORANGE
                    set(node_handles(i), 'MarkerFaceColor', [1, 0.5, 0], 'MarkerEdgeColor', [1, 0.5, 0], 'MarkerSize', 7);
                    set(circle_handles(i), 'FaceColor', [1, 0.5, 0], 'FaceAlpha', 0.15, 'EdgeColor', [1, 0.5, 0]);
                    
                case SENSOR_STATES.RETURNING_HOME
                    % Returning home - MAGENTA
                    set(node_handles(i), 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm', 'MarkerSize', 6);
                    set(circle_handles(i), 'FaceColor', 'm', 'FaceAlpha', 0.1, 'EdgeColor', 'm');
                    
                case SENSOR_STATES.SEARCHING
                    % Use contour coloring if touched
                    if sensors_touched_1sigma(i) == 1
                        % 1-sigma contour - BLACK
                        set(node_handles(i), 'MarkerFaceColor', [0, 0, 0], 'MarkerEdgeColor', [0, 0, 0], 'MarkerSize', 7);
                        set(circle_handles(i), 'FaceColor', [0, 0, 0], 'FaceAlpha', 0.15, 'EdgeColor', [0, 0, 0]);
                    elseif sensors_touched_2sigma(i) == 1
                        % 2-sigma contour - RED
                        set(node_handles(i), 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 7);
                        set(circle_handles(i), 'FaceColor', 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'r');
                    elseif sensors_touched_3sigma(i) == 1
                        % 3-sigma contour - GREEN
                        set(node_handles(i), 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g', 'MarkerSize', 7);
                        set(circle_handles(i), 'FaceColor', 'g', 'FaceAlpha', 0.15, 'EdgeColor', 'g');
                    else
                        % Searching but not touched - PURPLE
                        set(node_handles(i), 'MarkerFaceColor', [0.5, 0, 0.5], 'MarkerEdgeColor', [0.5, 0, 0.5], 'MarkerSize', 6);
                        set(circle_handles(i), 'FaceColor', [0.5, 0, 0.5], 'FaceAlpha', 0.1, 'EdgeColor', [0.5, 0, 0.5]);
                    end
                    
                case SENSOR_STATES.DETECTING
                    % Currently detecting - CYAN
                    set(node_handles(i), 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'c', 'MarkerSize', 7);
                    set(circle_handles(i), 'FaceColor', 'c', 'FaceAlpha', 0.15, 'EdgeColor', 'c');
                    
                case SENSOR_STATES.IDLE
                    % Check if previously detected any target
                    previously_detected = false;
                    for target_id = 1:num_targets
                        if any(detected_sensors{target_id} == i)
                            previously_detected = true;
                            break;
                        end
                    end
                    
                    if previously_detected
                        % Previously detected - LIGHT CYAN
                        set(node_handles(i), 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'c', 'MarkerSize', 6);
                        set(circle_handles(i), 'FaceColor', 'c', 'FaceAlpha', 0.1, 'EdgeColor', 'c');
                    else
                        % Normal sensor - NAVY BLUE
                        set(node_handles(i), 'MarkerFaceColor', [0, 0, 0.8], 'MarkerEdgeColor', [0, 0, 0.8], 'MarkerSize', 6);
                        set(circle_handles(i), 'FaceColor', [0, 0, 0.8], 'FaceAlpha', 0.1, 'EdgeColor', [0, 0, 0.8]);
                    end
            end
        end
        
        % Update sensor text labels
        for i = 1:num_nodes
            set(sensor_text_handles(i), 'Position', [node_positions(i,1)+0.3, node_positions(i,2)+0.3, 0]);
        end
        
        % Update status text for three targets
        num_tracking = sum(cellfun(@(x) strcmp(x, SENSOR_STATES.TRACKING), sensor_states));
        num_intercepting = sum(cellfun(@(x) strcmp(x, SENSOR_STATES.INTERCEPTING), sensor_states));
        num_searching = sum(cellfun(@(x) strcmp(x, SENSOR_STATES.SEARCHING), sensor_states));
        num_returning = sum(cellfun(@(x) strcmp(x, SENSOR_STATES.RETURNING_HOME), sensor_states));
        
        % Count active trackers per target
        trackers_per_target = '';
        for target_id = 1:num_targets
            trackers_per_target = [trackers_per_target sprintf('T%d:%d ', target_id, length(active_trackers{target_id}))];
        end
        
        status = sprintf('System: %s | Tracking: %d (%s), Intercepting: %d, Searching: %d, Returning: %d | Touched: 1σ:%d, 2σ:%d, 3σ:%d', ...
            system_state, num_tracking, trackers_per_target, num_intercepting, num_searching, num_returning, ...
            sum(sensors_touched_1sigma), sum(sensors_touched_2sigma), sum(sensors_touched_3sigma));
        set(status_text, 'String', status);
        
        % Update title
        title(sprintf('WSN FSM three Target Tracking - Time: %.1f s, System State: %s', current_time, system_state));
        
        drawnow;
    end
    
    % Check if any target has left the simulation area
    targets_exited = false(num_targets, 1);
    for target_id = 1:num_targets
        if target_positions(target_id, 1) > wsn_width + 30
            targets_exited(target_id) = true;
        end
    end
    
    % If any target has exited, send relevant sensors home
    if any(targets_exited)
        for i = 1:num_nodes
            if strcmp(sensor_states{i}, SENSOR_STATES.TRACKING) || ...
               strcmp(sensor_states{i}, SENSOR_STATES.INTERCEPTING) || ...
               strcmp(sensor_states{i}, SENSOR_STATES.SEARCHING)
                
                % Reset any loss prediction tracking for all targets
                for target_id = 1:num_targets
                    previous_loss_predictions(i, target_id) = 0;
                    stable_prediction_counts(i, target_id) = 0;
                end
                
                % Send home
                sensor_states{i} = SENSOR_STATES.RETURNING_HOME;
                sensor_roles{i} = SENSOR_ROLES.NONE;
                
                % Remove from active trackers for all targets
                for target_id = 1:num_targets
                    if ismember(i, active_trackers{target_id})
                        active_trackers{target_id} = active_trackers{target_id}(active_trackers{target_id} ~= i);
                    end
                end
                
                % Add to returning home list if not already there
                if ~ismember(i, sensors_returning_home)
                    sensors_returning_home = [sensors_returning_home; i];
                end
                
                logStateTransition(i, prev_sensor_states{i}, sensor_states{i}, ...
                    prev_sensor_roles{i}, sensor_roles{i}, current_time, ...
                    'Target(s) exited simulation area - returning home');
            end
        end
        
        % Update system state
        if ~strcmp(system_state, SYSTEM_STATES.IDLE)
            system_state = SYSTEM_STATES.IDLE;
            logSystemTransition(prev_system_state, system_state, current_time, 'Target(s) exited area');
            system_state_history = [system_state_history; current_time, string(system_state)];
        end
        
        % Reset interceptor flags for all targets
        for target_id = 1:num_targets
            interceptor_call_triggered(target_id) = false;
        end
        
        % Clear active trackers for all targets
        for target_id = 1:num_targets
            active_trackers{target_id} = [];
        end
    end
    
    % Continue simulation until all sensors are home (or timeout)
    all_sensors_home = false;
    if any(targets_exited)
        % Check if all sensors have returned home
        sensors_still_away = 0;
        for i = 1:num_nodes
            distance_from_home = norm(node_positions(i,:) - original_positions(i,:));
            if distance_from_home > 0.1  % Not considered "home" yet
                sensors_still_away = sensors_still_away + 1;
            end
        end
        
        if sensors_still_away == 0
            all_sensors_home = true;
        end
    end
    
    % Stop simulation when all sensors are home OR timeout after target exit
    if all_sensors_home || (any(targets_exited) && current_time > simulation_time + 20)
        break;
    end

    % Track specific sensor trajectory
    if TRACK_SENSOR_ID <= num_nodes
        sensor_trajectory_history = [sensor_trajectory_history; 
            current_time, node_positions(TRACK_SENSOR_ID, 1), node_positions(TRACK_SENSOR_ID, 2), ...
            double(strcmp(sensor_states{TRACK_SENSOR_ID}, SENSOR_STATES.INTERCEPTING))];
    end

end  % END OF MAIN SIMULATION LOOP

%% Plot Confidence Analysis
if ~isempty(confidence_data)
    figure('Name', 'Confidence Analysis', 'Position', [200, 200, 1200, 400]);
    
    subplot(1,2,1);
    % Plot confidence over time for all sensors and targets
    for target_id = 1:num_targets
        target_data = confidence_data(confidence_data(:,3) == target_id, :);
        if ~isempty(target_data)
            scatter(target_data(:,1), target_data(:,4), 20, target_colors{target_id}, 'filled');
            hold on;
        end
    end
    xlabel('Time (units)'); ylabel('Confidence');
    title('Confidence Values Over Time by Target');
    legend(arrayfun(@(x) sprintf('Target %d', x), 1:num_targets, 'UniformOutput', false));
    grid on; ylim([0 1]);
    
    subplot(1,2,2);
    % Histogram of confidence ranges
    histogram(confidence_data(:,4), 20, 'FaceAlpha', 0.7);
    xlabel('Confidence Value'); ylabel('Frequency');
    title('Distribution of Confidence Values');
    grid on;
    
    % Print statistics
    fprintf(fid, '[t=%5.2f][STATS] === CONFIDENCE ANALYSIS ===\n', simulation_time);
    fprintf(fid, '[t=%5.2f][STATS] Total confidence measurements: %d\n', simulation_time, size(confidence_data, 1));
    fprintf(fid, '[t=%5.2f][STATS] Confidence range: %.3f to %.3f\n', simulation_time, min(confidence_data(:,4)), max(confidence_data(:,4)));
    fprintf(fid, '[t=%5.2f][STATS] Mean confidence: %.3f\n', simulation_time, mean(confidence_data(:,4)));
    fprintf(fid, '[t=%5.2f][STATS] Confidence below 0.1: %.1f%%\n', simulation_time, sum(confidence_data(:,4) < 0.1)/size(confidence_data,1)*100);
    fprintf(fid, '[t=%5.2f][STATS] Confidence 0.1-0.3: %.1f%%\n', simulation_time, sum(confidence_data(:,4) >= 0.1 & confidence_data(:,4) < 0.3)/size(confidence_data,1)*100);
    fprintf(fid, '[t=%5.2f][STATS] Confidence above 0.3: %.1f%%\n', simulation_time, sum(confidence_data(:,4) >= 0.3)/size(confidence_data,1)*100);
end

%% Plot tracked sensor trajectory
if ~isempty(sensor_trajectory_history)
    figure('Name', sprintf('Sensor %d Trajectory', TRACK_SENSOR_ID), 'Position', [100, 100, 800, 600]);
    
    % Extract data
    times = sensor_trajectory_history(:, 1);
    x_pos = sensor_trajectory_history(:, 2);
    y_pos = sensor_trajectory_history(:, 3);
    intercepting_state = sensor_trajectory_history(:, 4);
    
    % Plot trajectory with color coding
    hold on;
    
    % Create legend handles
    h_intercepting = [];
    h_other = [];
    
    % Plot different segments based on state
    for i = 1:(length(times)-1)
        if intercepting_state(i) == 1
            % Intercepting - red line
            h = plot([x_pos(i), x_pos(i+1)], [y_pos(i), y_pos(i+1)], 'r-', 'LineWidth', 2);
            if isempty(h_intercepting)
                h_intercepting = h; % Save first red line for legend
            end
        else
            % Other states - blue line
            h = plot([x_pos(i), x_pos(i+1)], [y_pos(i), y_pos(i+1)], 'b-', 'LineWidth', 1);
            if isempty(h_other)
                h_other = h; % Save first blue line for legend
            end
        end
    end
    
    % Mark start and end points
    h_start = plot(x_pos(1), y_pos(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    h_end = plot(x_pos(end), y_pos(end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    
    % Create legend with proper handles
    legend_handles = [];
    legend_labels = {};
    
    if ~isempty(h_intercepting)
        legend_handles = [legend_handles, h_intercepting];
        legend_labels{end+1} = 'Intercepting';
    end
    if ~isempty(h_other)
        legend_handles = [legend_handles, h_other];
        legend_labels{end+1} = 'Other States';
    end
    legend_handles = [legend_handles, h_start, h_end];
    legend_labels{end+1} = 'Start';
    legend_labels{end+1} = 'End';
    
    legend(legend_handles, legend_labels, 'Location', 'best');
    
    % Add labels
    xlabel('X Position');
    ylabel('Y Position');
    title(sprintf('Sensor %d Complete Trajectory', TRACK_SENSOR_ID));
    grid on;
    axis equal;
    
    % Print trajectory summary
    fprintf(fid, '[t=%5.2f][STATS] === SENSOR %d TRAJECTORY SUMMARY ===\n', simulation_time, TRACK_SENSOR_ID);
    fprintf(fid, '[t=%5.2f][STATS] Total simulation time: %.1f seconds\n', simulation_time, times(end) - times(1));
    total_distance = 0;
    for i = 1:(length(x_pos)-1)
        total_distance = total_distance + norm([x_pos(i+1)-x_pos(i), y_pos(i+1)-y_pos(i)]);
    end
    fprintf(fid, '[t=%5.2f][STATS] Total distance traveled: %.2f units\n', simulation_time, total_distance);
    fprintf(fid, '[t=%5.2f][STATS] Start position: [%.2f, %.2f]\n', simulation_time, x_pos(1), y_pos(1));
    fprintf(fid, '[t=%5.2f][STATS] End position: [%.2f, %.2f]\n', simulation_time, x_pos(end), y_pos(end));
end

%% Count sensors that moved during simulation
sensors_that_moved = 0;
for i = 1:num_nodes
    history = sensor_state_history{i};
    sensor_was_active = false;
    
    for j = 1:size(history, 1)
        state = char(history(j, 2));
        if strcmp(state, 'TRACKING') || strcmp(state, 'INTERCEPTING') || strcmp(state, 'RETURNING_HOME')
            sensor_was_active = true;
            break;
        end
    end
    
    if sensor_was_active
        sensors_that_moved = sensors_that_moved + 1;
    end
end

engagement_percentage = (sensors_that_moved / num_nodes) * 100;
fprintf(fid, '[t=%5.2f][RESULT] FINAL: %d/%d sensors moved (%.1f%% engagement)\n', ...
    simulation_time, sensors_that_moved, num_nodes, engagement_percentage);

global CURRENT_ENGAGEMENT;
CURRENT_ENGAGEMENT = engagement_percentage;

%% Debug stuck sensors (optional analysis)
for i = 1:num_nodes
    distance_from_home = norm(node_positions(i,:) - original_positions(i,:));
    if distance_from_home > 0.5
        % Could log stuck sensors here if needed for debugging
    end
end

%% Post-simulation Analysis for three Targets

% Save final contour period if needed
if last_contour_state == 1 && ~isempty(current_contour_period)
    contour_periods{end+1} = current_contour_period;
end

% NEW: three target interceptor analysis
interceptor_assignments = 0;
successful_intercepts = 0;
missed_intercepts = 0;

for i = 1:num_nodes
    history = sensor_state_history{i};
    for j = 1:size(history, 1)
        if strcmp(history(j, 2), "INTERCEPTING")
            interceptor_assignments = interceptor_assignments + 1;
            
            % Check if this interceptor was successful
            if j < size(history, 1)
                next_state = history(j+1, 2);
                if strcmp(next_state, "TRACKING")
                    successful_intercepts = successful_intercepts + 1;
                elseif strcmp(next_state, "RETURNING_HOME")
                    missed_intercepts = missed_intercepts + 1;
                end
            end
        end
    end
end

% NEW: Analyze returning home behavior
sensors_that_returned = 0;
total_return_distance = 0;

for i = 1:num_nodes
    history = sensor_state_history{i};
    returned_home = false;
    
    for j = 1:size(history, 1)
        if strcmp(history(j, 2), "RETURNING_HOME")
            % Check if they completed the return journey
            if j < size(history, 1) && strcmp(history(j+1, 2), "IDLE")
                returned_home = true;
                break;
            end
        end
    end
    
    if returned_home
        sensors_that_returned = sensors_that_returned + 1;
        max_distance = norm(node_positions(i,:) - original_positions(i,:));
        total_return_distance = total_return_distance + max_distance;
    end
end

% Analyze sensor state distributions
state_counts = struct();
for state = fieldnames(SENSOR_STATES)'
    state_counts.(state{1}) = 0;
end

for i = 1:num_nodes
    if ~isempty(sensor_state_history{i})
        history = sensor_state_history{i};
        for j = 1:size(history, 1)-1
            state = char(history(j, 2));
            duration = double(history(j+1, 1)) - double(history(j, 1));
            if isfield(state_counts, state)
                state_counts.(state) = state_counts.(state) + duration;
            end
        end
        % Add time in final state
        final_state = char(history(end, 2));
        final_duration = current_time - double(history(end, 1));
        if isfield(state_counts, final_state)
            state_counts.(final_state) = state_counts.(final_state) + final_duration;
        end
    end
end

% NEW: Analyze handover events for three targets
immediate_handovers = 0;
planned_handovers = 0;

for i = 1:num_nodes
    history = sensor_state_history{i};
    for j = 1:size(history, 1)
        if strcmp(history(j, 2), "TRACKING")
            if j > 1 && strcmp(history(j-1, 2), "DETECTING")
                planned_handovers = planned_handovers + 1;
            elseif j > 1 && strcmp(history(j-1, 2), "INTERCEPTING")
                planned_handovers = planned_handovers + 1;
            end
        end
    end
end

% Analyze individual sensor performance
most_active_sensor = 1;
max_transitions = 0;
most_traveled_sensor = 1;
max_travel_distance = 0;

for i = 1:num_nodes
    num_transitions = size(sensor_state_history{i}, 1) - 1;
    if num_transitions > max_transitions
        max_transitions = num_transitions;
        most_active_sensor = i;
    end
    
    % Calculate total travel distance
    if ~isempty(sensor_trajectories{i})
        total_distance = 0;
        traj = sensor_trajectories{i};
        for j = 2:size(traj, 1)
            total_distance = total_distance + norm(traj(j,:) - traj(j-1,:));
        end
        
        if total_distance > max_travel_distance
            max_travel_distance = total_distance;
            most_traveled_sensor = i;
        end
    end
end

% NEW: Network configuration preservation analysis
sensors_at_home = 0;
max_displacement = 0;
total_displacement = 0;

for i = 1:num_nodes
    distance_from_home = norm(node_positions(i,:) - original_positions(i,:));
    total_displacement = total_displacement + distance_from_home;
    
    if distance_from_home < 0.5
        sensors_at_home = sensors_at_home + 1;
    end
    
    if distance_from_home > max_displacement
        max_displacement = distance_from_home;
    end
end

%% Plot Multiple Sensor Trajectories for three Targets
function plotMultipleSensorTrajectories(sensor_list, sensor_trajectories, original_positions, node_positions, target_trajectories, global_interceptor_data)
    if isempty(sensor_list)
        sensor_list = [];
        for i = 1:length(sensor_trajectories)
            if ~isempty(sensor_trajectories{i}) && size(sensor_trajectories{i}, 1) > 1
                sensor_list = [sensor_list, i];
            end
        end
    end
    
    figure(30); clf;
    set(gcf, 'Position', [300, 300, 1200, 800]);
    hold on; grid on; axis equal;
    xlim([-10, 80]); ylim([-15, 60]);
    xlabel('X (units)'); ylabel('Y (units)');
    title(sprintf('three Target Sensor Trajectories: [%s]', num2str(sensor_list)));
    
    legend_handles = [];
    legend_labels = {};
    
    % Plot both target trajectories
    target_colors = {'r', 'g', 'b', 'm', 'c', 'k'};  % Support up to 6 targets
    for target_id = 1:length(target_trajectories)
        if ~isempty(target_trajectories{target_id})
            h1 = plot(target_trajectories{target_id}(:,1), target_trajectories{target_id}(:,2), ...
                [target_colors{target_id} '-'], 'LineWidth', 2);
            h2 = plot(target_trajectories{target_id}(1,1), target_trajectories{target_id}(1,2), ...
                [target_colors{target_id} 'o'], 'MarkerSize', 12, 'MarkerFaceColor', target_colors{target_id});
            legend_handles = [legend_handles, h1, h2];
            legend_labels{end+1} = sprintf('Target %d Trajectory', target_id);
            legend_labels{end+1} = sprintf('Target %d Start', target_id);
        end
    end
    
    % Plot intercept points for any target with data
    for target_id = 1:length(global_interceptor_data)
        if ~isempty(global_interceptor_data{target_id}) && isfield(global_interceptor_data{target_id}, 'loss_point')
            loss_point = global_interceptor_data{target_id}.loss_point;
            safe_point = global_interceptor_data{target_id}.intercept_point;
            
            h3 = plot(loss_point(1), loss_point(2), 'rx', 'MarkerSize', 15, 'LineWidth', 2);
            h4 = plot(safe_point(1), safe_point(2), 'g^', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'g');
            h5 = plot([loss_point(1), safe_point(1)], [loss_point(2), safe_point(2)], 'k--', 'LineWidth', 1);
            
            legend_handles = [legend_handles, h3, h4, h5];
            legend_labels{end+1} = sprintf('T%d Loss Point (100%%)', target_id);
            legend_labels{end+1} = sprintf('T%d Safe Intercept (90%%)', target_id);
            legend_labels{end+1} = sprintf('T%d Safety Margin', target_id);
        end
    end
    
    % Plot sensor positions and trajectories
    if ~isempty(sensor_list)
        h7 = plot(original_positions(sensor_list,1), original_positions(sensor_list,2), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
        h8 = plot(node_positions(sensor_list,1), node_positions(sensor_list,2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        legend_handles = [legend_handles, h7, h8];
        legend_labels{end+1} = 'Home Positions';
        legend_labels{end+1} = 'Final Positions';
    end
    
    % Plot sensor trajectories with unique colors
    colors = lines(max(sensor_list));
    
    for idx = 1:length(sensor_list)
        i = sensor_list(idx);
        if ~isempty(sensor_trajectories{i}) && size(sensor_trajectories{i}, 1) > 1
            traj = sensor_trajectories{i};
            sensor_color = colors(i,:);
            
            h_actual = plot(traj(:,1), traj(:,2), 'Color', sensor_color, 'LineWidth', 1.5);
            legend_handles = [legend_handles, h_actual];
            legend_labels{end+1} = sprintf('S%d Path', i);
            
            h_start = plot(traj(1,1), traj(1,2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', sensor_color, 'MarkerEdgeColor', 'k');
            h_end = plot(traj(end,1), traj(end,2), 's', 'MarkerSize', 8, 'MarkerFaceColor', sensor_color, 'MarkerEdgeColor', 'k');
            
            legend_handles = [legend_handles, h_start, h_end];
            legend_labels{end+1} = sprintf('S%d Start', i);
            legend_labels{end+1} = sprintf('S%d End', i);
            
            % Add sensor name on trajectory
            mid_idx = round(size(traj,1)/2);
            text(traj(mid_idx,1), traj(mid_idx,2), sprintf('S%d', i), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', sensor_color, ...
                'BackgroundColor', 'white', 'EdgeColor', sensor_color, ...
                'HorizontalAlignment', 'center');
        end
    end
    
    legend(legend_handles, legend_labels, 'Location', 'eastoutside', 'FontSize', 9);
end

%% Plot Single Sensor Trajectory for three Targets
function plotSingleSensorTrajectory(sensor_id, sensor_trajectories, original_positions, node_positions, target_trajectories, global_interceptor_data)
    figure(31); clf;
    set(gcf, 'Position', [400, 400, 1200, 800]);
    hold on; grid on; axis equal;
    xlim([-10, 80]); ylim([-15, 60]);
    xlabel('X (units)'); ylabel('Y (units)');
    title(sprintf('three Target Sensor %d Movement Analysis', sensor_id));
    
    legend_handles = [];
    legend_labels = {};
    
    % Use consistent color for this sensor
    colors = lines(25);
    sensor_color = colors(sensor_id,:);
    
    % Plot both target trajectories
    target_colors = {'r', 'g', 'b'};
    for target_id = 1:length(target_trajectories)
        if ~isempty(target_trajectories{target_id})
            h1 = plot(target_trajectories{target_id}(:,1), target_trajectories{target_id}(:,2), ...
                [target_colors{target_id} '-'], 'LineWidth', 1.5, 'Color', [0.7, 0.7, 0.7]);
            h2 = plot(target_trajectories{target_id}(1,1), target_trajectories{target_id}(1,2), ...
                [target_colors{target_id} 'o'], 'MarkerSize', 12, 'MarkerFaceColor', target_colors{target_id});
            legend_handles = [legend_handles, h1, h2];
            legend_labels{end+1} = sprintf('Target %d Trajectory', target_id);
            legend_labels{end+1} = sprintf('Target %d Start', target_id);
        end
    end
    
    % Plot intercept points for relevant targets
    for target_id = 1:length(global_interceptor_data)
        if ~isempty(global_interceptor_data{target_id}) && isfield(global_interceptor_data{target_id}, 'loss_point')
            loss_point = global_interceptor_data{target_id}.loss_point;
            safe_point = global_interceptor_data{target_id}.intercept_point;
            
            h3 = plot(loss_point(1), loss_point(2), 'rx', 'MarkerSize', 20, 'LineWidth', 2);
            h4 = plot(safe_point(1), safe_point(2), 'g^', 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', 'g');
            h5 = plot([loss_point(1), safe_point(1)], [loss_point(2), safe_point(2)], 'k--', 'LineWidth', 1.5);
            
            legend_handles = [legend_handles, h3, h4, h5];
            legend_labels{end+1} = sprintf('T%d Loss Point (100%%)', target_id);
            legend_labels{end+1} = sprintf('T%d Safe Intercept (90%%)', target_id);
            legend_labels{end+1} = sprintf('T%d Safety Margin', target_id);
        end
    end
    
    % Plot sensor trajectory analysis
    if ~isempty(sensor_trajectories{sensor_id}) && size(sensor_trajectories{sensor_id}, 1) > 1
        traj = sensor_trajectories{sensor_id};
        
        % Plot home position
        h7 = plot(original_positions(sensor_id,1), original_positions(sensor_id,2), 'ko', 'MarkerSize', 15, 'MarkerFaceColor', 'k', 'LineWidth', 2);
        legend_handles = [legend_handles, h7];
        legend_labels{end+1} = sprintf('S%d Home Position', sensor_id);
        
        % Plot actual trajectory with gradient
        for j = 1:size(traj,1)-1
            color_intensity = j / size(traj,1);
            gradient_color = sensor_color * (0.3 + 0.7*color_intensity);
            plot(traj(j:j+1,1), traj(j:j+1,2), 'Color', gradient_color, 'LineWidth', 2);
        end
        
        % Add representative line for legend
        h9 = plot(NaN, NaN, 'Color', sensor_color, 'LineWidth', 2);
        legend_handles = [legend_handles, h9];
        legend_labels{end+1} = sprintf('S%d Actual Path', sensor_id);
        
        % Mark movement start and end
        h10 = plot(traj(1,1), traj(1,2), 'o', 'MarkerSize', 12, 'MarkerFaceColor', sensor_color, 'MarkerEdgeColor', 'k', 'LineWidth', 2);
        h11 = plot(traj(end,1), traj(end,2), 's', 'MarkerSize', 12, 'MarkerFaceColor', sensor_color, 'MarkerEdgeColor', 'k', 'LineWidth', 2);
        legend_handles = [legend_handles, h10, h11];
        legend_labels{end+1} = sprintf('S%d Movement Start', sensor_id);
        legend_labels{end+1} = sprintf('S%d Movement End', sensor_id);
        
        % Add sensor name TEXT on trajectory
        if size(traj,1) > 3
            mid_idx = round(size(traj,1) / 2);
            text(traj(mid_idx,1)+ 1.5, traj(mid_idx,2), sprintf('S%d', sensor_id), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', sensor_color, ...
                'BackgroundColor', 'white', 'EdgeColor', sensor_color, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end
    end
    
    legend(legend_handles, legend_labels, 'Location', 'eastoutside', 'FontSize', 10);
end

%% Updated Legend for three Target Simulation
figure(fig);

% Create dummy plot handles for legend - dynamic for multiple targets
legend_handles = [];
legend_labels = {};

% Add target handles dynamically
for target_id = 1:num_targets
    h_target = plot(NaN, NaN, [target_colors{target_id} '*'], 'MarkerSize', 10);
    h_target_path = plot(NaN, NaN, [target_colors{target_id} '-'], 'LineWidth', 1);
    legend_handles = [legend_handles, h_target, h_target_path];
    legend_labels{end+1} = sprintf('Target %d', target_id);
    legend_labels{end+1} = sprintf('Target %d Path', target_id);
end

% Add sensor state handles
h_primary_tracker = plot(NaN, NaN, 'bo', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
h_secondary_tracker = plot(NaN, NaN, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', [0.8, 0, 0]);
h_interceptor = plot(NaN, NaN, 'bo', 'MarkerSize', 7, 'MarkerFaceColor', [1, 0.5, 0]);
h_returning_home = plot(NaN, NaN, 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'm');
h_detecting = plot(NaN, NaN, 'bo', 'MarkerSize', 7, 'MarkerFaceColor', 'c');
h_normal = plot(NaN, NaN, 'bo', 'MarkerSize', 6, 'MarkerFaceColor', [0, 0, 0.8]);

legend_handles = [legend_handles, h_primary_tracker, h_secondary_tracker, h_interceptor, h_returning_home, h_detecting, h_normal];
legend_labels = [legend_labels, {'Primary Tracker', 'Secondary Tracker', 'Interceptor', 'Returning Home', 'Detecting', 'Normal Sensor'}];

legend(legend_handles, legend_labels, 'Location', 'northeastoutside');

% fprintf('\n=== three TARGET SIMULATION COMPLETE ===\n');
% fprintf('Enhanced FSM-based three target cooperative tracking simulation finished.\n');
% fprintf('Key three target features implemented:\n');
% fprintf('- Independent target movement with separate waypoint trajectories\n');
% fprintf('- Per-target EKF tracking and loss prediction\n');
% fprintf('- Competitive bidding system with conflict resolution\n');
% fprintf('- Target-specific interceptor assignment (nearest gets first 2, farthest gets next 2)\n');
% fprintf('- Individual sensor target selection (nearest target preference)\n');
% fprintf('- Per-target handover and replacement logic\n');
% fprintf('- three target visualization with color coding\n');

%% Save persistent outputs
fclose(fid);

save(mat_filename, ...
    'params', ...
    'node_positions_history', ...
    'interceptor_events', ...
    'assignment_events', ...
    'interceptor_employ_events', ...
    'target_trajectories', ...
    'sensor_trajectories', ...
    'sensor_P_trace_history', ...
    'system_state_history', ...
    'sensor_state_history', ...
    'sensor_trajectory_history', ...
    'original_positions', ...
    'total_successful_intercepts', 'interceptor_call_counter');

fprintf('Log  → %s\n', log_filename);
fprintf('Data → %s\n', mat_filename);
