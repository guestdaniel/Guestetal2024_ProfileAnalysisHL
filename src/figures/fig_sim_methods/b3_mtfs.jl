using Utilities
using UtilitiesViz
using CairoMakie
using Colors
using ProfileAnalysis

function plot_model_mtf!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = NoiseMTF(model, 8.0, 512.0, 31; l=20.0)
    out = @memo Default() simulate(sim)
    ax = plot_mtf!(ax, axis(sim), out, zeros(size(out)))
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

function plot_model_mtf!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = NoiseMTF(model, 8.0, 512.0, 31; l=20.0)
    out = @memo Default() simulate(sim)
    ax = plot_mtf!(ax, axis(sim), out, zeros(size(out)); color=parse(RGBA, :black))
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

# Set theme and other visual features
set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

# Create figure and axes for each MTF
fig = Figure(; resolution=(400, 125))
axs = [Axis(fig[1, i]; xscale=log10, xticks=(2 .^ (1:2:9), string.(2 .^ (1:2:9))), xminorticksvisible=false) for i in 1:4]

# Do each individual plot
plot_model_mtf!(axs[1], 2000.0, "high")
plot_model_mtf!(axs[2], 2000.0, "low")
plot_model_mtf!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
plot_model_mtf!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)

# Add labels
axs[1].ylabel = "Firing rate (sp/s)"
Label(fig[2, 2:3], "Modulation frequency (Hz)"; tellwidth=false)
rowgap!(fig.layout, 1, Relative(0.03))
colgap!(fig.layout, Relative(0.02))
fig

# Save to disk
save(projectdir("plots", "manuscript_fig_epsilon_b3.svg"), fig)