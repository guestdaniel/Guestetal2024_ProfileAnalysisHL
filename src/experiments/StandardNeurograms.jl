export StandardNeurograms 

"""
    StandardNeurograms

Experiment to simulate IC neurograms for the standard parameter sets at various increments 
"""
struct StandardNeurograms <: Utilities.ComplexExperiment end

function Utilities.getcontext(::StandardNeurograms; kwargs...)
    Context(; 
        path_out="\\home\\daniel\\cl_fig\\pahi\\parameter_sets",
        kwargs...
    )
end

"""
    setup(::StandardNeurograms)

Return Subexperiments containing two experiments (one BE, one BS)
"""
function Utilities.setup(experiment::StandardNeurograms)
    Subexperiments(
        "Standard BE" => setup(experiment, InferiorColliculusSFIEBE, StandardBE),
        "Standard BS" => setup(experiment, InferiorColliculusSFIEBS, StandardBS),
    )
end

"""
    setup(::StandardNeurograms, ::Type{M}, param::Dict)

Return matrix of Response objects with ProfileAnalysisTones with varying center frequencies
and increments and Models of type `M` with parameters `param`
"""
function Utilities.setup(
    experiment::StandardNeurograms,
    modeltype::Type{M},
    param::Dict;
    kwargs...
) where {M <: Model}
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    increments = -30.0:5.0:20.0
    map(Iterators.product(center_freqs, increments)) do (center_freq, increment)
        setup(experiment, modeltype, param, center_freq, increment)
    end
end

"""
    setup(::StandardNeurograms, ::Type{M}, param::Dict, center_freq::Float64, 
        increment::Float64)

Return single Response object for ProfileAnalysisTone with `center_freq` and `increment` for
model of type `M ` with parameters `param`
"""
function Utilities.setup(
    experiment::StandardNeurograms,
    modeltype::Type{M},
    param::Dict,
    center_freq::Float64,
    increment::Float64;
    kwargs...
) where {M <: InferiorColliculusSFIE}
    stimulus = ProfileAnalysisTone(; center_freq=center_freq, n_comp=21, increment=increment)
    model = M(;
        frontend=AuditoryNerveZBC2014(;
            cf=LogRange(center_freq/3, center_freq*3, 120),
            fractional=false,
        ),
        param...
    )
    Response(; stimulus=stimulus, model=model)
end

function Utilities.setup(
    experiment::StandardNeurograms,
    modeltype::Type{AuditoryNerveZBC2014},
    param::Dict,
    center_freq::Float64,
    increment::Float64;
    kwargs...
) 
    stimulus = ProfileAnalysisTone(; center_freq=center_freq, n_comp=21, increment=increment)
    model = AuditoryNerveZBC2014(;
        cf=LogRange(center_freq/3, center_freq*3, 120),
        fractional=false,
        param...
    )
    Response(; stimulus=stimulus, model=model)
end

function Utilities.viz(context::Context, ::StandardNeurograms, sim::Response)
    fig = plot_neurogram(
        synthesize(sim.stimulus),
        sim.model.cf,
        @with context run(sim);
        clims=standardclims(typeof(sim.model)),
        waterfall=false,
    )
    Label(fig[0, 2], id(sim.stimulus; accesses=standardfields(typeof(sim.stimulus)), connector=" // "); tellwidth=false)
    Label(fig[-1, 2], id(sim.model; accesses=standardfields(typeof(sim.model)), connector=" // "); tellwidth=false)
    fig
end