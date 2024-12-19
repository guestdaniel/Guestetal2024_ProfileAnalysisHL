export IsolevelTC, axis

"""
    IsolevelTC

Type for generating responses to pure tone at different frequencies for given model
"""
@with_kw struct IsolevelTC{M} <: Simulation where {M <: Model}
    stimuli::Vector{PureTone}
    model::M
    summary::Function=mean
    freqs::Vector{Float64}=[stim.f for stim in stimuli]
    n_freq::Float64=length(freqs)
    freq_low::Float64=minimum(freqs)
    freq_high::Float64=maximum(freqs)
    level::Float64=20.0
end

function IsolevelTC(model::M, level=20.0, freq_low=0.2e3, freq_high=10e3, n_freq=9; fs=100e3, kwargs...) where {M <: Model}
    stimuli = vcat(
        map(f -> PureTone(; f=f, l=level, fs=fs, kwargs...), LinRange(freq_low, freq_high, n_freq)),
    )
    IsolevelTC(; stimuli=stimuli, model=model, kwargs...)
end

function simulate(s::IsolevelTC) 
    map(s.stimuli) do stim
        s.summary(extract(s.model, compute(s.model, stim)))
    end
end

function axis(s::IsolevelTC)
    [stim.f for stim in s.stimuli]
end