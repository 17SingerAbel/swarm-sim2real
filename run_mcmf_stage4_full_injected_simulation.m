function result = run_mcmf_stage4_full_injected_simulation(use_mcmf, injection_time)
%RUN_MCMF_STAGE4_FULL_INJECTED_SIMULATION Run the Stage 4 full injected check.
%   Stage 4 uses the dedicated full-run injected V46 script and runs the
%   75 s horizon and enables the augment-or-fallback injection policy.

if nargin < 1
    use_mcmf = true;
end
if nargin < 2
    injection_time = 15;
end

setenv('ENABLE_MCMF_STAGE3_TEST', '1');
setenv('ENABLE_MCMF_STAGE4_TEST', '1');
setenv('MCMF_STAGE3_SIMULATION_TIME', '75');
setenv('MCMF_STAGE3_INJECTION_TIME', num2str(injection_time));
setenv('MCMF_STAGE3_USE_MCMF', string(double(use_mcmf)));

try
    example_v46_stage4_Yeqi;
    clearStage4Environment();
catch ME
    clearStage4Environment();
    rethrow(ME);
end

assert(exist('assignment_events', 'var') == 1, 'Stage4:MissingAssignmentEvents', ...
    'assignment_events was not created.');
assert(~isempty(assignment_events), 'Stage4:NoAssignmentEvents', ...
    'No assignment_events were created.');
assert(exist('stage3_injection_info', 'var') == 1 && stage3_injection_info.injected, ...
    'Stage4:InjectionMissing', 'The Stage 4 injection did not run.');
assert(strcmp(stage3_injection_info.injection_policy, 'AUGMENT_OR_FALLBACK'), ...
    'Stage4:WrongInjectionPolicy', 'Stage 4 did not use AUGMENT_OR_FALLBACK policy.');
assert(exist('stage3_assignment_snapshot', 'var') == 1 && ~isempty(stage3_assignment_snapshot), ...
    'Stage4:SnapshotMissing', 'No Stage 4 assignment snapshot was captured.');

event = assignment_events(stage3_assignment_snapshot.event_index);
expected_algorithm = ternary(params.USE_MCMF_ASSIGNMENT, 'MCMF', 'LEGACY');
assert(strcmp(event.algorithm, expected_algorithm), 'Stage4:WrongAlgorithm', ...
    'Expected %s assignment, got %s.', expected_algorithm, event.algorithm);
assert(numel(event.calling_targets) == 2, 'Stage4:WrongCallingTargetCount', ...
    'Expected a two-target Stage 4 conflict event.');

assigned_sensors = flattenStage4Assignments(event.assignments);
assert(~isempty(assigned_sensors), 'Stage4:NoAssignedSensors', ...
    'No sensors were assigned in the Stage 4 event.');
assert(numel(unique(assigned_sensors)) == numel(assigned_sensors), 'Stage4:DuplicateSensors', ...
    'A sensor was assigned more than once.');

active_trackers_at_assignment = flattenStage4ActiveTrackers(stage3_assignment_snapshot);
assert(isempty(intersect(assigned_sensors, active_trackers_at_assignment)), ...
    'Stage4:SelectedActiveTracker', ...
    'Stage 4 selected a sensor that was an active tracker at assignment time.');

assert(all(strcmp(stage3_assignment_snapshot.sensor_states, SENSOR_STATES.INTERCEPTING)), ...
    'Stage4:SelectedSensorsNotIntercepting', ...
    'At least one selected sensor did not enter INTERCEPTING in the assignment snapshot.');
assert(all(strcmp(stage3_assignment_snapshot.sensor_roles, SENSOR_ROLES.INTERCEPTOR_CANDIDATE)), ...
    'Stage4:SelectedSensorsWrongRole', ...
    'At least one selected sensor did not receive INTERCEPTOR_CANDIDATE role.');
assert(all(cellfun(@(target) ~isempty(target), stage3_assignment_snapshot.proactive_targets)), ...
    'Stage4:MissingProactiveTargets', ...
    'At least one selected sensor did not receive a proactive target.');
assert(current_time >= 74.9, 'Stage4:DidNotReachFullRun', ...
    'Stage 4 did not reach the expected full 75 s horizon.');

any_selected_sensor_moved = false;
unique_assigned_sensors = unique(assigned_sensors);
for unique_sensor_idx = 1:numel(unique_assigned_sensors)
    sensor_id = unique_assigned_sensors(unique_sensor_idx);
    trajectory = sensor_trajectories{sensor_id}; %#ok<USENS>
    if size(trajectory, 1) >= 2 && norm(trajectory(end, :) - trajectory(1, :)) > 0
        any_selected_sensor_moved = true;
        break;
    end
end
assert(any_selected_sensor_moved, 'Stage4:NoMovementObserved', ...
    'No selected sensor showed movement after Stage 4 assignment.');

assert(exist(mat_filename, 'file') == 2, 'Stage4:MissingMatOutput', ...
    'MAT output was not found: %s', mat_filename);
assert(exist(log_filename, 'file') == 2, 'Stage4:MissingLogOutput', ...
    'Log output was not found: %s', log_filename);

[mcmf_assignments, mcmf_info] = solveInterceptorAssignments( ...
    event.calling_targets(:), event.candidate_sensors(:), event.cost_matrix, ...
    event.requested_slots_per_target, true);
[legacy_assignments, legacy_info] = solveInterceptorAssignments( ...
    event.calling_targets(:), event.candidate_sensors(:), event.cost_matrix, ...
    event.requested_slots_per_target, false);

mcmf_assigned_sensors = flattenStage4Assignments(mcmf_assignments);
legacy_assigned_sensors = flattenStage4Assignments(legacy_assignments);
mcmf_total_cost = mcmf_info.total_cost;
legacy_total_cost = legacy_info.total_cost;
mcmf_cost_improvement = legacy_total_cost - mcmf_total_cost;

result = struct( ...
    'passed', true, ...
    'mat_filename', mat_filename, ...
    'log_filename', log_filename, ...
    'injection_policy', stage3_injection_info.injection_policy, ...
    'actual_injection_mode', stage3_injection_info.actual_injection_mode, ...
    'natural_target', stage3_injection_info.natural_target, ...
    'companion_target', stage3_injection_info.companion_target, ...
    'actual_algorithm', event.algorithm, ...
    'actual_assignments', {event.assignments}, ...
    'actual_assigned_sensors', assigned_sensors, ...
    'actual_total_cost', event.total_cost, ...
    'assignment_time', stage3_assignment_snapshot.time, ...
    'final_time', current_time, ...
    'calling_targets', event.calling_targets, ...
    'mcmf_assignments', {mcmf_assignments}, ...
    'mcmf_assigned_sensors', mcmf_assigned_sensors, ...
    'mcmf_total_cost', mcmf_total_cost, ...
    'legacy_assignments', {legacy_assignments}, ...
    'legacy_assigned_sensors', legacy_assigned_sensors, ...
    'legacy_total_cost', legacy_total_cost, ...
    'mcmf_cost_improvement', mcmf_cost_improvement, ...
    'candidate_sensors', event.candidate_sensors, ...
    'cost_matrix', event.cost_matrix);

fprintf('Stage 4 full injected simulation passed.\n');
fprintf('  MAT output: %s\n', mat_filename);
fprintf('  Log output: %s\n', log_filename);
fprintf('  Injection policy: %s\n', result.injection_policy);
fprintf('  Actual injection mode: %s\n', result.actual_injection_mode);
fprintf('  Assignment time: %.2f s\n', result.assignment_time);
fprintf('  Final simulation time: %.2f s\n', result.final_time);
fprintf('  Actual algorithm run in simulation: %s\n', result.actual_algorithm);
fprintf('  Calling targets: [%s]\n', num2str(result.calling_targets));
fprintf('  Actual assigned sensors: [%s]\n', num2str(result.actual_assigned_sensors));
fprintf('  Actual total cost: %.4f\n', result.actual_total_cost);
fprintf('  MCMF assigned sensors: [%s]\n', num2str(result.mcmf_assigned_sensors));
for target_idx = 1:numel(mcmf_assignments)
    fprintf('    MCMF target %d -> [%s]\n', event.calling_targets(target_idx), ...
        num2str(mcmf_assignments{target_idx}));
end
fprintf('  MCMF total cost: %.4f\n', result.mcmf_total_cost);
fprintf('  Legacy assigned sensors on same matrix: [%s]\n', num2str(result.legacy_assigned_sensors));
for target_idx = 1:numel(legacy_assignments)
    fprintf('    Legacy target %d -> [%s]\n', event.calling_targets(target_idx), ...
        num2str(legacy_assignments{target_idx}));
end
fprintf('  Legacy total cost: %.4f\n', result.legacy_total_cost);
fprintf('  MCMF cost improvement: %.4f\n', result.mcmf_cost_improvement);
end

function clearStage4Environment()
setenv('ENABLE_MCMF_STAGE3_TEST', '');
setenv('ENABLE_MCMF_STAGE4_TEST', '');
setenv('MCMF_STAGE3_SIMULATION_TIME', '');
setenv('MCMF_STAGE3_INJECTION_TIME', '');
setenv('MCMF_STAGE3_USE_MCMF', '');
end

function assigned_sensors = flattenStage4Assignments(assignments)
assigned_sensors = [];
for target_idx = 1:numel(assignments)
    assigned_sensors = [assigned_sensors, assignments{target_idx}(:)']; %#ok<AGROW>
end
end

function active_trackers = flattenStage4ActiveTrackers(snapshot)
active_trackers = [];
if isfield(snapshot, 'active_trackers_at_assignment')
    for target_idx = 1:numel(snapshot.active_trackers_at_assignment)
        active_trackers = [active_trackers, snapshot.active_trackers_at_assignment{target_idx}(:)']; %#ok<AGROW>
    end
else
    active_trackers = [snapshot.active_trackers_target_1, snapshot.active_trackers_target_2];
end
active_trackers = unique(active_trackers, 'stable');
end

function value = ternary(condition, true_value, false_value)
if condition
    value = true_value;
else
    value = false_value;
end
end
