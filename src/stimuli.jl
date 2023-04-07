export tone_ensemble, profile_analysis_tone, srs_to_ΔL, ΔL_to_srs, ProfileAnalysisTone

"""
    tone_ensemble(freq, level, phase; kwargs...)

Synthesize a complex tone composed of pure tones with the specified freqs, levels, and phases.

# Arguments
- `freqs`: frequencies of each component in the tone ensemble (Hz)
- `levels`: levels of each component in the tone ensemble (dB SPL)
- `phases`: staring phases of each component in the tone ensembles (radians), defaults to sine phase
- `dur`: duration of components (seconds)
- `dur_ramp`: duration of raised cosine ramp applied to each component (seconds)
- `fs`: sampling rate (Hz)

# Returns
- `signal`: output tone, size (dur*fs, )
"""
function tone_ensemble(
    freqs,
    levels,
    phases=repeat([0.0], length(levels));
    dur=1.0,
    dur_ramp=0.01,
    fs=100e3,
)
    # Create empty output vector
    signal = zeros(Int(floor(dur*fs)))

    # Loop through pure tones and synthesize each
    for (f, l, ϕ) in zip(freqs, levels, phases)
        signal .+=
        @chain f begin
            pure_tone(ϕ, dur, fs)   # synthesize pure tone in sine phase
            scale_dbspl(l)          # scale to pedestal level
            cosine_ramp(dur_ramp, fs)    # ramp with raised-cosine ramp
        end
    end

    # Return result
    return signal
end

"""
    profile_analysis_tone(freqs::Vector, [target_comp::Int]; kwargs...)

Synthesizes a profile analysis tone composed of a deterministic set of components

Synthesized in the following way, per procedure used in Carney lab for so-called
`profile_analysis_iso` as of 09/22/2022:
- Background is synthesized (i.e., stimulus w/o target component), and the
  overall background level is set to the requested level. That is, the requested
  levels refers to the overall sound level of the background in dB SPL
- Target component is added in, with -infy dB SRS yielding a target component w/
  with the same amplitude as the background components and 0 dB yielding a target
  component with twice the amplitude of the background components

# Arguments
- `freqs::Tuple`: vector of frequenices to include in stimulus
- `target_comp`: which component should contain the increment (index into component_freqs, see code below)
- `fs=100e3`: sampling rate (Hz)
- `dur=0.10`: duration (s)
- `dur_ramp=0.01`: ramp duration (s)
- `pedestal_level=50.0`: overall sound level of background (dB SPL)
- `increment=0.0`: increment size in units of signal re: standard (dB)

# Returns
- `::Vector`: vector containing profile analysis tone
"""
function profile_analysis_tone(
    freqs,
    target_comp=Int(ceil(length(freqs)/2));
    fs=100e3,
    dur=0.10,
    dur_ramp=0.01,
    pedestal_level=50.0,
    increment=0.0,
    phase_mode="fixed"
)
    # First, synthesize background, including component at target frequency
    background = map(freqs) do freq
        if phase_mode == "fixed"
            pure_tone(freq, 0.0, dur, fs)
        else
            pure_tone(freq, 2π*rand(), dur, fs)
        end
    end
    background = sum(background)

    # Given this stimulus, calculate required gain to achieve desired background
    # / pedestal level
    gain = pedestal_level - dbspl(background)

    # Synthesize target increment
    if phase_mode == "fixed"
        target = pure_tone(freqs[target_comp], 0.0, dur, fs) .* (10 .^ (increment./20))
    else
        target = pure_tone(freqs[target_comp], 2π*rand(), dur, fs) .* (10 .^ (increment./20))
    end

    # Add together, ramp, and scale
    stimulus = background .+ target
    stimulus = amplify(stimulus, gain)
    stimulus = cosine_ramp(stimulus, dur_ramp, fs)

    # Return
    return stimulus
end

"""
    ProfileAnalysisTone

Stimulus subtype for profile-analysis tones.

Contains information about parameter values for a profile-analysis tone and synthesizes
matching tone using fixed sine-phase components. Pedestal levels can be fixed values or 
distributions, which are sampled on initialization of each instance to determine the value
of pedestal level used in synthesis. Default values provide precise match to parameters 
used in the behavioral PAHI experiments.

# Fields
- `center_freq`: center frequency of the tone complex (Hz)
- `n_comp`: number of components in the tone complex
- `freqs`: frequencies of each component in the tone complex (Hz)
- `target_comp`: which component should contain the increment
- `increment`: increment size in units of signal re: standard (dB)
- `fs`: sampling rate (Hz)
- `dur`: duration (s)
- `dur_ramp`: ramp duration (s)
- `pedestal_level`: level of un-incremented components (dB SPL)
"""
@with_kw struct ProfileAnalysisTone <: Utilities.Stimulus
    # Stimulus interface
    dur::Float64=0.20
    fs::Float64=100e3

    # Stimulus parameters
    center_freq::Float64=1000.0
    n_comp::Int64=5
    freqs::Vector{Float64}=LogRange(center_freq * (1/5), center_freq * 5, n_comp)
    target_comp::Int64=Int(ceil(length(freqs)/2))
    increment::Float64=0.0
    pedestal_level::Union{Float64, Uniform{Float64}}=70.0
    pedestal_level_actual::Float64=pedestal_level isa Distribution ? rand(pedestal_level) : pedestal_level
    dur_ramp::Float64=0.01
end

function Utilities.synthesize(x::ProfileAnalysisTone)
    profile_analysis_tone(
        x.freqs,
        x.target_comp;
        fs=x.fs,
        dur=x.dur,
        dur_ramp=x.dur_ramp,
        pedestal_level=x.pedestal_level_actual,
        increment=x.increment,
        phase_mode="fixed",
    )
end

"""
    srs_to_ΔL(srs)

Converts a signal re: standard value in dB to a ΔL in dB.

Here, srs is the signal re: standard, i.e., 20 * log10(ΔA/A), ΔL is the difference between
levels of the standard and the standard + signal in dB.
"""
srs_to_ΔL(srs) = 20 * log10(1 + 10^(srs/20))

"""
    ΔL_to_srs(ΔL)

Converts a ΔL value in dB to a signal re: standard value in dB.

Here, srs is the signal re: standard, i.e., 20 * log10(ΔA/A), ΔL is the difference between
levels of the standard and the standard + signal in dB.
"""
ΔL_to_srs(ΔL) = 20 * log10(10^(ΔL/20) - 1)
