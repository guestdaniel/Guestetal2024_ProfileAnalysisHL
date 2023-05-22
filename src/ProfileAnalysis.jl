module ProfileAnalysis

using AuditoryNerveFiber
using AuditorySignalUtils
using CairoMakie
using Chain
using Colors
using ColorSchemes
using DataFrames
using Distributed
using Distributions
using LsqFit
using Parameters
using Statistics
using Random
using Utilities
using UtilitiesViz
using ProgressMeter
using Printf

# General code
include("stimuli.jl")            # stimulus code
include("utils.jl")              # random useful functions
include("figures.jl")            # code for figures
include("parallel.jl")           # stimulus code

# Experiment-specific code
#include(joinpath("experiments", "EvaluateParameters.jl"))  # exp to test IC model params
include(joinpath("experiments", "parameter_sets.jl"))
include(joinpath("experiments", "Templates", "Templates.jl"))
#include(joinpath("experiments", "StandardNeurograms.jl"))  # exp to make generating standard nuerograms easy!

# Talk-specific code
#include(joinpath(splitdir(Base.active_project())[1], "talks", "asa2023chicago", "src", "experiments", "RovingTemplates", "RovingTemplates.jl"))
#include(joinpath(splitdir(Base.active_project())[1], "talks", "asa2023chicago", "src", "experiments", "RovingTemplates", "RovingTemplates_plot.jl"))

# Constants
const C_path_models = "C:\\home\\daniel\\cl_sim\\pahi"
const C_path_figs = "C:\\home\\daniel\\cl_fig\\pahi"
const C_path_audiograms = "C:\\home\\daniel\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"

end # module
