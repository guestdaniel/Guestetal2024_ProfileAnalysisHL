using Utilities
using UtilitiesViz
using CairoMakie
using Colors
using ProfileAnalysis

function plot_model_tc!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = IsolevelTC(model, 30.0, cf * 2^-0.5, cf * 2^0.5, 40)
    out = @memo Default() simulate(sim)
    scatter!(ax, log2.(axis(sim)./cf), out; color=:black)
    lines!(ax, log2.(axis(sim)./cf), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

function plot_model_tc!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = IsolevelTC(model, 30.0, cf * 2^-0.5, cf * 2^0.5, 40)
    out = @memo Default() simulate(sim)
    scatter!(ax, log2.(axis(sim)./cf), out; color=:black)
    lines!(ax, log2.(axis(sim)./cf), quicksmooth(out); color=:black)
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
plot_model_tc!(axs[1], 2000.0, "high")
plot_model_tc!(axs[2], 2000.0, "low")
plot_model_tc!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
plot_model_tc!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)

# Add labels
axs[1].ylabel = "Firing rate (sp/s)"
Label(fig[2, 2:3], "Frequency (oct re: CF)"; tellwidth=false)
rowgap!(fig.layout, 1, Relative(0.03))
colgap!(fig.layout, Relative(0.02))
fig

# Save to disk
save(projectdir("plots", "manuscript_fig_epsilon_b2.svg"), fig)