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

# Calculate means
df_mean = @chain df begin
    # Group by condition and increment
    groupby([:condition, :freq, :rove, :increment, :n_comp, :subj, :hl_group])

    # Filter out places where we have too little data
#    transform(:pcorr => (x -> length(x)) => :count)
#    @subset(:count .> 3)

    # Group by condition and increment
#    groupby([:condition, :freq, :rove, :increment, :n_comp, :subj])

    # Average
    @combine(
        :pcorr = mean(:pcorr),
    )
end

# Fit psychometric functions
df_fitted = @chain df_mean begin
    # Perform separately for each condtion
    groupby([:condition, :freq, :rove, :n_comp, :subj, :hl_group])

    # Fit logistic function to data
    @combine(:fit = fit_psychometric_function(:increment, :pcorr))

    # Extract slope and threshold
    @transform(:threshold = getindex.(getfield.(:fit, ^(:param)), 1))
    @transform(:slope = getindex.(getfield.(:fit, ^(:param)), 2))
end

# Average bowls
df_mean = @chain df_fitted begin
    # Perform separately for each condtion
    groupby([:condition, :freq, :rove, :n_comp, :hl_group])

    # Summarize
    @combine(
        :err = 1.96 * std(:threshold)/sqrt(length(:threshold)),
        :μ = mean(:threshold),
    )

    # Sort
    @orderby(:n_comp)
end

# Plot bowls
plt =
    (
        # Thresholds versus HL scatter plot
        data(df_mean) * mapping(:n_comp, :μ, :err) * visual(Errorbars; whiskerwidth=10.0, linewidth=2.0) +
        data(df_mean) * mapping(:n_comp, :μ) * (visual(Lines, linewidth=2.0) + visual(Scatter; markersize=15))
    ) *
    mapping(
        col = :condition => sorter(
            "500 Hz unroved",
            "1000 Hz unroved",
            "1000 Hz roved",
            "2000 Hz unroved",
            "4000 Hz unroved"
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
        height=300,
        xlabel="Number of components",
        ylabel="Threshold (dB SRS)",
        xticks=[5, 13, 21, 29, 37],
        yticks=[-20, -15, -10, -5, 0, 5],
    #    limits=((-23, 23), (0.25, 1.05)),
    ),
)
tempsave(fig)
cl_save(plotsdir("bowls.png"), fig)
