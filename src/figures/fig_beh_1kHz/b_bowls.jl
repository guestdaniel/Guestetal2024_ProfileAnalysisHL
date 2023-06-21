# b_bowls.jl
#
# Plots average thresholds as a function of component spacing ("bowls") for different "HL" 
# groups for the roved and unroved conditions at 1 kHz

using CairoMakie
using CSV
using DataFrames
using DataFramesMeta
using Statistics
using Utilities
using ProfileAnalysis

# Load in data
df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

# Filter data only to include relevant subsections (1 kHz data)
df = @subset(df, :freq .== 1000)

# Summarize as function of number of components and group
df_summary = @chain df begin
    # Group by rove, component count, and group
    groupby([:rove, :n_comp, :hl_group])

    # Summarize
    @combine(
        :stderr = std(:threshold)/sqrt(length(:threshold)),
        :threshold = mean(:threshold),
    )
end

# Configure plotting parameters
set_theme!(theme_pahi; Scatter=(markersize=10.0, ))

# Create figure and axes
sf = 0.8
fig = Figure(; resolution=(450 * sf, 180 * sf))
axs = map(1:3) do i
    Axis(
        fig[1, i], 
        xticks=sort(unique(df.n_comp)),
    )
end
ylims!.(axs, -20.0, 1.0)
xlims!.(axs, 2, 40)
neaten_grid!(axs, "horizontal")

# Loop through combinations of component spacing (rows) and rove (columns), plot data
for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
    for (idx_rove, rove) in enumerate(["fixed level", "roved level"])
        # Subset means and filled data
        sub = @subset(df_summary, :rove .== rove, :hl_group .== group)

        # Plot bowl
        lines!(axs[idx_group], sub.n_comp, sub.threshold; color=color_group(group))
        if rove .== "fixed level"
            errorbars!(axs[idx_group], sub.n_comp, sub.threshold, 1.96 .* sub.stderr, zeros(5); color=color_group(group))
        else
            errorbars!(axs[idx_group], sub.n_comp, sub.threshold, zeros(5), 1.96 .* sub.stderr; color=color_group(group))
        end
        scatter!(axs[idx_group], sub.n_comp, sub.threshold; color=color_group(group), marker=rove == "fixed level" ? :circle : :rect)
        if rove == "roved level"
            scatter!(axs[idx_group], sub.n_comp, sub.threshold; color=:white, markersize=10.0/2, marker=rove == "fixed level" ? :circle : :rect)
        end
    end
end

# Adjust spacing
colgap!(fig.layout, Relative(0.02))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_alpha_b.svg"), fig)


