export EvaluateParameters

"""
    EvaluateParameters{<:InferiorColliculusSFIE}

Experiment to evaluate IC model parameters for inclusion in profile-analysis simulations

Measures responses to profile-analysis tones and MTF noises for a variety of different IC
models with different parameter configurations. Key related methods are briefly documented
here for convenience:

    `run(::EvaluateParameters{T})` runs whole experiment and plots
    `status(::EvaluateParameters{T})` checks whether the experiment is already run
    `viz(::T, param::Dict)` generates main experiment plot for IC model parameters in 
        `param` for subtype of InferiorColliculusSFIE T
"""
struct EvaluateParameters{T} <: Utilities.ComplexExperiment where {T <: InferiorColliculusSFIE} end

function Utilities.getcontext(::EvaluateParameters; kwargs...)
    Context(; 
        path_out="\\home\\daniel\\cl_fig\\pahi\\parameter_sets",
        kwargs...
    )
end

"""
    setup(::EvaluateParameters{InferiorColliculusBE}, param::Dict)

Generate stimuli and models for a single set of BE parameters stored in `param`. Returns a 
length-4 vector of SimulationSets (one SimulationSet for each center frequency!). This is
the core type of the present experiment (a vector of SimulationSets, each corresponding to 
a different stimulus parameter).
"""
function Utilities.setup(
    experiment::EvaluateParameters{T},
    param::Dict;
    kwargs...
)::Vector{SimulationSet} where {T <: InferiorColliculusSFIE}
    # Generate stimuli
    stimuli = map([500.0, 1000.0, 2000.0, 4000.0]) do center_freq
        ProfileAnalysisTone(; center_freq=center_freq, n_comp=21)
    end

    # Map over stimuli (0.5 to 4 kHz)
    map(stimuli) do stim
        # For each stimulus, generate:
        # - standard BE model units (full CF range for response, only one CF for MTF)
        model_full = T(;
            frontend=AuditoryNerveZBC2014(;
                cf=LogRange(stim.center_freq/3, stim.center_freq*3, 60),
                fractional=false,
            ),
            param...
        )
        model_single = T(;
            frontend=AuditoryNerveZBC2014(;
                cf=[stim.center_freq],
                fractional=false,
            ),
            param...
        )

        # Now, for this stimulus + model 
        # - Emit corresponding Response and NoiseMTF 
        SimulationSet(
            Response(; stimulus=stim, model=model_full),
            NoiseMTF(model_single),
        )
    end
end

"""
    setup(::EvaluateParameters{InferiorColliculusBE})

Specify the full set of BE simulations to evaluate
"""
function Utilities.setup(
    experiment::EvaluateParameters{InferiorColliculusSFIEBE};
    kwargs...
)::Subexperiments
    # Experiment 1: Varying time constant
    exp1_params = map(
        x -> Dict(
            :τ_e_ic => 1e-3*x,
            :τ_i_ic => 2e-3*x,
            :d_i_ic => 1e-3,
            :A_ic => 2.0,
            :S_ic => 1.0
        ),
        LinRange(0.5, 2.0, 7),
    )
    exp1 = map(param -> setup(experiment, param), exp1_params)

    # Experiment 2: Varying strength of inhibition
    exp2_params = map(
        x -> Dict(
            :τ_e_ic => 1e-3,
            :τ_i_ic => 2e-3,
            :d_i_ic => 1e-3,
            :A_ic => 2.0,
            :S_ic => x,
        ),
        [0.8, 0.9, 1.0, 1.1, 1.2],
    )
    exp2 = map(param -> setup(experiment, param), exp2_params)

    # Return 
    # Each sub-experiment is a Vector of Vector{SimulationSet}, with length equal to the 
    # number of different models tested 
    Subexperiments(
        "Evaluate effect of time constants" => exp1,
        "Evaluate effect of inhibition strength" => exp2,
    )
end

"""
    setup(::EvaluateParameters{InferiorColliculusBS})

Specify the full set of BS simulations to evaluate
"""
function Utilities.setup(
    experiment::EvaluateParameters{InferiorColliculusSFIEBS};
    kwargs...
)::Subexperiments
    # Experiment 1: Varying time constant
    exp1_params = map(
        x -> Dict(
            :τ_e_ic => 1e-3*x,
            :τ_i_ic => 2e-3*x,
            :d_i_ic => 1e-3,   # we should FIX delay --- it's not a time constant!
            :A_ic => 2.0,
            :S_ic => 1.0,
            :τ_i_bs => 2e-3*x,  
            :d_i_bs => 1e-3,   # we should FIX delay, see above
        ),
        LinRange(0.5, 2.0, 7),
    )
    exp1 = map(param -> setup(experiment, param), exp1_params)

    # Experiment 2: Varying strength of inhibition at BE stage
    exp2_params = map(
        x -> Dict(
            :τ_e_ic => 1e-3,
            :τ_i_ic => 2e-3,
            :d_i_ic => 1e-3,
            :A_ic => 2.0,
            :S_ic => x,
        ),
        [0.8, 0.9, 1.0, 1.1, 1.2],
    )
    exp2 = map(param -> setup(experiment, param), exp2_params)

    # Experiment 3: Varying strength of inhibition at BS stage
    exp3_params = map(
        x -> Dict(
            :τ_e_ic => 1e-3,
            :τ_i_ic => 2e-3,
            :d_i_ic => 1e-3,
            :A_ic => 2.0,
            :S_ic => 1.0,
            :S_bs => x,
        ),
        [1.0, 5.0, 10.0, 15.0, 20.0, 25.0],
    )
    exp3 = map(param -> setup(experiment, param), exp3_params)

    # Return 
    # Each sub-experiment is a Vector of Vector{SimulationSet}, with length equal to the 
    # number of different models tested 
    Subexperiments(
        "Evaluate effect of BE and BS time constants" => exp1,
        "Evaluate effect of BE inhibition strength" => exp2,
        "Evaluate effect of BS inhibition strength" => exp3,
    )
end

"""
    viz(context::Context, ::EvaluateParameters{T}, sim::Vector{SimulationSet})

Plot a single bottom-level simulation (a vector of SimulationSets, each containing a 
Response and a NoiseMTF with different center frequencies corresponding to the different 
stimuli)
"""
function Utilities.viz(
    context::Context, 
    ::EvaluateParameters{T}, 
    sim::Vector{SimulationSet}
) where {T <: InferiorColliculusSFIE}
    # Load simulations using @with macro
    out = @with context run(sim)

    # Loop through frequencies and plot
    subfigs = map(zip(out, sim)) do ((resp, mtf), (sim_resp, sim_mtf))
        # Plot neurogram
        fig_resp = plot_neurogram( 
            synthesize(sim_resp.stimulus),
            sim_resp.model.cf,
            resp;
            clims=standardclims(T),
        )

        # Plot MTF
        fig_mtf = plot_mtf(axis(sim_mtf), mtf)

        # Join plots
        fig = displayimg(padcat(getimg(fig_resp), getimg(fig_mtf)))

        # Add title
        title_model = id(
            sim_resp.model;
            accesses=standardfields(T),
            connector=" // ",
        )
        title_stim = id(
            sim_resp.stimulus;
            accesses=[:center_freq],
            connector = " // ",
        )
        title = title_model * "\n" * title_stim
        Label(fig[0, 1], title; tellwidth=false)
        fig
    end

    # Combine subfigs and save to disk
    displayimg(hcat(getimg.(subfigs)...))
end

"""
    viz(T, params)

Convenience method to quickly look at parameter set
"""
function Utilities.viz(
    T::Type{<:InferiorColliculusSFIE},
    param::Dict,
)
    experiment = EvaluateParameters{T}()
    context = getcontext(experiment)
    viz(context, experiment, setup(experiment, param))
end

"""
    viz(context::Context, ::EvaluateParameters{T})

Plot all simulation results from EvaluateParamters experiment
"""
function Utilities.viz(
    context::Context, 
    experiment::EvaluateParameters{T}
) where {T <: InferiorColliculusSFIE}
    # Loop over sub-experiments (which are Vector{Vector{SimulationSet}})
    for (idx, (name, subexp)) in enumerate(setup(experiment))
        # Map over elements of subexp to plot each 
        figs = map(sim -> viz(context, experiment, sim), subexp)

        # Combine them into one mega-plot horizontally
        fig = displayimg(vcat(getimg.(figs)...))

        # Determine save path and save
        fn = joinpath(
            context.path_out, 
            join([@sprintf("%02d", idx), string(T), replace(name, " " => "_")], "_") * ".png"
        )
        save(fn, fig)
    end
end