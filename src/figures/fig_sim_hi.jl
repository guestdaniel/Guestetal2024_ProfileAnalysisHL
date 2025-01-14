export genfig_sim_hi_behavior_correlations,
       genfig_sim_hi_cohc_correlations,
       genfig_audiograms_and_cohc,
       genfig_sim_hi_bowls,
       estimate_cohc_vs_gain

"""
    genfig_audiograms_and_cohc()

Generate plot showing each subject's audiogram and derived COHC value

Subjects are faceted over columns and rows and each subplot shows one subject's behavioral 
audiogrm plus their corresponding COHC and CIHC curves across the same frequency range.
Markers at each audiogram threshold are colored according to the resulting HL group the 
subject would be assigned to at that frequency.
"""
function genfig_audiograms_and_cohc()
    # Load audiograms, grab only needed rows, and transform into Audiogram objects
    subjs = unique(fetch_behavioral_data().subj)
    audiograms = DataFrame(CSV.File(projectdir("data", "int_pro", "audiometry.csv")))
    audiograms[audiograms.Subject .== "S98", :Subject] .= "S098"
    audiograms = @subset(audiograms, in.(:Subject, Ref(subjs)))
    audiograms = map(subjs) do subj
        # Subset row
        row = audiograms[audiograms.Subject .== subj, :]

        # Select frequencies and thresholds
        f = [250.0, 500.0, 1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]
        θ = Vector(row[1, 4:12])

        # Combine into Audiogram objects
        Audiogram(; freqs=f, thresholds=θ, species="human", desc=subj)
    end

    # Turn into models and plot COHC
    models = map(audiograms) do audiogram
        AuditoryNerveZBC2014(; cf=LogRange(250.0, 20e3, 200), audiogram=audiogram)
    end

    # Sort audiograms and models based on PTA across 0.5 - 4 kHz
    pta = map(audiograms) do audiogram
        θ_sub = audiogram.thresholds[[2, 3, 5, 7]]
        mean(θ_sub)
    end
    p = sortperm(pta)
    audiograms = audiograms[p]
    models = models[p]

    # Set up figure
    fig = Figure(; resolution=(900, 900))
    n_per_side = Int(ceil(sqrt(length(models))))
    axs_hl = Matrix{Axis}(undef, n_per_side, n_per_side)
    axs_cohc = Matrix{Axis}(undef, n_per_side, n_per_side)
    idxs = transpose(LinearIndices(axs_hl))
    color_cohc = HSL(300, 1.0, 0.5)

    # Loop through combinations
    for i in 1:n_per_side
        for j in 1:n_per_side
            # If we're exceeding bounds, skip!
            if idxs[i, j] > length(audiograms)
                continue
            end

            # Grab necessary objects
            audiogram = audiograms[idxs[i, j]]
            model = models[idxs[i, j]]
            axs_hl[i, j] = Axis(fig[i, j], xscale=log10)
            axs_cohc[i, j] = Axis(
                fig[i, j], 
                xscale=log10, 
                yaxisposition=:right, 
                ytickcolor=color_cohc, 
                yticklabelcolor=color_cohc,
            )

            # Make plot (HL)
            ax = axs_hl[i, j]
            lines!(ax, audiogram.freqs, audiogram.thresholds; color=:black, linewidth=2.0)  # main solid line
            f_sub = audiogram.freqs[[2, 3, 5, 7]]
            θ_sub = audiogram.thresholds[[2, 3, 5, 7]]
            colors = color_group.(θ_sub)
            scatter!(ax, f_sub, θ_sub; color=colors)
            xlims!(ax, 200.0, 16e3)
            ylims!(ax, 80.0, -5.0)
            ax.xticks = ([500.0, 1000.0, 2000.0, 4000.0, 8000.0], ["0", "1", "2", "4", "8"])
            ax.title = audiogram.desc

            # Make plot (COHC)
            ax = axs_cohc[i, j]
            lines!(ax, model.cf, model.cohc; color=color_cohc, linewidth=1.0)
            lines!(ax, model.cf, model.cihc; color=color_cohc, linewidth=1.0, linestyle=:dash)
            xlims!(ax, 200.0, 16e3)
            ylims!(ax, 0.0, 1.0625)
            ax.xticks = ([500.0, 1000.0, 2000.0, 4000.0, 8000.0], ["0", "1", "2", "4", "8"])
        end
    end

    # Hide unecessary grid components
    hidexdecorations!.(axs_hl[1:3, :], grid=false)
    hidexdecorations!(axs_hl[4, 1], grid=false)
    hideydecorations!.(axs_hl[1:4, 2:end], grid=false)
    hideydecorations!.(axs_cohc[1:4, 1:4], grid=false)
    hideydecorations!(axs_cohc[5, 1], grid=false)
    hidexdecorations!.(axs_cohc[1:3, :], grid=false)
    hidexdecorations!(axs_cohc[4, 1], grid=false)

    # Set gaps
    rowgap!(fig.layout, Relative(0.02))
    rowgap!(fig.layout, 4, Relative(-0.01))

    # Add labels
    Label(fig[1:5, 0], "Audiometric threshold (dB HL)"; rotation=π/2, tellheight=false)
    Label(fig[1:5, 6], "COHC (solid) / CIHC (dashed)"; rotation=π/2, tellheight=false, color=color_cohc)
    colgap!(fig.layout, 1, Relative(0.015))
    colgap!(fig.layout, 6, Relative(0.01))
    fig
end

"""
    genfig_sim_hi_behavior_correlations

Plot correlations between human thresholds and audiogram-matched model thresholds

Depicts scatterplots showing behavioral thresholds versus predicted thresholds for each
individual subject based on a model with their individual audiogram. Includes fixed-level
data only at kHz. Data are pooled across component-count conditions and then faceted by
model type and observer strategy. Color indicates the HL group. Variance explained values
for linear models fit through each HL group separately in each panel are printed in blank
space near the left.
"""
function genfig_sim_hi_behavior_correlations(freq=2e3, grouper=grouper_threeway)
    # Load simulated thresolds 
    sim = @chain load_simulated_thresholds_hi() begin 
        # Subset data
        @subset(:rove_size .== 0.001)  # as of 9/21/2023, only includes fixed-level, but this ensures it!
        @subset(:center_freq .== freq)

        # Group by freq, hl_group, subj, etc.
        groupby([:center_freq, :subj, :mode, :model])  # drop n_comp to pool across n_comp

        # Compute average threshold
        @combine(:threshold = mean(:θ))
    end

    # Load and summarize behavioral data
    beh = @chain grouper(fetch_behavioral_data()) begin
        # Subset data
        @subset(in.(:freq, Ref([freq])))
        @subset(:rove .== "fixed level")

        # Group by target frequency, number of components, and subject
        groupby([:freq, :hl_group, :subj])  # drop n_comp to pool across n_comp

        # Compute average threshold
        @combine(:threshold = mean(:threshold))
    end

    # Set up figure
    set_theme!(theme_carney; fontsize=13.0)
    fig = Figure(; resolution=(350, 475))
    axs = [Axis(fig[i, j]) for i in 1:3, j in 1:2]

    # Loop over different combinations of observer ("mode") and model stage
    modes = ["singlechannel", "templatebased"]
    models = ["AuditoryNerveZBC2014_low", "InferiorColliculusSFIEBE", "InferiorColliculusSFIEBS"]
    map(zip(axs, Iterators.product(models, modes))) do (ax, (model, mode))
        # Subset sim to this mode and model
        sim_subset = @subset(sim, :mode .== mode, :model .== model)

        # Order both beh and sim by subj -> freq -> n_comp
        beh_subset = @orderby(beh, :subj, :freq)#, :n_comp)
        sim_subset = @orderby(sim_subset, :subj, :center_freq)#, :n_comp)

        # Assert that everything is in the expected order across both datasets
        @assert all(beh_subset.subj .== sim_subset.subj)
        @assert all(beh_subset.freq .== sim_subset.center_freq)

        # Plot data + regression lines for each HL group separately
        map(enumerate(unique(beh.hl_group)[[2, 1, 3]])) do (idx, group)
            # Subset data
            idxs_good = beh_subset.hl_group .== group
#            idxs_good = (beh_subset.hl_group .== group) .& (beh_subset.include .== true)
#            idxs_bad = (beh_subset.hl_group .== group) .& (beh_subset.include .== false)

            # Configure color
            color=(color_group(group), group == "Hearing loss\n(LF and HF)" ? 1.0 : 0.5)

            # Plot scatter (for included "valid" data)
            scatter!(
                ax, 
                beh_subset[idxs_good, :threshold], 
                sim_subset[idxs_good, :threshold]; 
                color=color
            )

            # Plot scatter (for excluded "invalid" data)
            # scatter!(
            #     ax, 
            #     beh_subset[idxs_bad, :threshold], 
            #     sim_subset[idxs_bad, :threshold]; 
            #     color=:grey,
            #     marker=:xcross,
            # )

            # Fit linear model (only to included data)
            x̂, ŷ = quickfitlm(
                beh_subset.threshold[idxs_good], 
                sim_subset.threshold[idxs_good],
            )
            ρ = cor(
                beh_subset.threshold[idxs_good], 
                sim_subset.threshold[idxs_good]
            )

            # Plot lines and text
            lines!(ax, x̂, ŷ; color=color)
            text!(ax, [-33.0], [-20.0 + idx*5]; text="$(round(ρ^2*100; digits=1))%", color=color)
        end
    end

    # Neaten markings
    neaten_grid!(axs)

    # Set limits and ticks
    ylims!.(axs, -35.0, 25.0)
    xlims!.(axs, -35.0, 25.0)
    [ax.xticks = -30.0:10.0:20.0 for ax in axs]
    [ax.yticks = -30.0:10.0:20.0 for ax in axs]

    # Add labels
    Label(fig[4, :], "Behavioral threshold (dB SRS)")
    Label(fig[:, 0], "Predicted threshold (dB SRS)"; rotation=π/2)

    # Adjust spacing
    colgap!(fig.layout, Relative(0.015))
    rowgap!(fig.layout, Relative(0.015))

    fig
end

"""
    genfig_sim_hi_cohc_correlations

Plot correlations between audiogram-matched model thresholds and COHC at target frequency

Depicts scatterplots compared individualized model thresholds to underlying COHC/CIHC
values. Includes fixed-level data only at 2 kHz. Data are pooled component-count conditions
and then faceted by model type and observer strategy. Color indicates the HL group. 
"""
function genfig_sim_hi_cohc_correlations()
    # Load simulated thresolds 
    sim = @chain load_simulated_thresholds_hi() begin 
        @subset(:rove_size .== 0.001)  # as of 9/21/2023, only includes fixed-level, but this ensures it!
    end

    # Load and summarize behavioral data
    beh = @chain fetch_behavioral_data() begin
        # Subset to only include unroved data at 1 and 2 kHz for available subjs
        @subset(in.(:freq, Ref([1000.0, 2000.0])))
        @subset(:rove .== "fixed level")  # see comment above re: simulations

        # Group by target frequency, number of components, and subject
        groupby([:freq, :n_comp, :hl_group, :subj, :include])

        # Compute average threshold
        @combine(:threshold = mean(:threshold))
    end

    # Loop through rows of sim and add HL group and include
    sim[!, :hl_group] .= "none"
    sim[!, :include] .=  false
    for idx_row in 1:nrow(sim)
        sim[idx_row, :hl_group] = unique(beh[(beh.subj .== sim[idx_row, :subj]) .& (beh.freq .== sim[idx_row, :center_freq]), :hl_group])[1]
        sim[idx_row, :include] = unique(beh[(beh.subj .== sim[idx_row, :subj]) .& (beh.freq .== sim[idx_row, :center_freq]) .& (beh.n_comp .== sim[idx_row, :n_comp]), :include])[1]
    end

    # Transform "COHC" into "COHC_gainloss", a measure of how much cochlear gain is lost 
    # at a given COHC relative to COHC=0.0
    cohc, gainloss = estimate_cohc_vs_gain(2000.0, 20.0)  # 2 kHz, 20 dB SPL
    sim[!, :cohc_gainloss] .= 0.0
    for idx_row in 1:nrow(sim)
        sim[idx_row, :cohc_gainloss] = gainloss[argmin(abs.(cohc .- sim[idx_row, :cohc]))]
    end

    # Transform COHC_gainloss from negative-signed to positive-signed (interpret as gain reduction re: COHC=0.0)
    sim.cohc_gainloss[sim.cohc_gainloss .!= 0.0] .= -1 .* sim.cohc_gainloss[sim.cohc_gainloss .!= 0.0]

    # Figure out where to fill in background with color to indicate "HL group"
    criteria = @chain sim begin
        groupby([:hl_group])
        @combine(
            :cohc_gainloss_min = maximum(:cohc_gainloss),
            :cohc_gainloss_max = minimum(:cohc_gainloss),
        )
    end
    boundary_good_mid = mean([
        criteria[criteria.hl_group .== "< 5 dB HL", :cohc_gainloss_min][1],
        criteria[criteria.hl_group .== "5-15 dB HL", :cohc_gainloss_max][1],
    ])
    boundary_mid_poor = mean([
        criteria[criteria.hl_group .== "5-15 dB HL", :cohc_gainloss_min][1],
        criteria[criteria.hl_group .== "> 15 dB HL", :cohc_gainloss_max][1],
    ])

    # Set up figure
    set_theme!(theme_carney; fontsize=13.0)
    fig = Figure(; resolution=(350, 475))
    axs = [Axis(fig[i, j]) for i in 1:3, j in 1:2]

    # In each axis, draw colored boxes to indicate HL group
    for ax in axs
        band!(ax, [-5.0, boundary_good_mid], [-45.0, -45.0], [25.0, 25.0]; color=(get_hl_colors()[1], 0.2))
        band!(ax, [boundary_good_mid, boundary_mid_poor], [-45.0, -45.0], [25.0, 25.0]; color=(get_hl_colors()[2], 0.2))
        band!(ax, [boundary_mid_poor, 40.0], [-45.0, -45.0], [25.0, 25.0]; color=(get_hl_colors()[3], 0.2))
    end

    # Loop over different combinations of observer ("mode") and model stage
    modes = ["singlechannel", "templatebased"]
    models = ["AuditoryNerveZBC2014_low", "InferiorColliculusSFIEBE", "InferiorColliculusSFIEBS"]
    colors = ColorSchemes.OrRd_7[3:end]
    map(zip(axs, Iterators.product(models, modes))) do (ax, (model, mode))
        # Subset model data
        beh_subset = copy(beh)
        sim_subset = @subset(sim, :mode .== mode, :model .== model)

        # Order both by subject id
        beh_subset = @orderby(beh_subset, :subj, :freq, :n_comp)
        sim_subset = @orderby(sim_subset, :subj, :center_freq, :n_comp)
        @assert all(beh_subset.subj .== sim_subset.subj)
        @assert all(beh_subset.freq .== sim_subset.center_freq)
        @assert all(beh_subset.n_comp.== sim_subset.n_comp)

        # Plot LOESS lines for each component count
        map(enumerate([5, 13, 21, 29, 37])) do (idx, n_comp)
            map([2000.0]) do center_freq
                sim_ss = @subset(sim_subset, :n_comp .== n_comp, :center_freq .== center_freq)
                scatter!(
                    ax, 
                    sim_ss.cohc_gainloss[sim_ss.include .== true], 
                    sim_ss.θ[sim_ss.include .== true]; 
                    color=colors[idx], 
                    marker=pick_marker2(n_comp),
                    label=string(n_comp),
                )
                scatter!(
                    ax, 
                    sim_ss.cohc_gainloss[sim_ss.include .== false], 
                    sim_ss.θ[sim_ss.include .== false]; 
                    color=:gray, 
                    marker=:xcross,
                )
                lines!(
                    ax, 
                    smooth(sim_ss.cohc_gainloss[sim_ss.include .== true], sim_ss.θ[sim_ss.include .== true]; upsample=5, span=0.8)...; 
                    color=colors[idx]
                )
            end
        end
        if (model == "InferiorColliculusSFIEBS") & (mode == "templatebased")
            axislegend(ax; orientation=:horizontal, position=:lb, colgap=3.0, padding=(1.0f0, 1.0f0, 1.0f0, 1.0f0), nbanks=2, rowgap=0.0, patchlabelgap=1.0, markersize=20.0)
        end
    end

    # Neaten markings
    neaten_grid!(axs)

    # Set limits and ticks
    ylims!.(axs, -40.0, 25.0)
    xlims!.(axs, -3.0, 40.0)
    # [ax.xticks = 0.0:0.25:0.75 for ax in axs]
    [ax.yticks = -30.0:10.0:20.0 for ax in axs]

    # Add labels
    Label(fig[4, :], "Cochlear gain loss at CF attributed to OHC loss (dB)")
    Label(fig[:, 0], "Predicted threshold (dB SRS)"; rotation=π/2)

    # Adjust spacing
    colgap!(fig.layout, Relative(0.015))
    rowgap!(fig.layout, Relative(0.015))

    fig
end

"""
    genfig_sim_hi_bowls

Plot profile-analysis "bowls" for different simulated degrees of hearing loss

Depicts average thresholds as a function of component count for behavioral data and 
audiogram-matched hearing-impaired simulations. Can show data only for 1 kHz or data only for
2 kHz based on an argument, but only the 2-kHz result is currently included in figures.
Color and horizontal arrangement indicate HL group, while observer strategy and model stage
are faceted in a grid.
"""
function genfig_sim_hi_bowls(freq=1000.0, grouper=grouper_threeway)
    # Load simulated thresolds 
    sim = @chain load_simulated_thresholds_hi() begin 
        @subset(:rove_size .== 0.001)  # as of 9/21/2023, only includes fixed-level, but this ensures it!
        @subset(:center_freq .== freq)
    end

    # Load and summarize behavioral data
    beh = @chain grouper(fetch_behavioral_data()) begin
        # Subset to only include unroved data at 1 and 2 kHz for available subjs
        @subset(:freq .== freq)
        @subset(:rove .== "fixed level")  # see comment above re: simulations

        # Group by target frequency, number of components, and subject
        groupby([:freq, :n_comp, :hl_group, :subj])

        # Compute average threshold
        @combine(:threshold = mean(:threshold))
    end

    # Loop through rows of sim and add HL group to the sim dataframe
    sim[!, :hl_group] .= "none"
#    sim[!, :include] .=  false
    for idx_row in 1:nrow(sim)
        sim[idx_row, :hl_group] = unique(beh[(beh.subj .== sim[idx_row, :subj]) .& (beh.freq .== sim[idx_row, :center_freq]), :hl_group])[1]
#        sim[idx_row, :include] = unique(beh[(beh.subj .== sim[idx_row, :subj]) .& (beh.freq .== sim[idx_row, :center_freq]) .& (beh.n_comp .== sim[idx_row, :n_comp]), :include])[1]
    end

    # Configure plotting parameters and set up plot
    set_theme!(theme_carney; fontsize=13.0)
    fig = Figure(; resolution=(600, 450))
    axs = [Axis(fig[i, j]; xminorticksvisible=false, xticklabelrotation=π/2) for i in 1:3, j in 1:2]

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    # Loop over different combinations of observer ("mode") and model stage
    modes = ["singlechannel", "templatebased"]
    models = ["AuditoryNerveZBC2014_low", "InferiorColliculusSFIEBE", "InferiorColliculusSFIEBS"]
    map(zip(axs, Iterators.product(models, modes))) do (ax, (model, mode))
        # Compute average thresholds for this model and mode, separately for each HL group
        sub_beh = @chain beh begin
            groupby([:n_comp, :hl_group])
            @combine(
                :stderr = std(:threshold)/sqrt(length(:threshold)),
                :threshold = mean(:threshold),
            )
        end

        sub_sim = @chain sim begin
            @subset(:model .== model, :mode .== mode)
            groupby([:n_comp, :hl_group])
            @combine(
                :stderr = std(:θ)/sqrt(length(:θ)),
                :threshold = mean(:θ),
            )
        end

        # Adjust model thresholds to have same mean as behavioral threhsolds
        sub_sim.threshold .= sub_sim.threshold .+ mean(sub_beh.threshold .- sub_sim.threshold)

        # Make sure sub_beh and sub_sim are ordered in the same way and compute loss
        sub_beh = @orderby(sub_beh, :n_comp, :hl_group)
        sub_sim = @orderby(sub_sim, :n_comp, :hl_group)
        @assert all((sub_beh.hl_group .== sub_sim.hl_group) .& (sub_beh.n_comp .== sub_sim.n_comp))
        loss = sqrt(mean((sub_beh.threshold .- sub_sim.threshold) .^ 2))

        # Loop over and plot each group separately
        for (idx, group) in enumerate(unique(beh.hl_group)[[2, 1, 3]])
            # Subset data again
            temp_beh = @subset(sub_beh, :hl_group .== group)
            temp_sim = @subset(sub_sim, :hl_group .== group)

            # Plot behavoral bowl
            lines!(ax, (1:5) .+ (idx-1)*7, temp_beh.threshold; color=color_group(group))
            if mean(temp_beh.threshold) > mean(temp_sim.threshold)
                errorbars!(
                    ax, 
                    (1:5) .+ (idx-1)*7, 
                    temp_beh.threshold, 
                    zeros(nrow(temp_beh)), 
                    1.96 .* temp_beh.stderr; 
                    color=color_group(group)
                )
            else
                errorbars!(
                    ax, 
                    (1:5) .+ (idx-1)*7, 
                    temp_beh.threshold, 
                    1.96 .* temp_beh.stderr, 
                    zeros(nrow(temp_beh)); 
                    color=color_group(group)
                )
            end
            scatter!(ax, (1:5) .+ (idx-1)*7, temp_beh.threshold; color=color_group(group))

            # Plot model bowl
            lines!(ax, (1:5) .+ (idx-1)*7, temp_sim.threshold; color=:black, linestyle=:dash)
            if mean(temp_beh.threshold) > mean(temp_sim.threshold)
                errorbars!(
                    ax, 
                    (1:5) .+ (idx-1)*7, 
                    temp_sim.threshold, 
                    1.96 .* temp_sim.stderr, 
                    zeros(nrow(temp_sim)); 
                    color=:black,
                )
            else
                errorbars!(
                    ax, 
                    (1:5) .+ (idx-1)*7, 
                    temp_sim.threshold, 
                    zeros(nrow(temp_sim)), 
                    1.96 .* temp_sim.stderr; 
                    color=:black,
                )
            end
            scatter!(ax, (1:5) .+ (idx-1)*7, temp_sim.threshold; color=:black, marker=:utriangle)

            # Add loss text
            text!(ax, [1.0], [12.5]; text="RMSE adj. = $(round(loss; digits=1)) dB")

        end
        # Adjust limits and ticks 
        ylims!(ax, -25.0, 20.0)
        ax.yticks = -30:10:10

        # Set xticks
        xticks = vcat(
            [1, 2, 3, 4, 5],
            [8, 9, 10, 11, 12],
            [15, 16, 17, 18, 19],
        )
        xticklabels = repeat(["5", "13", "21", "29", "37"], 3)
        ax.xticks = (xticks, xticklabels)
    end

    # Add labels
    Label(fig[:, 0], "Model threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Number of components"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Render and save
    fig
end

function estimate_cohc_vs_gain(freq=2000.0, level=20.0)
    # Quick and dirty simulation to quantify degree of cochlear gain as a function of COHC
    cohcs = LinRange(0.0, 1.0, 30)
    gains = map(cohcs) do cohc
        # Synthesize pure tone
        stim = scale_dbspl(pure_tone(freq, 0.0, 0.1, 100e3), level)

        # Simulate C1 filter response
        c1 = sim_ihcall_zbc2014(stim, freq; fs=100e3, cohc=cohc)[2]  # second element is C1 response

        # Return gain
        20 * log10(maximum(c1)/maximum(stim))
    end

    # Express cochlear gain w.r.t. gain at 0 COHC
    gains = gains .- gains[end]
    
    return cohcs, gains
end