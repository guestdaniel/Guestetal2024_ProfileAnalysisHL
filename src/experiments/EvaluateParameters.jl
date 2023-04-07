export EvaluateParameters2, viz

"""
    EvaluateParameters2

Experiment to evaluate IC model parameters for inclusion in profile-analysis simulations

Experiment that measures responses to profile-analysis tones and measures MTFs for a variety
of different IC models with different parameter configurations. These responses are plotted
to disk, and the best-looking parameter sets are exported for later use.
"""
struct EvaluateParameters2 <: Utilities.Experiment end

function Base.run(
    experiment::EvaluateParameters2,
)
    context = getcontext(experiment)
    run(context, experiment)
end

function Base.run(
    context::Context,
    experiment::EvaluateParameters2,
)
    # Set up simulations and context
    sims = setup(experiment)

    # Print status
    printdiag(context, displvl[0], "Running $experiment")

    # Loop through simulations and evaluate
    @showprogress for sim in sims
        @cache context run(sim)
    end

    viz(context, experiment)
end

function Utilities.getcontext(::EvaluateParameters2; kwargs...)
    # Establish context
    # Set custom figure output path and pass kwargs to control resolution of cachepath
    Context(; 
        path_out="\\home\\daniel\\cl_fig\\pahi\\parameter_sets",
        kwargs...
    )
end

function Utilities.setup(::EvaluateParameters2; kwargs...)
    # Generate stimuli
    # Generate profile-analysis tones with 0 dB SRS at all tested center frequencies
    stimuli = map([500.0, 1000.0, 2000.0, 4000.0]) do center_freq
        ProfileAnalysisTone(; center_freq=center_freq)
    end

    # Generate model
    # Generate standard BE model units with CFs centered on each stimulus' target frequency
    models = map(stimuli) do stim
        InferiorColliculusSFIEBE(;
            frontend=AuditoryNerveZBC2014(;
                cf=LogRange(stim.center_freq/3, stim.center_freq*3, 60),
                fractional=false,
            ),
        )
    end

    # Compile stimuli and models into Responses, return
    map(zip(stimuli, models)) do (s, m)
        Response(; stimulus=s, model=m)
    end
end

function viz(context::Context, experiment::EvaluateParameters2)
    sims = setup(experiment)
    map(sims) do sim
        # Load from cache
        resp = @cache context run(sim)

        # Plot neurogram
        fig = plot_neurogram( 
            synthesize(sim.stimulus),
            sim.model.cf,
            resp;
        )

        # Save to disk with title
        title = id(sim.model; accesses=Symbol[], connector=" // ") *
                "\n" *
                id(sim.stimulus; accesses=[:center_freq], connector=" // ")
        Label(fig[0, 2], title; tellwidth=false)
        fn = outpath(
            context, 
            sim.model, 
            sim.stimulus; 
            accesses=Dict("ProfileAnalysisTone" => [:center_freq])
        )
        save(fn, fig)
    end
end