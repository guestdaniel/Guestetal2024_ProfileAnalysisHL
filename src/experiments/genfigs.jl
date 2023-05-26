export genfig_zeta_c1_psychometric_functions,
       genfig_zeta_c2_psychometric_functions,
       genfig_zeta_c3_psychometric_functions

function genfig_zeta_c1_psychometric_functions(increments=vcat(-Inf, -30.0:5.0:5.0))
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

function genfig_zeta_c2_psychometric_functions(increments=vcat(-Inf, -30.0:5.0:5.0))
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

function genfig_zeta_c3_psychometric_functions(increments=vcat(-Inf, -30.0:5.0:5.0))
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
