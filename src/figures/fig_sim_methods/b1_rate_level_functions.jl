using Utilities
using UtilitiesViz
using CairoMakie
using Colors
using ProfileAnalysis

function plot_model_rlf!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = ToneRLF(model, 0.0, 80.0, 20)
    out = @memo Default() simulate(sim)
    scatter!(ax, axis(sim), out; color=:black)
    lines!(ax, axis(sim), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

function plot_model_rlf!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = ToneRLF(model, 0.0, 80.0, 20)
    out = @memo Default() simulate(sim)
    scatter!(ax, axis(sim), out; color=:black)
    lines!(ax, axis(sim), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

# Set theme and other visual features
set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

# Create figure and axes for each MTF
fig = Figure(; resolution=(400, 125))
axs = [Axis(fig[1, i]) for i in 1:4]

# Do each individual plot
plot_model_rlf!(axs[1], 2000.0, "high")
plot_model_rlf!(axs[2], 2000.0, "low")
plot_model_rlf!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
plot_model_rlf!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)
[vlines!(ax, total_to_comp(70.0, 21); color=:gray, linestyle=:dash) for ax in axs]

# Add labels
axs[1].ylabel = "Firing rate (sp/s)"
Label(fig[2, 2:3], "Sound level (dB SPL)"; tellwidth=false)
rowgap!(fig.layout, 1, Relative(0.03))
colgap!(fig.layout, Relative(0.02))
fig

# Save to disk
save(projectdir("plots", "manuscript_fig_epsilon_b1.svg"), fig)