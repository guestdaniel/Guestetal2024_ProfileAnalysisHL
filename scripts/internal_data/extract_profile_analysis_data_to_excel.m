function extract_profile_analysis_data_to_excel(subject_id,freq,is_roved)
% PA_iso_multiseq2: Analysis program for profile_analysis_iso data.

% set default value 
if nargin < 3 || isempty(is_roved)
	is_roved = false;
end

% Get file names.
if strcmpi(getenv('COMPUTERNAME'),'nsc-lcarney-h1')
	base = 'C:\results\profile_analysis_iso_results';
else
	base = '\\nsc-lcarney-h1\c$\results\profile_analysis_iso_results';
end
if is_roved
	folder = fullfile(base,sprintf('S%03d',subject_id),'rove');
else
	folder = fullfile(base,sprintf('S%03d',subject_id));
end
d = dir(fullfile(folder,sprintf('S%03d_F%g_*.mat',subject_id,freq)));
if isempty(d) == 1
    disp(['Empty ! ']);
    return;
end
filenames = fullfile(folder,{d.name});

% Load data.
params = cellfun(@load,filenames);

% Select roved or not roved files, as desired.
rove_ranges = [params.RoveRange];
if is_roved
	use = rove_ranges ~= 0;
else
	use = rove_ranges == 0;
end
params = params(use);

% Add ToDo field of all false (no runs left) if it is missing (old file).
for i = 1:length(params)
	if ~isfield(params(i).RunData,'ToDo')
		[params(i).RunData.ToDo] = deal(false);
	end
end

num_files = length(params);
if num_files == 0
	error('No files to analyze.')
end

num_files = length(params);
for fi = 1:num_files
    % Make spreadsheet name.
    xls_name = fullfile(folder,sprintf('S%d_F%g_%.0fdB_%.0f.xlsx',subject_id,freq,params(1).SignalSPL, fi));

	run_data = params(fi).RunData;

	% Gather params.RunData for blocks only (where RunData.RunStyle = 2).
	% run_data = [params.RunData];
	run_style = [run_data.RunStyle];
	is_block = run_style >= 2;
	run_data = run_data(is_block);

	if isempty(run_data)
		continue
	end

	% Get earliest sequence time.
	created_time = params(fi).CreatedTime;

	% Get N for each block.
	N = [run_data.NumComponents];
	N = N(1,:);

	% Get increment for each block.
	incr = [run_data.StartLevel];

	% Get number of trials for each block.
	num_trials = arrayfun(@(x)length(x.Run.Correct(x.Run.NumTraining+1:end)),run_data);

	% Make three column vectors containing, for each trial, N (all_N), the increment
	% (all_incr), and whether it was correct (all_corr).
	N_c = arrayfun(@(N,nt){N*ones(nt,1)},N,num_trials);
	all_N = vertcat(N_c{:});
	incr_c = arrayfun(@(N,nt){N*ones(nt,1)},incr,num_trials);
	all_incr = vertcat(incr_c{:});
	corr_c = arrayfun(@(x){x.Run.Correct(x.Run.NumTraining+1:end)},run_data);
	all_corr = vertcat(corr_c{:});


	% Sort the the vectors into matrices containing the number of trials and the
	% number correct for each condition (combination of N and increment).
	[Nu,~,Ni] = unique(all_N);
	[iu,~,ii] = unique(all_incr);
	num_N = length(Nu);
	num_incr = length(iu);

	num = accumarray([ii,Ni],1);
	num_corr = accumarray([ii,Ni],all_corr);

	% The fraction correct for each combination is given by either of these two
	% expressions.
% 	fc = num_corr./num;
	fc = accumarray([ii,Ni],all_corr,[],@mean,NaN);
	% and the standard deviation can be computed with
% 	fcsd2 = accumarray([ii,Ni],all_corr,[],@std,NaN);

	% Build sheet contents.
	sheet_name = sprintf('Seq. %s',datestr(created_time,'yyyy-mm-dd HH.MM'));
	sheet = cell(size(fc) + 1);
	sheet(2:end,2:end) = num2cell(fc);
	sheet(2:end,1) = num2cell(iu(:));
	sheet(1,2:end) = num2cell(Nu(:).');
    display(['Saving ' fullfile('C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results\', xls_name(58:end))]);
	writecell(sheet,fullfile('C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results\', xls_name(58:end)),'Sheet',sheet_name)
end