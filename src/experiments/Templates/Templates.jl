# Handle exports
export ProfileAnalysis_Templates

# Declare a handful of constants that we will use throughout these experiments and analyses
const n_cf = 91                # number of CFs to simulate (#)
const n_rep = 200              # number of trials to simulate (#)
const fs = 100e3               # sampling rate (Hz)
const cf_range = [1/2.0, 2.0]  # range around center frequency (ratio)
const fractional = true        # include fractional Gaussian noise (bool)

# Declare experiment types
struct ProfileAnalysis_Templates <: Utilities.Experiment end

# Declare overall setup for RovingExperiments
function Utilities.setup(experiment::ProfileAnalysis_Templates)
    # Create empty vector to store Simulations 
    sims = []

    # Choose increments, frequencies, and component counts to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 13, 21, 29, 37]

    # Loop through and add simulations of interest
    sims = map(Iterators.product(center_freqs, n_comps)) do (center_freq, n_comp)
        # Create models
        models = getmodels(experiment, center_freq)

        # Map through, make stimuli and bundle with model in DeltaPattern
        map(models) do model
            setup(experiment, model, center_freq, n_comp)
        end
    end

    # Return
    vcat(sims...)
end

# Declare setup function to return specific simulation for combination of model, center_freq, and n_comp
function Utilities.setup(::ProfileAnalysis_Templates, model::Model, center_freq::Float64, n_comp::Int64)
    # Make stimuli
    stim = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf, fs=fs), 
        n_rep; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(60.0, 80.0)
    )

    # Bundle with stimuli with model in ExcitationPatternDetailed
    AvgPattern(; stimuli=stim, model=model)
end

# Declare setup function to get all available models given center frequency
function getmodels(
    ::ProfileAnalysis_Templates, 
    center_freq,
)
    # Prep frontend for IC models
    frontend = AuditoryNerveZBC2014(;
        cf=LogRange((center_freq .* cf_range)..., n_cf),
        fractional=fractional,
        fiber_type="high",
        fs=fs,
    )

    # Create all models
    [
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="high", fractional=fractional, fs=fs), 
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="low", fractional=fractional, fs=fs), 
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...),
    ]
end
