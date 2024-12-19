export Model, Null, compute, extract

"""
    Model

Abstract type for a mapping from input to ouptut

Below is a description of the informal method interface developed around Model:
- `compute(::Model, ::Stimulus)` should compute the output of a model given a stimulus
- `compute(::Model, ::Vector)` should compute the output of a model given a sound-pressure
  waveform
"""
abstract type Model <: Component end
@with_kw struct Null <: Model 
    cf::Vector{Float64}=[1000.0]
end

compute(m::Model, s::Stimulus) = compute(m, synthesize(s))

function extract(m::Model, r)
    if m.n_chan == 1
        r[1]
    else
        idx_mid = Int(round(m.n_chan/2))
        r[idx_mid]
    end
end