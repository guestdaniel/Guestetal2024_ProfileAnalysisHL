using Utilities
using UtilitiesViz
using ProfileAnalysis
using AuditorySignalUtils
using CairoMakie
using Statistics

function _prep_model(fiber_type::String; center_freq=1000.0)
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    return model
end

function _prep_model(modeltype::DataType, params::Dict; center_freq=1000.0)
    frontend = AuditoryNerveZBC2014(; cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    model = modeltype(; frontend=frontend, params...)
    return model
end

function _prep_sims(increment, args...; center_freq=1000.0, n_comp=21)
    # Get model
    model = _prep_model(args...; center_freq=center_freq)

    # Make stimuli
    stim_ref = ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf)
    stim_tar = ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=increment)

    # Generate resposnes
    sim_ref = Response(stim_ref, model)
    out_ref = @memo Default() run(sim_ref)

    sim_tar = Response(stim_tar, model)
    out_tar = @memo Default() run(sim_tar)

    # Return
    log2.(model.cf ./ center_freq), map(mean, out_ref), map(mean, out_tar)
end

function _plot_pair!(ax, cf, r, t; color=:black)
    lines!(ax, cf, r; color=color)
    lines!(ax, cf, t; color=:red)
    ylims!(ax, 0.0, 1.25 * max(maximum(r), maximum(t)))
end

# Set up plot
set_theme!(theme_carney; fontsize=10.0)
fig = Figure(; resolution=(400, 125))
axs = [Axis(fig[1, i]) for i in 1:4]

# Do each plot
_plot_pair!(axs[1], _prep_sims(-10.0, "high")...; color=:black)
_plot_pair!(axs[2], _prep_sims(-10.0, "low")...; color=:black)
_plot_pair!(axs[3], _prep_sims(-10.0, InferiorColliculusSFIEBE, StandardBE)...; color=:black)
_plot_pair!(axs[4], _prep_sims(-10.0, InferiorColliculusSFIEBS, StandardBS)...; color=:black)

# Adjust
axs[1].ylabel = "Firing rate (sp/s)"
Label(fig[2, 2:3], "CF (oct re: target frequency)"; tellwidth=false)
rowgap!(fig.layout, 1, Relative(0.03))
colgap!(fig.layout, Relative(0.02))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_epsilon_c.svg"), fig)
