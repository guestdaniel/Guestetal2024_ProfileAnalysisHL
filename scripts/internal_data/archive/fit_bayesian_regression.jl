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
idxs = 1:7500  # something in 7500-7600 causes error?
df = df[idxs, :]
modelframe = ModelFrame(@formula(pcorr ~ 1 + condition + n_comp + increment), df)
modelmatrix = ModelMatrix(modelframe)

# Extract y and X
y = modelframe.data.pcorr .* n_trial_per_run
X = modelmatrix.m

### Fit
# Declare Turing model
@model function model_block(y, X_cond, X_n_comp, X_increment)
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
chain = sample(
    model_block(
        y,
        X[:, modelmatrix.assign .== 2],
        X[:, modelmatrix.assign .== 3],
        X[:, modelmatrix.assign .== 4],
    ),
    NUTS(0.65),
    5000
)

### Generate true means and predicted means
# Calculate empirical means
df_mean = @chain df begin
    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp, :hl_group])

    # Average
    @combine(
        :err = 1.96*std(:pcorr)/sqrt(length(:pcorr)),
        :pcorr = mean(:pcorr),
    )
end

# Calculate posterior distributions
chain_posterior_pred = predict(
    model_block(
        Vector{Union{Missing, Float64}}(undef, length(idxs)),
        X[idxs, modelmatrix.assign .== 2],
        X[idxs, modelmatrix.assign .== 3],
        X[idxs, modelmatrix.assign .== 4],
    ),
    chain,
)
df[!, :yhat] = dropdims(dropdims(mean(chain_posterior_pred.value.data; dims=1); dims=3); dims=1)./20
df[!, :ymin] = dropdims(dropdims(mapslices((x -> quantile(x, 0.025)), chain_posterior_pred.value.data; dims=1); dims=1); dims=2)./20
df[!, :ymax] = dropdims(dropdims(mapslices((x -> quantile(x, 0.975)), chain_posterior_pred.value.data; dims=1); dims=1); dims=2)./20

### Visualize some predictions
# Calculate meane
df_mean = @chain df begin
    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp])

    # Filter out places where we have too little data
    transform(:pcorr => (x -> length(x)) => :count)
    @subset(:count .> 3)

    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp])

    # Average
    @combine(
        :err = 1.96*std(:pcorr)/sqrt(length(:pcorr)),
        :pcorr = mean(:pcorr),
    )
end

# Calculate pred prior means
df_fit = @chain df begin
    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp])

    # Average
    @combine(
        :ymin = mean(:ymin),
        :ymax = mean(:ymax),
        :yhat = mean(:yhat),
    )
end

# Calculate threshold distributions
temp = map(Iterators.product(unique(df.condition), unique(df.n_comp))) do (condition, n_comp)
    DataFrame(:increment => 0.0, :n_comp => n_comp, :condition => condition, :pcorr => 1.0)
end
temp = vcat(temp...)
modelframe_temp = ModelFrame(@formula(pcorr ~ 1 + condition + n_comp + increment), temp)
modelmatrix_temp = ModelMatrix(modelframe_temp)
X_temp = modelmatrix_temp.m
coefs = dropdims(chain.value.data[:, 1:10, :]; dims=3)
est_thresholds = coefs[:, 1] .+ coefs[:, 2:5] * X_temp[:, 2:5]' .+ coefs[:, 6:9] * X_temp[:, 6:9]'
outs = map(1:size(est_thresholds)[1]) do idx
    test = copy(temp)
    test[!, :threshold] .= est_thresholds[idx, :]
    test[!, :index] .= idx
    return test
end
df_thr = vcat(outs...)
df_thr = @chain df_thr begin
    groupby([:n_comp, :condition])
    @combine(
        :low = quantile(:threshold, 0.025),
        :high = quantile(:threshold, 0.975),
        :threshold = mean(:threshold),
    )
end
# Add dummy y value to df_fitted (fot use in plotting thresholds below data)
df_thr[!, :y] .= 0.35
df_thr[!, :u] .= 0.0
df_thr[!, :v] .= 0.05

### Plot
# Plot psychometric functions
plt =
    (
        # Thresholds below psychometric functions
        data(@orderby(df_fit, :increment)) * mapping(:increment, :yhat) * visual(Lines; color=:gray) +
        # Thresholds below psychometric functions
#        data(df_thr) * mapping(:threshold, :y) * visual(Scatter; marker=:rect) +
        data(df_thr) * mapping(:y, :low, :high) * visual(Rangebars; direction=:x) +
        # Scatter group-average means
        data(df_mean) * mapping(:increment, :pcorr) * visual(Scatter) +
        # Errorbars on group-average means
        data(df_mean) * mapping(:increment, :pcorr, :err) * visual(Errorbars)
    ) *
    mapping(
        col = :condition => sorter(
            "500 Hz unroved",
            "1000 Hz unroved",
            "1000 Hz roved",
            "2000 Hz unroved",
            "4000 Hz unroved"
        ),
        row = :n_comp => renamer(
            "5" => "5 comp",
            "13" => "13 comp",
            "21" => "21 comp",
            "29" => "29 comp",
            "37" => "37 comp"
        ),
    )
fig = draw(plt;
    axis=(
        width=400,
        height=200,
        xlabel="Increment size (dB SRS)",
        ylabel="Proportion correct",
        xticks=[-20, -10, 0, 10, 20],
        yticks=[0.5, 0.75, 1.0],
        limits=((-23, 23), (0.25, 1.05)),
    ),
)
tempsave(fig)
