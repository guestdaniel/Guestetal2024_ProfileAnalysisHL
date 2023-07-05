export postprocess_pfs, 
       compare_behavior_to_simulations,
       load_simulated_thresholds,
       load_simulated_thresholds_adjusted

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

function load_simulated_thresholds()
    load(joinpath("data", "sim_pro", "model_thresholds.jld2"))["df"]
end

function load_simulated_thresholds_adjusted()
    load(joinpath("data", "sim_pro", "model_thresholds_adjusted.jld2"))["df"]
end

function find_constant(θ_hat, θ)
    Optim.minimizer(optimize(p -> rms((p[1] .+ θ_hat) .- θ), [0.0], BFGS()))[1]
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
        @transform(:offset = find_constant(:θ, beh.threshold))

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
