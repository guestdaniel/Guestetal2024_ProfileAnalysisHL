# Here we provide a definitions for an abstract type "ProfileAnalysisExperiment", which is
# subtyped to implement different types of expeirments for the profile-analysis paper and
# other deliverables. 

# Handle exports
export ProfileAnalysisExperiment, setup_nohsr, setup_extended

# Declare experiment types
abstract type ProfileAnalysisExperiment <: Utilities.Experiment end

# Declare a handful of constants that we will use throughout these experiments and analyses
# These provide a basic set of rules of thumb to encourage cosistency across simulations
# and maximize simulation reuse
const n_cf = 91                     # number of CFs to simulate (#)
const n_cf_reduced = 61             # number of CFs to simulate for fast simulations (#)
const n_rep_template = 500          # number of ref responses to simulate for template (#)
const n_rep_template_reduced = 250  # number of ref responses to simulate for fast templates (#)
const n_rep_trial = 150             # number of trials to simulate for each point on PF (#)
const n_rep_trial_reduced = 50      # number of trials to simulate for fast simulations (#)
const fs = 100e3                    # sampling rate (Hz)
const cf_range = [1/2.0, 2.0]       # range around center tone frequency (ratio)
const fractional = true             # include fractional Gaussian noise (bool)

"""
    setup(::ProfileAnalysisExperiment, center_freq, cf_range[, audiogram])

Return vector of models with specified parameter settings

Return vector of Model objects with specified CF and audiogram parameter settings. Used
throughout the simulation code to standardize the process of setting up models.
"""
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

    # Create all primary models (HSR, LSR, BE, BS, BE-multi, BS-multi, BE-BS)
    [
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="high", fractional=fractional, audiogram=audiogram, fs=fs), 
        AuditoryNerveZBC2014(; cf=LogRange((center_freq .* cf_range)..., n_cf), fiber_type="low", fractional=fractional, audiogram=audiogram, fs=fs), 
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...),
    ]
end

"""
    setup_extended(::ProfileAnalysisExperiment, center_freq, cf_range[, audiogram])

Return vector of additional models with specified parameter settings

Return vector of Model objects with specified CF and audiogram parameter settings. Used
throughout the simulation code to standardize the process of setting up models. This 
variant, `setup_extended`, does not return the regular models provided by `setup`, but 
instead returns only the more complex multi-unit IC models.
"""
function setup_extended(
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

    # Create primary BE and BS models
    model_primary_be = InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...)
    model_primary_bs = InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...)

    # Create BE filterbank
    filterbank_be = [
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, LowBE...),
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, StandardBE...),
        InferiorColliculusSFIEBE(; frontend=frontend, fs=fs, HighBE...),
    ]

    # Create BS filterbank
    filterbank_bs = [
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, LowBS...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, StandardBS...),
        InferiorColliculusSFIEBS(; frontend=frontend, fs=fs, HighBS...),
    ]

    # Create supplementary models and return
    [
        # BE-BS opponent model
        InferiorColliculusSFIE_Multiunit(; 
            frontend=frontend, 
            fs=fs, 
            units_be=[model_primary_be], 
            units_bs=[model_primary_bs]
        ),
        # BE filterbank model
        InferiorColliculusSFIE_Multiunit(; 
            frontend=frontend, 
            fs=fs, 
            units_be=filterbank_be, 
        ),
        # BS filterbank model
        InferiorColliculusSFIE_Multiunit(; 
            frontend=frontend, 
            fs=fs, 
            units_bs=filterbank_bs,
        ),
    ]
end


"""
    setup_nohsr(::ProfileAnalysisExperiment, center_freq, cf_range[, audiogram])

Return vector of models with specified parameter settings, except for HSR model

Return vector of Model objects with specified CF and audiogram parameter settings. Used
throughout the simulation code to standardize the process of setting up models. Excludes the
HSR model.
"""
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