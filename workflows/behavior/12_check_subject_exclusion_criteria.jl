using CSV
using DataFrames
using DataFramesMeta
using Statistics
using Chain
using CairoMakie
df = CSV.read(datadir("int_pro", "data_postproc.csv"), DataFrame)

# Compute average HL in each frequency condition
summary = @chain df begin
    groupby([:freq, :subj])
    @combine(
        :hl = mean(:hl),
    )
    @transform(:threshold_spl = hl_to_spl.(:hl, :freq))
    @transform(:warning = :threshold_spl .> 60.0)
    @orderby(:subj, :freq)
end

warnings = map([500, 1000, 2000, 4000]) do freq
    summary[summary.freq .== freq, :warning]
end

fig = Figure()
ax = Axis(fig[1, 1])
heatmap!(ax, 1:4, 1:21, transpose(hcat(warnings...)))
ax.yticks = (1:21, summary[summary.freq .== 500, :subj])
ax.xticks = (1:4, string.([500, 1000, 2000, 4000]))
fig
