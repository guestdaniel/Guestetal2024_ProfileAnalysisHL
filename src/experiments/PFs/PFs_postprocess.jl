export postprocess_pfs, load_simulated_thresholds, compare_behavior_to_simulations

function postprocess_pfs(
    center_freqs=[500.0, 1000.0, 2000.0, 4000.0],
    n_comps=[5, 13, 21, 29, 37],
    increments=vcat(-999.9, -45.0:2.5:5.0),
)
    # Map through models and build dataframe containing thresholds for each model/condition
    df = map(center_freqs) do center_freq
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
                    pf = getpffunc(mode, model, exp)(model, increments, center_freq, n_comp)
                    out = @memo Default() simulate(pf)
                    Utilities.fit(pf, increments[2:end], out[2:end]).param[1]
                end
                DataFrame(θ=θ, n_comp=n_comps, center_freq=center_freq, mode=mode, model=model)
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
end

function load_simulated_thresholds()
    load(joinpath("data", "sim_pro", "model_thresholds.jld2"))["df"]
end

function find_constant(θ_hat, θ)
    Optim.minimizer(optimize(p -> rms((p[1] .+ θ_hat) .- θ), [0.0], BFGS()))[1]
end

function compare_behavior_to_simulations()
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
        groupby([:model, :mode])

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
        groupby([:model, :mode, :adjusted])

        # Compute all losses
        @transform(
            :rms = rms(:θ .- beh.threshold),
            :varexp = variance_explained(:θ, beh.threshold),
        )
    end

    return results
end