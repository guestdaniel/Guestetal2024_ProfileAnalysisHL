# validate_subject_screen.jl
#
# This script is designed to analyze available psychophysical data to determine which 
# listeners are included in which conditions

using DataFrames
using DataFramesMeta
using Chain
using CSV
using CairoMakie

# Load behavioral data
df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

# Select subjects and conditions to analyze
subjs = unique(df.subj)
freqs = [500, 1000, 2000, 4000]
results = zeros(length(subjs), length(freqs))

# Loop through all and check
counts = map(subjs) do subj
    map(freqs) do freq
        nrow(@subset(df, :subj .== subj, :freq .== freq, :rove .== "fixed level")) - 75
    end
end
counts = hcat(counts...)

# Make figure
fig = Figure()
ax = Axis(fig[1, 1])
hm = heatmap!(ax, counts; colorrange=(-25, 25), colormap=:RdBu)
Colorbar(fig[1, 2], hm)
for idx_subj = 1:length(subjs)
    for idx_freq = 1:length(freqs)
        text!(
            ax, 
            [idx_freq], 
            [idx_subj]; 
            text="$(counts[idx_freq, idx_subj])",
            align=(:center, :center),
        )
    end
end
ax.yticks = (1:length(subjs), subjs)
ax.ylabel = "Subj ID"
ax.xticks = (1:length(freqs), string.(freqs))
ax.xlabel = "Frequency"
fig
save("test.png", fig)