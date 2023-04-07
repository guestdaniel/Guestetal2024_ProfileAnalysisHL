using CSV
using DataFrames
using DataFramesMeta
using Statistics
using Chain
using CairoMakie
df = CSV.read(datadir("int_pro", "data_postproc.csv"), DataFrame)

# Compute average HL in each frequency condition
summary_hl = @chain df begin
    groupby([:freq, :subj])
    @combine(:hl = mean(:hl))
    groupby(:freq)
    @combine(
        :μ = mean(:hl),
        :σ = std(:hl),
        :min = minimum(:hl),
        :max = maximum(:hl),
        :med = median(:hl),
        :iqr_low = quantile(:hl, 0.25),
        :iqr_high = quantile(:hl, 0.75),
    )
end

# Plot audiogram figures
summary_hl = @chain df begin
    groupby([:freq, :subj])
    @combine(:hl = mean(:hl))
end
fig = Figure()
ax = Axis(fig[1, 1])
for (idx_freq, freq) in enumerate(sort(unique(summary_hl.freq)))
    sub = @subset(summary_hl, :freq .== freq)
    scatter!(ax, repeat([idx_freq], length(sub.hl)) .+ rand(length(sub.hl)) .* 0.1, sub.hl)
end
fig