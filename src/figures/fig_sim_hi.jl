export __genfig_sim_hi_behavior_correlations,
       __genfig_sim_hi_cohc_correlations,
       __genfig_sim_hi_psychometric_functions,
       genfig_individual_subj_cohc,
       genfig_audiograms_and_cohc

"""
    genfig_individual_subj_cohc()

Generate plot showing each subject's COHC from "fit_audiogram"
"""
function genfig_individual_subj_cohc()
    # Load audiograms, grab only needed rows, and transform into Audiogram objects
    subjs = unique(fetch_behavioral_data().subj)
    audiograms = DataFrame(CSV.File("C:\\Users\\dguest2\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"))
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

    # Plot all cohc curves
    fig = Figure()
    ax = Axis(fig[1, 1]; xscale=log10)
    map(models) do model
        lines!(ax, model.cf, max.(0.001, model.cohc))
        text!(ax, [22e3], [max(0.001, model.cohc[end])]; text=model.audiogram.desc, align=(:left, :center))
    end
    xlims!(ax, 200.0, 30e3)
    ax.xticks = [500.0, 1000.0, 2000.0, 4000.0, 8000.0]
    fig
end

"""
    genfig_audiograms_and_cohc()

Generate plot showing each subject's COHC from "fit_audiogram" and corresponding audiogram
"""
function genfig_audiograms_and_cohc()
    # Load audiograms, grab only needed rows, and transform into Audiogram objects
    subjs = unique(fetch_behavioral_data().subj)
    audiograms = DataFrame(CSV.File("C:\\Users\\dguest2\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"))
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
    __genfig_sim_hi_behavior_correlations

Plot correlations between human thresholds and audiogram-matched model thresholds
"""
function __genfig_sim_hi_behavior_correlations()
    # Load model results
    sim = load_simulated_thresholds_hi()
    sim = sim[.! isnan.(sim.θ), :]
    subjs = unique(sim.subj)
    sim = sim[in.(sim.subj, Ref(subjs)), :]
    
    # Load and summarize behavioral data
    beh = @chain fetch_behavioral_data() begin
        # Subset to only include unroved data at 1 and 2 kHz for available subjs
        @subset(in.(:freq, Ref([1000.0, 2000.0])))
        @subset(:rove .== "fixed level")
        @subset(in.(:subj, Ref(subjs)))

        # Group by target frequency, number of components, and subject
        groupby([:freq, :n_comp, :hl_group, :subj])

        # Compute average threshold
        @combine(:threshold = mean(:threshold))
    end

    figs = map(Iterators.product(unique(sim.mode), unique(sim.model))) do (mode, model)
        # Create canvas
        fig = Figure(; resolution=(500, 925))
        axs = [Axis(fig[i, j]) for i in 1:5, j in 1:2]

        # Loop through target frequencies and numbers of components, plotting correlations 
        map(zip(eachrow(axs),  [5, 13, 21, 29, 37])) do (axrow, n_comp)
            map(zip(axrow, [1000.0, 2000.0])) do (ax, center_freq)
                # Subset behavior and model results, plot
                beh_subset = @subset(beh, :freq .== center_freq, :n_comp .== n_comp)
                sim_subset = @subset(
                    sim, 
                    :center_freq .== center_freq, 
                    :n_comp .== n_comp,
                    :model .== model,
                    :mode .== mode,
                )

                # Order both by subject id
                beh_subset = @orderby(beh_subset, :subj)
                sim_subset = @orderby(sim_subset, :subj)
                @assert all(beh_subset.subj .== sim_subset.subj)

                # Plot!
                scatter!(ax, beh_subset.threshold, sim_subset.θ; color=color_group.(beh_subset.hl_group))

                # Plot model fit
                idxs = beh_subset.hl_group .!= "> 15 dB HL"
                x̂, ŷ = quickfitlm(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                ρ = cor(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                lines!(ax, x̂, ŷ; color=:black)
                text!(ax, [-20.0], [-10.0]; text="$(round(ρ; digits=2))")

                # Plot model fit (HI only)
                idxs = beh_subset.hl_group .== "> 15 dB HL"
                x̂, ŷ = quickfitlm(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                ρ = cor(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                lines!(ax, x̂, ŷ; color=get_hl_colors()[3])
                text!(ax, [-20.0], [0.0]; text="$(round(ρ; digits=2))", color=get_hl_colors()[3])
            end
        end

        # Neaten markings
        neaten_grid!(axs)

        # Set limits and ticks
        ylims!.(axs, -35.0, 10.0)
        xlims!.(axs, -30.0, 10.0)
        [ax.xticks = -30.0:10.0:0.0 for ax in axs]
        [ax.yticks = -30.0:10.0:0.0 for ax in axs]

        # Add labels
        [Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["1000.0", "2000.0"])]
        [Label(fig[i, 3], label; tellheight=false) for (i, label) in enumerate(["5", "13", "21", "29", "37"])]
        Label(fig[end+1, :], "Behavioral threshold (dB SRS)")
        Label(fig[:, 0], "Predicted threshold (dB SRS)"; rotation=π/2)

        # Adjust spacing
        colgap!(fig.layout, Relative(0.015))
        rowgap!(fig.layout, Relative(0.015))

        # Add label
        Label(fig[-1, :], "$model\n$mode")
        fig
    end

    fig = displayimg(tilecat(getimg.(figs)))
end

"""
    __genfig_sim_hi_cohc_correlations

Plot correlations between COHC and audiogram-matched model thresholds
"""
function __genfig_sim_hi_cohc_correlations()
    # Load model results
    sim = load_simulated_thresholds_hi()
    sim = sim[.! isnan.(sim.θ), :]
    subjs = unique(sim.subj)
    sim = sim[in.(sim.subj, Ref(subjs)), :]
    
    figs = map(Iterators.product(unique(sim.mode), unique(sim.model))) do (mode, model)
        # Create canvas
        fig = Figure(; resolution=(500, 925))
        axs = [Axis(fig[i, j]) for i in 1:5, j in 1:2]

        # Loop through target frequencies and numbers of components, plotting correlations 
        map(zip(eachrow(axs),  [5, 13, 21, 29, 37])) do (axrow, n_comp)
            map(zip(axrow, [1000.0, 2000.0])) do (ax, center_freq)
                # Subset behavior and model results, plot
                sim_subset = @subset(
                    sim, 
                    :center_freq .== center_freq, 
                    :n_comp .== n_comp,
                    :model .== model,
                    :mode .== mode,
                )
                color = map(sim_subset.audiogram) do audiogram
                    color_group(audiogram.thresholds[audiogram.freqs .== center_freq][1])
                end

                # Order both by subject id
#                sim_subset = @orderby(sim_subset, :subj)

                # Plot!
                scatter!(ax, sim_subset.cohc, sim_subset.θ; color=color)
                lines!(ax, smooth(sim_subset.cohc, sim_subset.θ; upsample=5, span=0.8)...; color=:black)

                # # Plot model fit
                # idxs = beh_subset.hl_group .!= "> 15 dB HL"
                # x̂, ŷ = quickfitlm(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                # ρ = cor(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                # lines!(ax, x̂, ŷ; color=:black)
                # text!(ax, [-20.0], [-10.0]; text="$(round(ρ; digits=2))")

                # # Plot model fit (HI only)
                # idxs = beh_subset.hl_group .== "> 15 dB HL"
                # x̂, ŷ = quickfitlm(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                # ρ = cor(beh_subset.threshold[idxs], sim_subset.θ[idxs])
                # lines!(ax, x̂, ŷ; color=get_hl_colors()[3])
                # text!(ax, [-20.0], [0.0]; text="$(round(ρ; digits=2))", color=get_hl_colors()[3])
            end
        end

        # Neaten markings
        neaten_grid!(axs)

        # Set limits and ticks
        ylims!.(axs, -35.0, 10.0)
        xlims!.(axs, 0.0, 1.0625)
#        [ax.xticks = -30.0:10.0:0.0 for ax in axs]
        [ax.yticks = -30.0:10.0:0.0 for ax in axs]

        # Add labels
        [Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["1000.0", "2000.0"])]
        [Label(fig[i, 3], label; tellheight=false) for (i, label) in enumerate(["5", "13", "21", "29", "37"])]
        Label(fig[end+1, :], "Behavioral threshold (dB SRS)")
        Label(fig[:, 0], "Predicted threshold (dB SRS)"; rotation=π/2)

        # Adjust spacing
        colgap!(fig.layout, Relative(0.015))
        rowgap!(fig.layout, Relative(0.015))

        # Add label
        Label(fig[-1, :], "$model\n$mode")
        fig
    end

    fig = displayimg(tilecat(getimg.(figs)))
end


"""
    __genfig_sim_hi_psychometric_functions()
"""
function __genfig_sim_hi_psychometric_functions(; 
#    mode="templatebased",
    center_freq=1000.0,
    n_comp=5,
    rove_size=0.001,
    increments=-30.0:2.5:5.0,
)
    # Select subjects
    subjs = ["S098", "S165", "S167", "S168", "S170"]
    audiograms = fetch_audiograms()
    audiogram_subjs = getfield.(audiograms, :desc)
    audiograms = map(subjs) do subj
        audiograms[audiogram_subjs .== subj][1]
    end

    # Create canvas
    fig = Figure(; resolution=(200*length(subjs), 800))
    axs = [Axis(fig[i, j]) for i in 1:4, j in eachindex(subjs)]

    # Map over audiograms
    map(zip(eachcol(axs), audiograms)) do (axcol, audiogram)
        # Choose model
        models = setup_nohsr(ProfileAnalysis_PFTemplateObserver(), center_freq, cf_range, audiogram; n_cf=n_cf_reduced)

        # Map over models and plot corresponding PFs
        map(zip(axcol[2:end], models)) do (ax, model)
            # Configure PF
            pf = Utilities.setup(
                ProfileAnalysis_PFTemplateObserver(), 
                model, 
                increments, 
                center_freq, 
                n_comp, 
                rove_size;
                n_rep_template=n_rep_template_reduced,
                n_rep_trial=n_rep_trial_reduced,
            )

            # Load if possible
            if isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                out = @memo Default() sim(pf)
                mod = Utilities.fit(pf, increments, out)
                μ = map(mean, out)
                σ = map(x -> std(x)/sqrt(length(x)), out)
                viz!(ProfileAnalysis_PFTemplateObserver(), ax, increments, μ, σ, mod)
            end

            # Add labels
            ax.xlabel = "Increment (dB SRS)"
            ax.ylabel = "Proportion correct"
        end

        # Plot audiogram
        scatter!(axcol[1], models[1].cf / 1000, models[1].cohc)
        lines!(axcol[1], models[1].cf / 1000, models[1].cohc)
        ylims!(axcol[1], 0.0, 1.0)
        xlims!(axcol[1], 0.25, 10.0)
        axcol[1].xscale = log10

        # Plot extended audiogram
        modeltemp = AuditoryNerveZBC2014(; cf=LogRange(0.2e3, 20e3, 250), audiogram=audiogram)
        lines!(axcol[1], modeltemp.cf / 1000, modeltemp.cohc; color=:lightgray)
        axcol[1].xticks = [500.0, 1000.0, 2000.0, 4000.0] ./ 1000
        axcol[1].xlabel = "CF (Hz)"
        axcol[1].ylabel = "COHC"
    end

    # Neaten markings
    neaten_grid!(axs)

    # Add labels
    map(enumerate(audiograms)) do (idx, audiogram)
        Label(fig[0, idx], audiogram.desc; tellwidth=false)
    end
    map(zip(2:4, ["LSR", "BE", "BS"])) do (idx, label)
        Label(fig[idx, length(subjs)+1], label; tellheight=false)
    end

    fig
end