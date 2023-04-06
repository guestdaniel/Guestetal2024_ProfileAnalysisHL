n_workers_target = 1
using Pkg; Pkg.activate(Base.current_project());
using CSV
using LsqFit
using DataFrames
using DataFramesMeta
using Statistics
using AlgebraOfGraphics
using CairoMakie
include(scriptsdir("publications", "publications.jl"))

# Calculate meane
df_mean = @chain df begin
    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp, :hl_group])

    # Filter out places where we have too little data
    transform(:pcorr => (x -> length(x)) => :count)
    @subset(:count .> 3)

    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp, :hl_group])

    # Average
    @combine(
        :err = 1.96*std(:pcorr)/sqrt(length(:pcorr)),
        :pcorr = mean(:pcorr),
    )
end

# Fit psychometric functions
df_fitted = @chain df_mean begin
    # Perform separately for each condtion
    groupby([:condition, :freq, :rove, :n_comp, :hl_group])

    # Fit logistic function to data
    @combine(:fit = fit_psychometric_function(:increment, :pcorr))

    # Extract slope and threshold
    @transform(:threshold = getindex.(getfield.(:fit, ^(:param)), 1))
    @transform(:slope = getindex.(getfield.(:fit, ^(:param)), 2))
end

# Replace fit objects with predicted performance at range of increment values
df_filled = map(eachrow(df_fitted)) do row
    # Fill data to x_hat_fill
    pcorr = logistic_predict(x_hat_fill, row.threshold, row.slope)
    rows = map(1:length(pcorr)) do idx
        temp = copy(row)
        temp = merge(temp, (:pcorr => pcorr[idx], :increment => x_hat_fill[idx]))
    end
    rows = DataFrame(rows)
end
df_filled = vcat(df_filled...)

# Add dummy y value to df_fitted (fot use in plotting thresholds below data)
df_fitted[!, :y] .= 0.35
df_fitted[!, :u] .= 0.0
df_fitted[!, :v] .= 0.05

# Calibrate font sizes
update_theme!(
    fontsize=30,
)

# Plot psychometric functions
plt =
    (
        # Scatter group-average means
        data(df_mean) * mapping(:increment, :pcorr) * visual(Scatter) +
        # Errorbars on group-average means
        data(df_mean) * mapping(:increment, :pcorr, :err) * visual(Errorbars) +
        # Thresholds below psychometric functions
        data(df_fitted) * mapping(:threshold, :y) * visual(Scatter; marker=:rect) +
        # Psychometric function fits
        data(df_filled) * mapping(:increment, :pcorr) * visual(Lines)
    ) *
    mapping(
        col = :condition => sorter(
            "500 Hz unroved",
            "1000 Hz unroved",
            "1000 Hz roved",
            "2000 Hz unroved",
            "4000 Hz unroved"
        ),
        row = :n_comp => renamer(
            5 => "5 comp",
            13 => "13 comp",
            21 => "21 comp",
            29 => "29 comp",
            37 => "37 comp"
        ),
        color = :hl_group => sorter(
            "< 5 dB HL",
            "5-15 dB HL",
            "> 15 dB HL"
        ) => "Threshold @ CF",
    )
fig = draw(plt;
    axis=(
        width=400,
        height=200,
        xlabel="Increment size (dB SRS)",
        ylabel="Proportion correct",
        xticks=[-20, -10, 0, 10, 20],
        yticks=[0.5, 0.75, 1.0],
        limits=((-23, 23), (0.25, 1.05)),
    ),
)
tempsave(fig)
cl_save(plotsdir("psychometric_functions_summary.png"), fig)
