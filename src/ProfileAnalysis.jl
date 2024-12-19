module ProfileAnalysis

using AuditorySignalUtils
using CairoMakie
using Chain
using Colors
using CSV
using ColorSchemes
using DataFrames
using DataFramesMeta
using Dates
using Distributed
using Distributions
using DrWatson
using DSP
using FFTW
using GLM
using HypothesisTests
using MAT
using LsqFit
using OnlineStats
using Parameters
using SHA
using Suppressor
using Statistics
using Random
using ProgressMeter
using Printf
using Match
using Optim
using ZilanyBruceCarney2014

# Utilities code
# This code is all salvaged from the now-long-dead Utilities package I wrote...
# To avoid making the user install everything themselves, we just incorporate it and its
# dependencies into this fine package.
# Core code
include(joinpath("core", "utils.jl"))
include(joinpath("core", "components.jl"))
include(joinpath("core", "audiograms.jl"))

# Stimulus code
include(joinpath("stimuli", "stimuli.jl"))
include(joinpath("stimuli", "tones.jl"))
include(joinpath("stimuli", "noises.jl"))
include(joinpath("stimuli", "compound.jl"))

# Modeling code
include(joinpath("models", "models.jl"))
include(joinpath("models", "zbc2014.jl"))
include(joinpath("models", "nc2004.jl"))

# Simulations and Experiments
include(joinpath("simulations", "configs.jl"))
include(joinpath("simulations", "simulations.jl"))
include(joinpath("simulations", "experiments.jl"))
include(joinpath("simulations", "mtf.jl"))
include(joinpath("simulations", "rlf.jl"))
include(joinpath("simulations", "tuning_curves.jl"))
include(joinpath("simulations", "patterns.jl"))
include(joinpath("simulations", "psychometric_functions.jl"))

# # Set up standards for types
include(joinpath("standards", "standards.jl"))

# General code
include("groupers.jl")           # functions for grouping rows of dfs based on audiometry
include("stimuli.jl")            # stimulus code
include("utils.jl")              # random useful functions
include("parallel.jl")           # stimulus code

# Experiment-specific code
include(joinpath("experiments", "parameter_sets.jl"))
include(joinpath("experiments", "experiments.jl"))
include(joinpath("experiments", "Templates", "Templates.jl"))
include(joinpath("experiments", "AvgPatterns", "AvgPatterns.jl"))
include(joinpath("experiments", "PFs", "PFs.jl"))
include(joinpath("experiments", "PFs", "PFs_postprocess.jl"))

# Figure code
#include("genfigs.jl")
include(joinpath("figures", "fig_intro.jl"))
include(joinpath("figures", "fig_beh_1kHz.jl"))
include(joinpath("figures", "fig_beh_alternatives_hl.jl"))
include(joinpath("figures", "fig_beh_frequency.jl"))
include(joinpath("figures", "fig_beh_hearing_loss.jl"))
include(joinpath("figures", "fig_sim_methods.jl"))
#include(joinpath("figures", "fig_sim_psychometric_functions.jl"))
include(joinpath("figures", "fig_sim_responses.jl"))
include(joinpath("figures", "fig_sim_bowls.jl"))
include(joinpath("figures", "fig_sim_LSR_followup.jl"))
include(joinpath("figures", "fig_sim_hi.jl"))

# Constants
const C_path_models = "C:\\home\\daniel\\cl_sim\\pahi"
const C_path_figs = "C:\\home\\daniel\\cl_fig\\pahi"
const C_path_audiograms = "C:\\home\\daniel\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"

end # module
