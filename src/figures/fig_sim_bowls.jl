export genfig_sim_bowls_density_and_frequency_bowls,
       genfig_sim_bowls_density_and_frequency_bowls_rove_effects,
       genfig_sim_bowls_summary

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
function genfig_sim_bowls_density_and_frequency_bowls(; rove_size=0.001)
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
    fig = Figure(; resolution=(700, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:3]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Plot each bowl, with raw and adjusted thresholds
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset further
            sims = @subset(df_subset, :center_freq .== freq, :adjusted .== false)
            sims_adj = @subset(df_subset, :center_freq .== freq, :adjusted .== true)
            behs = @subset(beh, :freq .== freq)

            # Add scatters and lines for: unadjusted thresholds (pink), adjusted thresholds
            # (red), and behavioral thresholds (black)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims.θ; color=:pink)
            lines!(ax, (1:5) .+ (idx-1)*7, sims.θ; color=:pink)
            scatter!(ax, (1:5) .+ (idx-1)*7, behs.threshold; color=:black)
            lines!(ax, (1:5) .+ (idx-1)*7, behs.threshold; color=:black)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_adj.θ; color=:red)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_adj.θ; color=:red)

            # Add another marker at the means in each frequency condition, beside data to right
            μ_beh = mean(behs.threshold)
            μ_mod = mean(sims_adj.θ)
            lines!(ax, [6 + (idx-1)*7, 6 + (idx-1)*7], [μ_beh, μ_mod]; color=:lightgray)
            scatter!(ax, [6 + (idx-1)*7], [μ_beh]; color=:black, marker=:rect)
            scatter!(ax, [6 + (idx-1)*7], [μ_mod]; color=:red, marker=:rect)
            scatter!(ax, [6 + (idx-1)*7], [μ_beh]; color=:white, marker=:rect, markersize=3.0)
            scatter!(ax, [6 + (idx-1)*7], [μ_mod]; color=:white, marker=:rect, markersize=3.0)
        end

        # Add ticks
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*7 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0

        # Add text label indicating performance
        err = round(@subset(df_subset, :adjusted .== true).rms[1]; digits=1)
        text!(ax, [20.0], [-33.0]; color=:red, text="$err dB")

        # Add info at top of page
        errvar = max(0.0, round(100.0 * @subset(df_subset, :adjusted .== true).varexp[1]; digits=3))
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
