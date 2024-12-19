using CairoMakie
using CSV
using AuditorySignalUtils

# Load audiograms, grab only needed rows, and transform into Audiogram objects
subjs = unique(fetch_behavioral_data().subj
audiograms = DataFrame(CSV.File("C:\\Users\\dguest2\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"))
audiograms[audiograms.Subject .== "S98", :Subject] .= "S098"
audiograms = @subset(audiograms, in.(:Subject, Ref(subjs)))
audiograms = map(subjs) do subj
    # Subset row
    row = audiograms[audiograms.Subject .== subj, :]

    # Select frequencies and thresholds
    f = [250.0, 500.0, 1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]
    θ = Vector(row[1, 4:12])

    # Combine into Audiogram objects
    Audiogram(; freqs=f, thresholds=θ, species="human", desc=subj)
end

# Turn into models and plot COHC
models = map(audiograms) do audiogram
    AuditoryNerveZBC2014(; cf=LogRange(250.0, 20e3, 200), audiogram=audiogram)
end

# Plot all cohc curves
fig = Figure()
ax = Axis(fig[1, 1]; xscale=log10, yscale=log10)
map(models) do model
    lines!(ax, model.cf, max.(0.001, model.cohc))
    text!(ax, [22e3], [max(0.001, model.cohc[end])]; text=model.audiogram.desc, align=(:left, :center))
end
xlims!(ax, 200.0, 30e3)
ax.xticks = [500.0, 1000.0, 2000.0, 4000.0]
fig