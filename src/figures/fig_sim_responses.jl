export genfig_sim_responses_main, fetch_pattern, _plot_sim!

"""
    genfig_sim_responses_main_stackplot

Plot response patterns for all conditions and models using the "stackplot" strategy from 
Maxwell et al. (2020). Each curve at different increment sizes will be visualized as a line
with the vertical offset indicating the increment. The height of each line will indicate 
the percent change in rate, while color of markers will indicate the significance of that 
change as a z-score.
"""
function genfig_sim_responses_main()
    # Configure parameters that vary within each panel 
    increments=[-20.0, -10.0, 0.0]

    # Configure parameters that need to be faceted within each subpanel
    n_comps = [5, 13, 21, 29, 37]
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]

    # Confiugre other parameters
    rove_size = 10.0
    offset_factor = 50.0
    cs = reverse(colorschemes[:roma])
    clims = (-3.0, 3.0)

    # Configure parameters that produce separate subplots
    model_ids = [1, 2, 3, 4]

    # Do each plot, looping over different models
    set_theme!(theme_carney; fontsize=10.0)
    figs = map(model_ids) do model_id
        # Set up figure
        fig = Figure(; resolution=(350, 350))
        axs = [Axis(fig[i, j]; xgridvisible=false, ygridvisible=false, yminorticksvisible=false) for i in 1:length(n_comps), j in 1:length(center_freqs)]

        # Loop through n_comp and center_freq
        for (idx_n_comp, n_comp) in enumerate(n_comps)
            for (idx_freq, center_freq) in enumerate(center_freqs)
                # Fetch axis 
                ax = axs[idx_n_comp, idx_freq]

                # Plot indicators at harmonic frequencies
                freqs = log2.(LogRange(center_freq/5, center_freq*5, n_comp) ./ center_freq)
                vlines!(ax, freqs; color=:lightgray, linewidth=0.5, linestyle=:solid)

                # Loop through increments
                for (idx_increment, increment) in enumerate(increments)
                    # Load responses
                    cf, r1, r2 = fetch_pattern(; 
                        center_freq=center_freq, 
                        model_id=model_id, 
                        n_comp=n_comp, 
                        increment=increment, 
                        rove_size=rove_size,
                    )
                    cf = log2.(cf ./ center_freq)

                    # Compute response metric (difference in rate normalized to reference rate)
                    δ = map(x -> x[2] .- x[1], zip(r1, r2))  # compute trial-wise differences
                    ref = mean(r1)                           # compute average of standard responses
                    δ = map(x -> x ./ ref .* 100, δ)         # compute percentage change on each trial re: average of standard
                    μ = mean(δ)                              # compute mean across trials
                    σ = std(δ)                               # compute std across trials

                    # Plot
                    lines!(
                        ax, 
                        cf, 
                        idx_increment * offset_factor .+ μ;
                        color=:lightgray, 
                        linewidth=1.0,
                    )

                    # Plot
                    scatter!(
                        ax, 
                        cf, 
                        idx_increment * offset_factor .+ μ;
                        color=get(cs, μ ./ σ, clims), 
                        markersize=4.0,
                    )
                end

                # Adjust ticks
                ylims!(ax, 0.0, offset_factor * length(increments) + 1.5*offset_factor)
                xlims!(ax, -1.0, 1.0)
                ax.yticks = (
                    offset_factor:offset_factor:(length(increments)*offset_factor),
                    string.(increments),
                )
                ax.xticks = ([-0.5, 0.0, 0.5], ["−1/2", "0", "1/2"])
            end
        end

        # Adjust
        Label(fig[1:5, 0], "Increment size (dB SRS)"; tellheight=false, rotation=π/2)
        Label(fig[6, 1:4], "CF (oct re: target frequency)"; tellwidth=false)
        neaten_grid!(axs)
        rowgap!(fig.layout, Relative(0.02))
        colgap!(fig.layout, Relative(0.02))
        fig
    end

    # Return
    return figs
end


"""
    genfig_sim_responses_main

Plot response patterns for all conditions and models
"""
function genfig_sim_responses_main()
    # Configure parameters that vary within each panel 
    increments=[-20.0, -10.0, 0.0]

    # Configure parameters that need to be faceted within each subpanel
    n_comps = [5, 13, 21, 29, 37]
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]

    # Configure parameters that produce separate subplots
    model_ids = [1, 2, 3, 4]

    # Set up colors 
    colors_unroved = range(HSL(270.0, 0.0, 0.8), HSL(270.0, 0.0, 0.3); length=(length(increments)))
    colors_roved = range(HSL(200.0, 0.5, 0.8), HSL(200.0, 0.5, 0.3); length=(length(increments)))
    colors = ColorSchemes.Set1_9

    # Do each plot, looping over different models
    set_theme!(theme_carney; fontsize=10.0)
    figs = map(model_ids) do model_id
        # Set up figure
        fig = Figure(; resolution=(350, 350))
        axs = [Axis(fig[i, j]) for i in 1:length(n_comps), j in 1:length(center_freqs)]

        # Loop through n_comp and center_freq
        for (idx_n_comp, n_comp) in enumerate(n_comps)
            for (idx_freq, center_freq) in enumerate(center_freqs)
                # Fetch axis 
                ax = axs[idx_n_comp, idx_freq]

                # Plot indicators at harmonic frequencies
                freqs = log2.(LogRange(center_freq/5, center_freq*5, n_comp) ./ center_freq)
                vlines!(ax, freqs; color=:lightgray, linewidth=0.5, linestyle=:dash)

                # Loop through increments and rove sizes
                for (colorset, rove_size) in zip([colors], [10.0])
                    for (increment, c) in zip(increments, colorset)
                        # Load responses
                        cf, r1, r2 = fetch_pattern(; 
                            center_freq=center_freq, 
                            model_id=model_id, 
                            n_comp=n_comp, 
                            increment=increment, 
                            rove_size=rove_size,
                        )
                        cf = log2.(cf ./ center_freq)

                        # Compute response metric (difference in rate normalized to reference rate)
                        δ = map(x -> x[2] .- x[1], zip(r1, r2))
                        ref = mean(r1)
                        δ = map(x -> x ./ ref .* 100, δ)
                        μ = mean(δ)
                        σ = std(δ)

                        # Plot
#                        band!(ax, cf, μ .- σ, μ .+ σ; color=(c, 0.20))
                        lines!(ax, cf, μ .- σ; color=(c, 0.20), linewidth=0.4)
                        lines!(ax, cf, μ .+ σ; color=(c, 0.20), linewidth=0.4)
                        lines!(ax, cf, μ; color=c, linewidth=1.25)
                    end
                end

                # Adjust ticks
                ylims!(ax, -100.0, 100.0)
                xlims!(ax, -1.0, 1.0)
                ax.yticks = -50.0:50.0:50.0
                ax.xticks = ([-0.5, 0.0, 0.5], ["−1/2", "0", "1/2"])
            end
        end

        # Adjust
        Label(fig[1:5, 0], "Change in rate (%)"; tellheight=false, rotation=π/2)
        Label(fig[6, 1:4], "CF (oct re: target frequency)"; tellwidth=false)
        neaten_grid!(axs)
        rowgap!(fig.layout, Relative(0.02))
        colgap!(fig.layout, Relative(0.02))
        fig
    end

    # Return
    return figs
end

function fetch_pattern(; 
    center_freq=1000.0, 
    model_id=1,
    n_comp=5,
    increment=-10.0, 
    rove_size=0.001,
)
    # Choose experiment
    experiment = ProfileAnalysis_PFTemplateObserver()
    models = Utilities.setup(experiment, center_freq)
    model = models[model_id]

    # Make stimuli
    stim_ref = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=-Inf), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size)
    )
    stim_tar = RovedStimulus(
        ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=increment), 
        n_rep_trial; 
        rove_params=[:pedestal_level], 
        rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size)
    )
    # Construct a string to disambiguate different repeats of -Inf dB SRS
    tag = "matched_to_$(id(stim_tar[1]))"

    # Compute memoized
    p1 = AvgPattern(; stimuli=stim_ref, model=model, tag=tag)
    p2 = AvgPattern(; stimuli=stim_tar, model=model)

    # Compute memoized
    r1 = @memo Default() simulate(p1)
    r2 = @memo Default() simulate(p2)

    # Return 
    return model.cf, r1, r2
end

