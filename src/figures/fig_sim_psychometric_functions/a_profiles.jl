using Utilities
using UtilitiesViz
using ProfileAnalysis
using AuditorySignalUtils
using CairoMakie
using Statistics
using Distributions
using Colors
using ColorSchemes
using Distributed

function _prep_model(fiber_type::String; center_freq=1000.0)
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, cf=LogRange(center_freq/2, center_freq*2, 91), fractional=true)
    return model
end

function _prep_model(modeltype::DataType, params::Dict; center_freq=1000.0)
    frontend = AuditoryNerveZBC2014(; cf=LogRange(center_freq/2, center_freq*2, 91), fractional=true)
    model = modeltype(; frontend=frontend, params...)
    return model
end

function _prep_sims(increment, model::Model; center_freq=1000.0, n_comp=21)
    # Choose experiment
    exp = ProfileAnalysis_AvgPatterns()

    # Set up simulations
    sim = DeltaPattern(;
        pattern_1=setup(exp, model, -Inf, center_freq, n_comp),
        pattern_2=setup(exp, model, increment, center_freq, n_comp),
        model=model,
    )

    # Run simulations
    out = @memo Default() simulate(sim)

    # Return
    log2.(model.cf ./ center_freq), out
end

function _plot_sim!(ax, cf, r; color=:black)
    μ = mean(r)
    σ = std(r)
    lines!(ax, cf, μ ./ σ; color=color)
    ylims!(ax, -5.0, 5.0)
end

function doplot(increments=[-999.9, -20.0, -10.0, 0.0])
    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(430, 130))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Add indicators for harmonic frequencies
    freqs = log2.(LogRange(1000.0/5, 1000.0*5, 21) ./ 1000.0)
    [arrows!(
        ax, 
        freqs,
        repeat([4.0], length(freqs)),
        repeat([0.0], length(freqs)),
        repeat([-0.5], length(freqs)); 
        color=:lightgray,
        arrowsize=4.0,
    ) for ax in axs]
    [xlims!(ax, -1.0, 1.0) for ax in axs]

    # Set up colors 
    cmap_periphe = range(HSL(270.0, 0.0, 0.8), HSL(270.0, 0.0, 0.3); length=length(increments))

    # Fetch models
    models = setup(exp, 1000.0)

    # Do each plot
    for (idx, inc) in enumerate(increments)
        for (ax, model) in zip(axs, models)
            _plot_sim!(ax, _prep_sims(inc, model)...; color=cmap_periphe[idx])
        end
    end

    # Adjust
    axs[1].ylabel = "Normalized Δ rate"
    Label(fig[2, 2:3], "CF (oct re: target frequency)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))

    # Return
    return fig
end

# Render and save
fig = doplot()
save(projectdir("plots", "manuscript_fig_zeta_a.svg"), fig)

# Render colorbars manually and save
fig = Figure(; resolution=(50, 135))
cb = Colorbar(fig[1, 1]; limits=(0, 1), colormap=cgrad(range(HSL(270.0, 0.0, 0.8), HSL(270.0, 0.0, 0.3); length=4); categorical=true))
cb.ticks = ((1/(4*2)):(2/(4*2)):(1.0 - 1/(4*2)), vcat("-Inf", string.(Int.([-20.0, -10.0, 0.0]))))
fig
save(projectdir("plots", "manuscript_fig_zeta_a_colorbar_grays.svg"), fig)