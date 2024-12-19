export genfig_sim_psychometric_functions_profiles,
       genfig_sim_psychometric_functions_colorbar,
       genfig_sim_psychometric_functions_rate_curves

"""
    genfig_sim_psychometric_functions_profiles

Plot example "profiles" for all tested auditory models
"""
function genfig_sim_psychometric_functions_profiles()
    # Set up plot
    increments=[-999.9, -20.0, -10.0, 0.0]
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(430, 130))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Add indicators for harmonic frequencies
    freqs = log2.(LogRange(1000.0/5, 1000.0*5, 21) ./ 1000.0)
    [arrows!(
        ax, 
        freqs,
        repeat([4.0], length(freqs)),
        repeat([0.0], length(freqs)),
        repeat([-0.5], length(freqs)); 
        color=:lightgray,
        arrowsize=4.0,
    ) for ax in axs]
    [xlims!(ax, -1.0, 1.0) for ax in axs]

    # Set up colors 
    cmap_periphe = range(HSL(270.0, 0.0, 0.8), HSL(270.0, 0.0, 0.3); length=length(increments))

    # Fetch models
    models = setup(ProfileAnalysis_AvgPatterns(), 1000.0)

    # Do each plot
    for (idx, inc) in enumerate(increments)
        for (ax, model) in zip(axs, models)
            _plot_sim!(ax, profiles_prep_sims(inc, model)...; color=cmap_periphe[idx])
        end
    end

    # Adjust
    axs[1].ylabel = "Normalized Δ rate"
    Label(fig[2, 2:3], "CF (oct re: target frequency)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))

    # Return
    return fig
end

function profiles_prep_model(fiber_type::String; center_freq=1000.0)
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, cf=LogRange(center_freq/2, center_freq*2, 91), fractional=true)
    return model
end

function profiles_prep_model(modeltype::DataType, params::Dict; center_freq=1000.0)
    frontend = AuditoryNerveZBC2014(; cf=LogRange(center_freq/2, center_freq*2, 91), fractional=true)
    model = modeltype(; frontend=frontend, params...)
    return model
end

function profiles_prep_sims(increment, model::Model; center_freq=1000.0, n_comp=21)
    # Choose experiment
    exp = ProfileAnalysis_AvgPatterns()

    # Set up simulations
    sim1 = setup(exp, model, -Inf, center_freq, n_comp)
    sim2 = setup(exp, model, increment, center_freq, n_comp)

    # Run simulations
    out1 = @memo Default() simulate(sim1)
    out2 = @memo Default() simulate(sim2)

    # Return
    log2.(model.cf ./ center_freq), out2 .- out1
end

function _plot_sim!(ax, cf, r; color=:black)
    μ = mean(r)
    σ = std(r)
    lines!(ax, cf, μ ./ σ; color=color)
    ylims!(ax, -5.0, 5.0)
end

"""
    genfig_sim_psychometric_functions_colorbar

Make colorbar for previous plot
"""
function genfig_sim_psychometric_functions_colorbar()
    # Render colorbars manually and save
    fig = Figure(; resolution=(50, 135))
    cb = Colorbar(fig[1, 1]; limits=(0, 1), colormap=cgrad(range(HSL(270.0, 0.0, 0.8), HSL(270.0, 0.0, 0.3); length=4); categorical=true))
    cb.ticks = ((1/(4*2)):(2/(4*2)):(1.0 - 1/(4*2)), vcat("-Inf", string.(Int.([-20.0, -10.0, 0.0]))))
    fig
end

"""
    genfig_sim_psychometric_functions_rate_curves()

Plot "rate curves" depicting decision variable response as function of increment size
"""
function genfig_sim_psychometric_functions_rate_curves(mode="singlechannel"; config=Default())
    # Set up experiment
    increments=vcat(-999.9, -45.0:2.5:5.0)
    exp = ProfileAnalysis_AvgPatterns()

    # Set up plot
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=4.0, ))
    fig = Figure(; resolution=(300, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [xlims!(ax, -40.0, 10.0) for ax in axs]
#    [ax.xticks = (-25.0:5.0:0.0, vcat("-Inf", string.(Int.(-20.0:5.0:0.0)))) for ax in axs]

    # Fetch models 
    models = setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Calculate CFs and middle index
        cf = log2.(model.cf ./ 1000.0)
        idx = Int(round(length(cf)/2))

        # Construct simulations and run
        out = map(increments) do increment
            # Construct reference and target trial simulations
            ref, tar = setup_pair(exp, model, increment, 1000.0, 21)

            # Load/run sims 
            out_ref = @memo config simulate(ref)
            out_tar = @memo config simulate(tar)

            # Depending on mode, preprocess 
            if mode == "profilechannel"
                out_ref = map(out_ref) do x
                    x .- mean(x)
                end
                out_tar = map(out_tar) do x
                    x .- mean(x)
                end
            elseif mode == "templatebased"
                template = setup(ProfileAnalysis_Templates(), model, 1000.0, 21)
                out_template = @memo config simulate(template)
                μ = mean(out_template)
                Σ = cov(out_template)
            end
            
            # Depending on mode, either return differences or distances
            if (mode == "profilechannel") | (mode == "singlechannel")
                out = map(zip(out_ref, out_tar)) do (r, t)
                    t .- r
                end
                return [x[idx] for x in out]
            else
                out = map(out_tar) do t
                    mahalanobis(μ, Σ, t)
                end
                return out
            end
        end

        # Depending on mode, either transform to z-score and plot or plot 
        if (mode == "profilechannel") | (mode == "singlechannel")
            μ = map(x -> mean(x)/std(x), out)
            band!(ax, increments, repeat([-1.0], length(increments)), repeat([1.0], length(increments)); color=:lightgray)
            hlines!(ax, [0.0]; color=:black, linewidth=1.0)
            scatter!(ax, increments, μ; color=:black)
            lines!(ax, increments, μ; color=:black)
        else
            μ = map(x -> mean(x), out)
            err = std(x[1])
            band!(ax, increments, fill(μ[1] - err, length(μ)), fill(μ[1] + err, length(μ)); color=:lightgray)
            hlines!(ax, [0.0]; color=:black, linewidth=1.0)
            scatter!(ax, increments, μ; color=:black)
            lines!(ax, increments, μ; color=:black)
        end
    end

    # Adjust
    if (mode == "singlechannel") | (mode == "profilechannel")
        [ylims!(ax, -3.0, 3.0) for ax in axs]
    else
        [ylims!(ax, 0.0, 25.0) for ax in axs]
    end
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    [ax.xticklabelrotation = π/2 for ax in axs]
    axs[1].ylabel = mode == "templatebased" ? "Mahalanobis dist." : "Normalized Δ rate"
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
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))
    fig = Figure(; resolution=(300, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pf = setup(exp, model, increments, 1000.0, 21; observer=obs)
        out = @memo Default() simulate(pf)

        # Summarize data
        μ = map(mean, out)
        σ = map(x -> sqrt((mean(x) * (1 - mean(x)))/length(x)), out)
        mod = fit(pf, increments[2:end], out[2:end])

        # Plot
        viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    [xlims!(ax, -45.0, 5.0) for ax in axs]
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
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))
    fig = Figure(; resolution=(300, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pf = setup(exp, model, increments, 1000.0, 21; observer=obs, preprocessor=pre_emphasize_profile)
        out = @memo Default() simulate(pf)

        # Summarize data
        μ = map(mean, out)
        σ = map(x -> sqrt((mean(x) * (1 - mean(x)))/length(x)), out)
        mod = fit(pf, increments[2:end], out[2:end])

        # Plot
        viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    [xlims!(ax, -45.0, 5.0) for ax in axs]
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
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))
    fig = Figure(; resolution=(300, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Grab models
    models = setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        pf = setup(
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
        mod = fit(pf, increments[2:end], out[2:end])

        # Plot
        viz!(exp, ax, increments, μ, σ, mod)
    end

    # Neaten up
    axs[1].ylabel = "Proportion correct"
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end