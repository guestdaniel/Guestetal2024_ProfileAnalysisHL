% This script loads in data in THRESHOLD_ALL_CAT, THRESHOLD_ALL_HM_Shera,
% and THRESHOLD_ALL_HM_GM, which maps between internal parameters in the
% Zilany, Bruce, and Carney auditory nerve model (cohc, outer hair cell
% count, [0, 1]; cihc, inner hair cell count, (0, 1]) and then upsamples
% the data substantially along all dimensions. These upsampled data are to
% be used by fitaudiogram3.m, which is an enhanced and updated version of
% fit audiogram2.m

% Load data
for species = 1:3
    switch species
        case 1
            file = load('THRESHOLD_ALL_CAT','CF','CIHC','COHC','THR');
        case 2
            file = load('THRESHOLD_ALL_HM_Shera','CF','CIHC','COHC','THR');
        case 3
            file = load('THRESHOLD_ALL_HM_GM','CF','CIHC','COHC','THR');
    end

    % Rename (and transform) variables
    cf = log10(file.CF);  % note that we log transform to interpolate along space correctly
    cihc = file.CIHC;
    cohc = file.COHC;
    threshold = file.THR;
    
    % Set parameters
    n_sample_pts = 200;  % Controls how many samples we want (uniform in all 3D)

    % Construct query axes
    cf_query = linspace(cf(1), cf(end), n_sample_pts);
    cihc_query = interp1(1:length(cihc), ...
        cihc, ...
        linspace(1.0, length(cihc), n_sample_pts) ...
    );
    cohc_query = interp1(1:length(cohc), ...
        cohc, linspace(1.0, length(cohc), ...
        n_sample_pts) ...
    );

    % Construct coordinate grids
    [X, Y, Z] = ndgrid(cf, cihc, cohc);
    [X_query, Y_query, Z_query] = ndgrid(cf_query, cihc_query, cohc_query);
    
    % Interpolate (linear without extrapolation)
    threshold_interp = interpn(X, Y, Z, threshold, X_query, Y_query, Z_query);

    % Rename (and transform) output variable names
    cf_out = 10 .^ cf_query;  % Note that we transform back to Hz for output
    cihc_out = cihc_query;
    cohc_out = cohc_query;
    threshold_out = threshold_interp;
    
    % Save to disk
    switch species
        case 1
            save('/home/daniel/cl_code/urear_2020b/thresholds_interpolated_cat.mat', 'cf_out', 'cihc_out', 'cohc_out', 'threshold_out')
        case 2
            save('/home/daniel/cl_code/urear_2020b/thresholds_interpolated_human_shera.mat', 'cf_out', 'cihc_out', 'cohc_out', 'threshold_out')
        case 3
            save('/home/daniel/cl_code/urear_2020b/thresholds_interpolated_human_glasberg_moore.mat', 'cf_out', 'cihc_out', 'cohc_out', 'threshold_out')
    end
end