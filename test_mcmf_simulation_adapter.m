function tests = test_mcmf_simulation_adapter
tests = functiontests(localfunctions);
end

function testBuildCostMatrixExcludesActiveTrackers(testCase)
fixture = makeAdapterFixture(8, {[1; 2], [3; 4]});

[candidates, cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
    fixture.calling_targets, fixture.num_nodes, fixture.num_targets, fixture.active_trackers, ...
    fixture.node_positions, fixture.original_positions, fixture.interceptor_process_data, ...
    fixture.sensor_ekf_states, fixture.sensor_detection_times, fixture.current_time, ...
    fixture.communication_range, fixture.wsn_width, fixture.wsn_height);

verifyEqual(testCase, candidates(:)', [5 6 7 8]);
verifySize(testCase, cost_matrix, [4 2]);
verifyTrue(testCase, all(isfinite(cost_matrix), 'all'));
end

function testTwoTargetsPendingSelectionBatchAssignment(testCase)
fixture = makeTwoTargetFullAllocationFixture();

[candidates, cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
    fixture.calling_targets, fixture.num_nodes, fixture.num_targets, fixture.active_trackers, ...
    fixture.node_positions, fixture.original_positions, fixture.interceptor_process_data, ...
    fixture.sensor_ekf_states, fixture.sensor_detection_times, fixture.current_time, ...
    fixture.communication_range, fixture.wsn_width, fixture.wsn_height);

[assignments, diagnostics] = solveInterceptorAssignments(fixture.calling_targets, candidates, cost_matrix, 2, true);
assigned_sensors = [assignments{:}];

verifyEqual(testCase, diagnostics.assigned_slots_total, 4);
verifyEqual(testCase, numel(unique(assigned_sensors)), numel(assigned_sensors));
verifyTrue(testCase, all(ismember(assigned_sensors, candidates)));
verifyEqual(testCase, diagnostics.algorithm, 'MCMF');
verifyEqual(testCase, sort(assignments{1}), [6 10]);
verifyEqual(testCase, sort(assignments{2}), [8 9]);
verifyEqual(testCase, sort(setdiff(candidates, assigned_sensors))', [5 7]);
end

function testShortageCaseStillProducesPartialAssignment(testCase)
fixture = makeAdapterFixture(5, {[1; 2], 3});

[candidates, cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
    fixture.calling_targets, fixture.num_nodes, fixture.num_targets, fixture.active_trackers, ...
    fixture.node_positions, fixture.original_positions, fixture.interceptor_process_data, ...
    fixture.sensor_ekf_states, fixture.sensor_detection_times, fixture.current_time, ...
    fixture.communication_range, fixture.wsn_width, fixture.wsn_height);

[assignments, diagnostics] = solveInterceptorAssignments(fixture.calling_targets, candidates, cost_matrix, 2, true);
assigned_sensors = [assignments{:}];

verifyEqual(testCase, candidates(:)', [4 5]);
verifyEqual(testCase, diagnostics.assigned_slots_total, 2);
verifyEqual(testCase, numel(unique(assigned_sensors)), numel(assigned_sensors));
verifyTrue(testCase, all(ismember(assigned_sensors, candidates)));
end

function testLegacyAndMCMFUseSameAdapterInputs(testCase)
fixture = makeLegacyComparisonFixture();

[candidates, cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
    fixture.calling_targets, fixture.num_nodes, fixture.num_targets, fixture.active_trackers, ...
    fixture.node_positions, fixture.original_positions, fixture.interceptor_process_data, ...
    fixture.sensor_ekf_states, fixture.sensor_detection_times, fixture.current_time, ...
    fixture.communication_range, fixture.wsn_width, fixture.wsn_height);

[legacy_assignments, legacy_diagnostics] = solveInterceptorAssignments(fixture.calling_targets, candidates, cost_matrix, 2, false);
[mcmf_assignments, mcmf_diagnostics] = solveInterceptorAssignments(fixture.calling_targets, candidates, cost_matrix, 2, true);

verifyEqual(testCase, legacy_diagnostics.algorithm, 'LEGACY');
verifyEqual(testCase, mcmf_diagnostics.algorithm, 'MCMF');
verifyEqual(testCase, legacy_diagnostics.assigned_slots_total, 4);
verifyEqual(testCase, mcmf_diagnostics.assigned_slots_total, 4);
verifyEqual(testCase, numel(unique([legacy_assignments{:}])), 4);
verifyEqual(testCase, numel(unique([mcmf_assignments{:}])), 4);
verifyLessThan(testCase, mcmf_diagnostics.total_cost, legacy_diagnostics.total_cost);
verifyEqual(testCase, sort(mcmf_assignments{1}), [5 8]);
verifyEqual(testCase, sort(mcmf_assignments{2}), [6 7]);
end

function testThreeTargetsWithCandidateShortageUsesAllAvailableSensors(testCase)
fixture = makeThreeTargetAdapterFixture();

[candidates, cost_matrix] = buildAssignmentCostMatrixForCallingTargets( ...
    fixture.calling_targets, fixture.num_nodes, fixture.num_targets, fixture.active_trackers, ...
    fixture.node_positions, fixture.original_positions, fixture.interceptor_process_data, ...
    fixture.sensor_ekf_states, fixture.sensor_detection_times, fixture.current_time, ...
    fixture.communication_range, fixture.wsn_width, fixture.wsn_height);

[assignments, diagnostics] = solveInterceptorAssignments(fixture.calling_targets, candidates, cost_matrix, 2, true);
assigned_sensors = [assignments{:}];

verifyEqual(testCase, candidates(:)', [7 8 9 10 11]);
verifySize(testCase, cost_matrix, [5 3]);
verifyEqual(testCase, diagnostics.requested_slots_total, 6);
verifyEqual(testCase, diagnostics.assigned_slots_total, 5);
verifyEqual(testCase, sort(assigned_sensors), candidates(:)');
verifyEqual(testCase, numel(unique(assigned_sensors)), numel(assigned_sensors));
verifyEqual(testCase, diagnostics.algorithm, 'MCMF');
end

function fixture = makeAdapterFixture(num_nodes, active_trackers)
num_targets = 2;
calling_targets = [1; 2];

node_positions = zeros(num_nodes, 2);
for sensor_id = 1:num_nodes
    node_positions(sensor_id, :) = [sensor_id * 2, mod(sensor_id, 3) * 1.5];
end
original_positions = node_positions;

interceptor_process_data = cell(num_targets, 1);
interceptor_process_data{1} = struct( ...
    'intercept_point', [14, 2], ...
    'predictor_id', 1, ...
    'target_position', [10, 1]);
interceptor_process_data{2} = struct( ...
    'intercept_point', [4, 3], ...
    'predictor_id', 3, ...
    'target_position', [8, 2]);

sensor_ekf_states = cell(num_nodes, num_targets);
sensor_detection_times = zeros(num_nodes, num_targets);

sensor_ekf_states{1, 1} = [10; 1; 1.0; 0.1];
sensor_ekf_states{2, 1} = [10.2; 1.1; 1.0; 0.1];
sensor_ekf_states{3, 2} = [8; 2; -0.8; 0.2];
sensor_ekf_states{4, 2} = [8.1; 2.2; -0.8; 0.2];
sensor_detection_times(1, 1) = 1;
sensor_detection_times(2, 1) = 1;
sensor_detection_times(3, 2) = 1;
sensor_detection_times(4, 2) = 1;

fixture = struct();
fixture.num_nodes = num_nodes;
fixture.num_targets = num_targets;
fixture.calling_targets = calling_targets;
fixture.active_trackers = active_trackers(:);
fixture.node_positions = node_positions;
fixture.original_positions = original_positions;
fixture.interceptor_process_data = interceptor_process_data;
fixture.sensor_ekf_states = sensor_ekf_states;
fixture.sensor_detection_times = sensor_detection_times;
fixture.current_time = 2;
fixture.communication_range = 100;
fixture.wsn_width = 20;
fixture.wsn_height = 20;
end

function fixture = makeThreeTargetAdapterFixture()
num_nodes = 11;
num_targets = 3;
calling_targets = [1; 2; 3];
active_trackers = {[1; 2], [3; 4], [5; 6]};

node_positions = zeros(num_nodes, 2);
for sensor_id = 1:num_nodes
    node_positions(sensor_id, :) = [sensor_id * 1.5, mod(sensor_id, 4) * 2.0];
end
original_positions = node_positions;

interceptor_process_data = cell(num_targets, 1);
interceptor_process_data{1} = struct( ...
    'intercept_point', [13, 2], ...
    'predictor_id', 1, ...
    'target_position', [9, 1]);
interceptor_process_data{2} = struct( ...
    'intercept_point', [6, 6], ...
    'predictor_id', 3, ...
    'target_position', [7, 4]);
interceptor_process_data{3} = struct( ...
    'intercept_point', [17, 4], ...
    'predictor_id', 5, ...
    'target_position', [14, 3]);

sensor_ekf_states = cell(num_nodes, num_targets);
sensor_detection_times = zeros(num_nodes, num_targets);
sensor_ekf_states{1, 1} = [9; 1; 1.0; 0.1];
sensor_ekf_states{2, 1} = [9.1; 1.1; 1.0; 0.1];
sensor_ekf_states{3, 2} = [7; 4; -0.4; 0.7];
sensor_ekf_states{4, 2} = [7.2; 4.1; -0.4; 0.7];
sensor_ekf_states{5, 3} = [14; 3; 0.6; -0.2];
sensor_ekf_states{6, 3} = [14.1; 3.2; 0.6; -0.2];
sensor_detection_times(1, 1) = 1;
sensor_detection_times(2, 1) = 1;
sensor_detection_times(3, 2) = 1;
sensor_detection_times(4, 2) = 1;
sensor_detection_times(5, 3) = 1;
sensor_detection_times(6, 3) = 1;

fixture = struct();
fixture.num_nodes = num_nodes;
fixture.num_targets = num_targets;
fixture.calling_targets = calling_targets;
fixture.active_trackers = active_trackers(:);
fixture.node_positions = node_positions;
fixture.original_positions = original_positions;
fixture.interceptor_process_data = interceptor_process_data;
fixture.sensor_ekf_states = sensor_ekf_states;
fixture.sensor_detection_times = sensor_detection_times;
fixture.current_time = 2;
fixture.communication_range = 100;
fixture.wsn_width = 25;
fixture.wsn_height = 25;
end

function fixture = makeTwoTargetFullAllocationFixture()
num_nodes = 10;
num_targets = 2;
calling_targets = [1; 2];
active_trackers = {[1; 2], [3; 4]};

node_positions = [ ...
    11.2740, 22.9642; ...
     9.3445,  6.3961; ...
    17.6392,  6.3685; ...
    19.3328,  3.2231; ...
    24.1020,  0.6448; ...
    10.8868, 14.6887; ...
     6.1890, 16.1146; ...
    14.1936, 11.9214; ...
    17.4042, 13.0193; ...
    10.9171, 12.3817];
original_positions = node_positions;

interceptor_process_data = cell(num_targets, 1);
interceptor_process_data{1} = struct( ...
    'intercept_point', [11.5792, 13.0016], ...
    'predictor_id', 1, ...
    'target_position', [5.6832, 1.5778]);
interceptor_process_data{2} = struct( ...
    'intercept_point', [16.7848, 11.9030], ...
    'predictor_id', 3, ...
    'target_position', [20.6325, 0.3778]);

sensor_ekf_states = cell(num_nodes, num_targets);
sensor_detection_times = zeros(num_nodes, num_targets);
sensor_ekf_states{1, 1} = [5.6832; 1.5778; -1.5468; 1.5375];
sensor_ekf_states{2, 1} = [5.7832; 1.6778; -0.1049; -0.8021];
sensor_ekf_states{3, 2} = [20.6325; 0.3778; 1.5935; 0.3287];
sensor_ekf_states{4, 2} = [20.7325; 0.4778; 0.6111; -0.2913];
sensor_detection_times(1, 1) = 1;
sensor_detection_times(2, 1) = 1;
sensor_detection_times(3, 2) = 1;
sensor_detection_times(4, 2) = 1;

fixture = struct();
fixture.num_nodes = num_nodes;
fixture.num_targets = num_targets;
fixture.calling_targets = calling_targets;
fixture.active_trackers = active_trackers(:);
fixture.node_positions = node_positions;
fixture.original_positions = original_positions;
fixture.interceptor_process_data = interceptor_process_data;
fixture.sensor_ekf_states = sensor_ekf_states;
fixture.sensor_detection_times = sensor_detection_times;
fixture.current_time = 2;
fixture.communication_range = 100;
fixture.wsn_width = 25;
fixture.wsn_height = 25;
end

function fixture = makeLegacyComparisonFixture()
num_nodes = 8;
num_targets = 2;
calling_targets = [1; 2];
active_trackers = {[1; 2], [3; 4]};

node_positions = [ ...
    13.5454, 16.6547; ...
     8.6921, 13.1140; ...
     8.2999, 12.3248; ...
    19.6423, 17.7241; ...
     4.4176,  4.4299; ...
     9.8287, 13.6080; ...
     1.4455, 11.5032; ...
    14.4616, 12.7406];
original_positions = node_positions;

interceptor_process_data = cell(num_targets, 1);
interceptor_process_data{1} = struct( ...
    'intercept_point', [17.8437, 0.0254], ...
    'predictor_id', 1, ...
    'target_position', [6.7645, 2.8537]);
interceptor_process_data{2} = struct( ...
    'intercept_point', [10.8040, 13.3937], ...
    'predictor_id', 3, ...
    'target_position', [14.2187, 3.9583]);

sensor_ekf_states = cell(num_nodes, num_targets);
sensor_detection_times = zeros(num_nodes, num_targets);
sensor_ekf_states{1, 1} = [6.7645; 2.8537; -1.3481; -0.8640];
sensor_ekf_states{2, 1} = [6.8645; 2.9537; 1.6005; -0.2549];
sensor_ekf_states{3, 2} = [14.2187; 3.9583; -0.1113; -0.6244];
sensor_ekf_states{4, 2} = [14.3187; 4.0583; 1.0658; -1.2728];
sensor_detection_times(1, 1) = 1;
sensor_detection_times(2, 1) = 1;
sensor_detection_times(3, 2) = 1;
sensor_detection_times(4, 2) = 1;

fixture = struct();
fixture.num_nodes = num_nodes;
fixture.num_targets = num_targets;
fixture.calling_targets = calling_targets;
fixture.active_trackers = active_trackers(:);
fixture.node_positions = node_positions;
fixture.original_positions = original_positions;
fixture.interceptor_process_data = interceptor_process_data;
fixture.sensor_ekf_states = sensor_ekf_states;
fixture.sensor_detection_times = sensor_detection_times;
fixture.current_time = 2;
fixture.communication_range = 100;
fixture.wsn_width = 20;
fixture.wsn_height = 20;
end
