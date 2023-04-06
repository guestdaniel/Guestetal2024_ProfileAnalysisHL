using Pkg
Pkg.activate(Base.current_project())
using Loess
using CSV
using DataFrames
using DataFramesMeta

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Setup
cd("/home/daniel/cl_code/pahi")
df = DataFrame(CSV.File("data/ext_pro/all_data.csv"))
span = 0.8

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# Filter out irrelevant datasets
temp = @subset(
    df,
#    (:experiment .== "Green, Kidd, and Picardi (1983), Figure 4") .|
#    (:experiment .== "Green and Mason (1985), Figure 3") .|
    (:experiment .== "Lentz, Richards, and Matiasek (1999), Figure 2") .|
    (
        (:experiment .== "Bernstein and Green (1987), Figure 2") .&
        (:freq .== 1000.0)
    )
)

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold, color=:experiment) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold) *
        smooth(; span=span) # +
    )
fig = draw(plt;
    axis=(
        width=300,
        height=150,
        xlabel="Spacing (ST)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Estimate relation between component spacing and threshold
# Filter to only include datasets we want
model = loess(temp.spacing_st, temp.threshold, span=span)
cl_save("/home/daniel/cl_code/pahi/data/ext_pro/loess_spacing_threshold.jld2", Dict("model" => model))
