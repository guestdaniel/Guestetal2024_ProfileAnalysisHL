% Get a list of subject names from the data folder
file_and_folder_names = dir('C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results');
subj_ids = [];
for idx_name=1:length(file_and_folder_names)
    name = file_and_folder_names(idx_name);
    if regexp(name.name, 'S\d{2,3}') == 1
        subj_ids = [subj_ids str2double(name.name(2:end))];
    end
end
subj_ids = subj_ids(subj_ids ~= 0);

% Loop thorugh and compile
freqs = [500.0, 1000.0, 2000.0, 4000.0];
for idx_freq=1:length(freqs)
    for idx_subj=1:length(subj_ids)
        disp(['Running subj ' num2str(subj_ids(idx_subj))]);
        extract_profile_analysis_data_to_excel(subj_ids(idx_subj), freqs(idx_freq), false);
        extract_profile_analysis_data_to_excel(subj_ids(idx_subj), freqs(idx_freq), true);
    end
end
clear;