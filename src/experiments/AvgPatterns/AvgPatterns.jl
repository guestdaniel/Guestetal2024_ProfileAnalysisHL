# Provide definitions and functionality for "ProfileAnalysis_AvgPatterns", an experiment
# subtype for generating high-resolution responses at varied increments sizes

# Handle exports
export ProfileAnalysis_AvgPatterns

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
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=increment, fs=fs), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_range, 70.0 + rove_range),
    )

    # Bundle with stimuli with AvgPattern
    AvgPattern(; stimuli=stim, model=model)
end