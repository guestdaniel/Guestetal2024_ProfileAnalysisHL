# Provide definitions and functionality for "ProfileAnalysis_Templates", an experiment
# subtype for generating high-resolution template responses at -Inf dB SRS

# Handle exports
export ProfileAnalysis_Templates

# Declare experiment types
struct ProfileAnalysis_Templates <: ProfileAnalysisExperiment end

# Declare overall setup for RovingExperiments, which returns a large sequence of 
# templates to be simulated with varying center frequencies and component densites for all
# four standard models (from setup(::ProfileAnalysisExperiment, center_freq))
function setup(experiment::ProfileAnalysis_Templates)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 9, 13, 17, 21, 25, 29, 33, 37]
    rove_sizes = [0.001, 10.0]

    # Loop through and add simulations of interest to output
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get models we want to test
        models = setup(experiment, center_freq)

        # Map through models and bundle with copy of stimuli into AvgPattern
        map(models) do model
            setup(experiment, model, center_freq, n_comp, rove_size)
        end
    end

    # Return
    vcat(sims...)
end

# Declare setup function to return AvgPattern for combination of model, center_freq, and n_comp
function setup(
    ::ProfileAnalysis_Templates, 
    model::Model, 
    center_freq::Float64, 
    n_comp::Int64,
    rove_size::Float64=0.001;
    n_rep_template=n_rep_template,
)
    # Make stimuli
    stim = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=-Inf, fs=fs), 
        n_rep_template; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size),
    )

    # Bundle with stimuli with model in ExcitationPatternDetailed
    AvgPattern(; stimuli=stim, model=model)
end