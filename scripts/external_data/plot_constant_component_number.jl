using Pkg
Pkg.activate(Base.current_project())
using CSV
using DataFrames
using DataFramesMeta
using CairoMakie
using AlgebraOfGraphics
using CarneyLabUtils
using Colors
using Distributions
using Random

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Setup
cd("/home/daniel/cl_code/pahi")
df = DataFrame(CSV.File("data/ext_pro/all_data.csv"))

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# Filter to only include datasets we want
temp = @subset(
    df,
    (:experiment .== "Green, Kidd, and Picardi (1983), Figure 4") .|
    (:experiment .== "Green and Mason (1985), Figure 3") .|
    (
        (:experiment .== "Bernstein and Green (1987), Figure 2") .&
        (:freq .== 1000.0)
    )
)


# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(
            :spacing_st,
            :bandwidth,
            marker=:n_comp => nonnumeric,
            color=:threshold,
        ) *
        (visual(Scatter)) # +
    )# +
#    data(@orderby(temp, :spacing_st)) *
#    (
#        mapping(:spacing_st, :threshold) *
#        smooth() # +
#    )
fig = draw(plt;
    axis=(
        width=300,
        height=150,
        xlabel="Spacing (semitones)",
        ylabel="Bandwidth (octaves)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# Filter to only include datasets we want
temp = @subset(
    df,
    (:experiment .== "Green, Kidd, and Picardi (1983), Figure 4") .|
    (:experiment .== "Green and Mason (1985), Figure 3") .|
    (
        (:experiment .== "Bernstein and Green (1987), Figure 2") .&
        (:freq .== 1000.0)
    )
)
temp[!, :bandwidth_group] .= "none"
temp[(temp.bandwidth .> 0.0) .& (temp.bandwidth .<= 1.0), :bandwidth_group] .= "0-1 oct"
temp[(temp.bandwidth .> 1.0) .& (temp.bandwidth .<= 3.0), :bandwidth_group] .= "1-3 oct"
temp[(temp.bandwidth .> 3.0) .& (temp.bandwidth .<= 5.0), :bandwidth_group] .= "3-5 oct"

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(
            :spacing_st,
            :threshold,
            color=:bandwidth_group,
        ) *
        (visual(Scatter)) # +
    )# +
#    data(@orderby(temp, :spacing_st)) *
#    (
#        mapping(:spacing_st, :threshold) *
#        smooth() # +
#    )
fig = draw(plt;
    axis=(
        width=300,
        height=150,
        xlabel="Spacing (semitones)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# Filter to only include datasets we want
temp = @subset(
    df,
    (:experiment .== "Green, Kidd, and Picardi (1983), Figure 4") .|
    (:experiment .== "Green and Mason (1985), Figure 3") .|
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
        mapping(
            :spacing_st,
            :threshold,
            color=:bandwidth,
        ) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold) *
        smooth(; span=0.9) # +
    )
fig = draw(plt;
    axis=(
        width=250,
        height=200,
        xlabel="Spacing (semitones)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of bandwidth
# Filter to only include datasets we want
temp = @subset(
    df,
    (:experiment .== "Green, Kidd, and Picardi (1983), Figure 4") .|
    (:experiment .== "Green and Mason (1985), Figure 3") .|
    (:experiment .== "Lentz, Richards, and Matiasek (1999), Figure 2") .|
    (
        (:experiment .== "Bernstein and Green (1987), Figure 2") .&
        (:freq .== 1000.0)
    )
)

# Jitter only points beyond 4 octaves
n_pt_to_jitter = length(temp[temp.bandwidth .> 4.0, :bandwidth])
temp[temp.bandwidth .> 4.0, :bandwidth] .+= rand(Uniform(-0.1, 0.1), 18)

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(
            :bandwidth,
            :threshold,
            color=:spacing_st,
        ) *
        (visual(Scatter)) # +
    )# +
#    data(@orderby(temp, :spacing_st)) *
#    (
#        mapping(:spacing_st, :threshold) *
#        smooth() # +
#    )
fig = draw(plt;
    axis=(
        width=250,
        height=200,
        xlabel="Bandwidth (octaves)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)
