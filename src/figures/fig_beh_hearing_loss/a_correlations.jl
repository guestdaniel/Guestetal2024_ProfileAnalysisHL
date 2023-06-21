# a_correlations.jl
#
# Plots correlations between hearing thresholds and profile-analysis thresholds

using CSV
using Colors
using DataFrames
using DataFramesMeta
using Statistics
using CairoMakie
using GLM
using Utilities
using UtilitiesViz
using ProfileAnalysis

# Write mini function to fit lm to data and return interpolated fits
function fit_lm(df)
    m = lm(@formula(threshold ~ hl), df)
    b, m = coef(m)
    x̂ = LinRange(-15.0, 90.0, 1000)
    ŷ = m .* x̂ .+ b
    return x̂, ŷ
end

# Load in data
df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

# Manually note which conditions are significant (as of 3/17/23)
significant = [
    (5, 500),
    (13, 500),
    (5, 1000),
    (13, 2000),
    (21, 2000),
    (29, 2000),
    (37, 2000),
    (37, 4000),
]

# Filter data only to include relevant subsections (unroved data) 
df = @subset(df, :rove .== "fixed level")

# Configure plotting parameters
set_theme!(theme_pahi)

# Create figure and axes
sf = 0.8
fig = Figure(; resolution=(600 * sf, 615 * sf))
axs = map(Iterators.product(1:5, 1:4)) do (i, j)
    Axis(
        fig[i, j], 
        yticks=-20:10:10,
    )
end
ylims!.(axs, -20.0, 15.0)
xlims!.(axs, -15.0, 90.0)
neaten_grid!(axs)

# Loop through combinations of component spacing (rows) and frequency (columns), plot data
for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
    for (idx_freq, freq) in enumerate([500, 1000, 2000, 4000])
        # Calculate SL cutoff and plot
        level_per_component = total_to_comp(70.0, n_comp)
        level_per_component_in_hl = spl_to_hl(level_per_component, freq)
        band!(axs[idx_n_comp, idx_freq], [level_per_component_in_hl, 90.0], [-20, -20], [15, 15]; color=HSL(0.0, 0.5, 0.95))

        # Summarize data and plot
        for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
            # Subset data
            sub = @subset(df, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)

            # Plot curve fit
            scatter!(axs[idx_n_comp, idx_freq], sub.hl, sub.threshold; color=color_group(group))
        end

        # Fit regression to pooled data and plot
        sub = @subset(df, :n_comp .== n_comp, :freq .== freq)
        x̂, ŷ = fit_lm(sub)
        matches_signif = any(map(x -> (x[1] == n_comp) & (x[2] == freq), significant))
        if !matches_signif
            lines!(axs[idx_n_comp, idx_freq], x̂, ŷ; color=:black, linestyle=:dash)
        else
            lines!(axs[idx_n_comp, idx_freq], x̂, ŷ; color=:black, linestyle=:solid)
#            x̂, ŷ = fit_lm(sub[sub.hl .> 0.0, :])
#            lines!(axs[idx_n_comp, idx_freq], x̂, ŷ; color=:gray, linestyle=:solid, linewidth=1.0)
        end
    end
end

# Add labels
[Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"])]
[Label(fig[i, 5], label; tellheight=false) for 
    (i, label) in enumerate(string.(sort(unique(df.n_comp))))]
Label(fig[1:5, 0], "Profile-analysis threshold (dB SRS)"; rotation=π/2)
Label(fig[6, 1:4], "Audiometric threshold at target frequency (dB HL)")

# Adjust spacing
rowgap!(fig.layout, Relative(0.02))
colgap!(fig.layout, Relative(0.02))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_gamma_a.svg"), fig)


