# b_freq_bowls.jl
#
# Plots average thresholds as a function of target frequency for different "HL groups"

using CairoMakie
using CSV
using DataFrames
using DataFramesMeta
using Statistics
using Utilities
using UtilitiesViz
using ProfileAnalysis

# Load in data
df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

# Filter data only to include relevant subsections (1 kHz data)
df = @subset(df, :rove .== "fixed level")

# Summarize as function of number of components and group
df_summary = @chain df begin
    # Group by freq, component count, and group
    groupby([:freq, :n_comp, :hl_group])

    # Summarize
    @combine(
        :stderr = std(:threshold)/sqrt(length(:threshold)),
        :threshold = mean(:threshold),
    )
end

# Configure plotting parameters
set_theme!(theme_carney; Scatter=(markersize=10.0, ))

# Create figure and axes
sf = 0.8
fig = Figure(; resolution=(235 * sf, 620 * sf))
axs = map(1:5) do i
    Axis(
        fig[i, 1], 
        xticklabelrotation=π/4,
        xticks=(1:4, ["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"]),
        yticks=-10:10:10,
        xminorticksvisible=false,
    )
end
ylims!.(axs, -20.0, 10.0)
xlims!.(axs, 0.5, 4.5)
neaten_grid!(axs, "vertical")

# Loop through combinations of component spacing (rows) and rove (columns), plot data
for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
    for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
        # Subset means and filled data
        sub = @subset(df_summary, :n_comp .== n_comp, :hl_group .== group)
        sub = @orderby(sub, :freq)

        # Plot bowl
        errorbars!(axs[idx_n_comp], 1:4, sub.threshold, 1.96 .* sub.stderr; color=color_group(group))
        scatter!(axs[idx_n_comp], 1:4, sub.threshold; color=color_group(group))
        lines!(axs[idx_n_comp], 1:4, sub.threshold; color=color_group(group))
    end
end

# Adjust spacing
axs[end].xlabel = "Target freq (Hz)"
Label(fig[1:5, 0], "Threshold (dB SRS)"; rotation=π/2, tellheight=false)
map(enumerate(sort(unique(df.n_comp)))) do (idx, label)
    Label(fig[idx, 2], "$label comp"; rotation=-π/2, tellheight=false)
end
rowgap!(fig.layout, Relative(0.02))
colgap!(fig.layout, Relative(0.05))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_beta_b.svg"), fig)


