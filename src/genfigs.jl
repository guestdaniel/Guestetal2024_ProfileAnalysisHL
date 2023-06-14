export genfig_eta_b1_rate_curves,
       genfig_eta_b2_rate_curves,
       genfig_eta_b3_rate_curves,
       genfig_zeta_c1_psychometric_functions,
       genfig_zeta_c2_psychometric_functions,
       genfig_zeta_c3_psychometric_functions,
       genfig_theta_bowls,
       genfig_theta_bowl_1kHz_vs_data,
       genfig_theta_bowl_1kHz_vs_data_free,
       genfig_theta_freq_bowls_summary,
       genfig_theta_freq_bowls_summary_free

# Figure Η
# Figure Η has a variety of very different subplots, each implemented as different functions (listed below). The top panel shows example z-score rates for a 21-component, 1-kHz stimulus. The bottom left panel shows the decision variables that enter into the psychometric function estimation procedure in the different models. The bottom right panel shows the corresponding estimated psychometric function.
# - genfig_eta_rate_curves: TODO, fix, ind -> comb
# - genfig_eta_psychometric_functions: TODO, fix zeta -> eta
function genfig_eta_b1_rate_curves(increments=vcat(-999.9, -45.0:2.5:5.0), config::Config=Default())
    # Set up experiment
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
            ref = setup(exp, model, -Inf, 1000.0, 21)
            tar = setup(exp, model, increment, 1000.0, 21)
            sim = DeltaPattern(; pattern_1=ref, pattern_2=tar)
            out = @memo config simulate(sim)
            [x[idx] for x in out]
        end

        # Preprocess to transform into z-scored rates
        μ = map(x -> mean(x)/std(x), out)

        # Plot results
        band!(ax, increments, repeat([-1.0], length(increments)), repeat([1.0], length(increments)); color=:lightgray)
        hlines!(ax, [0.0]; color=:black, linewidth=1.0)
        scatter!(ax, increments, μ; color=:black)
        lines!(ax, increments, μ; color=:black)
    end

    # Adjust
    [ylims!(ax, -3.0, 3.0) for ax in axs]
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    [ax.xticklabelrotation = π/2 for ax in axs]
    axs[1].ylabel = "Normalized Δ rate"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_eta_b2_rate_curves(increments=vcat(-999.9, -45.0:2.5:5.0), config::Config=Default())
    # Set up experiment
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
            ref = setup(exp, model, -Inf, 1000.0, 21)
            tar = setup(exp, model, increment, 1000.0, 21)

            # Load/run sims and normalize by subtracting mean across channels from each response
            out_ref = @memo config simulate(ref)
            out_ref = map(out_ref) do x
                x .- mean(x)
            end
            out_tar = @memo config simulate(tar)
            out_tar = map(out_tar) do x
                x .- mean(x)
            end

            # Return difference outputs
            out = map(zip(out_ref, out_tar)) do (r, t)
                t .- r
            end
            [x[idx] for x in out]
        end

        # Preprocess to transform into z-scored rates
        μ = map(x -> mean(x)/std(x), out)

        # Plot results
        band!(ax, increments, repeat([-1.0], length(increments)), repeat([1.0], length(increments)); color=:lightgray)
        hlines!(ax, [0.0]; color=:black, linewidth=1.0)
        scatter!(ax, increments, μ; color=:black)
        lines!(ax, increments, μ; color=:black)
    end

    # Adjust
    [ylims!(ax, -3.0, 3.0) for ax in axs]
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    [ax.xticklabelrotation = π/2 for ax in axs]
    axs[1].ylabel = "Normalized Δ rate"
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_eta_b3_rate_curves(increments=vcat(-999.9, -45.0:2.5:5.0), config::Config=Default())
    # Set up experiment
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

        # Get template
        template = setup(ProfileAnalysis_Templates(), model, 1000.0, 21)
        out_template = @memo config simulate(template)
        μ = mean(out_template)
        Σ = cov(out_template)

        # Construct simulations and run
        out = map(increments) do increment
            # Construct reference and target trial simulations
            tar = setup(exp, model, increment, 1000.0, 21)

            # Load/run sims 
            out_tar = @memo config simulate(tar)

            # Return difference outputs
            map(out_tar) do t
                mahalanobis(μ, Σ, t)
            end
        end

        # Preprocess to transform into means of the distances
        μ = map(mean, out)
        σ = map(std, out)

        # Plot results
        band!(ax, increments, repeat([μ[1] - σ[1]], length(increments)), repeat([μ[1] + σ[1]], length(increments)); color=:lightgray)
        hlines!(ax, [0.0]; color=:black, linewidth=1.0)
        scatter!(ax, increments, μ; color=:black)
        lines!(ax, increments, μ; color=:black)
    end

    # Adjust
    [ylims!(ax, 0.0, 25.0) for ax in axs]
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    [ax.xticklabelrotation = π/2 for ax in axs]
    axs[1].ylabel = "Mahalanobis dist."
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
    models = Utilities.setup(exp, 1000.0)

    # Do each plot, on-CF coding
    for (ax, model) in zip(axs, models)
        # Simulate psychometric function
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pf = Utilities.setup(exp, model, increments, 1000.0, 21; observer=obs, preprocessor=pre_emphasize_profile)
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
    [xlims!(ax, -45.0, 5.0) for ax in axs]
    Label(fig[2, 2:3], "Increment (dB SRS)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

# Figure Θ
# Figure Θ depicts the "executive summary" of the modeling, and bonus/extra/full results are also shown in a Figure Θ supplemental. In the main-text figure, the top panel depicts so-called "bowls" from the model vs behavior. The middle(?) panel depicts "frequency bowls" for the model vs behavior. Several supporting functions are provided, and different subpanels of the figures are generated using a few different functions:
# - theta_get_behavioral_data: utility function to grab behavioral data
# - theta_get_external_data: utility function to grab *external* behavioral data
# - theta_plot!: mutating function to plot bowls
# - getpffunc: utility factory function to get correct PF object
# - modelstr: utility function to get model string with spont rate information from 
#   model objects
# - genfig_theta_bowls(mode): generate one bowl figure for modeled PFs of the requested 
#   mode, where mode ∈ ["singlechannel", "profilechannel", "templatebased"]. Used for
#   supplemental figures, where we show all results.
# - genfig_theta_bowl_1kHz_vs_data: generate summary bowl figure showing only results at 
#   1 kHz and with different modes overlayed 
# - genfig_theta_bowl_1kHz_vs_data_free: same as above, but where we fit a simple additive
#   offset parameter that is optimized to fit model and data (i.e., emphasize curve rather
#   than absolute differences)
# - genfig_theta_freq_bowls(mode): generate one "frequency bowl figure" for modeled PFs of 
#   the requested mode, where mode ∈ ["singlechannel", "profilechannel", "templatebased"]. 
#   Used for supplemental figures, where we show all results.

function theta_get_behavioral_data()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :rove .== "fixed level")

    # Summarize as function of number of components and group
    @chain df begin
        # Group by freq, component count, and group
        groupby([:freq, :n_comp, :hl_group])

        # Summarize
        @combine(
            :stderr = std(:threshold)/sqrt(length(:threshold)),
            :threshold = mean(:threshold),
        )
    end
end

function theta_get_external_data()
    # Load in data
    df = DataFrame(CSV.File(datadir("ext_pro", "all_data.csv")))

    # Subset Green, Kidd, and Picardi and re-express n_comp in "standard" n_comp units
    temp = @subset(df, :experiment .== "Green, Kidd, and Picardi (1983), Figure 4", :bandwidth .> 2.5)
    temp.n_comp .= (12 * 4.64386) ./ temp.spacing_st

    # Subset other datasets that are more amenable to our needs (n_comp is directly comparable)
    df = vcat(
        @subset(df, :experiment .== "Green and Mason (1985), Figure 3"),
        @subset(df, :experiment .== "Bernstein and Green (1987), Figure 2", :freq .== 1000.0),
#        temp,
    )

    df = @orderby(df, :n_comp)
    return df
end

function theta_plot!(ax, n_comps, θ, beh, ext, center_freq; color=:black, marker=:rect, show_beh=false, show_ext=false, show_comb=false)
    # Plot external data
    if show_ext
        for exp in unique(ext.experiment)
            temp = @subset(ext, :experiment .== exp)
            scatter!(ax, temp.n_comp, temp.threshold; color=:darkgray, marker=:rect)
            lines!(ax, temp.n_comp, temp.threshold; color=:darkgray, marker=:rect)
        end
    end

    # Plot behavior
    if show_beh 
        temp = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== center_freq)
        if center_freq .== 1000.0
         #   errorbars!(ax, temp.n_comp, temp.threshold, temp.stderr .* 1.96; color=:black)
            scatter!(ax, temp.n_comp, temp.threshold; color=:black)
            lines!(ax, temp.n_comp, temp.threshold; color=:black)
        end
    end

    # Plot combined behavior from several studies
    if show_comb
        # Combine together datasets
        temp = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== center_freq)
        comb = vcat(temp, ext; cols=:intersect)
        comb = @orderby(comb, :n_comp)

        # Scatter our data
        scatter!(ax, temp.n_comp, temp.threshold; color=:black, marker='D')

        # Scatter external data
        for exp in unique(ext.experiment)
            temp = @subset(ext, :experiment .== exp)
            scatter!(ax, temp.n_comp, temp.threshold; color=:black, marker=exp[1])
        end

        # Draw line at loess fit
        lines!(ax, comb.n_comp, quicksmooth(comb.n_comp, comb.threshold; span=0.7); color=:black)
    end

    # Plot
    lines!(ax, n_comps, θ; color=color)
    scatter!(ax, n_comps, θ; color=color, marker=marker)
end

function getpffunc(mode, model, exp)
    if mode == "singlechannel"
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pffunc = (args...) -> Utilities.setup(exp, args...; observer=obs)
    elseif mode == "profilechannel"
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pffunc = (args...) -> Utilities.setup(exp, args...; observer=obs, preprocessor=pre_emphasize_profile)
    elseif mode == "templatebased"
        pffunc = (args...) -> Utilities.setup(exp, args...)
    end
    return pffunc
end

function modelstr(model::Model)
    if typeof(model) == AuditoryNerveZBC2014
        string(typeof(model)) * "_" * model.fiber_type
    else
        string(typeof(model))
    end
end

function find_constant(beh, sim)
    # Subset sim
    sim = @subset(sim, in.(:n_comp, Ref([5, 13, 21, 29, 37])))
    # Minimize
    Optim.minimizer(optimize(p -> sqrt(mean(((p[1] .+ sim.θ) .- beh.threshold).^2)), [0.0], BFGS()))
end

function genfig_theta_bowls(
    mode::String;
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 9, 13, 17, 21, 25, 29, 33, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
    marker=:rect,
)
    # Handle modeswitch
    if (mode == "singlechannel") | (mode == "profilechannel")
        exp = ProfileAnalysis_PFObserver()
    elseif mode == "templatebased"
        exp = ProfileAnalysis_PFTemplateObserver()
    end

    # Grab behavioral data
    beh = theta_get_behavioral_data()
    ext = theta_get_external_data()

    # Set up plot
    set_theme!(theme_carney; Scatter=(markersize=6.0, ))
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]) for i in 1:3]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Choose colors
    colors = ColorSchemes.Set2_4

    # Do each plot for each model
    for (center_freq, color) in zip(center_freqs, colors)
        # Grab models
        models = Utilities.setup(exp, center_freq)
        for (ax, model) in zip(axs, models)
            # Map through n_comps and estimate psychometric functions and extract threshold for each
            θ = map(n_comps) do n_comp
                # Simulate psychometric function
                pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                out = @memo Default() simulate(pf)
                Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
            end
            theta_plot!(ax, n_comps, θ, beh, ext, center_freq; color=color, marker=marker)
        end
    end

    # Neaten up
    axs[1].ylabel = "Threshold (dB SRS)"
    [ax.xticks = collect(5 .+ (8 .* (0:4))) for ax in axs]
    ylims!.(axs, -40.0, 10.0)
    xlims!.(axs, 2.0, 45.0)
    Label(fig[2, 2:3], "Number of components"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_theta_bowl_1kHz_vs_data(;
    n_comps=[5, 9, 13, 17, 21, 25, 29, 33, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
)
    # Grab behavioral data
    beh = theta_get_behavioral_data()
    ext = theta_get_external_data()

    # Set up plot
    set_theme!(theme_carney; Scatter=(markersize=6.0, ))
    fig = Figure(; resolution=(320, 125))
    axs = [Axis(fig[1, i]) for i in 1:3]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Choose colors
    colors = ColorSchemes.Set2_4

    # Grab models
    center_freq = 1000.0
    color = colors[2]
    models = Utilities.setup(ProfileAnalysis_PFObserver(), center_freq)[2:end]

    # Map through models and build dataframe containing results to compare to beh
    df = map(models) do model
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end
            # Map through n_comps and estimate psychometric functions and extract threshold for each
            θ = map(n_comps) do n_comp
                # Simulate psychometric function
                pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                out = @memo Default() simulate(pf)
                Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
            end
            DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
        end
        vcat(out...)
    end
    df = vcat(df...)

    # Loop through all combinations of model, center_freq, and mode and calcuate 
    # error between model predictions and behavior
    beh = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== 1000)
    θ_true = beh.threshold
    df.model .= modelstr.(df.model)
    comparison = @chain df begin
        # Take only 5, 13, 21, 29, 37
        @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
        # Group by target frequency, PF mode, and model
        groupby([:center_freq, :mode, :model])
        # Compare each to data using RMS error
        @combine(:error = sqrt(mean((:θ .- θ_true).^2)))
    end

    # Loop through models and panels 
    for (ax, model) in zip(axs, models)
        # Get all errors associated with this model
        errors = @subset(comparison, :model .== modelstr(model)).error
        # Map through possible PF modes and plot each with different markers
        map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Decide what color/contrast this line should be 
            dfsub = @subset(df, :mode .== mode, :model .== modelstr(model))
            compsub = @subset(comparison, :mode .== mode, :model .== modelstr(model))
            best = compsub.error[1] == minimum(errors)
            color = convert(HSL, color)
            _color = best ? color : HSL(color.h, 0.3, 0.9)
            # Decide what marker this line should be
            marker = @match mode begin
                "singlechannel" => :circle
                "profilechannel" => :rect 
                "templatebased" => :diamond
            end
            theta_plot!(ax, dfsub.n_comp, dfsub.θ, beh, ext, center_freq; color=_color, marker=marker, show_comb=true)
            if best
                text!(ax, 29, 0.0; text=string(round(compsub.error[1]; digits=1)) * " dB", color=color, fontsize=8.0)
            end
        end
    end

    # Neaten up
    axs[1].ylabel = "Threshold (dB SRS)"
    [ax.xticks = collect(5 .+ (8 .* (0:4))) for ax in axs]
    ylims!.(axs, -40.0, 10.0)
    xlims!.(axs, 2.0, 45.0)
    Label(fig[2, 1:3], "Number of components"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_theta_bowl_1kHz_vs_data_free(;
    n_comps=[5, 9, 13, 17, 21, 25, 29, 33, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
)
    # Grab behavioral data
    beh = theta_get_behavioral_data()
    ext = theta_get_external_data()

    # Set up plot
    set_theme!(theme_carney; Scatter=(markersize=6.0, ))
    fig = Figure(; resolution=(320, 125))
    axs = [Axis(fig[1, i]) for i in 1:3]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Choose colors
    colors = ColorSchemes.Set2_4

    # Grab models
    center_freq = 1000.0
    color = colors[2]
    models = Utilities.setup(ProfileAnalysis_PFObserver(), center_freq)[2:end]

    # Map through models and build dataframe containing results to compare to beh
    df = map(models) do model
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end
            # Map through n_comps and estimate psychometric functions and extract threshold for each
            θ = map(n_comps) do n_comp
                # Simulate psychometric function
                pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                out = @memo Default() simulate(pf)
                Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
            end
            DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
        end
        vcat(out...)
    end
    df = vcat(df...)

    # Loop through all combinations of model, center_freq, and mode and find additive 
    # constant that minimized error, then add to results
    beh = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== 1000)
    θ_true = beh.threshold
    df.model .= modelstr.(df.model)
    df = groupby(df, [:center_freq, :mode, :model])
    for grp in df
        grp.θ .= grp.θ .+ find_constant(beh, grp)
    end
    df = transform(df)

    # Loop through all combinations of model, center_freq, and mode and calcuate 
    # error between model predictions and behavior
    comparison = @chain df begin
        # Take only 5, 13, 21, 29, 37
        @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
        # Group by target frequency, PF mode, and model
        groupby([:center_freq, :mode, :model])
        # Compare each to data using RMS error
        @combine(:error = sqrt(mean((:θ .- θ_true).^2)))
    end

    # Loop through models and panels 
    for (ax, model) in zip(axs, models)
        # Get all errors associated with this model
        errors = @subset(comparison, :model .== modelstr(model)).error
        # Map through possible PF modes and plot each with different markers
        map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Decide what color/contrast this line should be 
            dfsub = @subset(df, :mode .== mode, :model .== modelstr(model))
            compsub = @subset(comparison, :mode .== mode, :model .== modelstr(model))
            best = compsub.error[1] == minimum(errors)
            color = convert(HSL, color)
            _color = best ? color : HSL(color.h, 0.3, 0.9)
            # Decide what marker this line should be
            marker = @match mode begin
                "singlechannel" => :circle
                "profilechannel" => :rect 
                "templatebased" => :diamond
            end
            theta_plot!(ax, dfsub.n_comp, dfsub.θ, beh, ext, center_freq; color=_color, marker=marker, show_comb=true)
            if best
                text!(ax, 29, 0.0; text=string(round(compsub.error[1]; digits=1)) * " dB", color=color, fontsize=8.0)
            end
        end
    end

    # Neaten up
    axs[1].ylabel = "Threshold (dB SRS)"
    [ax.xticks = collect(5 .+ (8 .* (0:4))) for ax in axs]
    ylims!.(axs, -40.0, 10.0)
    xlims!.(axs, 2.0, 45.0)
    Label(fig[2, 1:3], "Number of components"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_theta_freq_bowls_summary(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
)
    # Handle modeswitch
    if (mode == "singlechannel") | (mode == "profilechannel")
        exp = ProfileAnalysis_PFObserver()
    elseif mode == "templatebased"
        exp = ProfileAnalysis_PFTemplateObserver()
    end

    # Grab behavioral data
    beh = theta_get_behavioral_data()
    ext = theta_get_external_data()

    # Set up plot
    set_theme!(theme_carney; Scatter=(markersize=6.0, ))
    fig = Figure(; resolution=(260, 360))
    axs = [Axis(fig[i, j]; xminorticksvisible=false, xscale=log10) for i in eachindex(n_comps), j in 1:3]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Map through models and build dataframe containing results to compare to beh
    df = map(center_freqs) do center_freq
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end
            # Fetch models
            models = setup(exp, center_freq)[2:end]
            out = map(models) do model
                # Map through n_comps and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                    out = @memo Default() simulate(pf)
                    Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                end
                DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
            end
            vcat(out...)
        end
        vcat(out...)
    end
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Loop through all combinations of model, center_freq, and mode and calcuate 
    # error between model predictions and behavior
    beh = @subset(beh, :hl_group .== "< 5 dB HL")
    df[!, :θ_true] .= 0.0
    # First we need to fill in real threshold values
    for r in eachrow(df) 
        if r.n_comp in [5, 13, 21, 29, 37]
            r.θ_true = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== r.center_freq, :n_comp .== r.n_comp).threshold[1]
        end
    end

    # Next we compare data
    comparison = @chain df begin
        # Take only 5, 13, 21, 29, 37
        @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
        # Group by target frequency, PF mode, and model
        groupby([:n_comp, :mode, :model])
        # Compare each to data using RMS error
        @combine(:error = sqrt(mean((:θ .- :θ_true).^2)))
    end

    # Do each plot for each model
    for (idx_row, n_comp) in enumerate(n_comps)
        for (idx_col, model) in enumerate(modelstr.(setup(ProfileAnalysis_PFObserver(), 1000.0))[2:end])
            for mode in ["singlechannel", "profilechannel", "templatebased"]
                # Handle coloration and such 
                # Decide what marker this line should be
                marker = @match mode begin
                    "singlechannel" => :circle
                    "profilechannel" => :rect 
                    "templatebased" => :diamond
                end

                # Decide what color/constrast this line should be
                errors = @subset(comparison, :model .== model, :n_comp .== n_comp).error
                compsub = @subset(comparison, :mode .== mode, :model .== model, :n_comp .== n_comp)
                best = compsub.error[1] == minimum(errors)
                color = convert(HSL, RGB(1.0, 0.0, 0.0))
                _color = best ? color : HSL(color.h, 0.3, 0.9)

                # Subset simulated data and plot
                temp = @subset(df, :n_comp .== n_comp, :model .== model, :mode .== mode)
                lines!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color)
                scatter!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color, marker=marker)

                # Subset behavioral data and plot
                temp = @subset(beh, :n_comp .== n_comp, :hl_group .== "< 5 dB HL")
                temp = @orderby(temp, :freq)
                errorbars!(axs[idx_row, idx_col], temp.freq, temp.threshold, 1.96 .* temp.stderr; color=:black)
                lines!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)
                scatter!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)

                if best
                    text!(
                        axs[idx_row, idx_col], 
                        4000.0, 
                        -30.0; 
                        text=string(round(compsub.error[1]; digits=1)) * " dB", 
                        color=color, 
                        align=(:right, :center),
                        fontsize=8.0
                    )
                end
            end
        end
    end

    # Neaten up
    [ax.xticks = [500.0, 1000.0, 2000.0, 4000.0] for ax in axs]
    [ax.yticks = ([-40.0, -30.0, -20.0, -10.0, 0.0, 10.0], ["-40", "-30", "-20", "-10", "0", ""]) for ax in axs]
    ylims!.(axs, -40.0, 10.0)
    xlims!.(axs, 500.0 * 2^-0.3, 4000.0 * 2^0.3)
    Label(fig[1:5, 0], "Threshold (dB SRS)"; tellheight=false, rotation=π/2)
    Label(fig[end+1, 1:3], "Target frequency (Hz)"; tellwidth=false)
    [rowgap!(fig.layout, i, Relative(0.01)) for i in 1:4]
    rowgap!(fig.layout, 5, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end

function genfig_theta_freq_bowls_summary_free(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
)
    # Handle modeswitch
    if (mode == "singlechannel") | (mode == "profilechannel")
        exp = ProfileAnalysis_PFObserver()
    elseif mode == "templatebased"
        exp = ProfileAnalysis_PFTemplateObserver()
    end

    # Grab behavioral data
    beh = theta_get_behavioral_data()
    ext = theta_get_external_data()

    # Set up plot
    set_theme!(theme_carney; Scatter=(markersize=6.0, ))
    fig = Figure(; resolution=(260, 360))
    axs = [Axis(fig[i, j]; xminorticksvisible=false, xscale=log10) for i in eachindex(n_comps), j in 1:3]
    [ax.xticklabelrotation = π/2 for ax in axs]

    # Map through models and build dataframe containing results to compare to beh
    df = map(center_freqs) do center_freq
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end
            # Fetch models
            models = setup(exp, center_freq)[2:end]
            out = map(models) do model
                # Map through n_comps and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                    out = @memo Default() simulate(pf)
                    Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                end
                DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
            end
            vcat(out...)
        end
        vcat(out...)
    end
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Loop through all combinations of model, center_freq, and mode and find additive 
    # constant that minimized error, then add to results
    df = groupby(df, [:n_comp, :mode, :model])
    for grp in df
        temp = @subset(beh, :hl_group .== "< 5 dB HL", :n_comp .== grp.n_comp[1])
        temp = @orderby(temp, :freq)
        grp.θ .= grp.θ .+ find_constant(temp, grp)
    end
    df = transform(df)

    # Loop through all combinations of model, center_freq, and mode and calcuate 
    # error between model predictions and behavior
    beh = @subset(beh, :hl_group .== "< 5 dB HL")
    df[!, :θ_true] .= 0.0
    # First we need to fill in real threshold values
    for r in eachrow(df) 
        if r.n_comp in [5, 13, 21, 29, 37]
            r.θ_true = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== r.center_freq, :n_comp .== r.n_comp).threshold[1]
        end
    end

    # Next we compare data
    comparison = @chain df begin
        # Take only 5, 13, 21, 29, 37
        @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
        # Group by target frequency, PF mode, and model
        groupby([:n_comp, :mode, :model])
        # Compare each to data using RMS error
        @combine(:error = sqrt(mean((:θ .- :θ_true).^2)))
    end

    # Do each plot for each model
    for (idx_row, n_comp) in enumerate(n_comps)
        for (idx_col, model) in enumerate(modelstr.(setup(ProfileAnalysis_PFObserver(), 1000.0))[2:end])
            for mode in ["singlechannel", "profilechannel", "templatebased"]
                # Handle coloration and such 
                # Decide what marker this line should be
                marker = @match mode begin
                    "singlechannel" => :circle
                    "profilechannel" => :rect 
                    "templatebased" => :diamond
                end

                # Decide what color/constrast this line should be
                errors = @subset(comparison, :model .== model, :n_comp .== n_comp).error
                compsub = @subset(comparison, :mode .== mode, :model .== model, :n_comp .== n_comp)
                best = compsub.error[1] == minimum(errors)
                color = convert(HSL, RGB(1.0, 0.0, 0.0))
                _color = best ? color : HSL(color.h, 0.3, 0.9)

                # Subset simulated data and plot
                temp = @subset(df, :n_comp .== n_comp, :model .== model, :mode .== mode)
                lines!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color)
                scatter!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color, marker=marker)

                # Subset behavioral data and plot
                temp = @subset(beh, :n_comp .== n_comp, :hl_group .== "< 5 dB HL")
                temp = @orderby(temp, :freq)
                errorbars!(axs[idx_row, idx_col], temp.freq, temp.threshold, 1.96 .* temp.stderr; color=:black)
                lines!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)
                scatter!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)

                if best
                    text!(
                        axs[idx_row, idx_col], 
                        4000.0, 
                        -30.0; 
                        text=string(round(compsub.error[1]; digits=1)) * " dB", 
                        color=color, 
                        align=(:right, :center),
                        fontsize=8.0
                    )
                end
            end
        end
    end

    # Neaten up
    [ax.xticks = [500.0, 1000.0, 2000.0, 4000.0] for ax in axs]
    [ax.yticks = ([-40.0, -30.0, -20.0, -10.0, 0.0, 10.0], ["-40", "-30", "-20", "-10", "0", ""]) for ax in axs]
    ylims!.(axs, -40.0, 10.0)
    xlims!.(axs, 500.0 * 2^-0.3, 4000.0 * 2^0.3)
    Label(fig[1:5, 0], "Threshold (dB SRS)"; tellheight=false, rotation=π/2)
    Label(fig[end+1, 1:3], "Target frequency (Hz)"; tellwidth=false)
    [rowgap!(fig.layout, i, Relative(0.01)) for i in 1:4]
    rowgap!(fig.layout, 5, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))
    neaten_grid!(axs)

    # Return
    return fig
end