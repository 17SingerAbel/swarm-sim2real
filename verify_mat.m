%% verify_mat.m
% Compare a fresh simulation .mat output against the reference baseline.
%
% Usage:
%   Run example_V45_V38_b to generate a new logs/wsn_data_<timestamp>.mat,
%   then run this script:
%       verify_mat
%
% Exit codes (via assertion):
%   All variables PASS  → script completes normally
%   Any variable FAILS  → script prints FAIL lines and throws an error

REF_FILE = fullfile('logs', 'wsn_data_standard.mat');
TOLS.norm = 1e-10;   % tolerance for numeric arrays

%% 1. Load reference
if ~isfile(REF_FILE)
    error('verify_mat: reference file not found: %s', REF_FILE);
end
ref = load(REF_FILE);
fprintf('Reference : %s\n', REF_FILE);

%% 2. Find the most-recently-created wsn_data_*.mat (excluding the standard)
listing = dir(fullfile('logs', 'wsn_data_*.mat'));
% Remove the standard file from the list
listing = listing(~strcmp({listing.name}, 'wsn_data_standard.mat'));

if isempty(listing)
    error('verify_mat: no new wsn_data_*.mat found in logs/');
end
[~, newest_idx] = max([listing.datenum]);
new_file = fullfile('logs', listing(newest_idx).name);
fprintf('New run   : %s\n\n', new_file);
new = load(new_file);

%% 3. Variables to compare
vars_to_check = { ...
    'params', ...
    'node_positions_history', ...
    'target_trajectories', ...
    'sensor_trajectories', ...
    'sensor_P_trace_history', ...
    'system_state_history', ...
    'sensor_state_history', ...
    'sensor_trajectory_history', ...
    'original_positions', ...
    'total_successful_intercepts', ...
    'interceptor_call_counter' ...
};

%% 4. Compare each variable
all_passed = true;
for k = 1:numel(vars_to_check)
    vname = vars_to_check{k};

    % Check presence
    if ~isfield(ref, vname)
        fprintf('SKIP  %-35s  (not in reference)\n', vname);
        continue;
    end
    if ~isfield(new, vname)
        fprintf('FAIL  %-35s  (missing from new file)\n', vname);
        all_passed = false;
        continue;
    end

    r = ref.(vname);
    n = new.(vname);

    passed = compare_values(r, n, TOLS);
    if passed
        fprintf('PASS  %s\n', vname);
    else
        fprintf('FAIL  %s\n', vname);
        all_passed = false;
    end
end

%% 5. Summary
fprintf('\n');
if all_passed
    fprintf('=== OVERALL: PASS ===\n');
else
    fprintf('=== OVERALL: FAIL — see FAIL lines above ===\n');
    error('verify_mat: one or more variables differ from reference');
end

% -------------------------------------------------------------------------
function ok = compare_values(r, n, tols)
% Recursively compare two values; return true if they match within tolerance.
    ok = false;
    if isnumeric(r) && isnumeric(n)
        if ~isequal(size(r), size(n))
            return;
        end
        if isempty(r) && isempty(n)
            ok = true;
        elseif isempty(r) || isempty(n)
            ok = false;
        else
            ok = norm(double(r(:)) - double(n(:))) < tols.norm;
        end
    elseif iscell(r) && iscell(n)
        if ~isequal(size(r), size(n))
            return;
        end
        ok = true;
        for i = 1:numel(r)
            if ~compare_values(r{i}, n{i}, tols)
                ok = false;
                return;
            end
        end
    elseif isstruct(r) && isstruct(n)
        fields_r = fieldnames(r);
        fields_n = fieldnames(n);
        if ~isequal(sort(fields_r), sort(fields_n))
            return;
        end
        ok = true;
        for i = 1:numel(fields_r)
            fn = fields_r{i};
            if ~compare_values(r.(fn), n.(fn), tols)
                ok = false;
                return;
            end
        end
    elseif ischar(r) && ischar(n)
        ok = strcmp(r, n);
    elseif islogical(r) && islogical(n)
        ok = isequal(size(r), size(n)) && all(r(:) == n(:));
    elseif isequal(class(r), class(n))
        ok = isequal(r, n);
    end
end
