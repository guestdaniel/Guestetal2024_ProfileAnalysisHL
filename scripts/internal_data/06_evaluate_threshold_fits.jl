using Pkg; Pkg.activate(Base.current_project());
using DataFramesMeta
using DataFrames
using CSV
using LsqFit
using Statistics
using ProfileAnalysis
using CairoMakie

### Load raw data and fitted thresholds
df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))
thresholds = DataFrame(CSV.File(joinpath(datadir(), "int_pro", "thresholds.csv")))
@. logistic_fit(x, p) = pahi.logistic(x, p[1], p[2]; L=0.5, offset=0.5)

### Loop through each extracted threshold and compare data to fit
for row in eachrow(thresholds)
    # Extract data and process data
    df_ind = @chain df begin
        @subset(:subj .== row.subj)
        @subset(:rove .== row.rove)
        @subset(:n_comp .== row.n_comp)
        @subset(:freq .== row.freq)
    end

    df_avg = @chain df_ind begin
        groupby([:increment])
        @combine(:pcorr = mean(:pcorr))
    end

    # Create prediction df
    df_pred = DataFrame(increment=LinRange(-40.0, 20.0, 400))
    df_pred[!, :pcorr] = logistic_fit(df_pred.increment, [row.threshold, row.slope])

    # Create figure
    fig = Figure(; resolution=(350, 350))
    ax = Axis(fig[1, 1])
    ax.xlabel = "Increment (dB SRS)"
    ax.ylabel = "Proportion correct"
    ylims!(ax, 0.4, 1.1)
    xlims!(ax, -32, 22)
    ax.xticks = -30:5:20
    ax.yticks = 0.5:0.1:1.0
    hlines!(ax, [0.5, 1.0]; color=:red)

    # Plot data
    lines!(ax, df_pred.increment, df_pred.pcorr; color=:gray)
    scatter!(ax, df_avg.increment, df_avg.pcorr; color=:black, markersize=15.0)
    scatter!(ax, df_ind.increment, df_ind.pcorr; color=:blue, markersize=8.0, marker=:rect)
    Label(fig[0, 1], "Subj $(row.subj) / $(row.freq) Hz / $(row.rove) / $(row.n_comp)", tellwidth=false)

    # Save to disk
    fig
    save(
        "plots/diagnostic/thresholds/" * "$(row.subj)_$(row.freq)_$(row.rove)_$(row.n_comp)" * ".png", 
        fig
    )
end
