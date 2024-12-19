export GaussianNoise, PinkNoise, SAMNoise

"""
    GaussianNoise <: Stimulus

Unmodulated bandlimited Gaussian noise 
"""
@with_kw struct GaussianNoise <: Stimulus
    flow::Float64=20.0
    fhigh::Float64=10e3
    dur::Float64=0.5
    dur_ramp::Float64=0.01
    l::Float64=30.0  # spectrum level
    fs::Float64=100e3
end

function synthesize(x::GaussianNoise)
    Parameters.@unpack flow, fhigh, dur, fs, dur_ramp, l = x

    # Synthesize carrier as bandlimited Gaussian noise 
    filter = digitalfilter(Bandpass(flow, fhigh; fs=fs), Butterworth(4))
    level_spl = l + 10*log10(fs/2)  # get spl from spectrum level
    carrier = scale_dbspl(randn(Int(floor(dur*fs))), level_spl)
    carrier = filt(filter, carrier)
end

"""
    PinkNoise <: Stimulus

Unmodulated bandlimited Gaussian noise 
"""
@with_kw struct PinkNoise <: Stimulus
    flow::Float64=20.0
    fhigh::Float64=10e3
    dur::Float64=0.5
    dur_ramp::Float64=0.01
    l::Float64=30.0  # overall level
    fs::Float64=100e3
end

function synthesize(x::PinkNoise)
    Parameters.@unpack flow, fhigh, dur, fs, dur_ramp, l = x

    # Synthesize carrier of simple broadband white noise
    carrier = randn(Int(floor(dur*fs)))

    # Compute spectrum and divide each frequency component by 1/sqrt(f)
    C = fft(carrier)
    C[2:end] = C[2:end] ./ sqrt.(abs.(fftfreq(length(carrier), 100e3)[2:end]))    
    carrier = real.(ifft(C))

    # Filter and scale to requested level
    filter = digitalfilter(Bandpass(flow, fhigh; fs=fs), Butterworth(4))
    carrier = scale_dbspl(filt(filter, carrier), l)
end

# function test()
#     fig = Figure()
#     ax = Axis(fig[1, 1]; xscale=log10)
#     freqs = fftfreq(length(carrier), 100e3)
#     freqs = freqs[2:50000]
#     X = 20 .* log10.(abs.(fft(carrier)))[2:50000]
#     X = X .- X[argmin(freqs .- 1000.0)]
#     lines!(ax, freqs, X)
#     xlims!(ax, 1000.0 * 2.0^-2, 1000.0*2.0^2)
#     ax.xticks = 1000.0 .* (2.0 .^ (-2.0:0.5:2.0))
#     fig
# end

"""
    SAMNoise <: Stimulus

Sinusoidally amplitude-modulated broadband noise
"""
@with_kw struct SAMNoise <: Stimulus
    flow::Float64=20.0
    fhigh::Float64=10e3
    fm::Float64=10.0
    ϕm::Float64=0π
    m::Float64=1.0
    dur::Float64=0.5
    dur_ramp::Float64=0.01
    l::Float64=30.0
    fs::Float64=100e3
end

function synthesize(x::SAMNoise)
    Parameters.@unpack flow, fhigh, fm, ϕm, m, dur, fs, dur_ramp, l = x

    # Synthesize carrier as bandlimited Gaussian noise 
    filter = digitalfilter(Bandpass(flow, fhigh; fs=fs), Butterworth(4))
    level_spl = l + 10*log10(fs/2)  # get spl from spectrum level
    carrier = scale_dbspl(randn(Int(floor(dur*fs))), level_spl)
    carrier = filt(filter, carrier)
    level_spl_pre_mod = dbspl(carrier)

    # Synthesize modulator
    if fm == 0.0
        modulator = zeros(length(carrier))
    else
        modulator = pure_tone(fm, 0.0 - pi/2, dur, fs)
    end

    # Combine carrier and modulator, ramp, and scale
    stim = (1.0 .+ modulator) .* carrier
    stim = cosine_ramp(stim, 0.01, fs)
    scale_dbspl(stim, level_spl_pre_mod)
end
