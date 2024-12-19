export ToneRLF, axis

"""
    RLF

Type for generating responses to pure tone at different levels for given model
"""
@with_kw struct ToneRLF{M} <: Simulation where {M <: Model}
    stimuli::Vector{PureTone}
    model::M
    summary::Function=mean
    levels::Vector{Float64}=[stim.l for stim in stimuli]
    n_level::Float64=length(levels)
    level_low::Float64=minimum(levels)
    level_high::Float64=maximum(levels)
    freq::Float64=model.cf[1]
end

function ToneRLF(model::M, level_low=0.0, level_high=80.0, n_level=9; fs=100e3, kwargs...) where {M <: Model}
    stimuli = vcat(
        map(l -> PureTone(; f=model.cf[1], l=l, fs=fs, kwargs...), LinRange(level_low, level_high, n_level)),
    )
    ToneRLF(; stimuli=stimuli, model=model, kwargs...)
end

function simulate(s::ToneRLF) 
    map(s.stimuli) do stim
        s.summary(extract(s.model, compute(s.model, stim)))
    end
end

function axis(s::ToneRLF)
    [stim.l for stim in s.stimuli]
end