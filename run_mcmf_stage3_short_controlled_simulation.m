function result = run_mcmf_stage3_short_controlled_simulation(use_mcmf)
%RUN_MCMF_STAGE3_SHORT_CONTROLLED_SIMULATION Run the Stage 3 MCMF integration check.
%   This runner enables the default-off Stage 3 injection path in
%   example_v46_stage3_Yeqi, runs a short real simulation slice, and validates
%   that the injected simultaneous selection was consumed by the real V46 loop.
%   RUN_MCMF_STAGE3_SHORT_CONTROLLED_SIMULATION(false) runs the same injected
%   scenario with the legacy assignment path as the real simulation algorithm.

if nargin < 1
    use_mcmf = true;
end

setenv('ENABLE_MCMF_STAGE3_TEST', '1');
setenv('MCMF_STAGE3_SIMULATION_TIME', '8');
setenv('MCMF_STAGE3_INJECTION_TIME', '5');
setenv('MCMF_STAGE3_USE_MCMF', string(double(use_mcmf)));

try
    example_v46_stage3_Yeqi;
    setenv('ENABLE_MCMF_STAGE3_TEST', '');
    setenv('MCMF_STAGE3_SIMULATION_TIME', '');
    setenv('MCMF_STAGE3_INJECTION_TIME', '');
    setenv('MCMF_STAGE3_USE_MCMF', '');
catch ME
    setenv('ENABLE_MCMF_STAGE3_TEST', '');
    setenv('MCMF_STAGE3_SIMULATION_TIME', '');
    setenv('MCMF_STAGE3_INJECTION_TIME', '');
    setenv('MCMF_STAGE3_USE_MCMF', '');
    rethrow(ME);
end

assert(exist('assignment_events', 'var') == 1, 'Stage3:MissingAssignmentEvents', ...
    'assignment_events was not created.');
assert(~isempty(assignment_events), 'Stage3:NoAssignmentEvents', ...
    'No assignment_events were created.');
assert(exist('stage3_injection_info', 'var') == 1 && stage3_injection_info.injected, ...
    'Stage3:InjectionMissing', 'The Stage 3 injection did not run.');
assert(exist('stage3_assignment_snapshot', 'var') == 1 && ~isempty(stage3_assignment_snapshot), ...
    'Stage3:SnapshotMissing', 'No Stage 3 assignment snapshot was captured.');

event = assignment_events(stage3_assignment_snapshot.event_index);
assert(ismember(event.algorithm, {'MCMF', 'LEGACY'}), 'Stage3:WrongAlgorithm', ...
    'Expected MCMF or LEGACY assignment, got %s.', event.algorithm);
assert(all(ismember([1, 2], event.calling_targets)), 'Stage3:WrongCallingTargets', ...
    'The MCMF event did not include both target 1 and target 2.');

assigned_sensors = [];
for target_idx = 1:numel(event.assignments)
    assigned_sensors = [assigned_sensors, event.assignments{target_idx}(:)']; %#ok<AGROW>
end
assert(~isempty(assigned_sensors), 'Stage3:NoAssignedSensors', ...
    'MCMF did not assign any sensors in the Stage 3 event.');
assert(numel(unique(assigned_sensors)) == numel(assigned_sensors), 'Stage3:DuplicateSensors', ...
    'A sensor was assigned more than once.');

forced_active_trackers = [stage3_assignment_snapshot.active_trackers_target_1, ...
    stage3_assignment_snapshot.active_trackers_target_2];
assert(isempty(intersect(assigned_sensors, forced_active_trackers)), 'Stage3:SelectedActiveTracker', ...
    'MCMF selected a sensor that was an active tracker at injection time.');

assert(all(strcmp(stage3_assignment_snapshot.sensor_states, SENSOR_STATES.INTERCEPTING)), ...
    'Stage3:SelectedSensorsNotIntercepting', ...
    'At least one selected sensor did not enter INTERCEPTING in the assignment snapshot.');
assert(all(strcmp(stage3_assignment_snapshot.sensor_roles, SENSOR_ROLES.INTERCEPTOR_CANDIDATE)), ...
    'Stage3:SelectedSensorsWrongRole', ...
    'At least one selected sensor did not receive INTERCEPTOR_CANDIDATE role.');
assert(all(cellfun(@(target) ~isempty(target), stage3_assignment_snapshot.proactive_targets)), ...
    'Stage3:MissingProactiveTargets', ...
    'At least one selected sensor did not receive a proactive target.');
assert(current_time >= stage3_assignment_snapshot.time + 1.0, 'Stage3:DidNotContinue', ...
    'Simulation did not continue for at least 1.0 s after the Stage 3 assignment.');

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
assert(any_selected_sensor_moved, 'Stage3:NoMovementObserved', ...
    'No selected sensor showed movement after Stage 3 assignment.');

assert(exist(mat_filename, 'file') == 2, 'Stage3:MissingMatOutput', ...
    'MAT output was not found: %s', mat_filename);

[mcmf_assignments, mcmf_info] = solveInterceptorAssignments( ...
    event.calling_targets(:), event.candidate_sensors(:), event.cost_matrix, ...
    event.requested_slots_per_target, true);
[legacy_assignments, legacy_info] = solveInterceptorAssignments( ...
    event.calling_targets(:), event.candidate_sensors(:), event.cost_matrix, ...
    event.requested_slots_per_target, false);

mcmf_assigned_sensors = flattenStage3Assignments(mcmf_assignments);
legacy_assigned_sensors = flattenStage3Assignments(legacy_assignments);
mcmf_total_cost = mcmf_info.total_cost;
legacy_total_cost = legacy_info.total_cost;
mcmf_cost_improvement = legacy_total_cost - mcmf_total_cost;

result = struct( ...
    'passed', true, ...
    'mat_filename', mat_filename, ...
    'log_filename', log_filename, ...
    'actual_algorithm', event.algorithm, ...
    'actual_assignments', {event.assignments}, ...
    'actual_assigned_sensors', assigned_sensors, ...
    'actual_total_cost', event.total_cost, ...
    'assignment_time', stage3_assignment_snapshot.time, ...
    'calling_targets', event.calling_targets, ...
    'assigned_sensors', assigned_sensors, ...
    'total_cost', event.total_cost, ...
    'mcmf_assignments', {mcmf_assignments}, ...
    'mcmf_assigned_sensors', mcmf_assigned_sensors, ...
    'mcmf_total_cost', mcmf_total_cost, ...
    'legacy_assignments', {legacy_assignments}, ...
    'legacy_assigned_sensors', legacy_assigned_sensors, ...
    'legacy_total_cost', legacy_total_cost, ...
    'mcmf_cost_improvement', mcmf_cost_improvement, ...
    'candidate_sensors', event.candidate_sensors, ...
    'cost_matrix', event.cost_matrix);

fprintf('Stage 3 MCMF short controlled simulation passed.\n');
fprintf('  MAT output: %s\n', mat_filename);
fprintf('  Log output: %s\n', log_filename);
fprintf('  Assignment time: %.2f s\n', result.assignment_time);
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

function assigned_sensors = flattenStage3Assignments(assignments)
assigned_sensors = [];
for target_idx = 1:numel(assignments)
    assigned_sensors = [assigned_sensors, assignments{target_idx}(:)']; %#ok<AGROW>
end
end
