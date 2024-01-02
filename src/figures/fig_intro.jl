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

    # Create audiogram Figure
    set_theme!()
    fig = Figure(; resolution=(600, 450))
    ax = Axis(fig[1, 1]; xscale=log10)
    for idx in 1:nrow(audiograms)
        # Extract thresholds
        θ = Vector(audiograms[idx, 4:12])
        
        # Plot black lines and colored points to indicate HL group
        freqs = [250.0, 500.0, 1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]
        jitter = randn(length(θ)) ./ 30
        freqs = freqs .* 2 .^ (jitter)
        lines!(
            ax, 
            freqs,
            θ,
            color=:black,
        )
        scatter!(
            ax, 
            freqs,
            θ,
            color=color_group.(θ),
        )
    end

    # Loop through 0.5, 1, 2 and 4 kHz to add subject counts above audiograms
    for (freq, idx) in zip([0.5e3, 1e3, 2e3, 4e3], [5, 6, 8, 10])
        # Subset audiogram data
        sub = audiograms[:, idx]
        θ_1 = mean(sub[sub .< 5])
        n_1 = sum(sub .< 5)
        θ_2 = mean(sub[5 .<= sub .<= 15])
        n_2 = sum(5 .<= sub .<= 15)
        θ_3 = mean(sub[sub .> 15])
        n_3 = sum(sub .> 15)
        text!(ax, [freq * 2^(-0.05)], [-31.0]; text="n=$n_1", color=color_group(1), align=(:right, :center))
        text!(ax, [freq * 2^(-0.05)], [-25.0]; text="n=$n_2", color=color_group(2), align=(:right, :center))
        text!(ax, [freq * 2^(-0.05)], [-19.0]; text="n=$n_3", color=color_group(3), align=(:right, :center))

        text!(ax, [freq * 2^(0.05)], [-31.0]; text="$(round(θ_1; digits=1))", color=color_group(1), align=(:left, :center))
        text!(ax, [freq * 2^(0.05)], [-25.0]; text="$(round(θ_2; digits=1))", color=color_group(2), align=(:left, :center))
        text!(ax, [freq * 2^(0.05)], [-19.0]; text="$(round(θ_3; digits=1))", color=color_group(3), align=(:left, :center))
    end

    # Set limits, labels, ticks, etc.
    ylims!(ax, 110.0, -35.0)
    ax.xticks = [0.25e3, 0.5e3, 1e3, 2e3, 4e3, 8e3]
    ax.yticks = 0.0:20.0:100.0
    ax.xlabel = "Frequency (Hz)"
    ax.ylabel = "Audiometric threshold (dB HL)"
    fig
end