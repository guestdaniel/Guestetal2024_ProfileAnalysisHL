# a_psychometric_functions.jl
#
# Plots group-average psychometric functions for different "HL" groups as a function of
# component spacing for the unroved conditions at 0.5-4 kHz

using CairoMakie
using CSV
using DataFrames
using DataFramesMeta
using Statistics
using Utilities
using UtilitiesViz
using ProfileAnalysis

# Load in data
df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

# Filter data only to include relevant subsections (1 kHz data)
df = @subset(df, :rove .== "fixed level")

# Calculate means in each condition and store in dataframe
df_mean = @chain df begin
    # Group by freq, increment, component count, group, and subject
    groupby([:freq, :increment, :n_comp, :hl_group, :subj])

    # Calculate means (in each condition, for each subject)
    @combine(:μ = mean(:pcorr))

    # Group by freq, increment, component count, and group
    groupby([:freq, :increment, :n_comp, :hl_group])

    # Filter out places where we have too little data (we want at least 2 subjects at each point)
    transform(:μ => (x -> length(x)) => :count)
    @subset(:count .> 2)

    # Group again
    groupby([:freq, :increment, :n_comp, :hl_group])

    # Compute μ and stderr
    @combine(
        :stderr = std(:μ)/sqrt(length(:μ)),
        :μ = mean(:μ),
    )
end

# Fit psychometric functions and store in results in dataframe
df_fitted = @chain df_mean begin
    # Group by freq, component count, and group
    groupby([:freq, :n_comp, :hl_group])

    # Fit logistic function to data
    @combine(:fit = fit_psychometric_function(:increment, :μ))

    # Extract slope and threshold
    @transform(:threshold = getindex.(getfield.(:fit, ^(:param)), 1))
    @transform(:slope = getindex.(getfield.(:fit, ^(:param)), 2))
end

# Expand each row of df_fitted into interpolated datapoints  
x̂ = -30.0:0.1:20.0
df_filled = map(eachrow(df_fitted)) do row
    pcorr = logistic_predict(x̂, row.threshold, row.slope)
    rows = map(1:length(pcorr)) do idx
        temp = copy(row)
        temp = merge(temp, (:pcorr => pcorr[idx], :increment => x̂[idx]))
    end
    rows = DataFrame(rows)
end
df_filled = vcat(df_filled...)

# Configure plotting parameters
set_theme!(theme_carney)

# Create figure and axes
sf = 0.8
fig = Figure(; resolution=(600 * sf, 615 * sf))
axs = map(Iterators.product(1:5, 1:4)) do (i, j)
    Axis(
        fig[i, j], 
        xticks=-20:10:10, 
        xminorticks=-20:5:15,
        yticks=0.5:0.25:1.0, 
        yminorticks=(0.5-0.125):0.125:1.0,
    )
end
neaten_grid!(axs)
ylims!.(axs, 0.27, 1.1)
xlims!.(axs, -25.0, 16.0)

# Loop through combinations of component spacing (rows) and rove (columns), plot data
for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
    for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
        for (idx_freq, freq) in enumerate([500, 1000, 2000, 4000])
            # Subset means and filled data
            mean_sub = @subset(df_mean, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)
            filled_sub = @subset(df_filled, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)

            # Plot curve fit
            lines!(axs[idx_n_comp, idx_freq], filled_sub.increment, filled_sub.pcorr; color=color_group(group))

            # Plot data and errorbars
            errorbars!(axs[idx_n_comp, idx_freq], mean_sub.increment, mean_sub.μ, 1.96 .* mean_sub.stderr; color=color_group(group))
            scatter!(axs[idx_n_comp, idx_freq], mean_sub.increment, mean_sub.μ; color=color_group(group))

            # Handle plotting thresholds at arbitrary offset separately
            offset = 0.30 + (idx_group-1)*0.05
            fitted_sub = @subset(df_fitted, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)
            scatter!(axs[idx_n_comp, idx_freq], fitted_sub.threshold, [offset]; marker=:circle, color=color_group(group))
        end
    end
end

# Add labels
[Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"])]
[Label(fig[i, 5], label; tellheight=false, rotation=-π/2) for 
    (i, label) in enumerate(string.(sort(unique(df.n_comp))) .* " comps")]
Label(fig[1:5, 0], "Proportion correct"; rotation=π/2)
Label(fig[6, 1:4], "Increment (dB SRS)")

# Adjust spacing
rowgap!(fig.layout, Relative(0.02))
colgap!(fig.layout, Relative(0.02))

# Render and save
fig
save(projectdir("plots", "manuscript_fig_beta_a.svg"), fig)

