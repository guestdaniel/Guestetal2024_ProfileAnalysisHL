using CSV
using DataFrames
using DataFramesMeta
using CairoMakie
using CarneyLabUtils

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Set wd
cd("/home/daniel/cl_code/pahi")

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Green and Kidd (1983), Figure 2
# Load
df = DataFrame(CSV.File("data/ext_pro/Green1983a_Fig2.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xminorticksvisible=true)
ax.xlabel = "Pedestal level re: background level"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = -18:6:24
ax.yticks = -18:4:18
xlims!(ax, -20, 26)
ylims!(ax, -20, 20)
Label(fig[0, 1], "Green and Kidd (1983), Figure 2"; textsize=30, tellwidth=false)

# Plot data
df = @orderby(df, :n_comp)
lns = map(unique(df.n_comp)) do n_comp
    temp = @subset(df, :n_comp .== n_comp)
    lines!(ax, temp.pedestal_level_re_background, temp.threshold)
end
Legend(fig[1, 2], lns, string.(unique(df.n_comp)), "Number of components")
cl_save("/home/daniel/cl_fig/pahi/behavior/Green1983a_Fig2.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Green1983b
# Load
df = DataFrame(CSV.File("data/ext_pro/Green1983b_Fig4.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=true)
ax.xlabel = "Component spacing (multiple of 1.0116 ratio)"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [1, 2, 5, 10, 20, 40, 80]
ax.yticks = [-20, -15, -10, -5, 0, 5]
ax.xminorticks = [4, 5, 6, 7, 8, 9, 30, 50, 60, 70, 90]
ylims!(ax, -22, 7)
xlims!(ax, 0.8, 100)
Label(fig[0, 1], "Green, Kidd, and Picardi, Figure 4"; textsize=30, tellwidth=false)

# Add secondary axis
ax2 = Axis(fig[1, 1]; xscale=log10, xaxisposition=:top)
hidespines!(ax2)
hideydecorations!(ax2)
ax2.xticks = (
    [1, 2, 5, 10, 20, 40, 80],
    string.(Int.(round.(1/2 * (1000.0 .- 1000.0 ./ (1.0116 .^ [1, 2, 5, 10, 20, 40, 80]) .+ 1000.0 .* (1.0116 .^ [1, 2, 5, 10, 20, 40, 80]) .- 1000.0))))
)
ax2.xminorticks = [4, 5, 6, 7, 8, 9, 30, 50, 60, 70, 90]
xlims!(ax2, 0.8, 100)

# Plot data
lns = map(unique(df.n_comp)) do n_comp
    ss = @subset(df, :n_comp .== n_comp)
    lines!(ax, ss.spacing_au, ss.threshold)
end

# Add legend
Legend(fig[1, 2], lns, string.([3, 5, 11, 21]), "# Components")
#tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Green1983b_Fig4.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Green (1985), Figure 1
# Load
df = DataFrame(CSV.File("data/ext_pro/Green1985_Fig1.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=true)
ax.xlabel = "Signal frequency (Hz)"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [200, 1000, 5000]
ax.yticks = -25:5:0
ax.xminorticks = [200, 300, 400, 500, 600, 700, 800, 900, 2000, 3000, 4000]
ylims!(ax, -28, 3)
xlims!(ax, 180, 5200)
Label(fig[0, 1], "Green and Mason (1985), Figure 1"; textsize=30, tellwidth=false)

# Plot data
lines!(ax, df.freq, df.threshold)
#tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Green1985_Fig1.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Green (1985), Figure 2
# Load
df = DataFrame(CSV.File("data/ext_pro/Green1985_Fig2.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=true)
ax.xlabel = "Signal frequency (Hz)"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [200, 1000, 5000]
ax.yticks = -25:5:10
ax.xminorticks = [200, 300, 400, 500, 600, 700, 800, 900, 2000, 3000, 4000]
ylims!(ax, -28, 13)
xlims!(ax, 180, 5200)
Label(fig[0, 1], "Green and Mason (1985), Figure 2"; textsize=30, tellwidth=false)

# Plot data
lines!(ax, df.freq, df.threshold)
#tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Green1985_Fig2.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Green (1985), Figure 3
# Load
df = DataFrame(CSV.File("data/ext_pro/Green1985_Fig3.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, yminorticksvisible=true)
ax.xlabel = "Number of components"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [5, 11, 21, 43]
ax.yticks = [-20.0, -15.0, -10.0, -5.0]
ax.yminorticks = [-17.5, -12.5, -7.5]
ylims!(ax, -23, -3)
Label(fig[0, 1], "Green and Mason (1985), Figure 3"; textsize=30, tellwidth=false)

# Plot data
lines!(ax, df.n_comp, df.threshold)
#tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Green1985_Fig3.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Bernstein (1987), Figure 2
# Load
df = DataFrame(CSV.File("data/ext_pro/Bernstein1987_Fig2.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=true)
ax.xlabel = "Number of components"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [3, 10, 81]
ax.xminorticks = [4, 5, 6, 7, 8, 9, 20, 30, 40, 50, 60, 70, 80]
ax.yticks = -30:5:5
ylims!(ax, -32, 7)
Label(fig[0, 1], "Bernstein and Green (1987), Figure 2"; textsize=30, tellwidth=false)

# Plot data
lns = map(unique(df.freq)) do freq
    temp = @subset(df, :freq .== freq)
    lines!(ax, temp.n_comp, temp.threshold)
end
Legend(fig[1, 2], lns, string.(unique(df.freq)), "Frequency (Hz)")
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Bernstein1987_Fig2.png", fig)

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Plot Lentz (1999), Figure 2
# Load
df = DataFrame(CSV.File("data/ext_pro/Lentz1999_Fig2.csv"))

# Construct figure
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, xminorticksvisible=true)
ax.xlabel = "Number of components"
ax.ylabel = "Threshold (dB SRS)"
ax.xticks = [4, 10, 60]
ax.xminorticks = [4, 5, 6, 7, 8, 9, 20, 30, 40, 50]
ax.yticks = -25:5:-5
xlims!(ax, 3, 65)
ylims!(ax, -27, -3)
Label(fig[0, 1], "Lentz, Richards, and Matiasek (1999), Figure 2"; textsize=30, tellwidth=false)

# Plot data
lines!(ax, df.n_comp, df.threshold)
tempsave(fig)
cl_save("/home/daniel/cl_fig/pahi/behavior/Lentz1999_Fig2.png", fig)
