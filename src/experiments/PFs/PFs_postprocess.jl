export summon_pf,
       postprocess_pfs, 
       postprocess_pfs_extended,
       postprocess_pfs_reduced,
       postprocess_pfs_hi,
       postprocess_pfs_puretone,
       compare_behavior_to_simulations,
       load_simulated_thresholds,
       load_simulated_thresholds_hi,
       load_simulated_thresholds_adjusted,
       load_simulated_thresholds_reduced,
       load_simulated_thresholds_puretone,
       load_simulated_thresholds_extended,
       plot_histograms_versus_increment_sound_level_control

function summon_pf(; 
    center_freq=1000.0, 
    n_comp=21, 
    increments=vcat(-999.9, -45.0:2.5:5.0),
    rove_size=0.001,
    model=1,
    mode="singlechannel",
)
    # Handle modeswitch
    if (mode == "singlechannel") | (mode == "profilechannel")
        exp = ProfileAnalysis_PFObserver()
    elseif mode == "templatebased"
        exp = ProfileAnalysis_PFTemplateObserver()
    end
    models = setup(exp, center_freq)
    m = models[model]
    getpffunc(mode, model, exp)(m, increments, center_freq, n_comp, rove_size)
end

"""
    postprocess_pfs([center_freqs, n_comps, increments, rove_sizes])

Postprocess constant-stimulus PFs to extract thresholds and slopes and save
"""
function postprocess_pfs(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
    rove_sizes=[0.001, 10.0],
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(Iterators.product(center_freqs, rove_sizes)) do (center_freq, rove_size)
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end

            # Fetch possible models, subset to exclude HSR
            models = setup(exp, center_freq)[2:end]

            # Map through models
            out = map(models) do model
                # Map through n_comps for this model, fit psychometric function, and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp, rove_size)
                    if isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                        out = @memo Default() simulate(pf)
                        Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                    else
                        NaN
                    end
                end

                # Compile results into dataframe
                DataFrame(
                    θ=θ, 
                    n_comp=n_comps, 
                    center_freq=center_freq, 
                    mode=mode, 
                    model=model,
                    rove_size=rove_size,
                )
            end

            # Concatenate and return
            vcat(out...)
        end

        # Concatenate and return
        vcat(out...)
    end

    # Concatenate all together
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds.jld2"), Dict("df" => df))
    df
end

"""
    postprocess_pfs_reduced([center_freqs, n_comps, increments, rove_sizes])

Postprocess constant-stimulus PFs to extract thresholds and slopes and save
"""
function postprocess_pfs_reduced(
    center_freqs=[1000.0, 2000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
    rove_sizes=[0.001],
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(Iterators.product(center_freqs, rove_sizes)) do (center_freq, rove_size)
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end

            # Fetch possible models, subset to exclude HSR
            models = setup(exp, center_freq; n_cf=n_cf_reduced)[2:end]

            # Map through models
            out = map(models) do model
                # Map through n_comps for this model, fit psychometric function, and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    if mode == "singlechannel"
                        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
                        pf = Utilities.setup(
                            exp, 
                            model, 
                            increments, 
                            center_freq, 
                            n_comp, 
                            rove_size; 
                            observer=obs, 
                            n_rep_trial=n_rep_trial_reduced,
                        )
                    elseif mode == "templatebased"
                        pf = Utilities.setup(
                            exp, 
                            model, 
                            increments, 
                            center_freq, 
                            n_comp, 
                            rove_size; 
                            n_rep_template=n_rep_template_reduced, 
                            n_rep_trial=n_rep_trial_reduced,
                        )
                    end

                    # Check if files exist, and if so proceed
                    if isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                        out = @memo Default() simulate(pf)
                        Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                    else
                        NaN
                    end
                end

                # Compile results into dataframe
                DataFrame(
                    θ=θ, 
                    n_comp=n_comps, 
                    center_freq=center_freq, 
                    mode=mode, 
                    model=model,
                    rove_size=rove_size,
                )
            end

            # Concatenate and return
            vcat(out...)
        end

        # Concatenate and return
        vcat(out...)
    end

    # Concatenate all together
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds_reduced.jld2"), Dict("df" => df))
    df
end


"""
    postprocess_pfs_hi([center_freqs, n_comps, increments, rove_sizes])

Postprocess constant-stimulus PFs to extract thresholds and slopes and save

Variant for the hearing-impaired simulation series
"""
function postprocess_pfs_hi(
    center_freqs=[1000.0, 2000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=-30.0:2.5:5.0,
    rove_sizes=[0.001],
    audiograms=fetch_audiograms(),
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(Iterators.product(center_freqs, rove_sizes, audiograms)) do (center_freq, rove_size, audiogram)
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end

            # Fetch possible models, subset to exclude HSR
            models = setup_nohsr(exp, center_freq, cf_range, audiogram; n_cf=n_cf_reduced)

            # Map through models
            out = map(models) do model
                # Map through n_comps for this model, fit psychometric function, and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    if mode == "singlechannel"
                        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
                        pf = Utilities.setup(
                            exp, 
                            model, 
                            increments, 
                            center_freq, 
                            n_comp, 
                            rove_size; 
                            observer=obs, 
                            n_rep_trial=n_rep_trial_reduced,
                        )
                    elseif mode == "profilechannel"
                        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
                        pf = Utilities.setup(
                            exp, 
                            model, 
                            increments, 
                            center_freq, 
                            n_comp, 
                            rove_size; 
                            observer=obs, 
                            preprocessor=pre_emphasize_profile, 
                            n_rep_trial=n_rep_trial_reduced,
                        )
                    elseif mode == "templatebased"
                        pf = Utilities.setup(
                            exp, 
                            model, 
                            increments, 
                            center_freq, 
                            n_comp, 
                            rove_size; 
                            n_rep_template=n_rep_template_reduced, 
                            n_rep_trial=n_rep_trial_reduced,
                        )
                    end
                    fileexists = isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                    if fileexists
                        println("Necessary simulation files exist, fitting psychometric function!")
                        out = @memo Default() simulate(pf)
                        Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                    else
                        println("Necessary simulation files DO NOT exist, skipping fitting psychometric function!")
                        NaN
                    end
                end

                # Snag COHC values
                if typeof(model) == AuditoryNerveZBC2014
                    cohc = model.cohc[argmin(abs.(model.cf .- center_freq))]
                else
                    cohc = model.frontend.cohc[argmin(abs.(model.cf .- center_freq))]
                end

                # Compile results into dataframe
                DataFrame(
                    θ=θ, 
                    n_comp=n_comps, 
                    center_freq=center_freq, 
                    mode=mode, 
                    model=model,
                    rove_size=rove_size,
                    audiogram=audiogram,
                    subj=audiogram.desc,
                    cohc=cohc,
                )
            end

            # Concatenate and return
            vcat(out...)
        end

        # Concatenate and return
        vcat(out...)
    end

    # Concatenate all together
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds_hi.jld2"), Dict("df" => df))
    df
end

"""
    postprocess_pfs([center_freqs, n_comps, increments, rove_sizes])

Postprocess constant-stimulus PFs to extract thresholds and slopes and save
"""
function postprocess_pfs_puretone(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[1],
    increments=vcat(-999.9, -45.0:2.5:5.0),
    rove_sizes=[0.001, 10.0],
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(Iterators.product(center_freqs, rove_sizes)) do (center_freq, rove_size)
        # Map through possible PF modes and plot each with different markers
        out = map(["singlechannel", "profilechannel", "templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end

            # Fetch possible models, subset to exclude HSR
            models = setup(exp, center_freq)[2:end]

            # Map through models
            out = map(models) do model
                # Map through n_comps for this model, fit psychometric function, and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Simulate psychometric function
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp, rove_size)
                    if isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                        out = @memo Default() simulate(pf)
                        Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                    else
                        NaN
                    end
                end

                # Compile results into dataframe
                DataFrame(
                    θ=θ, 
                    n_comp=n_comps, 
                    center_freq=center_freq, 
                    mode=mode, 
                    model=model,
                    rove_size=rove_size,
                )
            end

            # Concatenate and return
            vcat(out...)
        end

        # Concatenate and return
        vcat(out...)
    end

    # Concatenate all together
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds_puretone.jld2"), Dict("df" => df))
    df
end

"""
    postprocess_pfs_extended([center_freqs, n_comps, increments, rove_sizes])

Postprocess constant-stimulus PFs based on extended midbrain models to extract thresholds 
and slopes and save
"""
function postprocess_pfs_extended(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
    rove_sizes=[0.001, 10.0],
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(Iterators.product(center_freqs, rove_sizes)) do (center_freq, rove_size)
        # Map through possible PF modes and plot each with different markers
        out = map(["templatebased"]) do mode
            # Handle modeswitch
            if (mode == "singlechannel") | (mode == "profilechannel")
                exp = ProfileAnalysis_PFObserver()
            elseif mode == "templatebased"
                exp = ProfileAnalysis_PFTemplateObserver()
            end

            # Fetch possible models, subset to exclude HSR
            models = setup_extended(exp, center_freq)

            # Map through models
            out = map(models) do model
                # Map through n_comps for this model, fit psychometric function, and estimate psychometric functions and extract threshold for each
                θ = map(n_comps) do n_comp
                    # Print progress
                    print(
                        "$(modelstr(model)) // $n_comp // $center_freq // $rove_size\n"
                    )
                    # Simulate psychometric function
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp, rove_size)
                    if isfile(pf.patterns[1][1]) & isfile(pf.patterns[end][end])
                        out = @memo Default() simulate(pf)
                        Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                    else
                        NaN
                    end
                end

                # Compile results into dataframe
                DataFrame(
                    θ=θ, 
                    n_comp=n_comps, 
                    center_freq=center_freq, 
                    mode=mode, 
                    model=model,
                    rove_size=rove_size,
                )
            end

            # Concatenate and return
            vcat(out...)
        end

        # Concatenate and return
        vcat(out...)
    end

    # Concatenate all together
    df = vcat(df...)

    # Convert model to model string
    df.model .= modelstr.(df.model)

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds_extended.jld2"), Dict("df" => df))
    df
end


function load_simulated_thresholds()
    load(joinpath("data", "sim_pro", "model_thresholds.jld2"))["df"]
end

function load_simulated_thresholds_hi()
    load(joinpath("data", "sim_pro", "model_thresholds_hi.jld2"))["df"]
end

function load_simulated_thresholds_adjusted()
    load(joinpath("data", "sim_pro", "model_thresholds_adjusted.jld2"))["df"]
end

function load_simulated_thresholds_reduced()
    load(joinpath("data", "sim_pro", "model_thresholds_reduced.jld2"))["df"]
end

function load_simulated_thresholds_puretone()
    load(joinpath("data", "sim_pro", "model_thresholds_puretone.jld2"))["df"]
end

function load_simulated_thresholds_extended()
    load(joinpath("data", "sim_pro", "model_thresholds_extended.jld2"))["df"]
end

# Numerically optimize constant that minimizes RMS error between vectors θ_hat and θ
function find_constant(θ_hat, θ)
    Optim.minimizer(optimize(p -> rms((p[1] .+ θ_hat) .- θ), [0.0], BFGS()))[1]
end

# Choose constant to minimize RMS error between vectors θ_hat and θ as the mean of their differences
function find_constant_simple(θ_hat, θ)
    mean(θ .- θ_hat)
end

function compare_behavior_to_simulations()
    # Compile relevant behavioral data
    beh = @chain fetch_behavioral_data() begin
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")
        avg_behavioral_data()
        @orderby(:freq, :n_comp)
    end

    # Load simulated thresholds from disk
    sim = load_simulated_thresholds() 

    # Loop through all models, esimate optimal offset parameters, and compute error between
    # data and behavior
    results = @chain sim begin
        # Subset to make sure we only consider component counts tested in behavior
        @subset(in.(:n_comp, Ref([5, 13, 21, 29, 37])))

        # Order in the same way as to match behavior
        @orderby(:center_freq, :n_comp)

        # Group simulations by model and observer type
        groupby([:model, :mode, :rove_size])

        # Compute constant that optimizes match between behavior and model across ALL conditions
        @transform(:offset = find_constant_simple(:θ, beh.threshold))

        # Compute thresholds with offset
        @transform(:θ_adjusted = :θ .+ :offset)

        # Stack
        stack([:θ, :θ_adjusted])

        # Rename and relabel
        rename!(:variable => :adjusted, :value => :θ)
        @transform(:adjusted = :adjusted .!= "θ")

        # Group simulations by model and observer type
        groupby([:model, :mode, :rove_size, :adjusted])

        # Compute all losses
        @transform(
            :rms = rms(:θ .- beh.threshold),
            :varexp = variance_explained(:θ, beh.threshold),
        )
    end

    # Save dataframe to disk
    save(joinpath("data", "sim_pro", "model_thresholds_adjusted.jld2"), Dict("df" => results))
    return results
end

function diagnostic_plot_behavior_vs_simulations()
    # Get full dataframe
    df = compare_behavior_to_simulations()

    # Compile relevant behavioral data
    beh = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))
    beh = @chain beh begin
        # Subset to only fixed-level data and "NH" subjects
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")

        # Group by freq, component count, and group
        groupby([:freq, :n_comp])

        # Summarize
        @combine(
            :stderr = std(:threshold)/sqrt(length(:threshold)),
            :threshold = mean(:threshold),
        )

        # Order in the correct way
        @orderby(:freq, :n_comp)
    end

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.mode), unique(df.model)))
    figs = map(itr) do (mode, model)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Create figure
        fig = Figure(; resolution=(500, 300))
        ax = Axis(fig[1, 1])
        ylims!(ax, -40.0, 10.0)

        # Plot each bowl, with raw and adjusted thresholds
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset further
            sims = @subset(df_subset, :center_freq .== freq, :adjusted .== false)
            sims_adj = @subset(df_subset, :center_freq .== freq, :adjusted .== true)
            behs = @subset(beh, :freq .== freq)
            scatter!(ax, (1:5) .+ (idx-1)*6, sims.θ; color=:pink)
            scatter!(ax, (1:5) .+ (idx-1)*6, sims_adj.θ; color=:red)
            scatter!(ax, (1:5) .+ (idx-1)*6, behs.threshold; color=:black)
            lines!(ax, (1:5) .+ (idx-1)*6, sims.θ; color=:pink)
            lines!(ax, (1:5) .+ (idx-1)*6, sims_adj.θ; color=:red)
            lines!(ax, (1:5) .+ (idx-1)*6, behs.threshold; color=:black)
        end

        # Add ticks
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*6 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "36"], 4),
        )

        # Add labels
        ax.xlabel = "Number of components"
        ax.ylabel = "Threshold (dB SRS)"

        # Add info at top of page
        err = round(@subset(df_subset, :adjusted .== false).rms[1]; digits=3)
        err_adj = round(@subset(df_subset, :adjusted .== true).rms[1]; digits=3)
        errvar = round(100.0 * @subset(df_subset, :adjusted .== false).varexp[1]; digits=3)
        errvar_adj = round(100.0 * @subset(df_subset, :adjusted .== true).varexp[1]; digits=3)

        fullstring = "$model // $mode \n offset = $(round(df_subset.offset[1]; digits=3)) dB \n rms = $err dB, rms_adj = $err_adj dB \n variance explained = $errvar %, variance explained adjusted = $errvar_adj %"
        ax.title = fullstring
        fig
    end

    # Combine into one master figure
    fig = displayimg(tilecat(getimg.(figs)))
end

function diagnostic_plot_behavior_vs_simulations_flavor2()
    # Get full dataframe
    df = compare_behavior_to_simulations()

    # Compile relevant behavioral data
    beh = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))
    beh = @chain beh begin
        # Subset to only fixed-level data and "NH" subjects
        @subset(:rove .== "fixed level", :hl_group .== "< 5 dB HL")

        # Group by freq, component count, and group
        groupby([:freq, :n_comp])

        # Summarize
        @combine(
            :stderr = std(:threshold)/sqrt(length(:threshold)),
            :threshold = mean(:threshold),
        )

        # Order in the correct way
        @orderby(:freq, :n_comp)
    end

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.mode), unique(df.model)))
    figs = map(itr) do (mode, model)
        # Subset data
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Create figure
        fig = Figure(; resolution=(300, 300))
        ax = Axis(fig[1, 1])

        # Scatter adjusted vs real thresholds
        scatter!(ax, beh.threshold, @subset(df_subset, :adjusted .== true).θ)

        # Add labels
        ax.xlabel = "Behavioral threshold"
        ax.ylabel = "Modeled threshold"

        # Add info at top of page
        err = round(@subset(df_subset, :adjusted .== false).rms[1]; digits=3)
        err_adj = round(@subset(df_subset, :adjusted .== true).rms[1]; digits=3)
        errvar = round(100.0 * @subset(df_subset, :adjusted .== false).varexp[1]; digits=3)
        errvar_adj = round(100.0 * @subset(df_subset, :adjusted .== true).varexp[1]; digits=3)
        ρ = round(cor(beh.threshold, @subset(df_subset, :adjusted .== true).θ); digits=3)
        ρ² = round(ρ^2; digits=3)

        fullstring = "$model // $mode \n offset = $(round(df_subset.offset[1]; digits=3)) dB \n rms = $err dB, rms_adj = $err_adj dB \n variance explained = $errvar %\n variance explained adjusted = $errvar_adj % \n ρ = $ρ, ρ²=$(ρ²)"
        ax.title = fullstring
        fig
    end

    # Combine into one master figure
    fig = displayimg(tilecat(getimg.(figs)))
end

function density_pair_stack(data, labels)
    # Create histograms
    fig = Figure(; resolution=(300, 900))
    ax = Axis(fig[1, 1])
    density_pair_stack!(fig, ax, data, labels)
end

function density_pair_stack!(fig, ax, data, labels; xlabel="Firing rate (sp/s)", xlims=nothing)
    # Determine the lowest/highest rate that will be plotted (so we know where to place labels)
    minrate = minimum(map(minimum, map(minimum, data)))
    maxrate = maximum(map(maximum, map(maximum, data)))

    # Plot all data
    map(enumerate(data)) do (idx, datum)
        # Extract reference and target rates
        rates_ref = datum[1]
        rates_tar = datum[2]

        # Plot as KDEs
        density!(ax, rates_ref; offset=idx/10, color=(:black, 0.3), strokecolor=:black, strokearound=true)
        density!(ax, rates_tar; offset=idx/10, color=(:red, 0.3), strokecolor=:red, strokearound=true)

        # Add label for increment
        text!(ax, [minrate-5.0], [idx/10]; text="$(round(labels[idx]; digits=1)) dB SRS", align=(:right, :baseline))

        # Add label for d'
        d′ = (mean(rates_tar) - mean(rates_ref)) / sqrt((var(rates_ref) + var(rates_tar))/2)
        text!(ax, [maxrate+5.0], [idx/10]; text="$(round(d′; digits=2))", align=(:left, :baseline))
    end
    ax.xlabel = xlabel
    if xlims === nothing
        xlims!(ax, 0.0, maxrate * 1.3)
    else
        xlims!(ax, xlims...)
    end
    ylims!(ax, 0.0, length(data)/10)
    hideydecorations!(ax)
    fig
end

function plot_histograms_versus_increment(pf::P) where {P <: Utilities.PF}
    # Load data from all increments
    data = map(pf.patterns) do pattern
        # Load reference and target patterns
        pattern_ref = pattern[1]  # AvgPattern object for reference stimuli
        pattern_tar = pattern[2]  # AvgPattern object for target stimuli
        resp_ref = @memo Default() simulate(pattern_ref)  # vector of responses for reference stimuli
        resp_tar = @memo Default() simulate(pattern_tar)  # vector of responses for target stimuli

        # Extract rates at target channel
        idx_center = Int(ceil(pattern_ref.model.n_chan/2))
        rates_ref = map(x -> x[idx_center], resp_ref)
        rates_tar = map(x -> x[idx_center], resp_tar)
        return rates_ref, rates_tar
    end

    incs = map(pf.patterns) do pattern
        pattern[2].stimuli[1].stimulus.increment
    end
    density_pair_stack(data, incs)
end

function ol_to_lpc(x, n)
    10.0 * log10(1/n * 10.0^(x/10.0))
end

function lpc_to_ol(x, n)
    10.0 * log10(n * 10.0^(x/10.0))
end

function plot_histograms_versus_increment_sound_level_control(pf::P) where {P <: Utilities.PF}
    # Load data from all increments
    @info "Loading simulated rates..."
    rates = map(pf.patterns) do pattern
        # Load reference and target patterns
        pattern_ref = pattern[1]  # AvgPattern object for reference stimuli
        pattern_tar = pattern[2]  # AvgPattern object for target stimuli
        resp_ref = @memo Default() simulate(pattern_ref)  # vector of responses for reference stimuli
        resp_tar = @memo Default() simulate(pattern_tar)  # vector of responses for target stimuli

        # Extract rates at target channel
        idx_center = Int(ceil(pattern_ref.model.n_chan/2))
        rates_ref = map(x -> x[idx_center], resp_ref)
        rates_tar = map(x -> x[idx_center], resp_tar)
        return rates_ref, rates_tar
    end

    # Calculate overall level in each increment
    # levels_empirical = map(pf.patterns) do pattern
    #     # Load reference and target patterns
    #     pattern_ref = pattern[1]  # AvgPattern object for reference stimuli
    #     pattern_tar = pattern[2]  # AvgPattern object for target stimuli
    #     lvls_ref = dbspl.(synthesize.(pattern_ref.stimuli))
    #     lvls_tar = dbspl.(synthesize.(pattern_tar.stimuli))

    #     return lvls_ref, lvls_tar
    # end

    # Calculate overall level distributions for tar/ref at each inc
    N = 1000  # how many pairs to simulate for analytical level calculations
    @info "Caculcating overall sound levels..."
    levels_overall = map(pf.patterns) do pattern
        # Load reference and target patterns
        pattern_ref = pattern[1]  # AvgPattern object for reference stimuli
        pattern_tar = pattern[2]  # AvgPattern object for target stimuli

        # Grab data we need
        inc = pattern_tar.stimuli[1].stimulus.increment  # target increment (dB SRS)

        # Calculate reference levels
        lvls_ref = map(x -> Random.rand(pattern_ref.stimuli[1].rove_dist), 1:N)

        # Calculate target levels
        ol_background_tar = map(x -> Random.rand(pattern_ref.stimuli[1].rove_dist), 1:N)
        lpc_background_tar = map(x -> ol_to_lpc(x, 21), ol_background_tar)
        lvls_tar = map(lpc_background_tar) do lpc
            10 * log10((21-1) * 10^(lpc/10) + 10^((lpc + srs_to_ΔL(inc))/10))
        end

        return lvls_ref, lvls_tar
    end

    # Calculate level of target component at each inc
    @info "Caculcating per-component sound levels..."
    levels_component = map(pf.patterns) do pattern
        # Load reference and target patterns
        pattern_ref = pattern[1]  # AvgPattern object for reference stimuli
        pattern_tar = pattern[2]  # AvgPattern object for target stimuli

        # Grab data we need
        inc = pattern_tar.stimuli[1].stimulus.increment  # target increment (dB SRS)

        # Calculate reference levels
        lvls_ref = ol_to_lpc.(map(x -> Random.rand(pattern_ref.stimuli[1].rove_dist), 1:N), 21)

        # Calculate target levels
        lvls_tar = ol_to_lpc.(map(x -> Random.rand(pattern_ref.stimuli[1].rove_dist), 1:N), 21) .+ srs_to_ΔL(inc)

        return lvls_ref, lvls_tar
    end


    fig = Figure(; resolution=(1800, 1500))
    axs = [Axis(fig[1, i]) for i in 1:3]
    incs = map(pf.patterns) do pattern
        pattern[2].stimuli[1].stimulus.increment
    end
    density_pair_stack!(fig, axs[1], rates, incs; xlabel="Firing rate (sp/s)")
    # density_pair_stack!(fig, axs[2], levels_empirical, incs)
    density_pair_stack!(fig, axs[2], levels_overall, incs; xlabel="Overall sound level (dB SPL)", xlims=(30.0, 90.0))
    density_pair_stack!(fig, axs[3], levels_component, incs; xlabel="Target component sound level (dB SPL)", xlims=(30.0, 90.0))
    if typeof(pf.model) == AuditoryNerveZBC2014
        accesses = [:fiber_type]
    else
        accesses = Symbol[]
    end
    Label(fig[0, :], id(pf.model; accesses=accesses))
    fig
end