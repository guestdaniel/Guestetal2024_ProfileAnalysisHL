module ProfileAnalysis

using AuditoryNerveFiber
using AuditorySignalUtils
using CairoMakie
using Chain
using Colors
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

include("stimuli.jl")
include("utils.jl")              # random useful functions
include("figures.jl")            # code for figures
#include("parameter_sets.jl")
#include(joinpath("experiments", "EvaluateParameters.jl"))  # exp to test IC model params

# Constants
const C_path_models = "C:\\home\\daniel\\cl_sim\\pahi"
const C_path_figs = "C:\\home\\daniel\\cl_fig\\pahi"
const C_path_audiograms = "C:\\home\\daniel\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"

end # module
