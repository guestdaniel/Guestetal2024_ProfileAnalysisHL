export Stimulus, RovedStimulus
export synthesize, dur

"""
    Stimulus

Abstract type for stimulus generation

Below is a description of the informal method interface developed around Stimulus:
- `synthesize(::Stimulus)` should return a sound-pressure waveform for the stimulus
"""
abstract type Stimulus <: Component end
abstract type DeterministicStimulus <: Stimulus end
abstract type RandomStimulus <: Stimulus end
function synthesize(::Stimulus) end

"""
    RovedStimulus

Wrapper for a regular stimulus that randomizes one or more stimulus parameters 

Wrapper for typical subtypes of stimulus that implements the concept of "roving" or
parameter randomization. RovedStimuli provide a `rand` method that returns a single sample
from the (multivariate) distribution of the parameter(s) that is(are) randomized. It also
provides an implementation of `synthesize` method that draws a parameter sample using `rand` 
and then synthesizes a copy of the stimulus with those parameter values.
"""
@with_kw struct RovedStimulus{S} <: RandomStimulus where {S <: Stimulus}
    rove_dist::Distribution
    rove_params::Vector{Symbol}=Symbol[]
    stimulus::S
end

Base.rand(s::RovedStimulus, args...; kwargs...) = rand(s.rove_dist, args...; kwargs...)

RovedStimulus(s::Stimulus, n::Int; kwargs...) = repeat([RovedStimulus(kwargs[:rove_dist], kwargs[:rove_params], s)], n)

function synthesize(s::RovedStimulus{S}) where {S <: Stimulus}
    # Get all field names and corresponding values for the underlying stimulus
    keyvals = Dict([(k, getfield(s.stimulus, k)) for k in fieldnames(typeof(s.stimulus))])

    # Draw a sample from the rove distribution and update relevant values
    θ = rand(s)
    @assert length(θ) == length(s.rove_params)
    for (k, v) in zip(s.rove_params, θ)
        keyvals[k] = v
    end
    # Synthesize a new stimulus copy
    stimulus_copy = S(; keyvals...)

    # Synthesize and return
    synthesize(stimulus_copy)
end

function id(comp::RovedStimulus; accesses=nothing, connector="_", kwargs...)
    id_main = savename(
        string(typeof(comp)),
        comp; 
        accesses=accesses === nothing ? fieldnames(typeof(comp)) : accesses,
        allowedtypes=(
            Real, 
            String, 
            Symbol, 
            Function,
            Component,
            Audiogram,
        ), 
        connector=connector,
        kwargs...
    )

    names = join(string.(comp.rove_params), connector)
    names = names * connector * "roved_over"
    dist = string(comp.rove_dist)

    return join([id_main, names, dist], connector)
end
