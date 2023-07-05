# Provide definitions and functionality for "ProfileAnalysis_AvgPatterns", an experiment
# subtype for generating high-resolution responses at varied increments sizes

# Handle exports
export ProfileAnalysis_AvgPatterns, setup_pair

# Declare experiment types
struct ProfileAnalysis_AvgPatterns <: ProfileAnalysisExperiment end

# Declare setup function to return AvgPattern for combination of model, increment, center_freq, and n_comp
function Utilities.setup(
    ::ProfileAnalysis_AvgPatterns, 
    model::Model, 
    increment::Float64, 
    center_freq::Float64, 
    n_comp::Int64;
    rove_range=10.0,
)
    # Make stimuli
    stim = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=increment, fs=fs), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_range, 70.0 + rove_range),
    )

    # Bundle with stimuli with AvgPattern
    AvgPattern(; stimuli=stim, model=model)
end

# Declare setup function to return AvgPattern for combination of model, increment, center_freq, and n_comp
function setup_pair(
    ::ProfileAnalysis_AvgPatterns, 
    model::Model, 
    increment::Float64, 
    center_freq::Float64, 
    n_comp::Int64;
    rove_size=10.0,
)
    # Make stimuli
    stim_ref = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=-Inf, fs=fs), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size),
    )
    stim_tar = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=increment), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size)
    )
    tag = "matched_to_$(id(stim_tar[1]))"

    # Bundle with stimuli with AvgPattern
    ref = AvgPattern(; stimuli=stim_ref, model=model, tag=tag)
    tar = AvgPattern(; stimuli=stim_tar, model=model)

    # Return
    return ref, tar
end