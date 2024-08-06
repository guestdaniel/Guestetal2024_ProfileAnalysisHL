export genfig_subj_audiograms
function genfig_subj_audiograms()
    # Load in master post-processed data frame
    df = CSV.read(datadir("int_pro", "data_postproc.csv"), DataFrame)
    subjs = unique(df.subj)

    # Load in raw subject audiograms
    audiograms = CSV.read(datadir("int_pro", "audiometry.csv"), DataFrame)

    # Manually correct label for S98 -> S098
    audiograms[audiograms.Subject .== "S98", :Subject] .= "S098"

    # Filter audiograms to only contain subjects we tested in profile analysis
    audiograms = @subset(audiograms, in.(:Subject, Ref(subjs)))

    # Add PTA column
    pta = map(eachrow(audiograms)) do row
        mean(row[[5, 6, 8, 10]])
    end
    audiograms[!, :pta] .= pta

    # Create audiogram Figure
    set_theme!()
    fig = Figure(; resolution=(600, 450))
    ax = Axis(fig[1, 1]; xscale=log10)
    for idx in 1:nrow(audiograms)
        # Extract thresholds
        freqs = [250.0, 500.0, 1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]
        θ = Vector(audiograms[idx, 4:12])
        pta = Float64(audiograms[idx, :pta])

        # Determine color based on thresholds
        if pta > 25.0
            color = :red
        elseif (mean(θ[freqs .<= 2000.0]) < 25.0) && (mean(θ[freqs .> 2000.0]) >= 25.0)
            color = :black
        else
            color = :black 
        end
        
        # Plot black lines and colored points to indicate HL group
        jitter = randn(length(θ)) ./ 30
        freqs = freqs .* 2 .^ (jitter)
        lines!(
            ax, 
            freqs,
            θ,
            color=color,
        )
        scatter!(
            ax, 
            freqs,
            θ,
            color=color,
        )
    end

   # Set limits, labels, ticks, etc.
    ylims!(ax, 110.0, -20.0)
    ax.xticks = [0.25e3, 0.5e3, 1e3, 2e3, 4e3, 8e3]
    ax.yticks = 0.0:20.0:100.0
    ax.xlabel = "Frequency (Hz)"
    ax.ylabel = "Audiometric threshold (dB HL)"
    fig
end