export genfig_sim_bowls_density_and_frequency_bowls,
       genfig_sim_bowls_gmmf,
       genfig_sim_bowls_density_and_frequency_bowls_rove_effects,
       genfig_sim_bowls_density_and_frequency_bowls_simple,
       genfig_sim_bowls_summary,
       genfig_sim_bowls_puretonecontrol,
       genfig_sim_bowls_puretonecontrol_LSR_only,
       genfig_followup_puretonecontrol,
       genfig_puretonecontrol_mechanism,
       genfig_followup_puretonecontrol_no_cochlear_gain,
       genfig_puretonecontrol_rl_functions,
       genfig_sim_bowls_frequency_summary,
       genfig_sim_bowls_modelbehavior_scatterplots,
       θ_energy

# Figure Θ
# Figure Θ depicts the "executive summary" of the modeling, and bonus/extra/full results are also shown in a Figure Θ supplemental. In the main-text figure, the top panel depicts so-called "bowls" from the model vs behavior. The middle(?) panel depicts "frequency bowls" for the model vs behavior. Several supporting functions are provided, and different subpanels of the figures are generated using a few different functions:
# - theta_get_behavioral_data: utility function to grab behavioral data
# - theta_get_external_data: utility function to grab *external* behavioral data
# - theta_plot!: mutating function to plot bowls
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

# function theta_plot!(ax, n_comps, θ, beh, ext, center_freq; color=:black, marker=:rect, show_beh=false, show_ext=false, show_comb=false)
#     # Plot external data
#     if show_ext
#         for exp in unique(ext.experiment)
#             temp = @subset(ext, :experiment .== exp)
#             scatter!(ax, temp.n_comp, temp.threshold; color=:darkgray, marker=:rect)
#             lines!(ax, temp.n_comp, temp.threshold; color=:darkgray, marker=:rect)
#         end
#     end

#     # Plot behavior
#     if show_beh 
#         temp = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== center_freq)
#         if center_freq .== 1000.0
#          #   errorbars!(ax, temp.n_comp, temp.threshold, temp.stderr .* 1.96; color=:black)
#             scatter!(ax, temp.n_comp, temp.threshold; color=:black)
#             lines!(ax, temp.n_comp, temp.threshold; color=:black)
#         end
#     end

#     # Plot combined behavior from several studies
#     if show_comb
#         # Combine together datasets
#         temp = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== center_freq)
#         comb = vcat(temp, ext; cols=:intersect)
#         comb = @orderby(comb, :n_comp)

#         # Scatter our data
#         scatter!(ax, temp.n_comp, temp.threshold; color=:black, marker='D')

#         # Scatter external data
#         for exp in unique(ext.experiment)
#             temp = @subset(ext, :experiment .== exp)
#             scatter!(ax, temp.n_comp, temp.threshold; color=:black, marker=exp[1])
#         end

#         # Draw line at loess fit
#         lines!(ax, comb.n_comp, quicksmooth(comb.n_comp, comb.threshold; span=0.7); color=:black)
#     end

#     # Plot
#     lines!(ax, n_comps, θ; color=color)
#     scatter!(ax, n_comps, θ; color=color, marker=marker)
# end

# function find_constant(beh, sim)
#     # Subset sim
#     sim = @subset(sim, in.(:n_comp, Ref([5, 13, 21, 29, 37])))
#     # Minimize
#     Optim.minimizer(optimize(p -> sqrt(mean(((p[1] .+ sim.θ) .- beh.threshold).^2)), [0.0], BFGS()))
# end

function genfig_theta_bowls(
    mode::String;
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
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

function genfig_sim_bowls_density_bowl(;
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

# function genfig_theta_bowl_1kHz_vs_data_free(;
#     n_comps=[5, 9, 13, 17, 21, 25, 29, 33, 37],
#     increments=vcat(-999.9, -45.0:2.5:5.0),
# )
#     # Grab behavioral data
#     beh = theta_get_behavioral_data()
#     ext = theta_get_external_data()

#     # Set up plot
#     set_theme!(theme_carney; Scatter=(markersize=6.0, ))
#     fig = Figure(; resolution=(320, 125))
#     axs = [Axis(fig[1, i]) for i in 1:3]
#     [ax.xticklabelrotation = π/2 for ax in axs]

#     # Choose colors
#     colors = ColorSchemes.Set2_4

#     # Grab models
#     center_freq = 1000.0
#     color = colors[2]
#     models = Utilities.setup(ProfileAnalysis_PFObserver(), center_freq)[2:end]

#     # Map through models and build dataframe containing results to compare to beh
#     df = map(models) do model
#         # Map through possible PF modes and plot each with different markers
#         out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
#             # Handle modeswitch
#             if (mode == "singlechannel") | (mode == "profilechannel")
#                 exp = ProfileAnalysis_PFObserver()
#             elseif mode == "templatebased"
#                 exp = ProfileAnalysis_PFTemplateObserver()
#             end
#             # Map through n_comps and estimate psychometric functions and extract threshold for each
#             θ = map(n_comps) do n_comp
#                 # Simulate psychometric function
#                 pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
#                 out = @memo Default() simulate(pf)
#                 Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
#             end
#             DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
#         end
#         vcat(out...)
#     end
#     df = vcat(df...)

#     # Loop through all combinations of model, center_freq, and mode and find additive 
#     # constant that minimized error, then add to results
#     beh = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== 1000)
#     θ_true = beh.threshold
#     df.model .= modelstr.(df.model)
#     df = groupby(df, [:center_freq, :mode, :model])
#     for grp in df
#         grp.θ .= grp.θ .+ find_constant(beh, grp)
#     end
#     df = transform(df)

#     # Loop through all combinations of model, center_freq, and mode and calcuate 
#     # error between model predictions and behavior
#     comparison = @chain df begin
#         # Take only 5, 13, 21, 29, 37
#         @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
#         # Group by target frequency, PF mode, and model
#         groupby([:center_freq, :mode, :model])
#         # Compare each to data using RMS error
#         @combine(:error = sqrt(mean((:θ .- θ_true).^2)))
#     end

#     # Loop through models and panels 
#     for (ax, model) in zip(axs, models)
#         # Get all errors associated with this model
#         errors = @subset(comparison, :model .== modelstr(model)).error
#         # Map through possible PF modes and plot each with different markers
#         map(["singlechannel", "profilechannel", "templatebased"]) do mode
#             # Decide what color/contrast this line should be 
#             dfsub = @subset(df, :mode .== mode, :model .== modelstr(model))
#             compsub = @subset(comparison, :mode .== mode, :model .== modelstr(model))
#             best = compsub.error[1] == minimum(errors)
#             color = convert(HSL, color)
#             _color = best ? color : HSL(color.h, 0.3, 0.9)
#             # Decide what marker this line should be
#             marker = @match mode begin
#                 "singlechannel" => :circle
#                 "profilechannel" => :rect 
#                 "templatebased" => :diamond
#             end
#             theta_plot!(ax, dfsub.n_comp, dfsub.θ, beh, ext, center_freq; color=_color, marker=marker, show_comb=true)
#             if best
#                 text!(ax, 29, 0.0; text=string(round(compsub.error[1]; digits=1)) * " dB", color=color, fontsize=8.0)
#             end
#         end
#     end

#     # Neaten up
#     axs[1].ylabel = "Threshold (dB SRS)"
#     [ax.xticks = collect(5 .+ (8 .* (0:4))) for ax in axs]
#     ylims!.(axs, -40.0, 10.0)
#     xlims!.(axs, 2.0, 45.0)
#     Label(fig[2, 1:3], "Number of components"; tellwidth=false)
#     rowgap!(fig.layout, 1, Relative(0.03))
#     colgap!(fig.layout, Relative(0.02))
#     neaten_grid!(axs)

#     # Return
#     return fig
# end

# function genfig_theta_freq_bowls_summary(
#     center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
#     n_comps=[5, 13, 21, 29, 37],
#     increments=vcat(-999.9, -45.0:2.5:5.0),
# )
#     # Handle modeswitch
#     if (mode == "singlechannel") | (mode == "profilechannel")
#         exp = ProfileAnalysis_PFObserver()
#     elseif mode == "templatebased"
#         exp = ProfileAnalysis_PFTemplateObserver()
#     end

#     # Grab behavioral data
#     beh = theta_get_behavioral_data()
#     ext = theta_get_external_data()

#     # Set up plot
#     set_theme!(theme_carney; Scatter=(markersize=6.0, ))
#     fig = Figure(; resolution=(260, 360))
#     axs = [Axis(fig[i, j]; xminorticksvisible=false, xscale=log10) for i in eachindex(n_comps), j in 1:3]
#     [ax.xticklabelrotation = π/2 for ax in axs]

#     # Map through models and build dataframe containing results to compare to beh
#     df = map(center_freqs) do center_freq
#         # Map through possible PF modes and plot each with different markers
#         out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
#             # Handle modeswitch
#             if (mode == "singlechannel") | (mode == "profilechannel")
#                 exp = ProfileAnalysis_PFObserver()
#             elseif mode == "templatebased"
#                 exp = ProfileAnalysis_PFTemplateObserver()
#             end
#             # Fetch models
#             models = setup(exp, center_freq)[2:end]
#             out = map(models) do model
#                 # Map through n_comps and estimate psychometric functions and extract threshold for each
#                 θ = map(n_comps) do n_comp
#                     # Simulate psychometric function
#                     pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
#                     out = @memo Default() simulate(pf)
#                     Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
#                 end
#                 DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
#             end
#             vcat(out...)
#         end
#         vcat(out...)
#     end
#     df = vcat(df...)

#     # Convert model to model string
#     df.model .= modelstr.(df.model)

#     # Loop through all combinations of model, center_freq, and mode and calcuate 
#     # error between model predictions and behavior
#     beh = @subset(beh, :hl_group .== "< 5 dB HL")
#     df[!, :θ_true] .= 0.0
#     # First we need to fill in real threshold values
#     for r in eachrow(df) 
#         if r.n_comp in [5, 13, 21, 29, 37]
#             r.θ_true = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== r.center_freq, :n_comp .== r.n_comp).threshold[1]
#         end
#     end

#     # Next we compare data
#     comparison = @chain df begin
#         # Take only 5, 13, 21, 29, 37
#         @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
#         # Group by target frequency, PF mode, and model
#         groupby([:n_comp, :mode, :model])
#         # Compare each to data using RMS error
#         @combine(:error = sqrt(mean((:θ .- :θ_true).^2)))
#     end

#     # Do each plot for each model
#     for (idx_row, n_comp) in enumerate(n_comps)
#         for (idx_col, model) in enumerate(modelstr.(setup(ProfileAnalysis_PFObserver(), 1000.0))[2:end])
#             for mode in ["singlechannel", "profilechannel", "templatebased"]
#                 # Handle coloration and such 
#                 # Decide what marker this line should be
#                 marker = @match mode begin
#                     "singlechannel" => :circle
#                     "profilechannel" => :rect 
#                     "templatebased" => :diamond
#                 end

#                 # Decide what color/constrast this line should be
#                 errors = @subset(comparison, :model .== model, :n_comp .== n_comp).error
#                 compsub = @subset(comparison, :mode .== mode, :model .== model, :n_comp .== n_comp)
#                 best = compsub.error[1] == minimum(errors)
#                 color = convert(HSL, RGB(1.0, 0.0, 0.0))
#                 _color = best ? color : HSL(color.h, 0.3, 0.9)

#                 # Subset simulated data and plot
#                 temp = @subset(df, :n_comp .== n_comp, :model .== model, :mode .== mode)
#                 lines!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color)
#                 scatter!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color, marker=marker)

#                 # Subset behavioral data and plot
#                 temp = @subset(beh, :n_comp .== n_comp, :hl_group .== "< 5 dB HL")
#                 temp = @orderby(temp, :freq)
#                 errorbars!(axs[idx_row, idx_col], temp.freq, temp.threshold, 1.96 .* temp.stderr; color=:black)
#                 lines!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)
#                 scatter!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)

#                 if best
#                     text!(
#                         axs[idx_row, idx_col], 
#                         4000.0, 
#                         -30.0; 
#                         text=string(round(compsub.error[1]; digits=1)) * " dB", 
#                         color=color, 
#                         align=(:right, :center),
#                         fontsize=8.0
#                     )
#                 end
#             end
#         end
#     end

#     # Neaten up
#     [ax.xticks = [500.0, 1000.0, 2000.0, 4000.0] for ax in axs]
#     [ax.yticks = ([-40.0, -30.0, -20.0, -10.0, 0.0, 10.0], ["-40", "-30", "-20", "-10", "0", ""]) for ax in axs]
#     ylims!.(axs, -40.0, 10.0)
#     xlims!.(axs, 500.0 * 2^-0.3, 4000.0 * 2^0.3)
#     Label(fig[1:5, 0], "Threshold (dB SRS)"; tellheight=false, rotation=π/2)
#     Label(fig[end+1, 1:3], "Target frequency (Hz)"; tellwidth=false)
#     [rowgap!(fig.layout, i, Relative(0.01)) for i in 1:4]
#     rowgap!(fig.layout, 5, Relative(0.02))
#     colgap!(fig.layout, Relative(0.02))
#     neaten_grid!(axs)

#     # Return
#     return fig
# end

# function genfig_theta_freq_bowls_summary_free(
#     center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
#     n_comps=[5, 13, 21, 29, 37],
#     increments=vcat(-999.9, -45.0:2.5:5.0),
# )
#     # Handle modeswitch
#     if (mode == "singlechannel") | (mode == "profilechannel")
#         exp = ProfileAnalysis_PFObserver()
#     elseif mode == "templatebased"
#         exp = ProfileAnalysis_PFTemplateObserver()
#     end

#     # Grab behavioral data
#     beh = theta_get_behavioral_data()
#     ext = theta_get_external_data()

#     # Set up plot
#     set_theme!(theme_carney; Scatter=(markersize=6.0, ))
#     fig = Figure(; resolution=(260, 360))
#     axs = [Axis(fig[i, j]; xminorticksvisible=false, xscale=log10) for i in eachindex(n_comps), j in 1:3]
#     [ax.xticklabelrotation = π/2 for ax in axs]

#     # Map through models and build dataframe containing results to compare to beh
#     df = map(center_freqs) do center_freq
#         # Map through possible PF modes and plot each with different markers
#         out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
#             # Handle modeswitch
#             if (mode == "singlechannel") | (mode == "profilechannel")
#                 exp = ProfileAnalysis_PFObserver()
#             elseif mode == "templatebased"
#                 exp = ProfileAnalysis_PFTemplateObserver()
#             end
#             # Fetch models
#             models = setup(exp, center_freq)[2:end]
#             out = map(models) do model
#                 # Map through n_comps and estimate psychometric functions and extract threshold for each
#                 θ = map(n_comps) do n_comp
#                     # Simulate psychometric function
#                     pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
#                     out = @memo Default() simulate(pf)
#                     Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
#                 end
#                 DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
#             end
#             vcat(out...)
#         end
#         vcat(out...)
#     end
#     df = vcat(df...)

#     # Convert model to model string
#     df.model .= modelstr.(df.model)

#     # Loop through all combinations of model, center_freq, and mode and find additive 
#     # constant that minimized error, then add to results
#     df = groupby(df, [:n_comp, :mode, :model])
#     for grp in df
#         temp = @subset(beh, :hl_group .== "< 5 dB HL", :n_comp .== grp.n_comp[1])
#         temp = @orderby(temp, :freq)
#         grp.θ .= grp.θ .+ find_constant(temp, grp)
#     end
#     df = transform(df)

#     # Loop through all combinations of model, center_freq, and mode and calcuate 
#     # error between model predictions and behavior
#     beh = @subset(beh, :hl_group .== "< 5 dB HL")
#     df[!, :θ_true] .= 0.0
#     # First we need to fill in real threshold values
#     for r in eachrow(df) 
#         if r.n_comp in [5, 13, 21, 29, 37]
#             r.θ_true = @subset(beh, :hl_group .== "< 5 dB HL", :freq .== r.center_freq, :n_comp .== r.n_comp).threshold[1]
#         end
#     end

#     # Next we compare data
#     comparison = @chain df begin
#         # Take only 5, 13, 21, 29, 37
#         @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37]))) 
#         # Group by target frequency, PF mode, and model
#         groupby([:n_comp, :mode, :model])
#         # Compare each to data using RMS error
#         @combine(:error = sqrt(mean((:θ .- :θ_true).^2)))
#     end

#     # Do each plot for each model
#     for (idx_row, n_comp) in enumerate(n_comps)
#         for (idx_col, model) in enumerate(modelstr.(setup(ProfileAnalysis_PFObserver(), 1000.0))[2:end])
#             for mode in ["singlechannel", "profilechannel", "templatebased"]
#                 # Handle coloration and such 
#                 # Decide what marker this line should be
#                 marker = @match mode begin
#                     "singlechannel" => :circle
#                     "profilechannel" => :rect 
#                     "templatebased" => :diamond
#                 end

#                 # Decide what color/constrast this line should be
#                 errors = @subset(comparison, :model .== model, :n_comp .== n_comp).error
#                 compsub = @subset(comparison, :mode .== mode, :model .== model, :n_comp .== n_comp)
#                 best = compsub.error[1] == minimum(errors)
#                 color = convert(HSL, RGB(1.0, 0.0, 0.0))
#                 _color = best ? color : HSL(color.h, 0.3, 0.9)

#                 # Subset simulated data and plot
#                 temp = @subset(df, :n_comp .== n_comp, :model .== model, :mode .== mode)
#                 lines!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color)
#                 scatter!(axs[idx_row, idx_col], temp.center_freq, temp.θ; color=_color, marker=marker)

#                 # Subset behavioral data and plot
#                 temp = @subset(beh, :n_comp .== n_comp, :hl_group .== "< 5 dB HL")
#                 temp = @orderby(temp, :freq)
#                 errorbars!(axs[idx_row, idx_col], temp.freq, temp.threshold, 1.96 .* temp.stderr; color=:black)
#                 lines!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)
#                 scatter!(axs[idx_row, idx_col], temp.freq, temp.threshold; color=:black)

#                 if best
#                     text!(
#                         axs[idx_row, idx_col], 
#                         4000.0, 
#                         -30.0; 
#                         text=string(round(compsub.error[1]; digits=1)) * " dB", 
#                         color=color, 
#                         align=(:right, :center),
#                         fontsize=8.0
#                     )
#                 end
#             end
#         end
#     end

#     # Neaten up
#     [ax.xticks = [500.0, 1000.0, 2000.0, 4000.0] for ax in axs]
#     [ax.yticks = ([-40.0, -30.0, -20.0, -10.0, 0.0, 10.0], ["-40", "-30", "-20", "-10", "0", ""]) for ax in axs]
#     ylims!.(axs, -40.0, 10.0)
#     xlims!.(axs, 500.0 * 2^-0.3, 4000.0 * 2^0.3)
#     Label(fig[1:5, 0], "Threshold (dB SRS)"; tellheight=false, rotation=π/2)
#     Label(fig[end+1, 1:3], "Target frequency (Hz)"; tellwidth=false)
#     [rowgap!(fig.layout, i, Relative(0.01)) for i in 1:4]
#     rowgap!(fig.layout, 5, Relative(0.02))
#     colgap!(fig.layout, Relative(0.02))
#     neaten_grid!(axs)

#     # Return
#     return fig
# end

"""
    genfig_sim_bowls_density_and_frequency_bowls()

Generate figure depicting behavior vs model performance

Generate figure depicting "bowls" in different frequency conditions for different models
and observers (rows and columns, respectively).
"""
function genfig_sim_bowls_density_and_frequency_bowls_simple()
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
    end

    # Compile relevant behavioral data
    beh = @chain fetch_behavioral_data() begin
        @subset(:hl_group .== "< 5 dB HL")
        avg_behavioral_data()
    end

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(600, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1, 3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Plot each bowl, with raw and adjusted thresholds
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset further
            sims = @subset(df_subset, :center_freq .== freq, :adjusted .== false)
            sims_fixed = @subset(sims, :rove_size .== 0.001)
            sims_roved = @subset(sims, :rove_size .== 10.0)
            beh_fixed = @subset(beh, :freq .== freq, :rove .== "fixed level")
            beh_roved = @subset(beh, :freq .== freq, :rove .== "roved level")

            # Add scatters and lines for: unadjusted thresholds (pink), adjusted thresholds
            # (red), and behavioral thresholds (black)
            scatter!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=:black)
            lines!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=:black)
            if nrow(beh_roved) > 0
                scatter!(ax, (1:5) .+ (idx-1)*7, beh_roved.threshold; color=:black, marker=:rect)
                lines!(ax, (1:5) .+ (idx-1)*7, beh_roved.threshold; color=:black, marker=:rect, linestyle=:dash)
            end
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_fixed.θ; color=:red)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_fixed.θ; color=:red)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:red, marker=:rect)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:red, marker=:rect, linestyle=:dash)

            # # Add another marker at the means in each frequency condition, beside data to right
            # μ_beh = mean(behs.threshold)
            # μ_mod = mean(sims_adj.θ)
            # lines!(ax, [6 + (idx-1)*7, 6 + (idx-1)*7], [μ_beh, μ_mod]; color=:lightgray)
            # scatter!(ax, [6 + (idx-1)*7], [μ_beh]; color=:black, marker=:rect)
            # scatter!(ax, [6 + (idx-1)*7], [μ_mod]; color=:red, marker=:rect)
            # scatter!(ax, [6 + (idx-1)*7], [μ_beh]; color=:white, marker=:rect, markersize=3.0)
            # scatter!(ax, [6 + (idx-1)*7], [μ_mod]; color=:white, marker=:rect, markersize=3.0)
        end

        # Add ticks
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*7 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0

        # # Add text label indicating performance
        # err = round(@subset(df_subset, :adjusted .== true).rms[1]; digits=1)
        # text!(ax, [20.0], [-33.0]; color=:red, text="$err dB")

        # # Add info at top of page
        # errvar = max(0.0, round(100.0 * @subset(df_subset, :adjusted .== true).varexp[1]; digits=3))
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Number of components // Target frequency (Hz)"); rowgap!(fig.layout, 3, Relative(0.05));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
#    colgap!(fig.layout, 3, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

function genfig_sim_bowls_frequency_summary()
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:rove_size .== 0.001, :adjusted .== false)
    end

    # Compile relevant behavioral data
    beh = @chain fetch_behavioral_data() begin
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")
        avg_behavioral_data()
    end

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(200, 250))
    axs = [Axis(fig[i, j]; xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1,3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset modeled data
        df_subset = @chain df begin
            @subset(:model .== model, :mode .== mode)
            groupby(:center_freq)
            @combine(:θ = mean(:θ))
            @orderby(:center_freq)
        end

        # Subset and average real data
        beh_subset = @chain beh begin
            groupby(:freq)
            @combine(:threshold = mean(:threshold))
            @orderby(:freq)
        end

        scatter!(ax, 1.0:1.0:4.0, df_subset.θ; color=:red)
        lines!(ax, 1.0:1.0:4.0, df_subset.θ; color=:red)
        scatter!(ax, 1.0:1.0:4.0, beh_subset.threshold; color=:black)
        lines!(ax, 1.0:1.0:4.0, beh_subset.threshold; color=:black)

        # Add ticks
        ax.xticks = (
            1.0:1.0:4.0,
            ["0.5", "1", "2", "4"],
        )

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Target frequency (kHz)"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

function genfig_sim_bowls_modelbehavior_scatterplots()
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:rove_size .== 0.001, :adjusted .== false)
    end

    # Compile relevant behavioral data
    beh = @chain fetch_behavioral_data() begin
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")
        avg_behavioral_data()
        @orderby(:n_comp, :freq)
    end

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(200, 250))
    axs = [Axis(fig[i, j]; xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1,3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset modeled data
        df_subset = @chain df begin
            @subset(:model .== model, :mode .== mode)
            @orderby(:n_comp, :center_freq)
        end

        # Scatter each dataset
        scatter!(ax, beh.threshold, df_subset.θ; color=:black, marker=pick_marker.(beh.freq))

        # Fit lm 
        temp = DataFrame(behavior=beh.threshold, model=df_subset.θ)
        m = lm(@formula(model ~ behavior), temp) 
        varexp = string(round(r2(m) * 100.0; digits=2))
        x̂ = -30.0:0.1:10.0
        β₀ = coef(m)[1]
        β = coef(m)[2]
        lines!(ax, x̂, β₀ .+ x̂ .* β; color=:gray)
        text!(ax, [-30.0], [0.0]; text=string(varexp))

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
        xlims!(ax, -35.0, 10.0)
        ax.xticks = -30.0:10.0:10.0
    end
    
    # Add labels
    Label(fig[:, 0], "Model threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Behavioral threshold (dB SRS)"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

function θ_energy(increments=-20.0:0.5:20.0, n=5000)
    # Loop through each increment
    pcorr = map(increments) do inc
        # Sample roved levels (standard and target, separately)
        lvls_ref = rand(Uniform(60.0, 80.0), n)
        lvls_tar = rand(Uniform(60.0, 80.0), n)

        # Apply increment to target levels
        lvls_tar .= lvls_tar .+ srs_to_ΔL(inc)

        # Return correct/incorrect
        mean(lvls_tar .> lvls_ref)
    end

    # Plot
    # fig = Figure()
    # ax = Axis(fig[1, 1])
    # lines!(ax, increments, pcorr)
    # hlines!(ax, [0.791])

    return increments[findfirst(x -> x > 0.75, pcorr)]
end

"""
    genfig_sim_bowls_puretonecontrol()

Generate figure depicting behavior vs model performance, pure-tone control 

Generate figure depicting "bowls" in different frequency conditions for different models and
observers (rows and columns, respectively). Focus on measurements of control
conditions/observers to help explain performance for LSR roved.
"""
function genfig_sim_bowls_puretonecontrol()
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:adjusted .== false)
    end

    # Load single-component control simulations
    df_control = @chain load_simulated_thresholds_puretone() begin
    end

    # Compile relevant behavioral data
    # beh = @chain fetch_behavioral_data() begin
    #     @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")
    #     avg_behavioral_data()
    # end

    # Run simulation to quickly assess where performance would be under energy-based 
    # decisions with roving
    θ_e = θ_energy()

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(700, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:3]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)
        df_control_subset = @subset(df_control, :model .== model, :mode .== mode)

        # Plot control line for θ_energy
        hlines!(ax, [θ_e]; color=:red, linestyle=:dash)

        # Plot each bowl, with raw and adjusted thresholds
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset further
            sims_unroved = @subset(df_subset, :center_freq .== freq, :adjusted .== false, :rove_size .== 0.001)
            sims_control_unroved = @subset(df_control_subset, :center_freq .== freq, :rove_size .== 0.001)
            sims_roved = @subset(df_subset, :center_freq .== freq, :adjusted .== false, :rove_size .== 10.0)
            sims_control_roved = @subset(df_control_subset, :center_freq .== freq, :rove_size .== 10.0)
            # behs = @subset(beh, :freq .== freq)

            # Add scatters and lines for: unadjusted thresholds (pink), adjusted thresholds
            # (red), and behavioral thresholds (black)
            # scatter!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_unroved.θ; color=:black)
            # lines!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_unroved.θ; color=:black)
            # scatter!(ax, [(idx-1)*8], sims_control_unroved.θ; color=:black, marker=:diamond, markersize=10.0)

            scatter!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
            lines!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
            scatter!(ax, [(idx-1)*8], sims_control_roved.θ; color=:black, marker=:diamond, markersize=10.0)

        end

        # Add ticks
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*8 .+ 1 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Set limits
        ylims!(ax, -35.0, 20.0)
        ax.yticks = -30.0:10.0:10.0
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:3], "Number of components // Target frequency (Hz)"); rowgap!(fig.layout, 3, Relative(0.05));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    colgap!(fig.layout, 3, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

"""
    genfig_sim_bowls_puretonecontrol_LSR_only()

Generate figure depicting behavior vs model performance, pure-tone control, LSR
single-channel only

Generate figure depicting "bowls" in different frequency conditions for the single-channel
LSR model.
"""
function genfig_sim_bowls_puretonecontrol_LSR_only()
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:adjusted .== false)
    end

    # Load single-component control simulations
    df_control = @chain load_simulated_thresholds_puretone() begin
    end

    # Run simulation to quickly assess where performance would be under energy-based 
    # decisions with roving
    θ_e = θ_energy()

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(300, 200))
    ax = Axis(fig[1, 1]; xticklabelrotation=π/2, xminorticksvisible=false)

    # Loop over all combinations of mode and model
    # Subset data
    df_subset = @subset(df, :model .== "AuditoryNerveZBC2014_low", :mode .== "singlechannel")
    df_control_subset = @subset(df_control, :model .== "AuditoryNerveZBC2014_low", :mode .== "singlechannel")

    # Plot control line for θ_energy
    hlines!(ax, [θ_e]; color=:red, linestyle=:dash)

    # Plot each bowl, with raw and adjusted thresholds
    map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
        # Subset further
        sims_roved = @subset(df_subset, :center_freq .== freq, :adjusted .== false, :rove_size .== 10.0)
        sims_control_roved = @subset(df_control_subset, :center_freq .== freq, :rove_size .== 10.0)

        # Plot data
        scatter!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
        lines!(ax, (1:5) .+ (idx-1)*8 .+ 1, sims_roved.θ; color=:black)
        scatter!(ax, [(idx-1)*8], sims_control_roved.θ; color=:darkgray, marker=:diamond, markersize=10.0)

    end

    # Add ticks
    ax.xticks = (
        vcat([(1:5) .+ (i-1)*8 .+ 1 for i in 1:4]...),
        repeat(["5", "13", "21", "29", "37"], 4),
    )

    # Set limits
    ylims!(ax, -35.0, 20.0)
    ax.yticks = -30.0:10.0:10.0
    
    # Add labels
    ax.ylabel = "Threshold (dB SRS)"
    ax.xlabel = "Number of components // Target frequency (Hz)"

    # Return
    fig
end


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

function genfig_followup_puretonecontrol_no_cochlear_gain()
    # We need to compare a distribution of observed target levels to a distribution of 
    # observered LSR target rates to convince ourselves that LSR rates can really outperform
    # energy-based decisions

    # Set random seeds
    seed = 949349302050240
    rng = Xoshiro(seed) 
    config = Default(; seed=seed, rng=rng, resolve_rng=true, resolve_codename=true, codename="puretonecontrol_no_cochlear_gain")

    # Pick params
    n = 1000
    n_comp = 21
    incs = -20.0:2.5:10.0

    # Configure model
    results = map(incs) do inc
        model = AuditoryNerveZBC2014(; cf=[2000.0], fiber_type="low", cohc=[0.0])

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
    genfig_puretonecontrol_mechanism()

Generates figure that demonstrates mechanism underlying LSRs exceeding expected performance 
under rove 

Simulates the difference in rate observed for a fixed level increment on a pure tone as a 
function of the relative level and frequeny of two pure-tone flankers, as compared to the 
difference in rate observed without flankers.
"""
function genfig_puretonecontrol_mechanism()
    # Set baseline parameters
    cf = 2000.0    # cf and tone frequency (Hz)
    inc = 0.0      # increment (dB SRS)
    level = 60.0   # sound level of unincremented tone (dB SPL)
    fs = 100e3     # sampling rate (Hz)
    dur = 0.1      # duration (s)

    # Set flanker parameters
    levels_flanker = 50.0:0.25:80.0
    spacings = [0.125, 0.2, 0.5, 1.0, 2.0]

    # Set up model
    model = AuditoryNerveZBC2014(; cf=[cf], fractional=false, fs=fs, fiber_type="low")

    # Simulate baseline difference
    stim1 = scale_dbspl(pure_tone(cf, 0.0, dur, fs), level)
    stim2 = scale_dbspl(pure_tone(cf, 0.0, dur, fs), level + srs_to_ΔL(inc))
    δ_ref = mean(compute(model, stim2)[1]) - mean(compute(model, stim1)[1]) 

    # Simulate differences with flankers
    results = map(spacings) do spacing
        map(levels_flanker) do level_flanker
            # Synthesize flankers
            flanker1 = scale_dbspl(pure_tone(cf * 2.0 ^ -spacing, 0.0, dur, fs), level_flanker)
            flanker2 = scale_dbspl(pure_tone(cf * 2.0 ^ spacing, 0.0, dur, fs), level_flanker)
            flanker = flanker1 .+ flanker2

            # Simulate delta
            return mean(compute(model, stim2 .+ flanker)[1]) - 
                   mean(compute(model, stim1 .+ flanker)[1])
        end
    end

    # Create figure
    colors = ColorSchemes.Dark2_6[[1, 2, 3, 4, 6]]
    set_theme!(theme_carney; fontsize=12.0)
    fig = Figure(; resolution=(350, 350))
    ax = Axis(fig[1, 1])
    lns = map(zip(results, colors)) do (r, color)
        # Transform result into percentage change
        temp = 100 .* (r ./ δ_ref) .- 100.0

        # Check if line ever goes below 0 --- if so, plot portion below as dotted, otherwise just plot it
        if any(temp .< 0.0)
            # Isolate portion above and below zero
            temp_above = temp[temp .>= 0.0]
            levels_above = levels_flanker[temp .>= 0.0]
            temp_below = temp[temp .< 0.0]
            levels_below = levels_flanker[temp .< 0.0]

            lines!(ax, levels_above, temp_above; linewidth=2.0, linestyle=:solid, color=color)
            lines!(ax, levels_below, temp_below; linewidth=2.0, linestyle=:dash, color=color)
        else
            lines!(ax, levels_flanker, temp; linewidth=2.0, color=color)
        end
    end
    hlines!(ax, [0.0]; color=:black, linewidth=3.0)

    ax.xlabel = "Flanker level (dB SPL)"
    ax.ylabel = "Increment response\nre: response w/o flankers (%)"
    ax.yticks = -100.0:50.0:150.0

    Legend(fig[2, 1], lns, string.(spacings), "Probe-flanker spacing (oct)"; orientation=:horizontal)

    fig
end

"""
    genfig_puretonecontrol_rl_functions()

Generates figure that demonstrates changes in RL functions underlying LSR "enhancement" 
under rove
"""
function genfig_puretonecontrol_rl_functions()
    # Set baseline parameters
    cf = 2000.0    # cf and tone frequency (Hz)
    fs = 100e3     # sampling rate (Hz)
    dur = 0.1      # duration (s)
    spacing = 0.5  # spacing of flakers re: target (oct)
    level_flanker = 70.0  # level of flankers (dB SPL)

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
    rl_flanked = map(levels) do level
        # Synthesize stim 
        stim = scale_dbspl(pure_tone(cf, 0.0, dur, fs), level)

        # Synthesize flankers
        flanker1 = scale_dbspl(pure_tone(cf * 2.0 ^ -spacing, 0.0, dur, fs), level_flanker)
        flanker2 = scale_dbspl(pure_tone(cf * 2.0 ^ spacing, 0.0, dur, fs), level_flanker)
        flanker = flanker1 .+ flanker2

        # Compute rate
        mean(compute(model, stim .+ flanker)[1])
    end

    # Plot
    set_theme!(theme_carney; fontsize=12.0)
    fig = Figure(; resolution=(300, 260))
    ax = Axis(fig[1, 1]; xminorticksvisible=false)
    vlines!(ax, [70.0]; color=:gray, linestyle=:dash, linewidth=1.0)
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

function gmmf(center_freq, n_comp)
    # Calculate component frequencies
    freqs = LogRange(center_freq/5, center_freq*5, n_comp)
    idx_center = Int(ceil(n_comp/2)) 
    mf1 = freqs[idx_center] - freqs[idx_center-1]
    mf2 = freqs[idx_center+1] - freqs[idx_center]
    sqrt(mf1 * mf2)
end

function pick_marker(freq)
    @match freq begin
        500.0 => :circle
        1000.0 => :rect
        2000.0 => :diamond
        4000.0 => :pentagon
    end
end

function genfig_sim_bowls_gmmf(; rove_size=0.001)
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:rove_size .== rove_size)
    end

    # Compile relevant behavioral data
    beh = @chain fetch_behavioral_data() begin
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")
        avg_behavioral_data()
    end

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(700, 700))
    axs = [Axis(fig[i, j]; xscale=log10, xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:3]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Transform into gmff units
        df_subset = @transform(df_subset, :gmmf = gmmf.(:center_freq, :n_comp))
        behs = @transform(beh, :gmmf = gmmf.(Float64.(:freq), :n_comp))

        # Subset further
        sims_adj = @subset(df_subset, :adjusted .== false)

        # Add scatters and lines for: unadjusted thresholds (pink), adjusted thresholds
        # (red), and behavioral thresholds (black)
        for center_freq in [500.0, 1000.0, 2000.0, 4000.0]
            # Plot behavioral data in black
            temp = @subset(behs, :freq .== center_freq)
            lines!(ax, temp.gmmf, temp.threshold; color=:black)
            scatter!(ax, temp.gmmf, temp.threshold; color=:black, marker=pick_marker(center_freq), markersize=10.0, label=string(center_freq))
            temp = @subset(sims_adj, :center_freq .== center_freq)
            lines!(ax, temp.gmmf, temp.θ; color=:red)
            scatter!(ax, temp.gmmf, temp.θ; color=:red, marker=pick_marker(center_freq), markersize=10.0)
        end

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
        ax.xticks = 2.0 .^ (0.0:1.0:11.0)
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:3], "Average modulation rate (Hz)"); rowgap!(fig.layout, 3, Relative(0.05));
    fig[2, 4] = Legend(fig, axs[end])

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    colgap!(fig.layout, 3, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end


"""
    genfig_sim_bowls_summary()

Generate summary plot depicting performance of each model/observer combinations

Generate a summary bar chart indicating overall model accuracy (i.e., accuracy across all
fixed-level conditions) in terms of RMS error in dB as a function of model and observer
combinations (e.g., single-channel LSR vs multi-channel IC-BE). Relies on 
compare_behavior_to_simulations() function in the PF postprocessing code.
"""
function genfig_sim_bowls_summary(; rove_size=0.001)
    # Get model results and summarize
    results = @chain load_simulated_thresholds_adjusted() begin
        groupby([:model, :mode, :rove_size, :adjusted])
        @combine(:rms = mean(:rms), :varexp = mean(:varexp))
        @orderby(:adjusted, :model)
        @subset(:rove_size .== rove_size)
    end

    # Set up fig and axes
    set_theme!(theme_carney)
    fig = Figure(; resolution=(440, 170))
    axs = [Axis(fig[1, i]; xticksvisible=false) for i in 1:2]
    ylims!.(axs, 0.0, 20.0)
    colors = ColorSchemes.Java

    # Map over unadjusted (top) and adjusted (bottom) thresholds
    bp = map(zip(
        groupby(results, :adjusted),  # grouped data
        ["Raw", "Adjusted"],          # labels
        axs,                          # axes
    )) do (data, label, ax)
        # Add title using label
        ax.title = label

        # Map over all coding schemes, plot each scheme's results as small cluster of bars
        bp = map(enumerate(["singlechannel", "profilechannel", "templatebased"])) do (idx, mode)
            # Subset data 
            temp = @chain data begin
                @subset(:mode .== mode)
                @orderby(:model)
            end

            # Add plots
            offsets = (1:3) .+ (idx - 1)*4
            bp = map(zip(offsets, temp.rms, colors)) do (offset, rms, color)
                barplot!(ax, [offset], [rms]; color=color)
            end
            return bp 
        end

        # Add ticks for each mode
        ax.xticks = ([2.0, 6.0, 10.0], ["Single\nChannel", "Profile\nChannel", "Template\nbased"])

        return bp
    end

    # Add labels to left
    Label(fig[:, 0], "RMS error (dB)"; tellheight=false, rotation=π/2)
    colgap!(fig.layout, 1, Relative(0.02))

    # Add legend to the right
    Legend(fig[:, 3], bp[1][1], ["LSR", "BE", "BS"])
    fig
end

"""
    genfig_sim_bowls_density_and_frequency_bowls_rove_effects()

Generate figure depicting model performance as function of rove

Generate figure depicting "bowls" in different frequency conditions for different models and
observers (rows and columns, respectively). Plot unroved and roved thresholds side-by-side
"""
function genfig_sim_bowls_density_and_frequency_bowls_rove_effects()
    # Get full dataframe
    df = load_simulated_thresholds_adjusted()

    # Set up figure
    set_theme!(theme_carney)
    fig = Figure(; resolution=(700, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:3]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Plot each bowl, with raw and adjusted thresholds
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset further
            sims_unroved = @subset(
                df, 
                :center_freq .== freq, 
                :adjusted .== false,
                :model .== model,
                :mode .== mode,
                :rove_size .== 0.001,
            )
            sims_roved = @subset(
                df, 
                :center_freq .== freq, 
                :adjusted .== false,
                :model .== model,
                :mode .== mode,
                :rove_size .== 10.0,
            )

            # Add scatters and lines for: unadjusted thresholds (pink), adjusted thresholds
            # (red), and behavioral thresholds (black)
            Δ = sims_roved.θ .- sims_unroved.θ
            map(enumerate(zip(sims_roved.θ, sims_unroved.θ))) do (idx_δ, (θ_roved, θ_unroved))
                lines!(ax, [idx_δ + (idx-1)*7, idx_δ + (idx-1)*7], [θ_unroved, θ_roved]; color=:darkgray)
            end
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_unroved.θ; color=:black, marker=:circle)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_unroved.θ; color=:black)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:orange, marker=:rect)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:orange)

            # Add another marker at the means in each frequency condition, beside data to right
            scatter!(ax, [6 + (idx-1)*7], [mean(sims_unroved.θ)]; color=:black, marker=:circle)
            scatter!(ax, [6 + (idx-1)*7], [mean(sims_roved.θ)]; color=:orange, marker=:rect)
            scatter!(ax, [6 + (idx-1)*7], [mean(sims_unroved.θ)]; color=:white, marker=:circle, markersize=3.0)
            scatter!(ax, [6 + (idx-1)*7], [mean(sims_roved.θ)]; color=:white, marker=:rect, markersize=3.0)

            # Add text indicating average rove effect size
            text!(ax, [3 + (idx-1)*7], [-45.0]; text="$(round(mean(Δ[.!isnan.(Δ)]); digits=1)) dB", align=(:center, :bottom), color=:darkgray)
        end

        # Add ticks
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*7 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Set limits
        ylims!(ax, -50.0, 10.0)
        ax.yticks = -40.0:10.0:10.0

        # Add text label indicating performance
#        err = round(@subset(df_subset, :adjusted .== true).rms[1]; digits=1)
#        text!(ax, [20.0], [-33.0]; color=:red, text="$err dB")
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:3], "Number of components // Target frequency (Hz)"); rowgap!(fig.layout, 3, Relative(0.05));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    colgap!(fig.layout, 3, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end
