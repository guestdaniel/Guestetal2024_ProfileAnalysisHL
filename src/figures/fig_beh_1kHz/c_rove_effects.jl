# c_rove_effects.jl
#
# Plots the magnitude of the "rove effect" (difference between roved-level and fixed-level 
# thresholds) as a function of component spacing ("bowls") for different "HL groups" for the
# 1-kHz condition

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
df_ind = @chain df begin
    # Select only what we need
    @select(:rove, :n_comp, :hl_group, :subj, :threshold)

    unstack(:rove, :threshold)

end
df_ind[!, :diff] .= df_ind[:, 5] .- df_ind[:, 4]
df_ind = df_ind[completecases(df_ind), :]

df_summary = @chain df_ind begin
    # Group by rove, component count, and group
    groupby([:n_comp, :hl_group])

    # Summarize
    @combine(
        :stderr = std(:diff)/sqrt(length(:diff)),
        :diff = mean(:diff),
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
        yticks=0:5:15, 
    )
end
ylims!.(axs, -2.5, 15.0)
xlims!.(axs, 2, 40)
neaten_grid!(axs, "horizontal")

# Add solid hline at 0.0
hlines!.(axs, [0.0]; color=:black, linewidth=1.0)

# Loop through combinations of component spacing (rows) and rove (columns), plot data
for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
    # Subset means and filled data
    sub = @subset(df_summary, :hl_group .== group)
    ind = @subset(df_ind, :hl_group .== group)

    # Plot bowl
    errorbars!(axs[idx_group], sub.n_comp, sub.diff, 1.96 .* sub.stderr; color=color_group(group))
    scatter!(axs[idx_group], sub.n_comp, sub.diff; color=color_group(group), marker=:utriangle)
    scatter!(axs[idx_group], ind.n_comp .+ 2, ind.diff; color=color_group(group), markersize=fig_defaults["markersize"]/3, marker=:utriangle)
end

# Adjust spacing
colgap!(fig.layout, Relative(0.02))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_alpha_c.svg"), fig)


