using ProfileAnalysis
using Utilities
using CairoMakie
using DataFrames
using DataFramesMeta
using Chain
using Statistics
using UtilitiesViz

# Get list of simulations and also list of which are complete
experiment = ProfileAnalysis_PFTemplateObserver()
sims = setup(experiment)
complete = isfile.(sims)

# Loop through all complete simulations and plot fitted PF
sims_complete = sims[complete]
figs = map(sims_complete) do sim
    # Set up 
    results = @memo Default() simulate(sim)
    μ = map(mean, results)
    σ = map(x -> std(x) / sqrt(length(x)), results)

    # Fit and plot
    incs = [x[2].stimuli[1].stimulus.increment for x in sim.patterns]
    mod = fit(sim, incs, results)
    fig = Figure()
    ax = Axis(fig[1, 1])
    viz!(ProfileAnalysis_PFTemplateObserver(), ax, incs, μ, σ, mod)

    # Add fancy label
    target_freq = sim.patterns[1][1].stimuli[1].stimulus.center_freq
    n_comp = sim.patterns[1][1].stimuli[1].stimulus.n_comp
    rove_dist = sim.patterns[1][1].stimuli[1].rove_dist
    rove_size = round((1/2) * (maximum(rove_dist) - minimum(rove_dist)); digits=3)

    ax.title = "n_comp=$n_comp, target_freq=$target_freq Hz, rove_size=$rove_size dB\n model=$(modelstr(sim.model)), observer=$(sim.observer)"

    # Return
    fig
end

# Compile
fig = displayimg(tilecat(getimg.(figs)))
save("\\home\\daniel\\cl_fig\\pahi\\2023-07-05_diagnosis.png", fig)