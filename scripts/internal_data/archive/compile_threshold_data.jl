n_workers_target = 1
using Pkg; Pkg.activate(Base.current_project());
using DataFramesMeta
using DataFrames
using CSV
using LsqFit

### Fit all thresholds together
df = DataFrame(CSV.File("/home/daniel/cl_data/pahi/clean/pahi1.csv"))
@. logistic_fit(x, p) = logistic(x, p[1], p[2]; L=0.5, offset=0.5)
fitted_data = @chain df begin
    # Preprocess by averaging data in each condition for each listener across runs
    groupby([:delta_l, :n_comp, :freq, :subj, :rove])
    @combine(
        :pcorr = mean(:pcorr)
    )
    # Fit thresholds to data
    groupby([:n_comp, :freq, :subj, :rove])
    @combine(
        :fit = curve_fit(
            logistic_fit,
            :delta_l,
            :pcorr,
            [0.0, 1.0],
            lower=[-25.0, 0.01],
            upper=[20.0, 10.0]
        )
    )
    # Extract thresholds and slopes from fits
    @transform(
        :threshold = getindex.(getfield.(:fit, ^(:param)), 1),
        :slope = getindex.(getfield.(:fit, ^(:param)), 2),
    )
    @select(:n_comp, :freq, :subj, :rove, :threshold)
end
CSV.write(joinpath(datadir(), "int_pro", "thresholds.csv"), fitted_data)

### Fit only NH thresholds
df = DataFrame(CSV.File("/home/daniel/cl_data/pahi/clean/pahi1.csv"))
@. logistic_fit(x, p) = logistic(x, p[1], p[2]; L=0.5, offset=0.5)
fitted_data = @chain df begin
    # Filter out data where hl > 20
    @subset(:hl .< 20.0)
    # Preprocess by averaging data in each condition for each listener across runs
    groupby([:delta_l, :n_comp, :freq, :subj, :rove])
    @combine(
        :pcorr = mean(:pcorr)
    )
    # Fit thresholds to data
    groupby([:n_comp, :freq, :subj, :rove])
    @combine(
        :fit = curve_fit(
            logistic_fit,
            :delta_l,
            :pcorr,
            [0.0, 1.0],
            lower=[-25.0, 0.01],
            upper=[20.0, 10.0]
        )
    )
    # Extract thresholds and slopes from fits
    @transform(
        :threshold = getindex.(getfield.(:fit, ^(:param)), 1),
        :slope = getindex.(getfield.(:fit, ^(:param)), 2),
    )
    @select(:n_comp, :freq, :subj, :rove, :threshold)
end
CSV.write(joinpath(datadir(), "int_pro", "thresholds_NH.csv"), fitted_data)
