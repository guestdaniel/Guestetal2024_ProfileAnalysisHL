using Pkg
Pkg.activate(Base.current_project())
using CSV
using DataFrames
using DataFramesMeta
using CairoMakie
using AlgebraOfGraphics
using CarneyLabUtils
using Colors

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Setup
cd(projectdir())
df = DataFrame(CSV.File("data/ext_pro/all_data.csv"))

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]

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
        smooth() # +
    )
fig = draw(plt;
    axis=(
        width=300"/home/daniel/cl_code/pahi",
        height=150,
        xlabel="Spacing (ST)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_spacing.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing, fancy lines
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]
temp = @subset(temp, :experiment .!= "Green, Kidd, and Picardi (1983), Figure 4")
temp = temp[.!((temp.freq .!= 1000.0) .& (temp.experiment .== "PAHI-1")), :]
temp = temp[.!((temp.freq .!= 1000.0) .& (temp.experiment .== "Bernstein and Green (1987), Figure 2")), :]
temp[!, :condition] .= "none"

# Add condition tags
function get_condition(row)
    if row.experiment == "PAHI-1"
        return "PAHI-" * string(row.freq) * "_" * row.rove
    elseif row.experiment == "Lentz, Richards, and Matiasek (1999), Figure 2"
        return "Lentz-1"
    elseif row.experiment == "Green, Kidd, and Picardi (1983), Figure 4"
        return "Green1983-" * string(row.n_comp)
    elseif row.experiment == "Green and Mason (1985), Figure 3"
        return "Green1985-1"
    elseif row.experiment == "Bernstein and Green (1987), Figure 2"
        return "Bernstein-" * string(row.freq)
    end
end
for idx in 1:nrow(temp)
    temp[idx, :condition] = get_condition(temp[idx, :])
end
colors = vcat(
    colormap("Reds", 4)[2:end],
#    colormap("Reds", 5)[2:end],
    colormap("Greens", 3)[2],
    colormap("Grays", 3)[2],
    colormap("Purples", 6)[2:end]
)

# Generate plot
temp = @orderby(temp, :spacing_st)
plt =
    data(@subset(temp, :experiment .!= "PAHI-1")) *
    (
        mapping(:spacing_st, :threshold, color=:condition, marker=:hearing_status) *
        (visual(Scatter) + visual(Lines))
    ) +
    data(@subset(temp, :experiment .== "PAHI-1")) *
    (
        mapping(:spacing_st, :threshold, color=:condition, marker=:hearing_status, col=:hearing_status) *
        (visual(Scatter; markersize=15) + visual(Lines; linewidth=4))
    ) +
    data(@subset(temp, :experiment .== "PAHI-1")) *
    (
        mapping(:spacing_st, :threshold, :error, color=:condition, marker=:hearing_status, col=:hearing_status) *
        (visual(Errorbars))
    )
# +
#    data(@subset(temp, :experiment .!= "PAHI-1")) *
#    (
#        mapping(:spacing_st, :threshold, marker=:hearing_status) *
#        (smooth(; span=0.9, degree=2))
#    )
fig = draw(plt;
    axis=(
        xscale=log10,
        width=450,
        height=500,
        xlabel="Spacing (ST)",
        ylabel="Threshold (dB SRS)",
        xticks=[0.1, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]
    ),
    palettes=(
        color=colors,
    )
)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_spacing_adv.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing
# F ilter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .== "PAHI-1")
temp[!, :condition] .= string.(temp.freq) .* "_" .* temp.rove

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold, color=:condition) *
        (visual(Scatter) + visual(Lines)) # +
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
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_spacing_ours_only.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing, colored by bandwidth
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold, color=:bandwidth) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold) *
        smooth() # +
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
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_spacing_and_bandwidth.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing (on linear scale), colored by bandwidth
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]

# Generate plot
plt =
    data(@orderby(temp, :spacing_hz)) *
    (
        mapping(:spacing_hz, :threshold, color=:bandwidth) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :spacing_hz)) *
    (
        mapping(:spacing_hz, :threshold) *
        smooth()
    )
fig = draw(plt;
    axis=(
        xscale=log10,
        width=300,
        height=150,
        xlabel="Spacing (Hz)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_linspacing_and_bandwidth.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing vs bandwidth
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]

# Generate plot
plt =
    data(temp) *
    (
        mapping(:spacing_st => (t -> t ./ 12), :bandwidth, color=:threshold, marker=:experiment) *
        (visual(Scatter)) # +
    )
fig = draw(plt;
    axis=(
#        yscale=log10,
        width=300,
        height=150,
        xlabel="Spacing (oct)",
        ylabel="Bandwidth (oct)",
    ),
)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_spacing_and_bandwidth_2d.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of component spacing, grouped by wide/narrow band
# Filter out irrelevant datasets
temp = copy(df)
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 1")
temp = @subset(temp, :experiment .!= "Green and Mason (1985), Figure 2")
temp = temp[.!((temp.pedestal_level_re_background .!= 0.0) .& (temp.experiment .== "Green and Kidd (1983), Figure 2")), :]
temp[!, :bandwidth_group] .= temp.bandwidth .> 3.0

# Generate plot
plt =
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold, color=:bandwidth_group) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :spacing_st)) *
    (
        mapping(:spacing_st, :threshold, color=:bandwidth_group) *
        smooth(; span=0.90, degree=1) # +
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
### Plot effect of bandwidth
# Generate plot
plt =
    data(@orderby(df, :bandwidth)) *
    (
        mapping(:bandwidth, :threshold, color=:experiment) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :bandwidth)) *
    (
        mapping(:bandwidth, :threshold) *
        smooth() # +
    )
fig = draw(plt;
    axis=(
        width=300,
        height=150,
        xlabel="Bandwidth (oct)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of bandwidth, colored by spacing
# Generate plot
plt =
    data(@orderby(df, :bandwidth)) *
    (
        mapping(:bandwidth, :threshold, color=:spacing_st) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :bandwidth)) *
    (
        mapping(:bandwidth, :threshold) *
        smooth() # +
    )
fig = draw(plt;
    axis=(
        width=300,
        height=150,
        xlabel="Bandwidth (oct)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot effect of frequency
temp = @subset(
    df,
    (:experiment .== "Green and Mason (1985), Figure 1") .|
    (:experiment .== "Green and Mason (1985), Figure 2") .|
    (:experiment .== "Bernstein and Green (1987), Figure 2")
)
plt =
    data(@orderby(temp, :freq)) *
    (
        mapping(:freq, :threshold, color=:experiment, marker=:bandwidth => (t -> nonnumeric(round(t; digits=2)))) *
        (visual(Scatter)) # +
    ) +
    data(@orderby(temp, :freq)) *
    (
        mapping(:freq, :threshold, color=:experiment) *
        smooth(; span=0.85, degree=2) # +
    )
fig = draw(plt;
    axis=(
        xscale=log2,
        width=300,
        height=150,
        xlabel="Target frequency (Hz)",
        ylabel="Threshold (dB SRS)",
    ),
)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/meta_frequency.png", fig)
