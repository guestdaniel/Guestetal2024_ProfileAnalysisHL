export genfig_zeta_c1_psychometric_functions,
       genfig_zeta_c2_psychometric_functions,
       genfig_zeta_c3_psychometric_functions

function genfig_eta_b1_rate_curves(increments=[-20.0, -15.0, -10.0, -5.0], config::Config=Default())
    # Set up experiment
    exp = ProfileAnalysis_AvgPatterns()

    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(360, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [xlims!(ax, -30.0, 3.0) for ax in axs]
    [ax.xticks = (-25.0:5.0:0.0, vcat("-Inf", string.(Int.(-20.0:5.0:0.0)))) for ax in axs]

    # Fetch models 
    models = setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models[1:1])
        # Calculate CFs and middle index
        cf = log2.(model.cf ./ 1000.0)
        idx = Int(round(length(cf)/2))

        # Construct simulations and run
        out = map(increments) do increment
            ref = setup(exp, model, -Inf, 1000.0, 21)
            tar = setup(exp, model, increment, 1000.0, 21)
            sim = DeltaPattern(; pattern_1=ref, pattern_2=tar)
            out = @memo config simulate(sim)
            [x[idx] for x in out]
        end

        # Preprocess to transform into z-scored rates
        μ = map(x -> mean(x)/std(x), out)

        # Plot results
        hlines!(ax, [0.0]; color=:black, linewidth=1.0)
        scatter!(ax, increments, μ; color=:black)
        lines!(ax, increments, μ; color=:black)
    end

    # Adjust
    [ylims!(ax, -5.0, 5.0) for ax in axs]
    [ax.xticklabelrotation = π/2 for ax in axs]
    axs[1].ylabel = "Normalized Δ rate"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_zeta_c1_psychometric_functions(increments=vcat(-999.9, -45.0:2.5:5.0))
    # Set experiment
    exp = ProfileAnalysis_PFObserver()

    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(360, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = Utilities.setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pf = Utilities.setup(exp, model, increments, 1000.0, 21; observer=obs)
        out = @memo Default() simulate(pf)

        # Summarize data
        μ = map(mean, out)
        σ = map(x -> sqrt((mean(x) * (1 - mean(x)))/length(x)), out)
        mod = Utilities.fit(pf, increments[2:end], out[2:end])

        # Plot
        Utilities.viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_zeta_c2_psychometric_functions(increments=vcat(-999.9, -45.0:2.5:5.0))
    # Set experiment
    exp = ProfileAnalysis_PFObserver()

    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(360, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = Utilities.setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pf = Utilities.setup(
            exp, 
            model, 
            increments, 
            1000.0, 
            21; 
            observer=obs, 
            preprocessor=pre_emphasize_profile
        )
        out = @memo Default() simulate(pf)

        # Summarize data
        μ = map(mean, out)
        σ = map(x -> sqrt((mean(x) * (1 - mean(x)))/length(x)), out)
        mod = Utilities.fit(pf, increments[2:end], out[2:end])

        # Plot
        Utilities.viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_zeta_c3_psychometric_functions(increments=vcat(-999.9, -45.0:2.5:5.0))
    # Set experiment
    exp = ProfileAnalysis_PFTemplateObserver()

    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(360, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = Utilities.setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        pf = Utilities.setup(
            exp, 
            model, 
            increments, 
            1000.0, 
            21; 
        )
        out = @memo Default() simulate(pf)

        # Summarize data
        μ = map(mean, out)
        σ = map(x -> sqrt((mean(x) * (1 - mean(x)))/length(x)), out)
        mod = Utilities.fit(pf, increments[2:end], out[2:end])

        # Plot
        Utilities.viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end
