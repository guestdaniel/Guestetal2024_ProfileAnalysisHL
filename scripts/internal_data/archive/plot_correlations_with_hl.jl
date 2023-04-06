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
    groupby([:condition, :freq, :rove, :increment, :n_comp, :subj, :hl, :hl_group])

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
    groupby([:condition, :freq, :rove, :n_comp, :subj, :hl, :hl_group])

    # Fit logistic function to data
    @combine(:fit = fit_psychometric_function(:increment, :pcorr))

    # Extract slope and threshold
    @transform(:threshold = getindex.(getfield.(:fit, ^(:param)), 1))
    @transform(:slope = getindex.(getfield.(:fit, ^(:param)), 2))
end

# Plot correlations between HL and threshold
plt =
    (
        # Thresholds versus HL scatter plot
        data(df_fitted) * mapping(
            :hl,
            :threshold,
            color = :hl_group => sorter("< 5 dB HL", "5-15 dB HL", "> 15 dB HL") => "Threshold @ CF",
        ) * visual(Scatter) +
        data(df_fitted) * mapping(:hl, :threshold) * linear()
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
    )
fig = draw(plt;
    axis=(
        width=400,
        height=200,
        xlabel="Threshold @ CF (dB HL)",
        ylabel="Threshold (dB SRS)",
        xticks=[0, 20, 40, 60, 80],
        yticks=[-20, -10, 0, 10],
    #    limits=((-23, 23), (0.25, 1.05)),
    ),
)
tempsave(fig)
cl_save(plotsdir("correlations_with_hl.png"), fig)
