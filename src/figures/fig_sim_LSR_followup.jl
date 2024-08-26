export θ_energy,
       genfig_sim_bowls_puretonecontrol_LSR_only, # Figure 8A
       genfig_followup_puretonecontrol,           # Figure 8B
       genfig_puretonecontrol_rl_functions,       # Figure 8C
       genfig_puretonecontrol_mechanism           # Figure 8D

"""
    θ_energy(increments, n)

Estimate threshold based on selecting interval with higher-level target component

Estimates a threshold for the profile-analysis task with a roved level under the assumptions
that: 
    - The observer selects the interval with the higher target-component sound level as
    the target interval on each trial
    - The observer has perfect estimation of target-component sound level, so the only 
    factor limiting performance in the level rove
"""
function θ_energy(increments=-20.0:0.5:20.0, n=5000)
    # Loop through each increment (in dB SRS)
    pcorr = map(increments) do inc
        # Sample from distribution for roved overall levels 2xn times 
        lvls_ref = rand(Uniform(60.0, 80.0), n)  # sample for reference intervals
        lvls_tar = rand(Uniform(60.0, 80.0), n)  # sample (independently) for target intervals

        # Add level increment to target levels
        lvls_tar .= lvls_tar .+ srs_to_ΔL(inc)

        # Compute the proportion of correct responses for each of n simulated trials
        mean(lvls_tar .> lvls_ref)
    end

    # Return the threshold at the 75% correct point on the psychometric function
    return increments[findfirst(x -> x > 0.75, pcorr)]
end

"""
    genfig_sim_bowls_puretonecontrol_LSR_only()

Generate figure depicting behavior vs LSR model performance, incl. pure-tone control 

Generate figure depicting "bowls" in different frequency conditions for the LSR
single-channel decoder. Data are plotted as in previous "bowl" figures, except that 
a red line indicating the output of `θ_energy()` is added and gray diamonds are added in 
between each bowl to indiate that target-frequency's "pure-tone control" in which 
psychometric functions were estimated for a profile-analysis stimulus with no maskers.
This figure is the top left of Figure 8.
"""
function genfig_sim_bowls_puretonecontrol_LSR_only()
    # Get full dataframe of simulated thresholds, subset to include only roved LSR single-channel
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:adjusted .== false, :model .== "AuditoryNerveZBC2014_low", :mode .== "singlechannel", :rove_size .== 10.0)
    end

    # Load single-component control simulations, subset to include only LSR single-channel
    df_control = @chain load_simulated_thresholds_puretone() begin
        @subset(:model .== "AuditoryNerveZBC2014_low", :mode .== "singlechannel", :rove_size .== 10.0)
    end

    # Run simulation to quickly assess where performance would be under energy-based 
    # decisions with roving
    θ_e = θ_energy()

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(300, 200))
    ax = Axis(fig[1, 1]; xticklabelrotation=π/2, xminorticksvisible=false, xticklabelsize=9.0)

    # Plot red-dashed control line for θ_energy
    hlines!(ax, [θ_e]; color=:red, linestyle=:dash)

    # Plot each bowl + PT control threshold
    map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
        # Subset by target frequency
        sims_roved = @subset(df, :center_freq .== freq)
        sims_control_roved = @subset(df_control, :center_freq .== freq)

        # Plot data
        scatter!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
        lines!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
        scatter!(ax, [(idx-1)*8], sims_control_roved.θ; color=:darkgray, marker=:diamond, markersize=10.0)

    end

    # Manually set xticks and labels
    ax.xticks = (
        vcat([(1:5) .+ (i-1)*8 .+ 1 for i in 1:4]...),
        repeat(["5", "13", "21", "29", "37"], 4),
    )

    # Set y-axis limits and ticks
    ylims!(ax, -35.0, 20.0)
    ax.yticks = -30.0:10.0:10.0
    
    # Add axis labels
    ax.ylabel = "Threshold (dB SRS)"
    ax.xlabel = "Number of components // Target frequency (Hz)"

    # Return
    fig
end

"""
    genfig_followup_puretonecontrol()

Generate figure depicting histograms of target levels vs histograms of LSR rates

Generate figure depicting histograms of target-component levels (left) or LSR rates at the
target channel (right) for reference (gray) and target (red) stimuli. Depicted as a "stack"
of histograms arranged vertically according to the underlying increment size. Markers
beneath each depict means and standard deviations. This figure is the bottom left of Figure
8.
"""
function genfig_followup_puretonecontrol()
    # We need to compare a distribution of observed target levels to a distribution of 
    # observered LSR target rates to convince ourselves that LSR rates can really outperform
    # energy-based decisions

    # Set random seeds
    seed = 949349302050240
    rng = Xoshiro(seed) 
    config = Default(; seed=seed, rng=rng, resolve_rng=true, resolve_codename=true, codename="puretonecontrol")

    # Pick params
    n = 1000
    n_comp = 21
    incs = -20.0:2.5:10.0

    # Configure model
    results = map(incs) do inc
        model = AuditoryNerveZBC2014(; cf=[2000.0], fiber_type="low")

        # First, pick distribution of levels
        levels_ref = rand(config.rng, Uniform(60.0, 80.0), n)
        levels_tar = rand(config.rng, Uniform(60.0, 80.0), n)

        # Next, synthesize stimuli
        stim_ref = map(x -> ProfileAnalysisTone(; center_freq=2e3, pedestal_level=x, increment=-1000.0, n_comp=n_comp), levels_ref)
        stim_tar = map(x -> ProfileAnalysisTone(; center_freq=2e3, pedestal_level=x, increment=inc, n_comp=n_comp), levels_tar)

        # Create AvgPattern
        sim_ref = AvgPattern(; model=model, stimuli=stim_ref)
        sim_tar = AvgPattern(; model=model, stimuli=stim_tar)

        # Simulate with memoization
        resp_ref = @memo config simulate(sim_ref)
        resp_tar = @memo config simulate(sim_tar)

        # Return
        return (getindex.(resp_ref, 1), levels_ref), (getindex.(resp_tar, 1), levels_tar) 
    end

    # Each element in `results` above is a tuple of tuples. The first sub-element is a tuple
    # containing a vector of N average rates in the target channel for a profile-analysis
    # standard stimulus and a vector of N corresponding target sound levels. The second
    # sub-element is the same, except for target stimuli. Each element corresponds to one of
    # the target increments specified in `incs`

    # Create figure
    fig = Figure(; resolution=(500, 500))
    ax_levels = Axis(fig[1, 1]; yminorticksvisible=false)
    ax_rates = Axis(fig[1, 2]; yminorticksvisible=false)

    # Set some figure parameters
    offset_y = 0.15  # vertical offset between each density kernel histogram
    alpha = 0.5     # alpha setting for all colors

    # Map through results and plot each
    map(enumerate(zip(incs, results))) do (idx, (inc, result))
        # Unpack data
        (μ_ref, l_ref), (μ_tar, l_tar) = result

        # Add figure for levels
        density!(ax_levels, l_ref; offset=offset_y*(idx-1), color=RGBA(0.0, 0.0, 0.0, alpha))
        density!(ax_levels, l_tar .+ srs_to_ΔL(inc); offset=offset_y*(idx-1), color=RGBA(1.0, 0.0, 0.0, alpha))
        density!(ax_rates, μ_ref; offset=offset_y*(idx-1), color=RGBA(0.0, 0.0, 0.0, alpha))
        density!(ax_rates, μ_tar; offset=offset_y*(idx-1), color=RGBA(1.0, 0.0, 0.0, alpha))

        # Demarcate mean and +/- 1 SD
        scatter!(ax_levels, [mean(l_ref)], [offset_y*(idx-1) - offset_y*0.1]; color=RGBA(0.0, 0.0, 0.0, alpha))
        scatter!(ax_levels, [mean(l_tar) + srs_to_ΔL(inc)], [offset_y*(idx-1) - offset_y*0.1]; color=RGBA(1.0, 0.0, 0.0, alpha))
        scatter!(ax_rates, [mean(μ_ref)], [offset_y*(idx-1) - offset_y*0.1]; color=RGBA(0.0, 0.0, 0.0, alpha))
        scatter!(ax_rates, [mean(μ_tar)], [offset_y*(idx-1) - offset_y*0.1]; color=RGBA(1.0, 0.0, 0.0, alpha))

        # Demarcate mean and +/- 1 SD
        errorbars!(ax_levels, [mean(l_ref)], [offset_y*(idx-1) - offset_y*0.1], [std(l_ref)]; color=RGBA(0.0, 0.0, 0.0, alpha), direction=:x)
        errorbars!(ax_levels, [mean(l_tar) + srs_to_ΔL(inc)], [offset_y*(idx-1) - offset_y*0.1], [std(l_tar .+ srs_to_ΔL(inc))]; color=RGBA(1.0, 0.0, 0.0, alpha), direction=:x)
        errorbars!(ax_rates, [mean(μ_ref)], [offset_y*(idx-1) - offset_y*0.1], [std(μ_ref)]; color=RGBA(0.0, 0.0, 0.0, alpha), direction=:x)
        errorbars!(ax_rates, [mean(μ_tar)], [offset_y*(idx-1) - offset_y*0.1], [std(μ_tar)]; color=RGBA(1.0, 0.0, 0.0, alpha), direction=:x)

        # Demarcate significance (based on d' >= 1)
        d′_level = (mean(l_tar) - mean(l_ref)) / sqrt(1/2 * (var(l_tar) + var(l_ref)))
        d′_rate = (mean(μ_tar) - mean(μ_ref)) / sqrt(1/2 * (var(μ_tar) + var(μ_ref)))

        if abs(d′_level) >= 1.0
            text!(ax_levels, [mean(l_ref)], [offset_y*(idx-1) - offset_y*0.12]; text="*", fontsize=20.0, align=(:center, :top))
        end

        if abs(d′_rate) >= 1.0
            text!(ax_rates, [mean(μ_ref)], [offset_y*(idx-1) - offset_y*0.12]; text="*", fontsize=20.0, align=(:center, :top))
        end
    end
    
    # Handle labels and ticks
    ax_levels.yticks = 0.0:(offset_y*1.0):(offset_y*(length(results)-1)), string.(incs)
    ax_levels.xticks = 60.0:10.0:90.0
    ax_levels.ylabel = "Increment (dB SRS)"
    ax_levels.xlabel = "Target component level (dB SPL)"

    ax_rates.yticks = 0.0:(offset_y*1.0):(offset_y*(length(results)-1))
    ax_rates.xticks = 20.0:10.0:70.0
    ax_rates.xlabel = "LSR average rate (sp/s)"
    neaten_grid!([ax_levels, ax_rates])

    # Return fig
    fig
end

"""
    genfig_puretonecontrol_rl_functions()

Generate figure comparing rate-level functions with and without flanking suppressors

Depicts a rate-level function for the LSR model using an isolated pure tone (black) versus a
pure tone with 70 dB SPL flankers above and below in frequency spaced by 1/2 octave (pink).
Is the upper right of Figure 8.
"""
function genfig_puretonecontrol_rl_functions()
    # Set baseline parameters
    cf = 2000.0    # cf and tone frequency (Hz)
    fs = 100e3     # sampling rate (Hz)
    dur = 0.1      # duration (s)
    level_pedestal = 70.0  # overall level of flanker stimulus, without component
    n_comp = 21    # number of components in flanker + 1 (i.e., incl target)

    # Set RL function parameters
    levels = 30.0:2.5:90.0

    # Set up model
    model = AuditoryNerveZBC2014(; cf=[cf], fractional=false, fs=fs, fiber_type="low")

    # Map over levels and simulate RL function w/o flankers
    rl_pure = map(levels) do level
        # Synthesize stim and simulate average rate
        stim = scale_dbspl(pure_tone(cf, 0.0, dur, fs), level)
        mean(compute(model, stim)[1])
    end

    # Map over levels and simulate RL function w/ flankers
    freqs = LogRange(cf/5, cf*5, n_comp)  # calculate frequencies for this condition
    target_comp=Int(ceil(length(freqs)/2))
    background = map(freqs) do freq  # synthesize background complex
        freq == freqs[target_comp] ? zeros(Int(round(dur*fs))) : pure_tone(freq, 0.0, dur, fs)
    end
    background = sum(background)
    background = scale_dbspl(background, level_pedestal)
    rl_flanked = map(levels) do level
        # Synthesize stim 
        stim = scale_dbspl(pure_tone(cf, 0.0, dur, fs), level)

        # Compute rate
        mean(compute(model, stim .+ background)[1])
    end

    # Plot
    set_theme!(theme_carney; fontsize=12.0)
    fig = Figure(; resolution=(300, 260))
    ax = Axis(fig[1, 1]; xminorticksvisible=false)
    vlines!(ax, [total_to_comp(level_pedestal, n_comp)]; color=:gray, linestyle=:dash, linewidth=1.0)
    lines!(ax, levels, rl_pure; color=:black, linewidth=3.0)
    lines!(ax, levels, rl_flanked; color=:pink, linewidth=3.0)

    # Adjust labels
    ax.xlabel = "Probe level (dB SPL)"
    ax.ylabel = "Average rate (sp/s)"
    ax.xticks = 10.0:10.0:90.0
    ax.yticks = 0.0:25.0:100.0

    # Adjust limits
    ylims!(ax, 0.0, 100.0)

    fig
end

"""
    genfig_puretonecontrol_mechanism()

Depicting "enhancement" of increment response in LSR model due to presence of suppressors

Depicts size of the "increment response" for 0 dB SRS increment as a function of flanker
level (x-axis) and probe-flanker spacing in octaves (color). Quantified in terms of % change
relative to the increment response in the absence of suppressors. Is the bottom right of
Figure 8.
"""
function genfig_puretonecontrol_mechanism()
    # Set baseline parameters
    cf = 2000.0    # cf and tone frequency (Hz)
    level_pedestal = 70.0  # pedestal level
    fs = 100e3     # sampling rate (Hz)
    dur = 0.1      # duration (s)

    # Set flanker parameters
    n_comps = [5, 13, 21, 29, 37]
    levels_srs = -20.0:2.5:20.0

    # Set up model
    model = AuditoryNerveZBC2014(; cf=[cf], fractional=false, fs=fs, fiber_type="low")

    # Simulate differences with flankers
    results = map(n_comps) do n_comp
        map(levels_srs) do srs
            # Calculate freqs
            freqs = LogRange(cf/5, cf*5, n_comp)  # calculate frequencies for this condition

            # Simulate pure-tone at this SRS
            iso_1 = profile_analysis_tone([cf]; pedestal_level=level_pedestal, dur=dur, increment=-Inf, fs=fs)
            iso_2 = profile_analysis_tone([cf]; pedestal_level=level_pedestal, dur=dur, increment=srs, fs=fs)
            iso_δ = mean(compute(model, iso_2)[1]) - mean(compute(model, iso_1)[1])

            # Simulate PA tone at this SRS
            complex_1 = profile_analysis_tone(freqs; pedestal_level=level_pedestal, dur=dur, increment=-Inf, fs=fs)
            complex_2 = profile_analysis_tone(freqs; pedestal_level=level_pedestal, dur=dur, increment=srs, fs=fs)
            complex_δ = mean(compute(model, complex_2)[1]) - mean(compute(model, complex_1)[1])

            return 100 * (complex_δ - iso_δ) / iso_δ
        end
    end

    # Create figure
    colors = ColorSchemes.Dark2_6[[1, 2, 3, 4, 6]]
    set_theme!(theme_carney; fontsize=12.0)
    fig = Figure(; resolution=(350, 350))
    ax = Axis(fig[1, 1])
    lns = map(zip(results, colors)) do (r, color)
        # Check if line ever goes below 0 --- if so, plot portion below as dotted, otherwise just plot it
        if any(r .< 0.0)
            # Isolate portion above and below zero
            temp_above = r[r.>= 0.0]
            levels_above = levels_srs[r .>= 0.0]
            temp_below = r[r .< 0.0]
            levels_below = levels_srs[r .< 0.0]

            lines!(ax, levels_above, temp_above; linewidth=2.0, linestyle=:solid, color=color)
            lines!(ax, levels_below, temp_below; linewidth=2.0, linestyle=:dash, color=color)
        else
            lines!(ax, levels_srs, r; linewidth=2.0, color=color)
        end
    end
#    hlines!(ax, [0.0]; color=:black, linewidth=3.0)
    ylims!(ax, 0.0, 200.0)
    xlims!(ax, -25.0, 25.0)

    ax.xlabel = "Increment size (dB SRS)"
    ax.ylabel = "Increment response\nre: response w/o flankers (%)"
    ax.yticks = 0.0:50.0:150.0
    ax.xticks = -20:10:20

    Legend(fig[2, 1], lns, string.(n_comps), "Component count"; orientation=:horizontal)

    fig
end

