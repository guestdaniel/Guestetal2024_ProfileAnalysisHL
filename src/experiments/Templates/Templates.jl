# Provide definitions and functionality for "ProfileAnalysis_Templates", an experiment
# subtype for generating high-resolution template responses at -Inf dB SRS

# Handle exports
export ProfileAnalysis_Templates

# Declare experiment types
struct ProfileAnalysis_Templates <: ProfileAnalysisExperiment end

# Declare overall setup for RovingExperiments, which returns a large sequence of 
# templates to be simulated with varying center frequencies and component densites for all
# four standard models (from setup(::ProfileAnalysisExperiment, center_freq))
function Utilities.setup(experiment::ProfileAnalysis_Templates)
    # Create empty vector to store Simulations 
    sims = []

    # Choose frequencies and component counts to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 9, 13, 17, 21, 25, 29, 33, 37]

    # Loop through and add simulations of interest to output
    sims = map(Iterators.product(center_freqs, n_comps)) do (center_freq, n_comp)
        # Get models we want to test
        models = Utilities.setup(experiment, center_freq)

        # Map through models and bundle with copy of stimuli into AvgPattern
        map(models) do model
            Utilities.setup(experiment, model, center_freq, n_comp)
        end
    end

    # Return
    vcat(sims...)
end

# Declare setup function to return AvgPattern for combination of model, center_freq, and n_comp
function Utilities.setup(::ProfileAnalysis_Templates, model::Model, center_freq::Float64, n_comp::Int64)
    # Make stimuli
    stim = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf, fs=fs), 
        n_rep_template; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(60.0, 80.0)
    )

    # Bundle with stimuli with model in ExcitationPatternDetailed
    AvgPattern(; stimuli=stim, model=model)
end