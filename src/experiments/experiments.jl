# Here we provide a definitions for an abstract type "ProfileAnalysisExperiment", which is
# subtyped to implement different types of expeirments for the profile-analysis paper and
# other deliverables. 

# Handle exports
export ProfileAnalysisExperiment, setup_nohsr

# Declare experiment types
abstract type ProfileAnalysisExperiment <: Utilities.Experiment end

# Declare a handful of constants that we will use throughout these experiments and analyses
# These provide a basic set of rules of thumb to encourage cosistency across simulations
# and maximize simulation reuse
const n_cf = 91                # number of CFs to simulate (#)
const n_cf_reduced = 61                # number of CFs to simulate (#)
const n_rep_template = 500     # number of ref responses to simulate for template (#)
const n_rep_template_reduced = 250
const n_rep_trial = 150        # number of trials to simulate for each point on PF (#)
const n_rep_trial_reduced = 50
const fs = 100e3               # sampling rate (Hz)
const cf_range = [1/2.0, 2.0]  # range around center tone frequency (ratio)
const fractional = true        # include fractional Gaussian noise (bool)

# Declare setup function to get all available models given center frequency:
# - HSR auditory nerve 
# - LSR auditory nerve 
# - BE inferior colliculus 
# - BS inferior colliculus
function Utilities.setup(
    ::ProfileAnalysisExperiment, 
    center_freq::Float64,
    cf_range=cf_range,
    audiogram=Audiogram();
    n_cf=n_cf,
)
    # Prep frontend for IC models
    frontend = AuditoryNerveZBC2014(;
        cf=LogRange((center_freq .* cf_range)..., n_cf),
        fractional=fractional,
        fiber_type="high",
        fs=fs,
        audiogram=audiogram,
    )

    # Create all models
    [
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="high", fractional=fractional, audiogram=audiogram, fs=fs), 
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="low", fractional=fractional, audiogram=audiogram, fs=fs), 
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...),
    ]
end

function setup_nohsr(
    ::ProfileAnalysisExperiment, 
    center_freq::Float64,
    cf_range=cf_range,
    audiogram=Audiogram();
    n_cf=n_cf,
)
    # Prep frontend for IC models
    frontend = AuditoryNerveZBC2014(;
        cf=LogRange((center_freq .* cf_range)..., n_cf),
        fractional=fractional,
        fiber_type="high",
        fs=fs,
        audiogram=audiogram,
    )

    # Create all models
    [
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="low", fractional=fractional, audiogram=audiogram, fs=fs), 
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...),
    ]
end
