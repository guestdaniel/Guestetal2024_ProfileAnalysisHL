export PrecursorStimulus, WBTIN, SIN, ZeroPaddedStimulus

"""
    PrecursorStimulus{A, B} <: Stimulus

Compound stimulus combining precursor of type A with stimulus of type B
"""
@with_kw struct PrecursorStimulus{A, B} <: Stimulus where {A <: Stimulus, B <: Stimulus}
    precursor::A
    stimulus::B
    fs::Float64=precursor.fs
    dur_psi::Float64=0.30
end

function PrecursorStimulus(a, b; kwargs...)
    PrecursorStimulus(; precursor=a, stimulus=b, kwargs...)
end

function synthesize(stimulus::PrecursorStimulus)
    vcat(
        synthesize(stimulus.precursor),
        zeros(Int(round(stimulus.fs * stimulus.dur_psi))),
        synthesize(stimulus.stimulus)
    )
end

@with_kw struct SIN{A, B} <: Stimulus where {A <: Stimulus, B <: Stimulus}
    stim::A
    noise::B
end

synthesize(stim::SIN) = synthesize(stim.noise) .+ synthesize(stim.stim)

"""
    WBTIN <: Stimulus

Wideband tone-in-noise from Jo Fritzinger's rabbit physiology expeirments
"""
@with_kw struct WBTIN <: Stimulus
    noise::GaussianNoise
    tone::PureTone
end

# function WBTIN(;
#     freq::Float64=1000.0, 
#     flow::Float64=20.0, 
#     fhigh::Float64=10e3,
#     level::Float64=30.0,  # spectrum level of the noise
#     snr::Float64=0.0,     # dB tone level re: masker spectrum level
#     dur::Float64=0.5,  
#     dur_ramp::Float64=0.01,
#     kwargs...
# )
#     WBTIN(
#         GaussianNoise(; flow=flow, fhigh=fhigh, l=level, dur=dur, dur_ramp=dur_ramp, kwargs...),
#         PureTone(; f=freq, dur=dur, dur_ramp=dur_ramp, l=level+snr, kwargs...)
#     )
# end

synthesize(stim::WBTIN) = synthesize(stim.noise) .+ synthesize(stim.tone)

"""
    ZeroPaddedStimulus{A <: Stimulus} <: Stimulus

Stimulus with leading and/or trailing zeros
"""
@with_kw struct ZeroPaddedStimulus{A} <: Stimulus where {A <: Stimulus}
    stimulus::A
    fs::Float64=stimulus.fs
    dur_pre::Float64=0.0
    dur_post::Float64=0.0
end

function synthesize(stimulus::ZeroPaddedStimulus)
    vcat(
        zeros(Int(round(stimulus.fs * stimulus.dur_pre))),
        synthesize(stimulus.stimulus),
        zeros(Int(round(stimulus.fs * stimulus.dur_post))),
    )
end
