### Imports
n_workers_target = 1
using Pkg; Pkg.activate(Base.current_project());
using CSV
using LsqFit
using DataFrames
using DataFramesMeta
using Statistics
using AlgebraOfGraphics
using CairoMakie
using Turing
using ProfileAnalysis
using StatsModels
using StatsFuns: logistic
using CarneyLabUtils
using FillArrays
using LinearAlgebra
include(scriptsdir("publications", "publications.jl"))

### Configuration
n_trial_per_run = 20
probit(p) = quantile(Normal(0, 1), p)
invprobit(z) = (cdf(Normal(0, 1), z)+1.0)/2.0

### Real regression model
df[!, :n_comp] .= string.(df.n_comp)
modelframe = ModelFrame(@formula(pcorr ~ 1 + condition + n_comp + increment), df)
modelmatrix = ModelMatrix(modelframe)

# Extract y and X
y = modelframe.data.pcorr .* n_trial_per_run
X = modelmatrix.m

### Fit
# Declare Turing model
@model function model_block(y, X_cond, X_n_comp, X_increment)
#    # Partition data
#    X_intercept = X[:, 1]
#    X_cond = X[:, modelmatrix.assign .== 2]
#$    X_increment = X[:, modelmatrix.assign .== 3]

    # Set up model variables
    intercept ~ Normal(-10, 10)
    β_cond ~ MvNormal([-10, -10, -10, -10], LinearAlgebra.I)
    β_n_comp ~ MvNormal([-10, -10, -10, -10], LinearAlgebra.I)
    slope ~ Normal(0, 100)

    N = 20
    for r in 1:length(y)
#        v = invprobit(slope * (X_increment[r, 1] - X_intercept[r, 1] * intercept + X_cond[r, :]' * β_cond))
       v = invprobit(
           slope * (
               X_increment[r, 1] - (intercept + X_cond[r, :]' * β_cond + X_n_comp[r, :]' * β_n_comp)
           )
        )
        y[r] ~ Binomial(N, v)
    end
end

# Sample model
idxs = 1:7500  # something in 7500-7600 causes error?
chain = sample(
    model_block(
        y[idxs],
        X[idxs, modelmatrix.assign .== 2],
        X[idxs, modelmatrix.assign .== 3],
        X[idxs, modelmatrix.assign .== 4],
    ),
    NUTS(0.65),
    5000
)
