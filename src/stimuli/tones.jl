export PureTone, SAMTone, CentroidTone 

"""
    PureTone <: Stimulus

Pure tone with frequency `f` and phase `ϕ` at level `l` for duration `dur`
"""
@with_kw struct PureTone <: Stimulus
    f::Float64=1000.0
    ϕ::Float64=0π
    dur::Float64=0.1
    dur_ramp::Float64=0.01
    l::Float64=50.0
    fs::Float64=100e3
end

function synthesize(x::PureTone)
    Parameters.@unpack f, ϕ, dur, fs, dur_ramp, l = x
    scale_dbspl(cosine_ramp(pure_tone(f, ϕ, dur, fs), dur_ramp, fs), l)
end

"""
    SAMTone <: Stimulus

Sinusoidally amplitude-modulated tone
"""
@with_kw struct SAMTone <: Stimulus
    f::Float64=1000.0
    fm::Float64=10.0
    ϕ::Float64=0π
    ϕm::Float64=0π
    m::Float64=1.0
    dur::Float64=0.1
    dur_ramp::Float64=0.01
    l::Float64=50.0
    fs::Float64=100e3
end

function synthesize(x::SAMTone)
    Parameters.@unpack f, fm, ϕ, ϕm, m, dur, fs, dur_ramp, l = x

    # Synthesize carrier
    carrier = pure_tone(f, ϕ, dur, fs)

    # Synthesize modulator
    modulator = pure_tone(fm, ϕm, dur, fs)

    # Combine, ramp, and scale
    comb = (1 .+ m .* modulator) .* carrier
    scale_dbspl(cosine_ramp(comb, dur_ramp, fs), l)
end

"""
    CentroidTone <: Stimulus
"""

@with_kw struct CentroidTone <: Stimulus
    f0::Float64=100.0
    level::Float64=70.0
    center_freq::Float64=1200.0
    slope::Float64=24.0
    dur::Float64=0.5
    dur_ramp::Float64=0.02
    fs::Float64=100e3
end

function synthesize(x::CentroidTone)
    Parameters.@unpack f0, level, center_freq, slope, dur, dur_ramp, fs = x

    # Determine frequencies and levels of components
    freqs = f0:f0:10e3
    Δ = -abs.(log2.(freqs) .- log2(center_freq))  # negative of unsigned distance from CF in octaves
    levels = slope .* Δ

    # Synthesize all components in sin phase with appropriate levels
    comps = map(zip(freqs, levels)) do (f, l)
        amplify(pure_tone(f, 0.0, dur, fs), l)
    end
    
    # Combine, ramp, scale, and return
    scale_dbspl(cosine_ramp(sum(comps), dur_ramp, fs), level)
end