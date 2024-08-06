using ProfileAnalysis
using DataFramesMeta
using DataFrames
using CSV
using LsqFit
using Statistics

# Fit all thresholds together
df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))
fitted_data = @chain df begin
    # Preprocess by averaging data in each condition for each listener across runs
    groupby([:increment, :n_comp, :freq, :subj, :rove, :age, :sex, :hl, :hl_group, :pta_all, :pta_3, :pta_4, :sl, :condition, :include])
    @combine(
        :pcorr = mean(:pcorr)
    )
    # Fit thresholds to data
    groupby([:n_comp, :freq, :subj, :rove, :age, :sex, :hl, :hl_group, :pta_all, :pta_3, :pta_4, :sl, :condition, :include])
    @combine(:fit = fit_psychometric_function(:increment, :pcorr))

    # Extract thresholds and slopes from fits
    @transform(
        :threshold = getindex.(getfield.(:fit, ^(:param)), 1),
        :slope = getindex.(getfield.(:fit, ^(:param)), 2),
    )
    @select(:n_comp, :freq, :subj, :rove, :threshold, :slope, :age, :hl_group, :sex, :hl, :pta_all, :pta_3, :pta_4, :sl, :condition, :include)
end

# Save output
CSV.write(joinpath(datadir(), "int_pro", "thresholds.csv"), fitted_data)
