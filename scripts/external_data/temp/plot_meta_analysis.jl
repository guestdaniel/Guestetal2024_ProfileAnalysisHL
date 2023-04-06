using Pkg
Pkg.activate(Base.current_project())
using CSV
using DataFrames
using DataFramesMeta
using CairoMakie
using AlgebraOfGraphics
using Colors

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Setup
df = DataFrame(CSV.File("data/ext_pro/profile_analysis_guestoxenham2023.csv"))
df[!, :spacing_oct] = df.spacing_st ./ 12

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Extract, clean, and join relevant datasets
green1985 = df[df.experiment .== "Green and Mason (1985), Figure 3", :]
bernstein1987 = df[(df.experiment .== "Bernstein and Green (1987), Figure 2") .& (df.freq .== 1000.0), :]
lentz1999 = df[df.experiment .== "Lentz, Richards, and Matiasek (1999), Figure 2", :]
df_comb = vcat(green1985, bernstein1987, lentz1999)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Generate plot
fig = Figure(; resolution=(500, 400))
ax = Axis(fig[1, 1], xscale=log10)
xtickvals = [1/8, 1/4, 1/2, 1]
xticklabs = ["1/8", "1/4", "1/2", "1"]
ax.xticks = (xtickvals, xticklabs)
ax.xlabel = "Component spacing (octaves)"
ax.ylabel = "Threshold (dB SRS)"
for (idx_dataset, dataset) in enumerate(unique(df_comb.experiment))
    df_subset = @subset(df_comb, :experiment .== dataset)
    df_subset = @orderby(df_subset, :spacing_oct)
    scatter!(ax, df_subset.spacing_oct, df_subset.threshold)
    lines!(ax, df_subset.spacing_oct, df_subset.threshold)
end
fig