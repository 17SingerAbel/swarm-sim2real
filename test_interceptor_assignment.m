function tests = test_interceptor_assignment
tests = functiontests(localfunctions);
end

function testSingleTargetMCMFPicksLowestTwo(testCase)
calling_targets = 1;
candidates = [11; 12; 13];
cost_matrix = [0.8; 0.2; 0.4];

[assignments, diagnostics] = solveInterceptorAssignmentMCMF(calling_targets, candidates, cost_matrix, 2);

verifyEqual(testCase, sort(assignments{1}(:))', [12 13]);
verifyEqual(testCase, diagnostics.assigned_slots_total, 2);
verifyEqual(testCase, diagnostics.total_cost, 0.6, 'AbsTol', 1e-10);
end

function testTwoTargetMCMFAvoidsCandidateConflicts(testCase)
calling_targets = [1; 2];
candidates = [1; 2; 3; 4];
cost_matrix = [1.0, 1.1; ...
               1.2, 1.0; ...
               3.0, 0.2; ...
               0.1, 3.0];

[assignments, diagnostics] = solveInterceptorAssignmentMCMF(calling_targets, candidates, cost_matrix, 2);

verifyEqual(testCase, sort(assignments{1}(:))', [1 4]);
verifyEqual(testCase, sort(assignments{2}(:))', [2 3]);
verifyEqual(testCase, diagnostics.assigned_slots_total, 4);
verifyEqual(testCase, diagnostics.total_cost, 2.3, 'AbsTol', 1e-10);
end

function testMCMFHandlesShortageWithPartialAssignment(testCase)
calling_targets = [1; 2];
candidates = [5; 6; 7];
cost_matrix = [0.1, 1.0; ...
               0.2, 0.9; ...
               0.3, 0.8];

[assignments, diagnostics] = solveInterceptorAssignmentMCMF(calling_targets, candidates, cost_matrix, 2);

verifyEqual(testCase, diagnostics.assigned_slots_total, 3);
verifyEqual(testCase, sort(assignments{1}(:))', [5 6]);
verifyEqual(testCase, assignments{2}, 7);
verifyEqual(testCase, diagnostics.total_cost, 1.1, 'AbsTol', 1e-10);
end

function testLegacySingleTargetRemainsAvailable(testCase)
calling_targets = 3;
candidates = [8; 9; 10];
cost_matrix = [0.6; 0.2; 0.4];

[assignments, diagnostics] = solveInterceptorAssignments(calling_targets, candidates, cost_matrix, 2, false);

verifyEqual(testCase, sort(assignments{1}(:))', [9 10]);
verifyEqual(testCase, diagnostics.algorithm, 'LEGACY');
end
