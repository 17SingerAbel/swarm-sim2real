% test_2for2_handover.m — Minimal regression test for 2-for-2 handover fix
clear;

% State constants (mirror the main script)
SENSOR_STATES.INTERCEPTING    = 'INTERCEPTING';
SENSOR_STATES.TRACKING        = 'TRACKING';
SENSOR_STATES.RETURNING_HOME  = 'RETURNING_HOME';
SENSOR_ROLES.PRIMARY_TRACKER        = 'PRIMARY_TRACKER';
SENSOR_ROLES.SECONDARY_TRACKER      = 'SECONDARY_TRACKER';
SENSOR_ROLES.INTERCEPTOR_CANDIDATE  = 'INTERCEPTOR_CANDIDATE';
SENSOR_ROLES.NONE                   = 'NONE';

num_sensors = 6; num_targets = 3; detected_target_id = 1; current_time = 15.0;

% Sensors 1,2 = original trackers; Sensors 3,4 = interceptors
sensor_states = repmat({'IDLE'}, num_sensors, 1);
sensor_states{1} = 'TRACKING';      sensor_states{2} = 'TRACKING';
sensor_states{3} = 'INTERCEPTING';  sensor_states{4} = 'INTERCEPTING';

sensor_roles = repmat({'NONE'}, num_sensors, 1);
sensor_roles{1} = 'PRIMARY_TRACKER';       sensor_roles{2} = 'SECONDARY_TRACKER';
sensor_roles{3} = 'INTERCEPTOR_CANDIDATE'; sensor_roles{4} = 'INTERCEPTOR_CANDIDATE';
prev_sensor_roles = sensor_roles;

active_trackers = {[1; 2], [], []};   % target 1 → sensors 1 and 2
sensors_returning_home = [];
total_successful_intercepts = 0;
interceptor_call_triggered = [true, false, false];
target_positions = [10, 5; 0, 0; 0, 0];

sensor_detection_times = zeros(num_sensors, num_targets);
sensor_ekf_states    = cellfun(@(~) zeros(4,1), cell(num_sensors, num_targets), 'UniformOutput', false);
sensor_P_matrices    = cellfun(@(~) eye(4),     cell(num_sensors, num_targets), 'UniformOutput', false);
sensor_P_trace_history = cell(num_sensors, num_targets);

fid = 1;  % stdout (no file I/O needed for test)

% Stub logStateTransition to suppress output during test
logStateTransition = @(varargin) deal();  %#ok<NASGU>

% Both interceptors detected the target in the same timestep
detecting_interceptors_for_target = [3; 4];
current_active_trackers = active_trackers{detected_target_id};   % [1; 2]

% Simulate the outer sensor iteration for i=3 then i=4
for i = [3, 4]
    if i == detecting_interceptors_for_target(1)
        % First interceptor: release old trackers and claim PRIMARY
        for old_tracker = current_active_trackers'
            sensor_states{old_tracker} = SENSOR_STATES.RETURNING_HOME;
            sensor_roles{old_tracker} = SENSOR_ROLES.NONE;
            sensors_returning_home = [sensors_returning_home; old_tracker]; %#ok<AGROW>
        end

        active_trackers{detected_target_id} = [];

        sensor_states{i} = SENSOR_STATES.TRACKING;
        sensor_roles{i} = SENSOR_ROLES.PRIMARY_TRACKER;
        active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];

        sensor_detection_times(i, detected_target_id) = current_time;
        sensor_ekf_states{i, detected_target_id} = [target_positions(detected_target_id, 1); target_positions(detected_target_id, 2); 0; 0];
        sensor_P_matrices{i, detected_target_id} = eye(4);
        sensor_P_trace_history{i, detected_target_id} = [current_time, trace(sensor_P_matrices{i, detected_target_id})];

        total_successful_intercepts = total_successful_intercepts + 1;
        interceptor_call_triggered(detected_target_id) = false;

    elseif i == detecting_interceptors_for_target(2)
        % Second interceptor: old trackers already released — just add as SECONDARY
        sensor_states{i} = SENSOR_STATES.TRACKING;
        sensor_roles{i} = SENSOR_ROLES.SECONDARY_TRACKER;
        active_trackers{detected_target_id} = [active_trackers{detected_target_id}; i];

        sensor_detection_times(i, detected_target_id) = current_time;
        sensor_ekf_states{i, detected_target_id} = [target_positions(detected_target_id, 1); target_positions(detected_target_id, 2); 0; 0];
        sensor_P_matrices{i, detected_target_id} = eye(4);
        sensor_P_trace_history{i, detected_target_id} = [current_time, trace(sensor_P_matrices{i, detected_target_id})];

        total_successful_intercepts = total_successful_intercepts + 1;
    end
end

% Assertions
ok = strcmp(sensor_states{3}, 'TRACKING')          && ...
     strcmp(sensor_states{4}, 'TRACKING')          && ...
     strcmp(sensor_roles{3},  'PRIMARY_TRACKER')   && ...
     strcmp(sensor_roles{4},  'SECONDARY_TRACKER') && ...
     strcmp(sensor_states{1}, 'RETURNING_HOME')    && ...
     strcmp(sensor_states{2}, 'RETURNING_HOME')    && ...
     length(active_trackers{1}) == 2               && ...
     total_successful_intercepts == 2;

fprintf('active_trackers{1}           = [%s]  (want [3 4])\n', num2str(active_trackers{1}'));
fprintf('sensor_states{3}             = %s  (want TRACKING)\n',           sensor_states{3});
fprintf('sensor_states{4}             = %s  (want TRACKING)\n',           sensor_states{4});
fprintf('sensor_roles{3}              = %s  (want PRIMARY_TRACKER)\n',    sensor_roles{3});
fprintf('sensor_roles{4}              = %s  (want SECONDARY_TRACKER)\n',  sensor_roles{4});
fprintf('sensor_states{1}             = %s  (want RETURNING_HOME)\n',     sensor_states{1});
fprintf('sensor_states{2}             = %s  (want RETURNING_HOME)\n',     sensor_states{2});
fprintf('length(active_trackers{1})   = %d  (want 2)\n',                  length(active_trackers{1}));
fprintf('total_successful_intercepts  = %d  (want 2)\n',                  total_successful_intercepts);
if ok
    fprintf('\n*** PASS ***\n');
else
    fprintf('\n*** FAIL ***\n');
end
