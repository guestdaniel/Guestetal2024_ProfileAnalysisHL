module ProfileAnalysis

using AuditoryNerveFiber
using AuditorySignalUtils
using CairoMakie
using Chain
using Colors
using CSV
using ColorSchemes
using DataFrames
using DataFramesMeta
using Distributed
using Distributions
using DrWatson
using LsqFit
using Parameters
using Statistics
using Random
using Utilities
using UtilitiesViz
using ProgressMeter
using Printf
using Match
using Optim
using GLM

# General code
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
include(joinpath("figures", "fig_beh_1kHz.jl"))
include(joinpath("figures", "fig_beh_frequency.jl"))
include(joinpath("figures", "fig_sim_bowls.jl"))

# Constants
const C_path_models = "C:\\home\\daniel\\cl_sim\\pahi"
const C_path_figs = "C:\\home\\daniel\\cl_fig\\pahi"
const C_path_audiograms = "C:\\home\\daniel\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"

end # module
